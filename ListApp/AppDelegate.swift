 
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
    var refreshEventIsPending = false
    
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
        
        // push notification setup
        let notificationSettings = UIUserNotificationSettings(forTypes: UIUserNotificationType.None, categories: nil)
        application.registerUserNotificationSettings(notificationSettings)
        application.registerForRemoteNotifications()
        
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
        CKContainer.defaultContainer().accountStatusWithCompletionHandler({ status, error in
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
        
        return true
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        print("didFailToRegisterForRemoteNotificationsWithError: \(error)")
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        print("didRegisterForRemoteNotificationsWithDeviceToken: \(deviceToken)")
        self.deleteCurrentSubscriptions()
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject])
    {
        let cloudKitNotification = CKNotification(fromRemoteNotificationDictionary: userInfo as! [String : NSObject])
        
        if cloudKitNotification.notificationType == .Query {
            let queryNotification = cloudKitNotification as! CKQueryNotification
            if queryNotification.queryNotificationReason == .RecordDeleted {
                // If the record has been deleted in CloudKit then delete the local copy here
                print("CloudKit: delete notification... \(queryNotification.recordID!.recordName)")
                dispatch_async(dispatch_get_main_queue()) {
                    if queryNotification.recordID != nil {
                        self.deleteRecord(queryNotification.recordID!.recordName)
                    } else {
                        print("queryNotification gave nil recordID...!")
                    }
                }
            } else {
                // If the record has been created or changed, we fetch the data from CloudKit
                if let database = privateDatabase {
                    database.fetchRecordWithID(queryNotification.recordID!, completionHandler: { (record: CKRecord?, error: NSError?) -> Void in
                        if error != nil {
                            // Handle the error here
                            print("Notification error: \(error?.localizedDescription)")
                            return
                        }
                        if record != nil {
                            dispatch_async(dispatch_get_main_queue()) {
                                self.updateFromRecord(record!, forceUpdate: true)
                            }
                        }
                    })
                }
            }
        }
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        
        print("applicationWillResignActive...")
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
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        
        print("applicationWillTerminate...")
        
        // save state and data
        saveAll()
    }
    
////////////////////////////////////////////////////////////////
//
//  MARK: - Subscription and storage methods
//
////////////////////////////////////////////////////////////////
    
    // delete any old subscriptions before create new subscriptions
    func deleteCurrentSubscriptions()
    {
        print("called deleteCurrentSubscriptions...")
        
        if let database = privateDatabase {
            database.fetchAllSubscriptionsWithCompletionHandler() { [unowned self] (subscriptions, error) -> Void in
                if error == nil
                {
                    var subscriptionsDeletedCount = 0
                    
                    if let subscriptions = subscriptions {
                        for subscription in subscriptions {
                            database.deleteSubscriptionWithID(subscription.subscriptionID, completionHandler: { (str, error) -> Void in
                                if error != nil {
                                    // do your error handling here!
                                    print(error!.localizedDescription)
                                } else {
                                    print("\(subscription.recordType) subscription deleted.  subscriptionsDeletedCount is \(subscriptionsDeletedCount + 1) of \(subscriptions.count) \(subscription.subscriptionID)")
                                    if ++subscriptionsDeletedCount >= subscriptions.count {
                                        // call addNewSubscriptions after the last current subscription is deleted
                                        self.addNewSubscriptions()
                                    }
                                }
                            })
                        }
                     }
                } else {
                    // fetchAllSubscriptionsWithCompletionHandler error
                    print("fetchAllSubscriptionsWithCompletionHandler error: \(error!.localizedDescription)")
                }
                print("fetchAllSubscriptionsWithCompletionHandler subscription count is \(subscriptions!.count)")
                if subscriptions!.count < 3 {
                    self.addNewSubscriptions()
                }
            }
        }
    }
    
    // add subscriptions after deleting all current subscriptions
    func addNewSubscriptions()
    {
        print("called addNewSubscriptions...")
        
        func saveSubscription(recordType: String) {
            // run later, making sure that all subscriptions have been deleted before re-subscribing...
            let predicate = NSPredicate(format: "TRUEPREDICATE")
            
            // save new subscription
            if let database = privateDatabase {
                print("preparing to subscribe to \(recordType) changes")
                let subscription = CKSubscription(recordType: recordType, predicate: predicate, options: [.FiresOnRecordCreation, .FiresOnRecordUpdate, .FiresOnRecordDeletion])
                database.saveSubscription(subscription) { (subscription: CKSubscription?, error: NSError?) -> Void in
                    if subscription != nil {
                        print("saved \(recordType) subscription... \(subscription!.subscriptionID)")
                    } else {
                        print("ERROR: saveSubscription error for \(recordType): \(error!.localizedDescription)")
                    }
                }
            }
        }
        
        for subscriptionType in [ListsRecordType, CategoriesRecordType, ItemsRecordType] {
            saveSubscription(subscriptionType)
        }
    }
    
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
        
        // cloud save -- now send the the records for batch updating
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
    
    // create or update a local object with the given record
    func updateFromRecord(record: CKRecord, forceUpdate: Bool)
    {
        //print("CloudKit: update notification... \(record["name"])")
        var list: List?
        var category: Category?
        var item: Item?
        var update: Bool = forceUpdate
        let localObj = getLocalObject(record.recordID.recordName)
        
        // compare the cloud version with local version
        var cloudDataTime: NSDate = NSDate.init(timeIntervalSince1970: NSTimeInterval.init())
        var localDataTime: NSDate = NSDate.init(timeIntervalSince1970: NSTimeInterval.init())
        
        // get cloud data mod time and local data mod time
        if record.modificationDate != nil { cloudDataTime = record.modificationDate! }
        
        switch record.recordType {
        case ListsRecordType:
            if localObj is List {
                list = localObj as? List
                if list!.modificationDate != nil {
                    localDataTime = list!.modificationDate!
                }
            }
        case CategoriesRecordType:
            if localObj is Category {
                category = localObj as? Category
                if category!.modificationDate != nil {
                    localDataTime = category!.modificationDate!
                }
            }
        case ItemsRecordType:
            if localObj is Item {
                item = localObj as? Item
                if item!.modificationDate != nil {
                    localDataTime = item!.modificationDate!
                }
            }
        default:
            print("updateFromRecord: unknown record type received from cloud data...!")
            return
        }
        
        // if not forcing the update then check if cloud data is newer than local data
        if !forceUpdate {
            update = cloudDataTime.compare(localDataTime) == NSComparisonResult.OrderedDescending
        }

        if update && (list != nil || category != nil || item != nil) {
            // local record exists, so update
            switch record.recordType {
            case ListsRecordType:
                if list != nil {
                    if let name               = record["name"]               { list!.name = name as! String }
                    if let showCompletedItems = record["showCompletedItems"] { list!.showCompletedItems = showCompletedItems as! Bool }
                    if let showInactiveItems  = record["showInactiveItems"]  { list!.showInactiveItems = showInactiveItems as! Bool }
                    if let listColor          = record["listColor"]          { list!.listColor = getUIColorFromRGB(listColor as! Int) }
                    if let order              = record["order"]              { list!.order = order  as! Int }
                    
                    list!.listRecord = record
                    //print("updated list: \(list!.name)")
                }
            case CategoriesRecordType:
                if category != nil {
                    if let name          = record["name"]          { category!.name = name as! String }
                    if let expanded      = record["expanded"]      { category!.expanded = expanded as! Bool }
                    if let displayHeader = record["displayHeader"] { category!.displayHeader = displayHeader as! Bool }
                    if let order         = record["order"]         { category!.order = order as! Int }
                    
                    category!.categoryRecord = record
                    //print("updated category: \(category!.name)")
                }
            case ItemsRecordType:
                if let item = item {
                    if let name  = record["name"]  { item.name  = name  as! String }
                    if let note  = record["note"]  { item.note  = note  as! String }
                    if let order = record["order"] { item.order = order as! Int    }
                    
                    // check if item has changed categories
                    if let itemRecord = item.itemRecord {
                        let currentCategory = getCategoryFromReference(itemRecord)
                        let updateCategory = getCategoryFromReference(record)
                        
                        if currentCategory != updateCategory && updateCategory != nil {
                            // item changed categories = delete item from old category
                            if currentCategory != nil {
                                let index = currentCategory!.items.indexOf(item)
                                if index != nil {
                                    currentCategory!.items.removeAtIndex(index!)
                                    print("Item Move: deleted \(item.name) from \(currentCategory!.name)")
                                }
                            }
                            // add item to new category
                            if item.order >= 0 {
                                if item.order < updateCategory!.items.count {
                                    updateCategory!.items.insert(item, atIndex: item.order)
                                } else {
                                    updateCategory!.items.append(item)
                                }
                                print("Item Move: inserted \(item.name) in \(updateCategory!.name) at pos \(item.order)")
                            }
                        }
                    }
                    
                    item.state = ItemState.Incomplete
                    if let itemState = record["state"] as? Int {
                        item.state = itemState == 0 ? ItemState.Inactive : itemState == 1 ? ItemState.Incomplete : ItemState.Complete
                    }
                    item.itemRecord = record
                    //print("updated item: \(item.name)")
                }
            default:
                break
            }
        } else if list == nil && category == nil && item == nil {
            // local record does not exist, so add
            switch record.recordType {
            case ListsRecordType:
                print("adding a new category: \(record["name"])")
                let newList = List(name: "", createRecord: false)
                
                if let name               = record["name"]               { newList.name = name as! String }
                if let showCompletedItems = record["showCompletedItems"] { newList.showCompletedItems = showCompletedItems as! Bool }
                if let showInactiveItems  = record["showInactiveItems"]  { newList.showInactiveItems = showInactiveItems as! Bool }
                if let listColor          = record["listColor"]          { newList.listColor = getUIColorFromRGB(listColor as! Int) }
                if let order              = record["order"]              { newList.order = order as! Int }
                
                newList.listRecord = record
                newList.listReference = CKReference.init(record: record, action: CKReferenceAction.DeleteSelf)
                
                if let listVC = listViewController {
                    listVC.lists.append(newList)
                    print("added new list: \(newList.name)")
                }
            case CategoriesRecordType:
                print("adding a new category: \(record["name"])")
                if let list = getListFromReference(record) {
                    let newCategory = list.addCategory("", displayHeader: true, updateIndices: true, createRecord: false)
                    
                    if let name          = record["name"]          { newCategory.name          = name as! String }
                    if let displayHeader = record["displayHeader"] { newCategory.displayHeader = displayHeader as! Bool }
                    if let expanded      = record["expanded"]      { newCategory.expanded      = expanded as! Bool }
                    if let order         = record["order"]         { newCategory.order = order as! Int }
                    
                    newCategory.categoryRecord = record
                    newCategory.categoryReference = CKReference.init(record: record, action: CKReferenceAction.DeleteSelf)
                    print("added new category: \(newCategory.name)")
                } else {
                    print("category \(record["name"]) can't find list \(record["owningList"])")
                    // need to delete the category as it didn't send a valid list reference
                    if let database = privateDatabase {
                        database.deleteRecordWithID(record.recordID, completionHandler: { returnRecord, error in
                            if let err = error {
                                print("updateFromRecord: delete category error for '\(record["name"])': \(err.localizedDescription)")
                            } else {
                                print("updateFromRecord: category record deleted successfully '\(record["name"])'")
                            }
                        })
                    }
                }
            case ItemsRecordType:
                print("adding a new item: \(record["name"])")
                if let category = getCategoryFromReference(record) {
                    if category.categoryRecord != nil {
                        if let list = getListFromReference(category.categoryRecord!) {
                            let item = list.addItem(category, name: "", state: ItemState.Incomplete, updateIndices: true, createRecord: false)
                            
                            if let newItem = item {
                                if let name  = record["name"]  { newItem.name  = name as! String }
                                if let note  = record["note"]  { newItem.note  = note as! String }
                                if let order = record["order"] { newItem.order = order as! Int }
                                
                                if let itemState = record["state"] as? Int {
                                    newItem.state = itemState == 0 ? ItemState.Inactive : itemState == 1 ? ItemState.Incomplete : ItemState.Complete
                                }
                                
                                newItem.itemRecord = record
                                print("added new item: \(newItem.name)")
                            }
                        }
                    }
                } else {
                    print("item \(record["name"]) can't find category \(record["owningCategory"])")
                    // need to delete the item as it didn't send a valid category reference
                    if let database = privateDatabase {
                        database.deleteRecordWithID(record.recordID, completionHandler: { returnRecord, error in
                            if let err = error {
                                print("updateFromRecord: delete item error for '\(record["name"])': \(err.localizedDescription)")
                            } else {
                                print("updateFromRecord: item record deleted successfully '\(record["name"])'")
                            }
                        })
                    }
                }
            default:
                break
            }
        }
        
        if !refreshEventIsPending {
            print("preparing refreshEvent timer for update...")
            NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector: "refreshEvent", userInfo: nil, repeats: false)
            refreshEventIsPending = true
        }
    }
    
    // deletes local data associated with the given recordName
    func deleteRecord(recordName: String)
    {
        if let listVC = listViewController {
            if let obj = getLocalObject(recordName) {
                if obj is List {
                    let list = obj as! List
                    let i = listVC.lists.indexOf(list)
                    if i != nil {
                        listVC.lists.removeAtIndex(i!)
                    }
                } else if obj is Category {
                    let category = obj as! Category
                    let list = listVC.getListForCategory(category)
                    if list != nil {
                        let i = list!.categories.indexOf(category)
                        if i != nil {
                            list!.categories.removeAtIndex(i!)
                        }
                    }
                } else if obj is Item {
                    let item = obj as! Item
                    let category = listVC.getCategoryForItem(item)
                    if category != nil {
                        let i = category!.items.indexOf(item)
                        if i != nil {
                            category!.items.removeAtIndex(i!)
                        }
                    }
                }
            } else {
                print("deleteRecord: recordName not found...!")
            }
        }
        
        // now reorder and refresh the table view
        if !refreshEventIsPending {
            print("preparing refreshEvent timer for delete...")
            NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector: "refreshEvent", userInfo: nil, repeats: false)
            refreshEventIsPending = true
        }
    }
    
    // called from a timer to batch refreshes
    func refreshEvent() {
        print("refreshEvent timer did fire...")
        refreshEventIsPending = false
        self.refreshListData()
    }
    
    func addToUpdateRecords(record: CKRecord, obj: AnyObject) {
        updateRecords[record] = obj
    }
    
    // sends all records needing updating to cloud storage
    func batchRecordUpdate()
    {
        if let database = privateDatabase {
            let saveRecordsOperation = CKModifyRecordsOperation()
            let ckRecords = [CKRecord](updateRecords.keys)      // initializes an array of CKRecords with the keys from the updateRecords dictionary
            
            //for ckRecord in updateRecords.keys {
            //    ckRecords.append(ckRecord)
            //}
            
            saveRecordsOperation.recordsToSave = ckRecords
            saveRecordsOperation.savePolicy = .ChangedKeys
            
            saveRecordsOperation.perRecordCompletionBlock = { record, error in
                // deal with conflicts
                // set completionHandler of wrapper operation if it's the case
                if error == nil && record != nil {
                    //print("batch save: \(record!["name"])")
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
                        print("batch update error: \(list.name) \(error!.localizedDescription)")
                    } else if obj is Category {
                        let category = obj as! Category
                        print("batch update error: \(category.name) \(error!.localizedDescription)")
                    } else if obj is Item {
                        let item = obj as! Item
                        print("batch update error: \(item.name) \(error!.localizedDescription)")
                    }
                }
            }
            
            saveRecordsOperation.modifyRecordsCompletionBlock = { savedRecords, deletedRecordIDs, error in
                if error == nil {
                    print("batch save operation complete!")
                } else {
                    print("batch save error: \(error!.localizedDescription)")
                }
            }
            
            // execute the batch save operation
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
                //print("list recordFetchedBlock: \(record["name"]) \(record["order"]) \(record.recordID.recordName)")
            }
            
            categoryFetch.recordFetchedBlock = { (record : CKRecord!) in
                self.categoryArray.append(record)
                //print("category recordFetchedBlock: \(record["name"]) \(record["order"]) \(record.recordID.recordName)")
            }
            
            itemFetch.recordFetchedBlock = { (record : CKRecord!) in
                self.itemArray.append(record)
                //print("item recordFetchedBlock: \(record["name"]) \(record["order"]) \(record.recordID.recordName)")
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
    
    // after fetching cloud data, merge with local data
    func mergeCloudData()
    {
        print("mergeCloudData")
        
        for cloudList in listArray
        {
            updateFromRecord(cloudList, forceUpdate: false)
        }
        
        for cloudCategory in categoryArray
        {
            updateFromRecord(cloudCategory, forceUpdate: false)
        }
        
        for cloudItem in itemArray
        {
           updateFromRecord(cloudItem, forceUpdate: false)
        }
        
        // updateFromRecord will set a timer to fire refreshListData after three seconds
    }
    
    // sorts all lists, categories and items and updates indices
    func refreshListData()
    {
        if let listVC = listViewController {
            listVC.reorderListObjects()         // reorders all lists, categories and items according to order number
            listVC.tableView.reloadData()
        }
        
        if let itemVC = itemViewController {
            itemVC.tableView.reloadData()
            itemVC.resetCellViewTags()          // is this needed???
        }
    }
    
    // returns a ListData object from the given recordName
    func getLocalObject(recordIDName: String) -> AnyObject?
    {
        if let listVC = listViewController {
            for list in listVC.lists {
                if list.listRecord != nil {
                    if list.listRecord!.recordID.recordName == recordIDName {
                        return list
                    }
                    
                    for category in list.categories {
                        if category.categoryRecord != nil {
                            if category.categoryRecord!.recordID.recordName == recordIDName {
                                return category
                            }
                            
                            for item in category.items {
                                if item.itemRecord != nil {
                                    if item.itemRecord!.recordID.recordName == recordIDName {
                                        return item
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        return nil
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

