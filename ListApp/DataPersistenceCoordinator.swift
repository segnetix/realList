//
//  DataPersistenceCoordinator.swift
//  EnList
//
//  Created by Steven Gentry on 11/2/19.
//  Copyright © 2019 Steven Gentry. All rights reserved.
//

import Foundation
import CloudKit

let key_selectionIndex          = "selectionIndex"
let key_printNotes              = "printNotes"
let key_namesCapitalize         = "namesCapitalize"
let key_namesSpellCheck         = "namesSpellCheck"
let key_namesAutocorrection     = "namesAutocorrection"
let key_notesCapitalize         = "notesCapitalize"
let key_notesSpellCheck         = "notesSpellCheck"
let key_notesAutocorrection     = "notesAutocorrection"
let key_picsInPrintAndEmail     = "picsInPrintAndEmail"

class DataPersistenceCoordinator {
    
    /// Saves current app state to disk, synchronously or asynchronously.
    static func saveState(async asynchronously: Bool) {
        func save() {
            // save current selection
            UserDefaults.standard.set(appDelegate.listViewController!.selectionIndex, forKey: key_selectionIndex)
            UserDefaults.standard.set(appDelegate.printNotes,                         forKey: key_printNotes)
            
            // save app settings
            UserDefaults.standard.set(appDelegate.namesCapitalize,                    forKey: key_namesCapitalize)
            UserDefaults.standard.set(appDelegate.namesSpellCheck,                    forKey: key_namesSpellCheck)
            UserDefaults.standard.set(appDelegate.namesAutocorrection,                forKey: key_namesAutocorrection)
            UserDefaults.standard.set(appDelegate.notesCapitalize,                    forKey: key_notesCapitalize)
            UserDefaults.standard.set(appDelegate.notesSpellCheck,                    forKey: key_notesSpellCheck)
            UserDefaults.standard.set(appDelegate.notesAutocorrection,                forKey: key_notesAutocorrection)
            UserDefaults.standard.set(appDelegate.picsInPrintAndEmail,                forKey: key_picsInPrintAndEmail)
            
            UserDefaults.standard.synchronize()
        }
        
        if asynchronously {
            DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async {
                save()
            }
        } else {
            save()
        }
    }
    
    /// Saves all app data.  If asynchronous then the save is put on a background thread.
    static func saveAll(asynch asynchronously: Bool) {
        saveState(async: asynchronously)
        saveListData(async: asynchronously)
        print("all list data saved locally...")
    }
    
    /// Writes list data locally and to the cloud
    static func saveListData(async asynchronously: Bool) {
        saveListDataCloud(async: asynchronously)
        saveListDataLocal(async: asynchronously)
    }
    
    /// Writes the complete object graph locally.
    static func saveListDataLocal(async asynchronously: Bool) {
        func save() {
            guard let archiveURL = appDelegate.archiveURL else { return }
            
            //let successfulSave = NSKeyedArchiver.archiveRootObject(ListData.lists, toFile: archiveURL.path)
            let successfulSave = ListData.saveLocal(filePath: archiveURL.path)
            
            if !successfulSave {
                print("ERROR: Failed to save list data locally...")
            }
        }
        
        if asynchronously {
            DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async {
                save()
            }
        } else {
            save()
        }
    }
    
    /// Writes any dirty objects to the cloud in a batch operation.
    static func saveListDataCloud(async asynchronously: Bool) {
        appDelegate.updateRecords.removeAll()   // empty the updateRecords array
        guard CloudCoordinator.iCloudIsAvailable() else { print("saveListDataCloud - iCloud is not available..."); return }
        
        func save() {
            // cloud batch save ready -- now send the records for batch updating
            CloudCoordinator.batchRecordUpdate()
        }
        
        // ListData.saveToCloud() must be run on the main thread to ensure that
        // we have gathered any records to be deleted before the
        // list data for the object is deleted
        ListData.saveToCloud()
        
        if asynchronously {
            DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async {
                save()
            }
        } else {
            save()
        }
    }
    
    // create or update a local object with the given record
    static func updateFromRecord(_ record: CKRecord, forceUpdate: Bool) {
        var list: List?
        var category: Category?
        var item: Item?
        var imageAsset: ImageAsset?
        var update: Bool = forceUpdate
        let localObj = ListData.getLocalObject(record.recordID.recordName)
        
        // compare the cloud version with local version
        var cloudDataTime: Date = Date.init(timeIntervalSince1970: TimeInterval.init())
        var localDataTime: Date = Date.init(timeIntervalSince1970: TimeInterval.init())
        
        // get cloud data mod time and local data mod time
        if record.modificationDate != nil { cloudDataTime = record.modificationDate! }
        
        switch record.recordType {
        case ListsRecordType:
            if localObj is List {
                list = localObj as? List
                if list!.modificationDate != nil {
                    localDataTime = list!.modificationDate! as Date
                }
            }
        case CategoriesRecordType:
            if localObj is Category {
                category = localObj as? Category
                if category!.modificationDate != nil {
                    localDataTime = category!.modificationDate! as Date
                }
            }
        case ItemsRecordType:
            if localObj is Item {
                item = localObj as? Item
                localDataTime = item!.modifiedDate as Date
            }
        case ImagesRecordType:
            if localObj is ImageAsset {
                imageAsset = localObj as? ImageAsset
                localDataTime = imageAsset!.modifiedDate as Date
            }
        default:
            print("*** ERROR: updateFromRecord - unknown record type received from cloud data...!")
            return
        }
        
        // if not forcing the update then check if cloud data is newer than local data
        if !forceUpdate {
            update = cloudDataTime > localDataTime
        }

        if update && (list != nil || category != nil || item != nil || imageAsset != nil) {
            // local record exists, so update the object
            switch record.recordType {
            case ListsRecordType:
                list!.updateFromRecord(record)
            case CategoriesRecordType:
                category!.updateFromRecord(record)
            case ItemsRecordType:
                item!.updateFromRecord(record)
            case ImagesRecordType:
                imageAsset!.updateFromRecord(record)
            default:
                break
            }
        } else if list == nil && category == nil && item == nil && imageAsset == nil {
            // local record does not exist, so add
            switch record.recordType {
            case ListsRecordType:
                let newList = List(name: "", createRecord: false)
                newList.updateFromRecord(record)
                ListData.appendList(newList)
                print("added new list: \(newList.name)")
            case CategoriesRecordType:
                if let list = getListFromReference(record) {
                    let newCategory = list.addCategory("", displayHeader: true, updateIndices: false, createRecord: false)
                    newCategory.updateFromRecord(record)
                    
                    print("added new category: \(newCategory.name)")
                } else {
                    print("*** ERROR: category \(String(describing: record[key_name])) can't find list \(String(describing: record[key_owningList]))")
                }
            case ItemsRecordType:
                if let category = getCategoryFromReference(record) {
                    if category.categoryRecord != nil {
                        if let list = getListFromReference(category.categoryRecord!) {
                            let item = list.addItem(category, name: "", state: ItemState.incomplete, updateIndices: false, createRecord: false)
                            
                            if let newItem = item {
                                newItem.updateFromRecord(record)
                                print("added new item: \(newItem.name)")
                            }
                        }
                    }
                } else {
                    print("*** ERROR: item \(String(describing: record[key_name])) can't find category \(String(describing: record[key_owningCategory]))")
                }
            case ImagesRecordType:
                if let item = getItemFromReference(record) {
                    if let image = item.addImageAsset() {
                        image.updateFromRecord(record)
                        print("added new image to item: '\(item.name)' imageGUID: \(image.imageGUID)")
                    }
                } else {
                    print("*** ERROR: image \(String(describing: record[key_imageGUID])) can't find item \(String(describing: record[key_owningItem]))")
                }
            default:
                break
            }
        }
    }
    
    // deletes local data associated with the given recordName
    static func deleteRecordLocal(_ recordName: String) {
        guard let listVC = appDelegate.listViewController else { return }
        guard let obj = ListData.getLocalObject(recordName) else { print("deleteRecord: recordName not found...!"); return }
        
        if obj is List {
            let list = obj as! List
            if let i = ListData.listIndex(of: list) {
                _ = ListData.removeListAt(i)
                
                if ListData.listCount > 0 {
                    var selectRow = 0
                    
                    if i-1 < ListData.listCount {
                        // select the previous row before deleting
                        selectRow = i-1
                    }
                    let rowToSelect:IndexPath = IndexPath(row: selectRow, section: 0)
                    listVC.tableView.selectRow(at: rowToSelect, animated: true, scrollPosition: UITableView.ScrollPosition.none)
                    listVC.tableView(listVC.tableView, didSelectRowAt: rowToSelect)
                }
            }
        } else if obj is Category {
            let category = obj as! Category
            let list = ListData.getListForCategory(category)
            if  let list = list {
                list.categories.removeObject(category)
            }
        } else if obj is Item {
            let item = obj as! Item
            let category = ListData.getCategoryForItem(item)
            if category != nil {
                category!.items.removeObject(item)
            }
        }
    }
    
    
    // process the notification records
    @objc static func processNotificationRecords() {
        NSLog("*** processNotificationRecords - update records: \(appDelegate.notificationArray.count)  delete records: \(appDelegate.deleteNotificationArray.count)")
        
        // separate notification records into list, category, item and image arrays
        var listRecords = [CKRecord]()
        var categoryRecords = [CKRecord]()
        var itemRecords = [CKRecord]()
        var imageRecords = [CKRecord]()
        
        for record in appDelegate.notificationArray {
            switch record.recordType {
            case ListsRecordType:
                listRecords.append(record)
            case CategoriesRecordType:
                categoryRecords.append(record)
            case ItemsRecordType:
                itemRecords.append(record)
            case ImagesRecordType:
                imageRecords.append(record)
            default:
                break
            }
        }
        
        // process the updates in logical order
        for listRecord in listRecords {
            updateFromRecord(listRecord, forceUpdate: false)
        }
        for categoryRecord in categoryRecords {
            updateFromRecord(categoryRecord, forceUpdate: false)
        }
        for itemRecord in itemRecords {
            updateFromRecord(itemRecord, forceUpdate: false)
        }
        for imageRecord in imageRecords {
            updateFromRecord(imageRecord, forceUpdate: false)
        }
        
        // process the delete records
        for deleteRecordIDName in appDelegate.deleteNotificationArray {
            deleteRecordLocal(deleteRecordIDName)
        }
        
        // clear notification arrays and event flag
        appDelegate.notificationArray.removeAll()
        appDelegate.deleteNotificationArray.removeAll()
        appDelegate.notificationProcessingEventIsPending = false
        
        // now refresh the list data
        refreshListData()
        //NSLog("*** processNotificationRecords - finished")
    }
    
    // check if any of the local objects are in the deleted list (deletedArray) and if so delete
    static func processDeletedObjects() {
        //NSLog("processDeletedObjects...")
        
        // create an array of recordID.recordName from the cloud delete records
        var listDeleteRecordIDs = [String]()
        var categoryDeleteRecordIDs = [String]()
        var itemDeleteRecordIDs = [String]()
        
        // populate the delete record arrays by record type
        for deleteRecord in appDelegate.deleteFetchArray {
            let recordType = deleteRecord[key_objectType] as? String
            let recordID = deleteRecord[key_objectRecordID] as? String
            
            if recordType == ListsRecordType {
                if let recordID = recordID {
                    listDeleteRecordIDs.append(recordID)
                }
            } else if recordType == CategoriesRecordType {
                if let recordID = recordID {
                    categoryDeleteRecordIDs.append(recordID)
                }
            } else if recordType == ItemsRecordType {
                if let recordID = recordID {
                    itemDeleteRecordIDs.append(recordID)
                }
            }
        }
        
        // populate delete object arrays where local objects are in the cloud delete arrays
        ListData.deleteObjects(listDeleteRecordIDs: listDeleteRecordIDs, categoryDeleteRecordIDs: categoryDeleteRecordIDs, itemDeleteRecordIDs: itemDeleteRecordIDs)
        
        /*
        //guard let listVC = listViewController else { return }
        var listsToDelete = [List]()
        
        for list in listVC.lists {
            let listRecordName = list.listRecord?.recordID.recordName
            if let listRecordName = listRecordName {
                if listDeleteRecordIDs.contains(listRecordName) {
                    listsToDelete.append(list)
                }
            }
            
            var categoriesToDelete = [Category]()
            for category in list.categories {
                let categoryRecordName = category.categoryRecord?.recordID.recordName
                if let categoryRecordName = categoryRecordName {
                    if categoryDeleteRecordIDs.contains(categoryRecordName) {
                        categoriesToDelete.append(category)
                    }
                }
                
                var itemsToDelete = [Item]()
                for item in category.items {
                    let itemRecordName = item.itemRecord?.recordID.recordName
                    if let itemRecordName = itemRecordName {
                        if itemDeleteRecordIDs.contains(itemRecordName) {
                            itemsToDelete.append(item)
                        }
                    }
                }
                
                // remove the deleted items in this category
                category.items.removeObjectsInArray(itemsToDelete)
                //print("*** processDeleteObjects - deleted \(itemsToDelete.count) items in \(list.name): \(category.name)")
            }
            
            // remove the deleted categories in this list
            list.categories.removeObjectsInArray(categoriesToDelete)
            //print("*** processDeleteObjects - deleted \(categoriesToDelete.count) categories in \(list.name)")
        }
        
        // remove the deleted lists
        listVC.lists.removeObjectsInArray(listsToDelete)
        //print("*** processDeleteObjects - deleted \(listsToDelete.count) lists")
        */
    }
    
    static func addToUpdateRecords(_ record: CKRecord, obj: AnyObject) {
        appDelegate.updateRecords[record] = obj
    }
    
    // these are references to items that need an updated image from the cloud
    static func addToItemReferences(_ reference: CKRecord.Reference) {
        appDelegate.itemReferences.append(reference)
    }
    
    // sorts all lists, categories and items and updates indices
    // called as part of the notification chain
    static func refreshListData() {
        if let listVC = appDelegate.listViewController {
            ListData.reorderListObjects()         // reorders all lists, categories and items according to order number
            listVC.tableView.reloadData()
        }
        
        if let itemVC = appDelegate.itemViewController {
            if let list = itemVC.list {
                itemVC.listNameChanged(list.name)
            }
            if itemVC.inEditMode == false {
                itemVC.tableView.reloadData()
                itemVC.resetCellViewTags()
            }
        }
    }
    
}
