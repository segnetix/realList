//
//  CloudCoordinator.swift
//  EnList
//
//  Created by Steven Gentry on 11/2/19.
//  Copyright © 2019 Steven Gentry. All rights reserved.
//

import Foundation
import CloudKit

class CloudCoordinator {
    
    // checks if the user has logged into their iCloud account or not
    static func iCloudIsAvailable() -> Bool {
        var iCloudDriveOn = false
        var netReachable  = false
        var networkType   = "network not reachable"
        
        // determine if iCloudDrive is enabled for realList
        if let _ = FileManager.default.ubiquityIdentityToken {
            iCloudDriveOn = true
        }
        
        // determine if network is reachable
        if (AppManager.sharedInstance.isReachable) {
            netReachable = true
        }
        
        // determine network Type
        if netReachable {
            if (AppManager.sharedInstance.reachabiltyNetworkType == "Wifi") {
                networkType = ".Wifi"
            } else if (AppManager.sharedInstance.reachabiltyNetworkType == "Cellular") {
                networkType = ".Cellular"
            }
        }
        
        print("iCloudDrive: \(iCloudDriveOn)  network reachable: \(netReachable)  network type: \(networkType)")
        
        return iCloudDriveOn && netReachable
    }
    

    // sends all records needing updating in batches to cloud storage
    static func batchRecordUpdate() {
        guard let database = appDelegate.privateDatabase else { return }
        
        let batchSize = 250                                             // this number must be no greater than 400
        let ckRecords = [CKRecord](appDelegate.updateRecords.keys)      // initializes an array of CKRecords with the keys from the updateRecords dictionary
        var startIndex = 0                                              // start index for each loop
        var stopIndex = -1                                              // stop index for each loop
        
        if ckRecords.count == 0 {
            print("batchRecordUpdate - ckRecords.count == 0")
            return
        }
        
        // submit a limited number (batchSize) of records in each operation
        repeat {
            startIndex = stopIndex + 1
            stopIndex += batchSize
            
            if stopIndex > ckRecords.count - 1 {
                stopIndex = ckRecords.count - 1
            }
            
            if stopIndex < startIndex {
                print("ERROR: batchRecordUpdate - stopIndex < startIndex")
                return
            }
            
            // set up a temp arrary of records for this batch
            var batchRecords = [CKRecord]()
            for i in startIndex...stopIndex {
                batchRecords.append(ckRecords[i])
            }
            
            print("batchRecordUpdate - \(startIndex+1) to \(stopIndex+1) of \(ckRecords.count)")
            
            let saveRecordsOperation = CKModifyRecordsOperation()
            saveRecordsOperation.recordsToSave = batchRecords
            saveRecordsOperation.savePolicy = .changedKeys
            saveRecordsOperation.perRecordCompletionBlock = { record, error in
                // deal with conflicts
                // set completionHandler of wrapper operation if it's the case
                if error == nil {
                    //print("batch save: \(record![key_name])")
                    let obj = appDelegate.updateRecords[record]
                    if obj is List {
                        let list = obj as! List
                        list.needToSave = false
                    } else if obj is Category {
                        let category = obj as! Category
                        category.needToSave = false
                    } else if obj is Item {
                        let item = obj as! Item
                        item.needToSave = false
                    } else if obj is ImageAsset {
                        let image = obj as! ImageAsset
                        image.needToDelete = false
                        image.deleteImageFile()
                    }
                } else {
                    // NOTE: This should be able to handle a CKErrorLimitExceeded error.
                    let obj = appDelegate.updateRecords[record]
                    if obj is List {
                        let list = obj as! List
                        print("batch update error: list \(list.name) \(error!.localizedDescription)")
                    } else if obj is Category {
                        let category = obj as! Category
                        print("batch update error: category \(category.name) \(error!.localizedDescription)")
                    } else if obj is Item {
                        let item = obj as! Item
                        print("batch update error: item \(item.name) \(error!.localizedDescription)")
                    } else if obj is ImageAsset {
                        let image = obj as! ImageAsset
                        print("batch update error: image \(image.imageGUID) \(error!.localizedDescription)")
                    }
                }
            }
            
            saveRecordsOperation.modifyRecordsCompletionBlock = { savedRecords, deletedRecordIDs, error in
                if error == nil && savedRecords != nil {
                    print("batch save operation complete for \(savedRecords!.count) records")
                } else if error != nil {
                    // ******* NOTE: This should be able to handle a CKErrorLimitExceeded error. ******* //
                    print("*** ERROR: batchRecordUpdate - \(error!.localizedDescription)")
                    print("The following records had problems: \(String(describing: (error as NSError?)!.userInfo[CKPartialErrorsByItemIDKey]))")
                }
            }
            
            // execute the batch save operation
            database.add(saveRecordsOperation)
            
        } while stopIndex < ckRecords.count - 1
        
    }
    
    // deletes an array of records
    static func batchRecordDelete(_ deleteRecords: [CKRecord]) {
        guard let database = appDelegate.privateDatabase else { return }
        
        // generate the array of recordIDs to be deleted
        var deleteRecordIDs = [CKRecord.ID]()
        for record in deleteRecords {
            deleteRecordIDs.append(record.recordID)
        }
        
        let deleteRecordsOperation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: deleteRecordIDs)
        deleteRecordsOperation.recordsToSave = nil
        deleteRecordsOperation.recordIDsToDelete = deleteRecordIDs
        deleteRecordsOperation.perRecordCompletionBlock = { record, error in
            if error == nil {
                print("batchRecordDelete: deleted \(String(describing: record[key_objectName]))")
            } else if error != nil {
                print("*** ERROR: batchRecordDelete: \(error!.localizedDescription)")
            }
        }
        deleteRecordsOperation.modifyRecordsCompletionBlock = { savedRecords, deletedRecordIDs, error in
            if error == nil {
                print("batch delete operation complete - \(String(describing: savedRecords?.count)) deleted.")
            } else {
                // ******* NOTE: This should be able to handle a CKErrorLimitExceeded error. ******* //
                print("*** ERROR: batchRecordDelete. The following records had problems: \(String(describing: (error as NSError?)?.userInfo[CKPartialErrorsByItemIDKey]))")
            }
        }
        
        // execute the batch delete operation
        database.add(deleteRecordsOperation)
    }
    
    // pulls all list, category and item data from cloud storage
    static func fetchCloudData(_ refreshLabel: UILabel?, refreshEnd:@escaping () -> Void) {
        //NSLog("fetchCloudData...")
        if appDelegate.isUpdating {
            // we only want one refresh running at a time
            refreshEnd()
            return
        }
        
        appDelegate.isUpdating = true
        appDelegate.refreshLabel = refreshLabel
        appDelegate.refreshEnd = refreshEnd
        
        guard let database = appDelegate.privateDatabase else { return }
        guard iCloudIsAvailable() else {
            print("fetchCloudData - iCloud is not available...")
            if let refreshLabel = appDelegate.refreshLabel {
                refreshLabel.text = NSLocalizedString("iCloud_not_available", comment: "iCloud not available.")
                Utilities.runAfterDelay(1.5, block: {
                    appDelegate.refreshEnd()
                    appDelegate.refreshLabel = nil
                    appDelegate.isUpdating = false
                })
            } else {
                appDelegate.isUpdating = false
            }
            return
        }
        
        let resultCount = 0         // default value will let iCloud server decide how much to send in each block
        var itemFetchCount = 0      // holds the number of item records fetched
        let msg = NSLocalizedString("Fetching_Data", comment: "Fetching data message for the iCloud import HUD.")
        
        if let refreshLabel = appDelegate.refreshLabel {
            refreshLabel.text = msg
        } else {
            HUDControl.startHUD("iCloud", subtitle: msg)
        }
        
        // clear the record arrays
        appDelegate.listFetchArray.removeAll()
        appDelegate.categoryFetchArray.removeAll()
        appDelegate.itemFetchArray.removeAll()
        appDelegate.deleteFetchArray.removeAll()
        appDelegate.itemReferences.removeAll()   // this array will be populated after the items have been merged with any item references that need image updates
        
        // set up query operations
        let truePredicate = NSPredicate(value: true)
        
        let listQuery = CKQuery(recordType: ListsRecordType, predicate: truePredicate)
        let categoryQuery = CKQuery(recordType: CategoriesRecordType, predicate: truePredicate)
        let itemQuery = CKQuery(recordType: ItemsRecordType, predicate: truePredicate)
        let deleteQuery = CKQuery(recordType: DeletesRecordType, predicate: truePredicate)
        
        listQuery.sortDescriptors = [NSSortDescriptor(key: key_order, ascending: true)]
        categoryQuery.sortDescriptors = [NSSortDescriptor(key: key_order, ascending: true)]
        itemQuery.sortDescriptors = [NSSortDescriptor(key: key_order, ascending: true)]
        
        var listFetch = CKQueryOperation(query: listQuery)
        var categoryFetch = CKQueryOperation(query: categoryQuery)
        var deleteFetch = CKQueryOperation(query: deleteQuery)
        var itemFetch = CKQueryOperation(query: itemQuery)
        
        listFetch.resultsLimit = resultCount
        categoryFetch.resultsLimit = resultCount
        deleteFetch.resultsLimit = resultCount
        itemFetch.resultsLimit = resultCount
        
        // set up the record fetched block
        listFetch.recordFetchedBlock = { (record : CKRecord!) in
            appDelegate.listFetchArray.append(record)
            //print("list recordFetchedBlock: \(record[key_name]) \(record[key_order]) \(record.recordID.recordName)")
        }
        
        categoryFetch.recordFetchedBlock = { (record : CKRecord!) in
            appDelegate.categoryFetchArray.append(record)
            //print("category recordFetchedBlock: \(record[key_name]) \(record[key_order]) \(record.recordID.recordName)")
        }
        
        deleteFetch.recordFetchedBlock = { (record : CKRecord!) in
            appDelegate.deleteFetchArray.append(record)
            //print("delete recordFetchedBlock: \(record[key_itemName]) \(record[key_deletedDate]) \(record.recordID.recordName)")
        }
        
        itemFetch.recordFetchedBlock = { (record : CKRecord!) in
            appDelegate.itemFetchArray.append(record)
            itemFetchCount += 1
            //print("item recordFetchedBlock: \(record[key_name]) \(record[key_order]) \(record.recordID.recordName)")
        }

        // set up completion blocks with cursors so they can recursively gather all of the records
        // also handles cascading cancellation of the operations
        
        // listFetch
        listFetch.queryCompletionBlock = { (cursor : CKQueryOperation.Cursor?, error : Error?) in
            if error != nil {
                print("listFetch error: \(String(describing: error?.localizedDescription))")
            }
            
            if cursor != nil {
                print("\(appDelegate.listFetchArray.count) lists - there is more data to fetch...")
                let newOperation = CKQueryOperation(cursor: cursor!)
                newOperation.recordFetchedBlock = listFetch.recordFetchedBlock
                newOperation.queryCompletionBlock = listFetch.queryCompletionBlock
                newOperation.resultsLimit = resultCount
                listFetch = newOperation
                appDelegate.externalListFetch = listFetch
                database.add(newOperation)
            } else if listFetch.isCancelled {
                print("listFetch cancelled...")
                appDelegate.externalListFetch = nil
                appDelegate.externalCategoryFetch?.cancel()
                appDelegate.externalDeleteFetch?.cancel()
                appDelegate.externalItemFetch?.cancel()
                HUDControl.stopHUD()
                appDelegate.isUpdating = false
                appDelegate.refreshEnd()
            } else {
                //NSLog("list fetch complete")
                DispatchQueue.main.async { appDelegate.externalListFetch = nil }
            }
        }
        
        // categoryFetch
        categoryFetch.queryCompletionBlock = { (cursor : CKQueryOperation.Cursor?, error : Error?) in
            if error != nil {
                print("categoryFetch error: \(String(describing: error?.localizedDescription))")
            }
            
            if cursor != nil {
                print("\(appDelegate.categoryFetchArray.count) categories - there is more data to fetch...")
                let newOperation = CKQueryOperation(cursor: cursor!)
                newOperation.recordFetchedBlock = categoryFetch.recordFetchedBlock
                newOperation.queryCompletionBlock = categoryFetch.queryCompletionBlock
                newOperation.resultsLimit = resultCount
                categoryFetch = newOperation
                appDelegate.externalCategoryFetch = categoryFetch
                database.add(newOperation)
            } else if categoryFetch.isCancelled {
                print("categoryFetch cancelled...")
                appDelegate.externalCategoryFetch = nil
                appDelegate.externalDeleteFetch?.cancel()
                appDelegate.externalItemFetch?.cancel()
                HUDControl.stopHUD()
            } else {
                //NSLog("category fetch complete")
                DispatchQueue.main.async { appDelegate.externalCategoryFetch = nil }
            }
        }
        
        // deleteFetch
        deleteFetch.queryCompletionBlock = { (cursor : CKQueryOperation.Cursor?, error : Error?) in
            if error != nil {
                print("deleteFetch error: \(String(describing: error?.localizedDescription))")
            }
            
            if cursor != nil {
                print("\(appDelegate.deleteFetchArray.count) delete items - there is more data to fetch...")
                let newOperation = CKQueryOperation(cursor: cursor!)
                newOperation.recordFetchedBlock = deleteFetch.recordFetchedBlock
                newOperation.queryCompletionBlock = deleteFetch.queryCompletionBlock
                newOperation.resultsLimit = resultCount
                deleteFetch = newOperation
                appDelegate.externalDeleteFetch = deleteFetch
                database.add(newOperation)
            } else if deleteFetch.isCancelled {
                print("deleteFetch cancelled...")
                appDelegate.externalDeleteFetch = nil
                appDelegate.externalItemFetch?.cancel()
                HUDControl.stopHUD()
            } else {
                //NSLog("delete fetch complete")
                DispatchQueue.main.async { appDelegate.externalDeleteFetch = nil }
            }
        }
        
        // itemFetch - passes on to mergeCloudData when complete
        itemFetch.queryCompletionBlock = { (cursor : CKQueryOperation.Cursor?, error : Error?) in
            if error != nil {
                print("itemFetch error: \(String(describing: error?.localizedDescription))")
            }
            
            // update HUD
            DispatchQueue.main.async {
                if itemFetchCount > 0 {
                    if let refreshLabel = appDelegate.refreshLabel {
                        refreshLabel.text = msg + " \(itemFetchCount)"
                    } else if appDelegate.hud != nil {
                        appDelegate.hud!.detailsLabel.text = msg + " \(itemFetchCount)"
                    }
                }
            }
            
            if cursor != nil {
                //print("item cursor: \(cursor)")
                print("\(appDelegate.itemFetchArray.count) items - there is more data to fetch...")
                let newOperation = CKQueryOperation(cursor: cursor!)
                newOperation.recordFetchedBlock = itemFetch.recordFetchedBlock
                newOperation.queryCompletionBlock = itemFetch.queryCompletionBlock
                newOperation.resultsLimit = resultCount
                itemFetch = newOperation
                appDelegate.externalItemFetch = itemFetch
                database.add(newOperation)
            } else if itemFetch.isCancelled {
                print("itemFetch cancelled...")
                appDelegate.externalItemFetch = nil
                HUDControl.stopHUD()
            } else {
                //NSLog("item fetch complete")
                
                // need to wait for all fetches before continuing to merge
                //NSLog("start fetch wait...")
                repeat {
                    // hold until other completion blocks finish
                } while appDelegate.externalListFetch != nil || appDelegate.externalCategoryFetch != nil || appDelegate.externalDeleteFetch != nil
                //NSLog("end fetch wait...")
                
                //NSLog("array counts - list: \(self.listFetchArray.count) category: \(self.categoryFetchArray.count) item: \(self.itemFetchArray.count) delete: \(self.deleteFetchArray.count)")
                
                DispatchQueue.main.async {
                    //NSLog("dispatch main thread merge")
                    appDelegate.externalListFetch = nil
                    appDelegate.externalCategoryFetch = nil
                    appDelegate.externalItemFetch = nil
                    appDelegate.externalDeleteFetch = nil
                    
                    // merge cloud data
                    CloudCoordinator.mergeCloudData()
                }
            }
        }
        
        // set external fetch pointers
        appDelegate.externalListFetch = listFetch
        appDelegate.externalCategoryFetch = categoryFetch
        appDelegate.externalDeleteFetch = deleteFetch
        appDelegate.externalItemFetch = itemFetch
        
        // execute the query operations
        database.add(itemFetch)
        database.add(categoryFetch)
        database.add(listFetch)
        database.add(deleteFetch)
    }
    
    // must be called on main thread
    @objc static func cancelCloudDataFetch() {
        guard Thread.isMainThread else { print("*** calling from other than main thread..."); return }
        
        print("*** cancelCloudDataFetch ***")
        var canceled = false
        
        // executes on main thread
        if let externalListFetch = appDelegate.externalListFetch {
            externalListFetch.cancel()
            canceled = true
        }
        if let externalCategoryFetch = appDelegate.externalCategoryFetch {
            externalCategoryFetch.cancel()
            canceled = true
        }
        if let externalDeleteFetch = appDelegate.externalDeleteFetch {
            externalDeleteFetch.cancel()
            canceled = true
        }
        if let externalItemFetch = appDelegate.externalItemFetch {
            externalItemFetch.cancel()
            canceled = true
        }
        
        if canceled && appDelegate.refreshLabel == nil {
            if let itemVC = appDelegate.itemViewController {
                itemVC.dataFetchCanceledAlert()
            }
        }
        
        appDelegate.refreshEnd()
    }
    
    // pulls image data in batches for items needing updating (itemReferences)
    static func fetchImageData() {
        //NSLog("fetchImageData - \(itemReferences.count) items need new images...")
        
        guard let database = appDelegate.privateDatabase else { return }
        
        let batchSize = 50          // size of the batch request block
        var imageFetchCount = 0     // holds count of fetched images
        
        if appDelegate.itemReferences.count == 0 {
            print("fetchImageData = itemReferences.count == 0")
            HUDControl.stopHUD()
            return
        }
        
        // submit a limited number of references in each operation
        var startIndex = 0
        var stopIndex = -1
        var loop = 0
        //let msg = NSLocalizedString("Fetching_Images", comment: "Fetching images message for the iCloud import HUD.")
        
        //if itemReferences.count > 5 {
        //    startHUD("iCloud", subtitle: msg + " 0")
        //}
        
        repeat {
            startIndex = stopIndex + 1
            stopIndex += batchSize
            loop += 1
            
            if stopIndex > appDelegate.itemReferences.count - 1 {
                stopIndex = appDelegate.itemReferences.count - 1
            }
            
            if stopIndex < startIndex {
                print("ERROR: fetchImageData - stopIndex < startIndex")
                HUDControl.stopHUD()
                return
            }
            
            // temp image record array
            var imageArray = [CKRecord]()
            
            // set up a temp arrary of references for this batch
            var batchReferences = [CKRecord.Reference]()
            for i in startIndex...stopIndex {
                batchReferences.append(appDelegate.itemReferences[i])
            }
            
            print("fetchImageData - \(startIndex+1) to \(stopIndex+1) of \(appDelegate.itemReferences.count)")
            
            let predicate = NSPredicate(format: "owningItem IN %@", argumentArray: [batchReferences])
            let imageQuery = CKQuery(recordType: ImagesRecordType, predicate: predicate)
            let imageFetch = CKQueryOperation(query: imageQuery)
            
            imageFetch.recordFetchedBlock = { (record : CKRecord!) in
                imageArray.append(record)
                imageFetchCount += 1
                //print("image recordFetchedBlock - GUID: \(record[key_imageGUID]) recordId: \(record.recordID.recordName)")
            }
            
            imageFetch.queryCompletionBlock = { [loop, startIndex, stopIndex] (cursor : CKQueryOperation.Cursor?, error : Error?) in
                if cursor != nil {
                    print("******* ERROR:  fetchImageData - there is more data to fetch and there should not be...")
                }
                
                if error != nil {
                    print("imageFetch error: \(String(describing: error?.localizedDescription) )")
                }
                
                print("image record fetch operation for loop \(loop) is complete... \(startIndex+1) to \(stopIndex+1)")
                
                // send this batch of image records to the merge method on the main thread
                DispatchQueue.main.async {
                    CloudCoordinator.mergeImageCloudData(imageArray)
                }
            }
            
            // execute the query operation
            database.add(imageFetch)
            
        } while stopIndex < appDelegate.itemReferences.count - 1
    }
    
    // after fetching cloud data, merge with local data
    // NOTE: this must be called from the main thread
    static func mergeCloudData() {
        //NSLog("mergeCloudData...")
        
        // the closing hud (1.0 sec) will prevent user interaction during the merge
        HUDControl.startHUDwithDone()
        
        for cloudList in appDelegate.listFetchArray {
            DataPersistenceCoordinator.updateFromRecord(cloudList, forceUpdate: false)
        }
        
        for cloudCategory in appDelegate.categoryFetchArray {
            DataPersistenceCoordinator.updateFromRecord(cloudCategory, forceUpdate: false)
        }
        
        for cloudItem in appDelegate.itemFetchArray {
           DataPersistenceCoordinator.updateFromRecord(cloudItem, forceUpdate: false)
        }
        
        // check if any of the local objects are in the deleted list and if so delete
        DataPersistenceCoordinator.processDeletedObjects()
        
        // purge old delete records from cloud storage
        purgeOldDeleteRecords()
        
        // now that items are merged we can call fetchImageData to
        // retreive any images that need updating
        CloudCoordinator.fetchImageData()
        
        // refreshListData
        DataPersistenceCoordinator.refreshListData()
        
        // reload list and item views and update orders
        if let itemVC = appDelegate.itemViewController {
            itemVC.refreshItems()
        }
        
        if let listVC = appDelegate.listViewController {
            listVC.tableView.reloadData()
        }
        
        ListData.resetListCategoryAndItemOrderByPosition()
        
        // update indices and clear needToSave on all objects as we are clean from local load
        ListData.updateIndices()
        ListData.clearNeedToSave()
        
        // shows the completed HUD then dismisses itself
        appDelegate.isUpdating = false
        appDelegate.refreshEnd()
        appDelegate.refreshLabel = nil
        appDelegate.refreshEnd = { }
    }
    
    static func mergeImageCloudData(_ imageRecords: [CKRecord]) {
        //NSLog("mergeImageCloudData...")
        
        //startHUD("iCloud", subtitle: NSLocalizedString("Merging_Images", comment: "Merging images message for the iCloud import HUD."))
        
        for cloudImage in imageRecords {
            DataPersistenceCoordinator.updateFromRecord(cloudImage, forceUpdate: false)
        }
    }
    
    // purge any delete records older than one month
    static func purgeOldDeleteRecords() {
        //NSLog("purgeOldDeleteRecords...")
        
        let now = Date.init()
        let userCalendar = Calendar.current
        var timeInterval = DateComponents()
        timeInterval.day = appDelegate.deletePurgeDays
        
        var purgeRecords = [CKRecord]()
        
        // collect records to be purged
        for record in appDelegate.deleteFetchArray {
            if let deleteDate = record[key_deletedDate] as? Date {
                let expirationDate = (userCalendar as NSCalendar).date(byAdding: timeInterval, to: deleteDate, options: [])!
                
                if now > expirationDate {
                    purgeRecords.append(record)
                }
            }
        }
        
        // submit delete operation
        CloudCoordinator.batchRecordDelete(purgeRecords)
    }
    
}
