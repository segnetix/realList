//  AppDelegate.swift
//  EnList
//
//  Created by Steven Gentry on 12/30/15.
//  Copyright © 2015 Steven Gentry. All rights reserved.
//

import UIKit
import CloudKit
import StoreKit

let key_listData             = "listData"
let key_selectionIndex       = "selectionIndex"
let key_printNotes           = "printNotes"
let key_namesCapitalize      = "namesCapitalize"
let key_namesSpellCheck      = "namesSpellCheck"
let key_namesAutocorrection  = "namesAutocorrection"
let key_notesCapitalize      = "notesCapitalize"
let key_notesSpellCheck      = "notesSpellCheck"
let key_notesAutocorrection  = "notesAutocorrection"
let key_picsInPrintAndEmail  = "picsInPrintAndEmail"

// list and item limits
let kMaxListCount            =  3
let kMaxItemCount            = 20

// price formatter function
let priceFormatter: NSNumberFormatter = {
    let formatter = NSNumberFormatter()
    formatter.formatterBehavior = .Behavior10_4
    formatter.numberStyle = .CurrencyStyle
    return formatter
}()

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate
{
    var window: UIWindow?
    var splitViewController: UISplitViewController?
    var leftNavController: UINavigationController?
    var listViewController: ListViewController?
    var rightNavController: UINavigationController?
    var itemViewController: ItemViewController?
    var aboutViewController: AboutViewController?
    var DocumentsDirectory: NSURL?
    var ArchiveURL = NSURL()
    var cloudUploadStatusRecord: CKRecord?
    var updateRecords = [CKRecord: AnyObject]()
    var itemReferences = [CKReference]()                // holds references to items that have outdated image assets
    var listArray = [CKRecord]()                        // holds fetched list records for app launch data merge
    var categoryArray = [CKRecord]()                    // "
    var itemArray = [CKRecord]()                        // "
    var imageArray = [CKRecord]()                       // "
    var deleteArray = [CKRecord]()                      // "
    var refreshEventIsPending = false
    var printNotes = true
    var upgradePriceString = ""
    var upgradeProduct: SKProduct?
    var appIsUpgraded: Bool = false {
        didSet {
            if let itemVC = itemViewController {
                print("appIsUpgraded was set to \(appIsUpgraded)")
                if itemVC.adBanner != nil && appIsUpgraded {
                    itemVC.adBanner.delegate = nil
                    itemVC.adBanner.removeFromSuperview()
                }
                itemVC.layoutAnimated(false)
            }
        }
    }
    
    // app settings
    var namesCapitalize = false
    var namesSpellCheck = false
    var namesAutocorrection = false
    var notesCapitalize = false
    var notesSpellCheck = false
    var notesAutocorrection = false
    var picsInPrintAndEmail = false
    
    // delete purge delay
    let deletePurgeDays = 30                            // delete records will be purged from cloud storage after this many days
    
    // iCloud
    let container = CKContainer.defaultContainer()
    var privateDatabase: CKDatabase?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool
    {
        // set up controller access for application state persistence
        splitViewController = self.window!.rootViewController as? UISplitViewController
        leftNavController   = (splitViewController!.viewControllers.first as! UINavigationController)
        listViewController  = (leftNavController!.topViewController as! ListViewController)
        rightNavController  = (splitViewController!.viewControllers.last as! UINavigationController)
        itemViewController  = (rightNavController!.topViewController as! ItemViewController)
        
        listViewController!.delegate = itemViewController
        itemViewController!.navigationItem.leftItemsSupplementBackButton = true
        itemViewController!.navigationItem.leftBarButtonItem = splitViewController!.displayModeButtonItem()
        
        DocumentsDirectory = NSFileManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        ArchiveURL = DocumentsDirectory!.URLByAppendingPathComponent(key_listData)
        
        splitViewController!.preferredDisplayMode = UISplitViewControllerDisplayMode.AllVisible
        
        privateDatabase = container.privateCloudDatabase

        // push notification setup
        let notificationSettings = UIUserNotificationSettings(forTypes: UIUserNotificationType.None, categories: nil)
        application.registerUserNotificationSettings(notificationSettings)
        application.registerForRemoteNotifications()
        
        // restore the list data from local storage
        if let archivedListData = NSKeyedUnarchiver.unarchiveObjectWithFile(ArchiveURL.path!) as? [List] {
            listViewController!.lists = archivedListData
            
            // restore the selected list
            if let initialListIndex = NSUserDefaults.standardUserDefaults().objectForKey(key_selectionIndex) as? Int {
                if initialListIndex >= 0 && initialListIndex < listViewController!.lists.count {
                    itemViewController!.list = listViewController!.lists[initialListIndex]
                    listViewController!.selectionIndex = initialListIndex
                } else {
                    listViewController!.selectionIndex = -1
                }
            }
        } else {
            // temp - comment out the tutorial generation line below for development
            listViewController!.generateTutorial()
            listViewController!.selectList(0)
        }
        
        print("iCloudIsAvailable: \(self.iCloudIsAvailable())")
        
        // restore app settings
        if let printNotes          = NSUserDefaults.standardUserDefaults().objectForKey(key_printNotes)          as? Bool { self.printNotes          = printNotes          }
        if let namesCapitalize     = NSUserDefaults.standardUserDefaults().objectForKey(key_namesCapitalize)     as? Bool { self.namesCapitalize     = namesCapitalize     }
        if let namesSpellCheck     = NSUserDefaults.standardUserDefaults().objectForKey(key_namesSpellCheck)     as? Bool { self.namesSpellCheck     = namesSpellCheck     }
        if let namesAutocorrection = NSUserDefaults.standardUserDefaults().objectForKey(key_namesAutocorrection) as? Bool { self.namesAutocorrection = namesAutocorrection }
        if let notesCapitalize     = NSUserDefaults.standardUserDefaults().objectForKey(key_notesCapitalize)     as? Bool { self.notesCapitalize     = notesCapitalize     }
        if let notesSpellCheck     = NSUserDefaults.standardUserDefaults().objectForKey(key_notesSpellCheck)     as? Bool { self.notesSpellCheck     = notesSpellCheck     }
        if let notesAutocorrection = NSUserDefaults.standardUserDefaults().objectForKey(key_notesAutocorrection) as? Bool { self.notesAutocorrection = notesAutocorrection }
        if let picsInPrintAndEmail = NSUserDefaults.standardUserDefaults().objectForKey(key_picsInPrintAndEmail) as? Bool { self.picsInPrintAndEmail = picsInPrintAndEmail }
        
        // restore upgrade status from user defaults
        if RealListProducts.store.isProductPurchased(RealListProducts.FullVersion) {
            self.appIsUpgraded = true
        } else {
            // check the product on the app store to get pricing
            self.appIsUpgraded = false
            RealListProducts.store.requestProducts { success, products in
                if success {
                    if let products = products {
                        if products.count > 0 {
                            // we have only one product
                            let product = products[0]
                            self.upgradeProduct = product
                            
                            print("localizedTitle: \(product.localizedTitle)")
                            print("localizedDescription: \(product.localizedDescription)")
                            print("productIdentifier: \(product.productIdentifier)")
                            
                            if RealListProducts.store.isProductPurchased(product.productIdentifier) {
                                self.appIsUpgraded = true
                            } else {
                                self.appIsUpgraded = false
                                priceFormatter.locale = product.priceLocale
                                self.upgradePriceString = priceFormatter.stringFromNumber(product.price)!
                            }
                        }
                    }
                }
            }
        }
        
        return true
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError)
    {
        print("*** didFailToRegisterForRemoteNotificationsWithError: \(error)")
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData)
    {
        print("*** didRegisterForRemoteNotificationsWithDeviceToken: \(deviceToken)")
        
        // will create subscriptions if necessary
        self.createSubscriptions()
    }
    
    // iCloud sent notification of a change
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
        aboutViewController?.updateCloudStatus()
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        print("applicationDidBecomeActive...")
        
        fetchCloudData()
    }
    
    // called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground
    func applicationWillTerminate(application: UIApplication)
    {
        print("applicationWillTerminate...")
        
        // save state and data
        saveAll()
    }
    
////////////////////////////////////////////////////////////////
//
//  MARK: - Subscription and storage methods
//
////////////////////////////////////////////////////////////////
    
    // create subscriptions if necessary
    func createSubscriptions()
    {
        print("called createSubscriptions...")
        
        // create a single subscription of the given type
        func createSubscription(recordType: String) {
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
        
        // subscription check
        if let database = privateDatabase {
            database.fetchAllSubscriptionsWithCompletionHandler() { (subscriptions, error) -> Void in
                if error == nil
                {
                    var haveListsSub = false
                    var haveCategoriesSub = false
                    var haveItemsSub = false
                    var haveImagesSub = false
                    
                    // check for existing subscriptions
                    if let subscriptions = subscriptions {
                        for subscription in subscriptions {
                            if subscription.recordType == ListsRecordType {
                                print("*** subscription check: Lists")
                                haveListsSub = true
                            }
                            if subscription.recordType == CategoriesRecordType {
                                print("*** subscription check: Categories")
                                haveCategoriesSub = true
                            }
                            if subscription.recordType == ItemsRecordType {
                                print("*** subscription check: Items")
                                haveItemsSub = true
                            }
                            if subscription.recordType == ImagesRecordType {
                                print("*** subscription check: Images")
                                haveImagesSub = true
                            }
                        }
                    }
                    
                    // create any missing subscriptions
                    if !haveListsSub      { createSubscription(ListsRecordType)      }
                    if !haveCategoriesSub { createSubscription(CategoriesRecordType) }
                    if !haveItemsSub      { createSubscription(ItemsRecordType)      }
                    if !haveImagesSub     { createSubscription(ImagesRecordType)     }
                    
                } else {
                    print("fetchAllSubscriptionsWithCompletionHandler error: \(error!.localizedDescription)")
                }
            }
        }
    }
    
    // checks if the user has logged into their iCloud account or not
    func iCloudIsAvailable() -> Bool
    {
        if let _ = NSFileManager.defaultManager().ubiquityIdentityToken {
            return true
        } else {
            return false
        }
    }
    
    func saveState()
    {
        // save current selection
        NSUserDefaults.standardUserDefaults().setObject(listViewController!.selectionIndex, forKey: key_selectionIndex)
        NSUserDefaults.standardUserDefaults().setObject(printNotes,                         forKey: key_printNotes)
        
        // save app settings
        NSUserDefaults.standardUserDefaults().setObject(namesCapitalize,                    forKey: key_namesCapitalize)
        NSUserDefaults.standardUserDefaults().setObject(namesSpellCheck,                    forKey: key_namesSpellCheck)
        NSUserDefaults.standardUserDefaults().setObject(namesAutocorrection,                forKey: key_namesAutocorrection)
        NSUserDefaults.standardUserDefaults().setObject(notesCapitalize,                    forKey: key_notesCapitalize)
        NSUserDefaults.standardUserDefaults().setObject(notesSpellCheck,                    forKey: key_notesSpellCheck)
        NSUserDefaults.standardUserDefaults().setObject(notesAutocorrection,                forKey: key_notesAutocorrection)
        NSUserDefaults.standardUserDefaults().setObject(picsInPrintAndEmail,                forKey: key_picsInPrintAndEmail)
        
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    /// Writes the complete object graph locally and writes any dirty objects to the cloud in a batch operation
    func saveListData(cloudOnly: Bool)
    {
        // save the list data - iCloud
        //cloudUploadSuccess = true
        updateRecords.removeAll()       // empty the updateRecords array
        
        // saveToCloud will add all records needing updating to the updateRecords array
        if iCloudIsAvailable() {
            if let listVC = listViewController {
                for list in listVC.lists {
                    list.saveToCloud()
                }
            }
            
            // cloud batch save ready -- now send the records for batch updating
            batchRecordUpdate()
        }
        
        if !cloudOnly {
            // save the list data - local
            if let listVC = listViewController {
                let successfulSave = NSKeyedArchiver.archiveRootObject(listVC.lists, toFile: ArchiveURL.path!)
                
                if !successfulSave {
                    print("ERROR: Failed to save list data locally...")
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
        var list: List?
        var category: Category?
        var item: Item?
        var imageAsset: ImageAsset?
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
                localDataTime = item!.modifiedDate
            }
        case ImagesRecordType:
            if localObj is ImageAsset {
                imageAsset = localObj as? ImageAsset
                localDataTime = imageAsset!.modifiedDate
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
            case ListsRecordType:       list!.updateFromRecord(record)
            case CategoriesRecordType:  category!.updateFromRecord(record)
            case ItemsRecordType:       item!.updateFromRecord(record)
            case ImagesRecordType:      imageAsset!.updateFromRecord(record)
            default:
                break
            }
        } else if list == nil && category == nil && item == nil && imageAsset == nil {
            // local record does not exist, so add
            switch record.recordType {
            case ListsRecordType:
                let newList = List(name: "", createRecord: false)
                
                newList.updateFromRecord(record)
                
                if let listVC = listViewController {
                    listVC.lists.append(newList)
                    print("added new list: \(newList.name)")
                }
            case CategoriesRecordType:
                if let list = getListFromReference(record) {
                    let newCategory = list.addCategory("", displayHeader: true, updateIndices: true, createRecord: false)
                    
                    newCategory.updateFromRecord(record)
                    
                    print("added new category: \(newCategory.name)")
                } else {
                    print("*** ERROR: category \(record[key_name]) can't find list \(record[key_owningList])")
                }
            case ItemsRecordType:
                if let category = getCategoryFromReference(record) {
                    if category.categoryRecord != nil {
                        if let list = getListFromReference(category.categoryRecord!) {
                            let item = list.addItem(category, name: "", state: ItemState.Incomplete, updateIndices: true, createRecord: false)
                            
                            if let newItem = item {
                                newItem.updateFromRecord(record)
                                print("added new item: \(newItem.name)")
                            }
                        }
                    }
                } else {
                    print("*** ERROR: item \(record[key_name]) can't find category \(record[key_owningCategory])")
                }
            case ImagesRecordType:
                if let item = getItemFromReference(record) {
                    if let image = item.addImage(false) {
                        image.updateFromRecord(record)
                        print("added new image to item: '\(item.name)' imageGUID: \(image.imageGUID)")
                    }
                } else {
                    print("*** ERROR: image \(record[key_imageGUID]) can't find item \(record[key_owningItem])")
                }
            default:
                break
            }
        }
        
        if !refreshEventIsPending {
            print("preparing refreshEvent timer for update...")
            NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector: #selector(AppDelegate.refreshEvent), userInfo: nil, repeats: false)
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
            NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector: #selector(AppDelegate.refreshEvent), userInfo: nil, repeats: false)
            refreshEventIsPending = true
        }
    }
    
    // called from a timer to batch refreshes
    func refreshEvent() {
        print("refreshEvent timer did fire...")
        refreshEventIsPending = false
        self.refreshListData()
        print("refreshEvent did finish...")
    }
    
    func addToUpdateRecords(record: CKRecord, obj: AnyObject) {
        updateRecords[record] = obj
    }
    
    // these are references to items that need an updated image from the cloud
    func addToItemReferences(reference: CKReference) {
        itemReferences.append(reference)
    }
    
    // sends all records needing updating to cloud storage
    func batchRecordUpdate()
    {
        if let database = privateDatabase {
            let saveRecordsOperation = CKModifyRecordsOperation()
            let ckRecords = [CKRecord](updateRecords.keys)      // initializes an array of CKRecords with the keys from the updateRecords dictionary
            
            saveRecordsOperation.recordsToSave = ckRecords
            saveRecordsOperation.savePolicy = .ChangedKeys
            saveRecordsOperation.perRecordCompletionBlock = { record, error in
                // deal with conflicts
                // set completionHandler of wrapper operation if it's the case
                if error == nil && record != nil {
                    //print("batch save: \(record![key_name])")
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
                    } else if obj is ImageAsset {
                        let image = obj as! ImageAsset
                        image.needToDelete = false
                        image.deleteImageFile()
                    }
                } else if error != nil {
                    // NOTE: This should be able to handle a CKErrorLimitExceeded error.
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
                    } else if obj is ImageAsset {
                        let image = obj as! ImageAsset
                        print("batch update error: \(image.imageGUID) \(error!.localizedDescription)")
                    }
                }
            }
            saveRecordsOperation.modifyRecordsCompletionBlock = { savedRecords, deletedRecordIDs, error in
                if error == nil {
                    print("batch save operation complete!")
                } else {
                    // ******* NOTE: This should be able to handle a CKErrorLimitExceeded error. ******* //
                    print("*** ERROR: batchRecordUpdate - \(error!.localizedDescription)")
                    print("The following records had problems: \(error!.userInfo[CKPartialErrorsByItemIDKey])")
                }
            }
            
            // execute the batch save operation
            database.addOperation(saveRecordsOperation)
        }
    }
    
    // deletes an array of records
    func batchRecordDelete(deleteRecords: [CKRecord])
    {
        if let database = privateDatabase
        {
            // generate the array of recordIDs to be deleted
            var deleteRecordIDs = [CKRecordID]()
            for record in deleteRecords {
                deleteRecordIDs.append(record.recordID)
            }
            
            let deleteRecordsOperation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: deleteRecordIDs)
            deleteRecordsOperation.recordsToSave = nil
            deleteRecordsOperation.recordIDsToDelete = deleteRecordIDs
            deleteRecordsOperation.perRecordCompletionBlock = { record, error in
                if error == nil && record != nil {
                    print("batchRecordDelete: deleted \(record![key_objectName])")
                } else if error != nil {
                    print("*** ERROR: batchRecordDelete: \(error!.localizedDescription)")
                }
            }
            deleteRecordsOperation.modifyRecordsCompletionBlock = { savedRecords, deletedRecordIDs, error in
                if error == nil {
                    print("batch delete operation complete - \(savedRecords?.count) deleted.")
                } else {
                    // ******* NOTE: This should be able to handle a CKErrorLimitExceeded error. ******* //
                    print("*** ERROR: batchRecordDelete. The following records had problems: \(error!.userInfo[CKPartialErrorsByItemIDKey])")
                }
            }
            
            // execute the batch delete operation
            database.addOperation(deleteRecordsOperation)
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
            deleteArray.removeAll()
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
            
            let listFetch = CKQueryOperation(query: listQuery)
            let categoryFetch = CKQueryOperation(query: categoryQuery)
            let itemFetch = CKQueryOperation(query: itemQuery)
            let deleteFetch = CKQueryOperation(query: deleteQuery)
            
            // set up the record fetched block
            listFetch.recordFetchedBlock = { (record : CKRecord!) in
                self.listArray.append(record)
                //print("list recordFetchedBlock: \(record[key_name]) \(record[key_order]) \(record.recordID.recordName)")
            }
            
            categoryFetch.recordFetchedBlock = { (record : CKRecord!) in
                self.categoryArray.append(record)
                //print("category recordFetchedBlock: \(record[key_name]) \(record[key_order]) \(record.recordID.recordName)")
            }
            
            itemFetch.recordFetchedBlock = { (record : CKRecord!) in
                self.itemArray.append(record)
                //print("item recordFetchedBlock: \(record[key_name]) \(record[key_order]) \(record.recordID.recordName)")
            }
            
            deleteFetch.recordFetchedBlock = { (record : CKRecord!) in
                self.deleteArray.append(record)
                //print("delete recordFetchedBlock: \(record[key_itemName]) \(record[key_deletedDate]) \(record.recordID.recordName)")
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
            
            deleteFetch.queryCompletionBlock = { (cursor : CKQueryCursor?, error : NSError?) in
                if cursor != nil {
                    print("there is more data to fetch")
                    let newOperation = CKQueryOperation(cursor: cursor!)
                    newOperation.recordFetchedBlock = deleteFetch.recordFetchedBlock
                    newOperation.queryCompletionBlock = deleteFetch.queryCompletionBlock
                    database.addOperation(newOperation)
                }
                if error != nil {
                    print("deleteFetch error: \(error?.localizedDescription)")
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
                    print("array counts - list: \(self.listArray.count) category: \(self.categoryArray.count) item: \(self.itemArray.count) delete: \(self.deleteArray.count)")
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        self.mergeCloudData()
                    }
                }
            }
            
            // execute the query operations
            database.addOperation(listFetch)
            database.addOperation(categoryFetch)
            database.addOperation(itemFetch)
            database.addOperation(deleteFetch)
        }
    }
    
    // pulls image data for items needing updating
    func fetchImageData()
    {
        //print("*** fetchImageData - \(itemReferences.count) items need new images...")
        
        if let database = privateDatabase {
            // clear the record array
            imageArray.removeAll()
            
            let predicate = NSPredicate (format: "owningItem IN %@", argumentArray: [itemReferences])
            let imageQuery = CKQuery(recordType: ImagesRecordType, predicate: predicate)
            let imageFetch = CKQueryOperation(query: imageQuery)
            
            imageFetch.recordFetchedBlock = { (record : CKRecord!) in
                self.imageArray.append(record)
                print("image recordFetchedBlock - GUID: \(record[key_imageGUID]) recordId: \(record.recordID.recordName)")
            }
            
            // set up completion block with cursors so they can recursively gather all of the image records
            imageFetch.queryCompletionBlock = { (cursor : CKQueryCursor?, error : NSError?) in
                if cursor != nil {
                    print("there is more data to fetch")
                    let newOperation = CKQueryOperation(cursor: cursor!)
                    newOperation.recordFetchedBlock = imageFetch.recordFetchedBlock
                    newOperation.queryCompletionBlock = imageFetch.queryCompletionBlock
                    database.addOperation(newOperation)
                }
                
                if error != nil {
                    print("imageFetch error: \(error?.localizedDescription)")
                }
                
                if cursor == nil {
                    print("The image record fetch operation is complete...")
                    print("array count - image: \(self.imageArray.count)")
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        self.mergeImageCloudData()
                    }
                }
            }
            
            // execute the query operation
            database.addOperation(imageFetch)
        }
    
    }
    
    // after fetching cloud data, merge with local data
    func mergeCloudData()
    {
        print("mergeCloudData...")
        
        for cloudList in listArray {
            updateFromRecord(cloudList, forceUpdate: false)
        }
        
        for cloudCategory in categoryArray {
            updateFromRecord(cloudCategory, forceUpdate: false)
        }
        
        for cloudItem in itemArray {
           updateFromRecord(cloudItem, forceUpdate: false)
        }
        
        // check if any of the local objects are in the deleted list and if so delete
        processDeletedObjects()
        
        // purge old delete records from cloud storage
        purgeOldDeleteRecords()
        
        // now that items are merged we can call fetchImageData to
        // retreive any images that need updating
        self.fetchImageData()
        
        // updateFromRecord will set a timer to fire refreshListData after three seconds,
        // giving more time for cloud records to arrive before refreshing the UI
    }
    
    func mergeImageCloudData()
    {
        print("mergeImageCloudData...")
        
        for cloudImage in imageArray {
            updateFromRecord(cloudImage, forceUpdate: false)
        }
    }
    
    // check if any of the local objects are in the deleted list (deletedArray) and if so delete
    func processDeletedObjects()
    {
        print("processing deleted objects...")
        
        // create an array of recordID.recordName from the cloud delete records
        var listDeleteRecordIDs = [String]()
        var categoryDeleteRecordIDs = [String]()
        var itemDeleteRecordIDs = [String]()
        
        // populate the delete record arrays by record type
        for deleteRecord in deleteArray {
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
        if let listVC = listViewController
        {
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
        }
    }
    
    // purge any delete records older than one month
    func purgeOldDeleteRecords()
    {
        let now = NSDate.init()
        let userCalendar = NSCalendar.currentCalendar()
        let timeInterval = NSDateComponents()
        timeInterval.day = deletePurgeDays
        
        var purgeRecords = [CKRecord]()
        
        // collect records to be purged
        for record in deleteArray {
            if let deleteDate = record[key_deletedDate] as? NSDate {
                let expirationDate = userCalendar.dateByAddingComponents(timeInterval, toDate: deleteDate, options: [])!
                
                if now > expirationDate {
                    purgeRecords.append(record)
                }
            }
        }
        
        // submit delete operation
        batchRecordDelete(purgeRecords)
    }
    
    // sorts all lists, categories and items and updates indices
    func refreshListData()
    {
        if let listVC = listViewController {
            listVC.reorderListObjects()         // reorders all lists, categories and items according to order number
            listVC.tableView.reloadData()
        }
        
        if let itemVC = itemViewController {
            if let list = itemVC.list {
                itemVC.listNameChanged(list.name)
            }
            if itemVC.inEditMode == false {
                itemVC.tableView.reloadData()
                itemVC.resetCellViewTags()
            }
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
    
}

////////////////////////////////////////////////////////////////
//
//  MARK: - Global Methods and Extensions
//
////////////////////////////////////////////////////////////////

// Array extension for removing objects
extension Array where Element: Equatable
{
    mutating func removeObject(object: Element) {
        if let index = self.indexOf(object) {
            self.removeAtIndex(index)
        }
    }
    
    mutating func removeObjectsInArray(array: [Element]) {
        for object in array {
            self.removeObject(object)
        }
    }
}

// Date extension and methods for comparisons
public func ==(lhs: NSDate, rhs: NSDate) -> Bool
{
    return lhs === rhs || lhs.compare(rhs) == .OrderedSame
}

public func <(lhs: NSDate, rhs: NSDate) -> Bool
{
    return lhs.compare(rhs) == .OrderedAscending
}

public func >(lhs: NSDate, rhs: NSDate) -> Bool
{
    return lhs.compare(rhs) == .OrderedDescending
}

extension NSDate: Comparable { }


// print wrapper - will remove print statements from the release version
func print(items: Any..., separator: String = " ", terminator: String = "\n")
{
    #if DEBUG
    var idx = items.startIndex
    let endIdx = items.endIndex
    
    repeat {
        Swift.print(items[idx], separator: separator, terminator: idx == (endIdx - 1) ? terminator : separator)
        idx += 1
    } while idx < endIdx
    
    #endif
}
