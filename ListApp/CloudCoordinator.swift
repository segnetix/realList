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
    private static let container = CKContainer.default()
    static let privateDatabase = container.privateCloudDatabase
    static let sharedDatabase = container.sharedCloudDatabase
    static let sharedZoneName = "SharedZone"
    static let sharedZone = CKRecordZone(zoneName: sharedZoneName)
    static let sharedZoneID = sharedZone.zoneID
    
    // iCloud query operations
    static var externalListFetchOperation: CKQueryOperation?
    static var externalCategoryFetchOperation: CKQueryOperation?
    static var externalDeleteFetchOperation: CKQueryOperation?
    static var externalItemFetchOperation: CKQueryOperation?
    
    // cloud record fetch arrays for launch data merge
    static var listFetchArray = [CKRecord]()
    static var categoryFetchArray = [CKRecord]()
    static var itemFetchArray = [CKRecord]()
    static var deleteFetchArray = [CKRecord]()
    
    // holds references to items that have outdated image assets
    static var itemReferences = [CKRecord.Reference]()
    
    // cloud record array for uploading to the cloud
    static var updateRecords = [CKRecord: AnyObject?]()
    
    // MARK:- Functions
    
    // adds the given record to the array of records to be saved to the cloud
    static func addToUpdateRecords(_ record: CKRecord, obj: AnyObject) {
        updateRecords[record] = obj
    }
    
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
    
    static func sharedZoneExists(completion: @escaping (Bool, Error?) -> Void) {
        let fetchZonesOperation = CKFetchRecordZonesOperation.fetchAllRecordZonesOperation()
        
        fetchZonesOperation.fetchRecordZonesCompletionBlock = { (recordZones: [CKRecordZone.ID : CKRecordZone]?, error: Error?) -> Void in
            guard error == nil else {
                completion(false, error)
                return
            }
                    
            if let fetchedRecordZones = recordZones {
                let hasSharedZone = fetchedRecordZones.contains(where: { $0.key.zoneName == sharedZoneName } )
                completion(hasSharedZone, nil)
            } else {
                completion(false, nil)
            }
        }
        
        fetchZonesOperation.qualityOfService = .utility
        let container = CKContainer.default()
        let db = container.privateCloudDatabase
        db.add(fetchZonesOperation)
    }
    
    // checks for a shared zone and creates one once if necessary
    static func setupSharedZone(completion: @escaping (Bool, Error?) -> Void) {
//        guard !UserDefaults.standard.bool(forKey: key_sharedZoneCreated) else {
//            completion(false, nil)
//            return
//        }
        
        let operation = CKModifyRecordZonesOperation(recordZonesToSave: [sharedZone], recordZoneIDsToDelete: [])
        operation.modifyRecordZonesCompletionBlock = { recordZones, recordZoneIDs, error in
            guard error == nil else {
                completion(false, error)
                return
            }
            
            // update the flag to note the shared zone has been created
            //UserDefaults.standard.set(true, forKey: key_sharedZoneCreated)
            
            // set flag to note that we will need to save after data migration
            DispatchQueue.main.async {
                appDelegate.needsDataSaveOnMigration = true
            }
            
            completion(true, nil)
        }
        
        operation.qualityOfService = .utility
        privateDatabase.add(operation)
    }
    
// Development only
//    static func deleteSharedZone() {
//        let operation = CKModifyRecordZonesOperation(recordZonesToSave: [], recordZoneIDsToDelete: [sharedZone.zoneID])
//        operation.modifyRecordZonesCompletionBlock = { recordZones, recordZoneIDs, error in
//            print("deleted zone: \(recordZoneIDs)")
//        }
//
//        operation.qualityOfService = .utility
//        privateDatabase.add(operation)
//    }

    // sends all records needing updating in batches to cloud storage (shared zone)
    static func batchRecordUpdate() {
        let database = privateDatabase
        let batchSize = 250                                // this number must be no greater than 400
        let ckRecords = [CKRecord](updateRecords.keys)     // initializes an array of CKRecords with the keys from the updateRecords dictionary
        var startIndex = 0                                 // start index for each loop
        var stopIndex = -1                                 // stop index for each loop
        
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
                    let obj = updateRecords[record]
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
                    let obj = updateRecords[record]
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
                    print("all list data saved to cloud for \(savedRecords!.count) records")
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
        let database = privateDatabase

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
    
    // pulls all list, category and item data from cloud storage and merges with local data
    static func fetchCloudData(_ refreshLabel: UILabel?, refreshEnd: @escaping () -> Void) {
        //NSLog("fetchCloudData...")
        if appDelegate.isUpdating {
            // we only want one refresh running at a time
            return
        }
        
        // HUD setup
        appDelegate.isUpdating = true
        appDelegate.refreshLabel = refreshLabel
        appDelegate.refreshEnd = refreshEnd
        
        let database = privateDatabase
        
        guard iCloudIsAvailable() else {
            print("fetchCloudData - iCloud is not available...")
            if let refreshLabel = appDelegate.refreshLabel {
                refreshLabel.text = NSLocalizedString("iCloud_not_available", comment: "iCloud not available.")
                Utilities.runAfterDelay(1.5, block: {
                    assert(Thread.isMainThread)
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
        listFetchArray.removeAll()
        categoryFetchArray.removeAll()
        itemFetchArray.removeAll()
        deleteFetchArray.removeAll()
        itemReferences.removeAll()   // this array will be populated after the items have been merged with any item references that need image updates
        
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
            listFetchArray.append(record)
            //print("list recordFetchedBlock: \(record[key_name]) \(record[key_order]) \(record.recordID.recordName)")
        }
        
        categoryFetch.recordFetchedBlock = { (record : CKRecord!) in
            categoryFetchArray.append(record)
            //print("category recordFetchedBlock: \(record[key_name]) \(record[key_order]) \(record.recordID.recordName)")
        }
        
        deleteFetch.recordFetchedBlock = { (record : CKRecord!) in
            deleteFetchArray.append(record)
            //print("delete recordFetchedBlock: \(record[key_itemName]) \(record[key_deletedDate]) \(record.recordID.recordName)")
        }
        
        itemFetch.recordFetchedBlock = { (record : CKRecord!) in
            itemFetchArray.append(record)
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
                print("\(listFetchArray.count) lists - there is more data to fetch...")
                let newOperation = CKQueryOperation(cursor: cursor!)
                newOperation.recordFetchedBlock = listFetch.recordFetchedBlock
                newOperation.queryCompletionBlock = listFetch.queryCompletionBlock
                newOperation.resultsLimit = resultCount
                listFetch = newOperation
                externalListFetchOperation = listFetch
                database.add(newOperation)
            } else if listFetch.isCancelled {
                print("listFetch cancelled...")
                externalListFetchOperation = nil
                externalCategoryFetchOperation?.cancel()
                externalDeleteFetchOperation?.cancel()
                externalItemFetchOperation?.cancel()
                HUDControl.stopHUD()
                appDelegate.isUpdating = false
                appDelegate.refreshEnd()
            } else {
                //NSLog("list fetch complete")
                DispatchQueue.main.async { externalListFetchOperation = nil }
            }
        }
        
        // categoryFetch
        categoryFetch.queryCompletionBlock = { (cursor : CKQueryOperation.Cursor?, error : Error?) in
            if error != nil {
                print("categoryFetch error: \(String(describing: error?.localizedDescription))")
            }
            
            if cursor != nil {
                print("\(categoryFetchArray.count) categories - there is more data to fetch...")
                let newOperation = CKQueryOperation(cursor: cursor!)
                newOperation.recordFetchedBlock = categoryFetch.recordFetchedBlock
                newOperation.queryCompletionBlock = categoryFetch.queryCompletionBlock
                newOperation.resultsLimit = resultCount
                categoryFetch = newOperation
                externalCategoryFetchOperation = categoryFetch
                database.add(newOperation)
            } else if categoryFetch.isCancelled {
                print("categoryFetch cancelled...")
                externalCategoryFetchOperation = nil
                externalDeleteFetchOperation?.cancel()
                externalItemFetchOperation?.cancel()
                HUDControl.stopHUD()
            } else {
                //NSLog("category fetch complete")
                DispatchQueue.main.async { externalCategoryFetchOperation = nil }
            }
        }
        
        // deleteFetch
        deleteFetch.queryCompletionBlock = { (cursor : CKQueryOperation.Cursor?, error : Error?) in
            if error != nil {
                print("deleteFetch error: \(String(describing: error?.localizedDescription))")
            }
            
            if cursor != nil {
                print("\(deleteFetchArray.count) delete items - there is more data to fetch...")
                let newOperation = CKQueryOperation(cursor: cursor!)
                newOperation.recordFetchedBlock = deleteFetch.recordFetchedBlock
                newOperation.queryCompletionBlock = deleteFetch.queryCompletionBlock
                newOperation.resultsLimit = resultCount
                deleteFetch = newOperation
                externalDeleteFetchOperation = deleteFetch
                database.add(newOperation)
            } else if deleteFetch.isCancelled {
                print("deleteFetch cancelled...")
                externalDeleteFetchOperation = nil
                externalItemFetchOperation?.cancel()
                HUDControl.stopHUD()
            } else {
                //NSLog("delete fetch complete")
                DispatchQueue.main.async { externalDeleteFetchOperation = nil }
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
                print("\(itemFetchArray.count) items - there is more data to fetch...")
                let newOperation = CKQueryOperation(cursor: cursor!)
                newOperation.recordFetchedBlock = itemFetch.recordFetchedBlock
                newOperation.queryCompletionBlock = itemFetch.queryCompletionBlock
                newOperation.resultsLimit = resultCount
                itemFetch = newOperation
                externalItemFetchOperation = itemFetch
                database.add(newOperation)
            } else if itemFetch.isCancelled {
                print("itemFetch cancelled...")
                externalItemFetchOperation = nil
                HUDControl.stopHUD()
            } else {
                //NSLog("item fetch complete")
                
                // need to wait for all fetches before continuing to merge
                //NSLog("start fetch wait...")
                repeat {
                    // hold until other completion blocks finish
                } while externalListFetchOperation != nil || externalCategoryFetchOperation != nil || externalDeleteFetchOperation != nil
                //NSLog("end fetch wait...")
                
                //NSLog("array counts - list: \(self.listFetchArray.count) category: \(self.categoryFetchArray.count) item: \(self.itemFetchArray.count) delete: \(self.deleteFetchArray.count)")
                
                DispatchQueue.main.async {
                    //NSLog("dispatch main thread merge")
                    externalListFetchOperation = nil
                    externalCategoryFetchOperation = nil
                    externalItemFetchOperation = nil
                    externalDeleteFetchOperation = nil
                    
                    // merge cloud data
                    mergeCloudData()
                }
            }
        }
        
        // set external fetch pointers
        externalListFetchOperation = listFetch
        externalCategoryFetchOperation = categoryFetch
        externalDeleteFetchOperation = deleteFetch
        externalItemFetchOperation = itemFetch
        
        // execute the query operations
        database.add(itemFetch)
        database.add(categoryFetch)
        database.add(listFetch)
        database.add(deleteFetch)
    }
    
    // must be called on main thread
    @objc static func cancelCloudDataFetch() {
        guard Thread.isMainThread else {
            print("*** calling from other than main thread...")
            appDelegate.isUpdating = false
            return
        }
        
        print("*** cancelCloudDataFetch ***")
        var canceled = false
        
        // executes on main thread
        if let externalListFetch = externalListFetchOperation {
            externalListFetch.cancel()
            canceled = true
        }
        if let externalCategoryFetch = externalCategoryFetchOperation {
            externalCategoryFetch.cancel()
            canceled = true
        }
        if let externalDeleteFetch = externalDeleteFetchOperation {
            externalDeleteFetch.cancel()
            canceled = true
        }
        if let externalItemFetch = externalItemFetchOperation {
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
    static func fetchImageData(forceUpdate: Bool, completion: @escaping () -> Void) {
        //NSLog("fetchImageData - \(itemReferences.count) items need new images...")
                
        let batchSize = 50          // size of the batch request block
        var imageFetchCount = 0     // holds count of fetched images
        
        if itemReferences.count == 0 {
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
            
            if stopIndex > itemReferences.count - 1 {
                stopIndex = itemReferences.count - 1
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
                batchReferences.append(itemReferences[i])
            }
            
            print("fetchImageData - \(startIndex+1) to \(stopIndex+1) of \(itemReferences.count)")
            
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
                    mergeImageCloudData(imageArray, forceUpdate: forceUpdate, completion: completion)
                }
            }
            
            // execute the query operation
            privateDatabase.add(imageFetch)
            
        } while stopIndex < itemReferences.count - 1
    }
    
    // after fetching cloud data, merge with local data
    // NOTE: this must be called from the main thread
    static func mergeCloudData() {
        assert(Thread.isMainThread)
        //NSLog("mergeCloudData...")
        
        // the closing hud (1.0 sec) will prevent user interaction during the merge
        HUDControl.startHUDwithDone()
        
        for cloudList in listFetchArray {
            DataPersistenceCoordinator.updateFromRecord(cloudList, forceUpdate: false)
        }
        
        for cloudCategory in categoryFetchArray {
            DataPersistenceCoordinator.updateFromRecord(cloudCategory, forceUpdate: false)
        }
        
        for cloudItem in itemFetchArray {
           DataPersistenceCoordinator.updateFromRecord(cloudItem, forceUpdate: false)
        }
        
        // check if any of the local objects are in the deleted list and if so delete
        DataPersistenceCoordinator.processDeletedObjects()
        
        // purge old delete records from cloud storage
        purgeOldDeleteRecords()
        
        // now that items are merged we can call fetchImageData to
        // retreive any images that need updating
        fetchImageData(forceUpdate: appDelegate.needsDataSaveOnMigration) {
            DispatchQueue.main.async {
                appDelegate.imageDataMergeComplete = true
            }
        }
        
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
        appDelegate.listDataMergeComplete = true
    }
    
    static func mergeImageCloudData(_ imageRecords: [CKRecord], forceUpdate: Bool, completion: @escaping () -> Void) {
        //NSLog("mergeImageCloudData...")
        
        //startHUD("iCloud", subtitle: NSLocalizedString("Merging_Images", comment: "Merging images message for the iCloud import HUD."))
        
        for cloudImage in imageRecords {
            DataPersistenceCoordinator.updateFromRecord(cloudImage, forceUpdate: forceUpdate)
        }
        
        completion()
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
        for record in deleteFetchArray {
            if let deleteDate = record[key_deletedDate] as? Date {
                let expirationDate = (userCalendar as NSCalendar).date(byAdding: timeInterval, to: deleteDate, options: [])!
                
                if now > expirationDate {
                    purgeRecords.append(record)
                }
            }
        }
        
        // submit delete operation
        batchRecordDelete(purgeRecords)
    }
    
    // delete all default zone records
    // this should be run once after successfully copying data to the shared zone
    static func deleteAllRecordsInDefaultZone() {
        
        container.privateCloudDatabase.fetchAllRecordZones { zones, error in
            guard let zones = zones, error == nil else {
                print("Error fetching zones.")
                return
            }
            
            let zoneIDs = zones.map { $0.zoneID }
            let defaultZoneID = zoneIDs.filter { $0.zoneName.contains("default") }
                        
            let deletionOperation = CKModifyRecordZonesOperation(recordZonesToSave: nil, recordZoneIDsToDelete: defaultZoneID)
            deletionOperation.modifyRecordZonesCompletionBlock = { _, deletedZones, error in
                guard error == nil else {
                    let error = error!

                    print("Error deleting records.", error)
                    return
                }

                print("Records successfully deleted in this zone.")
            }

            container.privateCloudDatabase.add(deletionOperation)
            
        }
    }
    
}
