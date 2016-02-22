 
//  AppDelegate.swift
//  ListApp
//
//  Created by Steven Gentry on 12/30/15.
//  Copyright © 2015 Steven Gentry. All rights reserved.
//

import UIKit
import CloudKit
 
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate
{
    var window: UIWindow?
    var splitViewController: UISplitViewController?
    var leftNavController: UINavigationController?
    var listViewController: ListViewController?
    var rightNavController: UINavigationController?
    var itemViewController: ItemViewController?
    var DocumentsDirectory: NSURL?
    var ArchiveURL = NSURL()
    var cloudUploadStatusRecord: CKRecord?
    var localTimestamp: NSDate?
    var updateRecords = [CKRecord: AnyObject]()
    var listArray = [CKRecord]()
    var categoryArray = [CKRecord]()
    var itemArray = [CKRecord]()
    
    // iCloud
    let container = CKContainer.defaultContainer()
    var privateDatabase: CKDatabase?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool
    {
        // set up controller access for application state persistence
        splitViewController = self.window!.rootViewController as? UISplitViewController
        leftNavController = (splitViewController!.viewControllers.first as! UINavigationController)
        listViewController = (leftNavController!.topViewController as! ListViewController)
        rightNavController = (splitViewController!.viewControllers.last as! UINavigationController)
        itemViewController = (rightNavController!.topViewController as! ItemViewController)
        
        listViewController!.delegate = itemViewController
        itemViewController!.navigationItem.leftItemsSupplementBackButton = true
        itemViewController!.navigationItem.leftBarButtonItem = splitViewController!.displayModeButtonItem()
        
        DocumentsDirectory = NSFileManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        ArchiveURL = DocumentsDirectory!.URLByAppendingPathComponent("listData")
        
        splitViewController!.preferredDisplayMode = UISplitViewControllerDisplayMode.AllVisible
        
        privateDatabase = container.privateCloudDatabase
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        
        print("applicationWillResignActive...")
        
        // save state and data
        saveAll()
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        print("applicationDidEnterBackground...")
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        
        print("applicationWillEnterForeground...")
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        print("applicationDidBecomeActive...")
        
        // get local data timestamp
        localTimestamp = NSUserDefaults.standardUserDefaults().objectForKey("timestamp") as? NSDate
        if localTimestamp != nil {
            print("localTimestamp: \(localTimestamp)")
        }
        
        // restore the list data from local storage
        if let archivedListData = NSKeyedUnarchiver.unarchiveObjectWithFile(ArchiveURL.path!) as? [List] {
            listViewController!.lists = archivedListData
        }
        
        // merge local data with cloud data
        let container = CKContainer.defaultContainer()
        
        container.accountStatusWithCompletionHandler({status, error in
            if (error != nil) { print("Error = \(error!.description)")}
            print("Account status = \(status.hashValue) (0=CouldNotDetermine/1=Available/2=Restricted/3=NoAccount)")
        })
        
        // restore the selected list
        if let initialListIndex = NSUserDefaults.standardUserDefaults().objectForKey("selectionIndex") as? Int {
            if initialListIndex >= 0 && initialListIndex < listViewController!.lists.count {
                itemViewController!.list = listViewController!.lists[initialListIndex]
                listViewController!.selectionIndex = initialListIndex
            } else {
                listViewController!.selectionIndex = -1
            }
        }
        
        fetchCloudData()
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        
        print("applicationWillTerminate...")
        
    }
    
////////////////////////////////////////////////////////////////
//
//  MARK: - Storage methods
//
////////////////////////////////////////////////////////////////
    
    // Checks if the user has logged into their iCloud account or not
    func isIcloudAvailable() -> Bool {
        if let _ = NSFileManager.defaultManager().ubiquityIdentityToken {
            return true
        } else {
            return false
        }
    }
    
    func saveState()
    {
        // save current selection
        NSUserDefaults.standardUserDefaults().setObject(listViewController!.selectionIndex, forKey: "selectionIndex")
        
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    /// Writes the complete object graph locally and writes any dirty objects to the cloud in a batch operation
    func saveListData(cloudOnly: Bool)
    {
        // save the list data - iCloud
        //cloudUploadSuccess = true
        updateRecords.removeAll()       // empty the updateRecords array
        
        // saveToCloud will add all records needing updating to the updateRecords array
        if let listVC = listViewController {
            for list in listVC.lists {
                list.saveToCloud()
            }
        }
        
        // now send the the records for batch updating
        batchRecordUpdate()
        
        if !cloudOnly {
            // save the list data - local
            if let listVC = listViewController {
                let successfulSave = NSKeyedArchiver.archiveRootObject(listVC.lists, toFile: ArchiveURL.path!)
                
                if !successfulSave {
                    print("Failed to save list data locally...")
                }
            }
        }
    }

    func saveAll() {
        saveState()
        saveListData(false)
        print("all list data saved locally...")
    }
    
    func addToUpdateRecords(record: CKRecord, obj: AnyObject) {
        updateRecords[record] = obj
    }
    
    func batchRecordUpdate()
    {
        if let database = privateDatabase {
            let saveRecordsOperation = CKModifyRecordsOperation()
            var ckRecords = [CKRecord]()
            
            for (ckRecord, _) in updateRecords {
                ckRecords.append(ckRecord)
            }
            
            saveRecordsOperation.recordsToSave = ckRecords
            saveRecordsOperation.savePolicy = .IfServerRecordUnchanged
            saveRecordsOperation.perRecordCompletionBlock = { record, error in
                // deal with conflicts
                // set completionHandler of wrapper operation if it's the case
                if error == nil && record != nil {
                    print("batch save: \(record!["name"])")
                    let obj = self.updateRecords[record!]
                    if obj is List {
                        let list = obj as! List
                        list.needToSave = false
                    } else if obj is Category {
                        let category = obj as! Category
                        category.needToSave = false
                    } else if obj is Item {
                        let item = obj as! Item
                        item.needToSave = false
                    }
                } else if error != nil {
                    let obj = self.updateRecords[record!]
                    if obj is List {
                        let list = obj as! List
                        print("batch update: \(list.name) \(error!.localizedDescription)")
                        
                    } else if obj is Category {
                        let category = obj as! Category
                        print("batch update: \(category.name) \(error!.localizedDescription)")
                    } else if obj is Item {
                        let item = obj as! Item
                        print("batch update: \(item.name) \(error!.localizedDescription)")
                    }
                }
            }
            
            saveRecordsOperation.modifyRecordsCompletionBlock = { savedRecords, deletedRecordIDs, error in
                // deal with conflicts
                // set completionHandler of wrapper operation if it's the case
                if error == nil {
                    print("batch save operation complete!")
                } else {
                    print("batch save error: \(error!.localizedDescription)")
                }
                
            }
            
            database.addOperation(saveRecordsOperation)
        }
    }
    
    // pulls all list, category and item data from cloud storage
    func fetchCloudData()
    {
        if let database = privateDatabase {
            // clear the record arrays
            listArray.removeAll()
            categoryArray.removeAll()
            itemArray.removeAll()
            
            // set up query operations
            let truePredicate = NSPredicate(value: true)
            
            let listQuery = CKQuery(recordType: ListsRecordType, predicate: truePredicate)
            let categoryQuery = CKQuery(recordType: CategoriesRecordType, predicate: truePredicate)
            let itemQuery = CKQuery(recordType: ItemsRecordType, predicate: truePredicate)
            
            listQuery.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
            categoryQuery.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
            itemQuery.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
            
            let listFetch = CKQueryOperation(query: listQuery)
            let categoryFetch = CKQueryOperation(query: categoryQuery)
            let itemFetch = CKQueryOperation(query: itemQuery)
            
            // set up the record fetched block
            listFetch.recordFetchedBlock = { (record : CKRecord!) in
                self.listArray.append(record)
                print("list recordFetchedBlock: \(record["name"]) \(record["order"]) \(record.recordID.recordName)")
            }
            
            categoryFetch.recordFetchedBlock = { (record : CKRecord!) in
                self.categoryArray.append(record)
                print("category recordFetchedBlock: \(record["name"]) \(record["order"]) \(record.recordID.recordName)")
            }
            
            itemFetch.recordFetchedBlock = { (record : CKRecord!) in
                self.itemArray.append(record)
                print("item recordFetchedBlock: \(record["name"]) \(record["order"]) \(record.recordID.recordName)")
            }
            
            // set up completion blocks with cursors so they can recursively gather all of the records
            listFetch.queryCompletionBlock = { (cursor : CKQueryCursor?, error : NSError?) in
                if cursor != nil {
                    print("there is more data to fetch")
                    let newOperation = CKQueryOperation(cursor: cursor!)
                    newOperation.recordFetchedBlock = listFetch.recordFetchedBlock
                    newOperation.queryCompletionBlock = listFetch.queryCompletionBlock
                    database.addOperation(newOperation)
                }
                if error != nil {
                    print("listFetch error: \(error?.localizedDescription)")
                }
            }
            
            categoryFetch.queryCompletionBlock = { (cursor : CKQueryCursor?, error : NSError?) in
                if cursor != nil {
                    print("there is more data to fetch")
                    let newOperation = CKQueryOperation(cursor: cursor!)
                    newOperation.recordFetchedBlock = categoryFetch.recordFetchedBlock
                    newOperation.queryCompletionBlock = categoryFetch.queryCompletionBlock
                    database.addOperation(newOperation)
                }
                if error != nil {
                    print("categoryFetch error: \(error?.localizedDescription)")
                }
            }
            
            itemFetch.queryCompletionBlock = { (cursor : CKQueryCursor?, error : NSError?) in
                if cursor != nil {
                    print("there is more data to fetch")
                    let newOperation = CKQueryOperation(cursor: cursor!)
                    newOperation.recordFetchedBlock = itemFetch.recordFetchedBlock
                    newOperation.queryCompletionBlock = itemFetch.queryCompletionBlock
                    database.addOperation(newOperation)
                }
                if error != nil {
                    print("itemFetch error: \(error?.localizedDescription)")
                }
                
                if cursor == nil {
                    print("The record fetch operation is complete...")
                    print("array counts - list: \(self.listArray.count) category: \(self.categoryArray.count) item: \(self.itemArray.count)")
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        self.mergeCloudData()
                    }
                }
            }
            
            // execute the query operations
            database.addOperation(listFetch)
            database.addOperation(categoryFetch)
            database.addOperation(itemFetch)
        }
    }
    
    func mergeCloudData()
    {
        print("mergeCloudData")
        
        for cloudList in listArray
        {
            if let localList = getLocalList(cloudList.recordID.recordName) {
                // compare the cloud version with local version
                var cloudDataTime: NSDate = NSDate.init(timeIntervalSince1970: NSTimeInterval.init())
                var localDataTime: NSDate = NSDate.init(timeIntervalSince1970: NSTimeInterval.init())
                
                if cloudList.modificationDate != nil { cloudDataTime = cloudList.modificationDate! }
                if localList.modificationDate != nil { localDataTime = localList.modificationDate! }
                
                if cloudDataTime.compare(localDataTime) == NSComparisonResult.OrderedDescending {
                    // cloud data is newer -- update local record
                    if let name               = cloudList["name"]               { localList.name = name as! String }
                    if let showCompletedItems = cloudList["showCompletedItems"] { localList.showCompletedItems = showCompletedItems as! Bool }
                    if let showInactiveItems  = cloudList["showInactiveItems"]  { localList.showInactiveItems = showInactiveItems as! Bool }
                    if let listColor          = cloudList["listColor"]          { localList.listColor = getUIColorFromRGB(listColor as! Int) }
                    if let order              = cloudList["order"]              { localList.order = order as! Int }
                    
                    localList.listRecord = cloudList
                    print("updated list: \(localList.name)")
                }
            } else {
                // local version does not exist, so add
                if let listVC = listViewController
                {
                    let newList = List(name: "")
                    
                    if let name               = cloudList["name"]               { newList.name = name as! String }
                    if let showCompletedItems = cloudList["showCompletedItems"] { newList.showCompletedItems = showCompletedItems as! Bool }
                    if let showInactiveItems  = cloudList["showInactiveItems"]  { newList.showInactiveItems = showInactiveItems as! Bool }
                    if let listColor          = cloudList["listColor"]          { newList.listColor = getUIColorFromRGB(listColor as! Int) }
                    if let order              = cloudList["order"]              { newList.order = order as! Int }
                    
                    newList.listRecord = cloudList
                    
                    listVC.lists.append(newList)
                    print("added new list: \(newList.name)")
                }
            }
        }
        
        for cloudCategory in categoryArray
        {
            if let localCategory = getLocalCategory(cloudCategory.recordID.recordName) {
                // compare the cloud version with local version
                var cloudDataTime: NSDate = NSDate.init(timeIntervalSince1970: NSTimeInterval.init())
                var localDataTime: NSDate = NSDate.init(timeIntervalSince1970: NSTimeInterval.init())
                
                if cloudCategory.modificationDate != nil { cloudDataTime = cloudCategory.modificationDate! }
                if localCategory.modificationDate != nil { localDataTime = localCategory.modificationDate! }
                
                if cloudDataTime.compare(localDataTime) == NSComparisonResult.OrderedDescending {
                    // cloud data is newer -- update local record
                    if let name          = cloudCategory["name"]          { localCategory.name = name as! String }
                    if let expanded      = cloudCategory["expanded"]      { localCategory.expanded = expanded as! Bool }
                    if let displayHeader = cloudCategory["displayHeader"] { localCategory.displayHeader = displayHeader as! Bool }
                    if let order         = cloudCategory["order"]         { localCategory.order = order as! Int }
                    
                    localCategory.categoryRecord = cloudCategory
                    print("updated category: \(localCategory.name)")
                }
            } else {
                // local version of this category does not exist, so add
                print("adding a new category: \(cloudCategory["name"])")
                if let list = getListFromReference(cloudCategory) {
                    var newCategory = list.addCategory("", displayHeader: true, updateIndices: true)
                    
                    if let name          = cloudCategory["name"]          { newCategory.name          = name as! String }
                    if let displayHeader = cloudCategory["displayHeader"] { newCategory.displayHeader = displayHeader as! Bool }
                    if let expanded      = cloudCategory["expanded"]      { newCategory.expanded      = expanded as! Bool }
                    if let order         = cloudCategory["order"]         { newCategory.order = order as! Int }
                    
                    newCategory.categoryRecord = cloudCategory
                    print("added new category: \(newCategory.name)")
                }
            }
        }
        
        for cloudItem in itemArray
        {
            if let localItem = getLocalItem(cloudItem.recordID.recordName) {
                // compare the cloud version with local version
                var cloudDataTime: NSDate = NSDate.init(timeIntervalSince1970: NSTimeInterval.init())
                var localDataTime: NSDate = NSDate.init(timeIntervalSince1970: NSTimeInterval.init())
                
                if cloudItem.modificationDate != nil { cloudDataTime = cloudItem.modificationDate! }
                if localItem.modificationDate != nil { localDataTime = localItem.modificationDate! }
                
                if cloudDataTime.compare(localDataTime) == NSComparisonResult.OrderedDescending {
                    // cloud data is newer -- update local record
                    if let name  = cloudItem["name"]  { localItem.name  = name as! String }
                    if let note  = cloudItem["note"]  { localItem.note  = note as! String }
                    if let order = cloudItem["order"] { localItem.order = order as! Int }
                    
                    localItem.state = ItemState.Incomplete
                    if let itemState = cloudItem["state"] as? Int {
                        localItem.state = itemState == 0 ? ItemState.Inactive : itemState == 1 ? ItemState.Incomplete : ItemState.Complete
                    }
                    
                    localItem.itemRecord = cloudItem
                    print("updated item: \(localItem.name)")
                }
            } else {
                // local version of this item does not exist, so add
                print("adding a new item: \(cloudItem["name"])")
                if let category = getCategoryFromReference(cloudItem) {
                    if category.categoryRecord != nil {
                        if let list = getListFromReference(category.categoryRecord!) {
                            var item = list.addItem(category, name: "", state: ItemState.Incomplete, updateIndices: true)
                            
                            if let newItem = item {
                                if let name  = cloudItem["name"]  { newItem.name  = name as! String }
                                if let note  = cloudItem["note"]  { newItem.note  = note as! String }
                                if let order = cloudItem["order"] { newItem.order = order as! Int }
                                
                                if let itemState = cloudItem["state"] as? Int {
                                    newItem.state = itemState == 0 ? ItemState.Inactive : itemState == 1 ? ItemState.Incomplete : ItemState.Complete
                                }
                                
                                newItem.itemRecord = cloudItem
                                print("added new item: \(newItem.name)")
                            }
                        }
                    }
                }
            }
        }
        
        if let listVC = listViewController {
            listVC.reorderListObjects()
            listVC.tableView.reloadData()
        }
        
        if let itemVC = itemViewController {
            itemVC.tableView.reloadData()
        }
    }
    
    // returns a List object matching the given CKRecordID
    func getLocalList(recordIDName: String) -> List?
    {
        if let listVC = listViewController {
            for list in listVC.lists {
                if list.listRecord != nil {
                    if list.listRecord!.recordID.recordName == recordIDName {
                        return list
                    }
                }
            }
        }
        
        return nil
    }
    
    // returns a Category object matching the given CKRecordID
    func getLocalCategory(recordIDName: String) -> Category?
    {
        if let listVC = listViewController {
            for list in listVC.lists {
                for category in list.categories {
                    if category.categoryRecord?.recordID.recordName == recordIDName {
                        return category
                    }
                }
            }
        }
        
        return nil
    }

    // returns an Item object matching the given CKRecordID
    func getLocalItem(recordIDName: String) -> Item?
    {
        if let listVC = listViewController {
            for list in listVC.lists {
                for category in list.categories {
                    for item in category.items {
                        if item.itemRecord?.recordID.recordName == recordIDName {
                            return item
                        }
                    }
                }
            }
        }
        
        return nil
    }

    func getListFromReference(categoryRecord: CKRecord) -> List?
    {
        if let listReference = categoryRecord["owningList"] as? CKReference {
            return getLocalList(listReference.recordID.recordName)
        }
        
        return nil
    }
    
    func getCategoryFromReference(itemRecord: CKRecord) -> Category?
    {
        if let categoryReference = itemRecord["owningCategory"] as? CKReference {
            return getLocalCategory(categoryReference.recordID.recordName)
        }
        
        return nil
    }
    
    func getUIColorFromRGB(rgb: Int) -> UIColor?
    {
        if rgb == 0 {
            return nil
        }
        
        let RGB: Int64 = Int64.init(rgb)
        
        // let rgb = (iAlpha << 24) + (iRed << 16) + (iGreen << 8) + iBlue
        
        let blue  = Float(RGB & 0xFF)       / 0xFF
        let green = Float(RGB & 0xFF00)     / 0xFF00
        let red   = Float(RGB & 0xFF0000)   / 0xFF0000
        let alpha = Float(RGB & 0xFF000000) / 0xFF000000
        
        return UIColor(colorLiteralRed: red, green: green, blue: blue, alpha: alpha)
    }
}

