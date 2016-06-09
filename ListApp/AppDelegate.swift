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

// list and item limits for free version
let kMaxListCount            =  2
let kMaxItemCount            = 12

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
    
    // holds references to items that have outdated image assets
    var itemReferences = [CKReference]()
    
    // cloud record fetch arrays for launch data merge
    var listFetchArray = [CKRecord]()
    var categoryFetchArray = [CKRecord]()
    var itemFetchArray = [CKRecord]()
    var deleteFetchArray = [CKRecord]()
    
    // notification record arrays
    var notificationArray = [CKRecord]()
    var deleteNotificationArray = [String]()
    
    // notification processing delay
    let kNotificationProcessingDelay = 2.0
    
    var notificationProcessingEventIsPending = false
    var printNotes = true
    var upgradePriceString = ""
    var upgradeProduct: SKProduct?
    var appIsUpgraded: Bool = false
    /*
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
    } */
    
    // app settings
    var namesCapitalize = true
    var namesSpellCheck = false
    var namesAutocorrection = false
    var notesCapitalize = true
    var notesSpellCheck = false
    var notesAutocorrection = false
    var picsInPrintAndEmail = false
    
    // delete purge delay
    let deletePurgeDays = 30                            // delete records will be purged from cloud storage after this many days
    
    // iCloud
    let container = CKContainer.defaultContainer()
    var privateDatabase: CKDatabase?
    
    // iCloud query operations
    var externalListFetch: CKQueryOperation?
    var externalCategoryFetch: CKQueryOperation?
    var externalDeleteFetch: CKQueryOperation?
    var externalItemFetch: CKQueryOperation?
    
    // reachability manager
    var manager: AppManager = AppManager.sharedInstance
    
    // HUD
    var hud: MBProgressHUD?
    
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
        
        // show both list and item view controllers if possible
        splitViewController!.preferredDisplayMode = UISplitViewControllerDisplayMode.AllVisible
        
        privateDatabase = container.privateCloudDatabase

        // init the reachability monitor
        AppManager.sharedInstance.initReachabilityMonitor()
        
        // app setup
        pushNotificationSetup(application)          // asks user for notification permission the first time app is run
        restoreListDataFromLocalStorage()           // gets list data from local storage
        restoreAppSettings()                        // restores the general app settings
        restoreUpgradeStatus()                      // restores upgrade status from local storage otherwise gets data from app store regarding upgrade pricing
        fetchCloudData()                            // gets cloud data and merges with local data including cloud deletes
        
        return true
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError)
    {
        print("*** didFailToRegisterForRemoteNotificationsWithError: \(error)")
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        print("*** didRegisterForRemoteNotificationsWithDeviceToken: \(deviceToken)")
        
        // user agreed to notifications so create subscriptions if necessary
        self.createSubscriptions()
    }

    func pushNotificationSetup(application: UIApplication) {
        let notificationSettings = UIUserNotificationSettings(forTypes: UIUserNotificationType.None, categories: nil)
        application.registerUserNotificationSettings(notificationSettings)
        application.registerForRemoteNotifications()
    }
    
    func restoreListDataFromLocalStorage() {
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
    }
    
    func restoreAppSettings() {
        // restore app settings
        if let printNotes          = NSUserDefaults.standardUserDefaults().objectForKey(key_printNotes)          as? Bool { self.printNotes          = printNotes          }
        if let namesCapitalize     = NSUserDefaults.standardUserDefaults().objectForKey(key_namesCapitalize)     as? Bool { self.namesCapitalize     = namesCapitalize     }
        if let namesSpellCheck     = NSUserDefaults.standardUserDefaults().objectForKey(key_namesSpellCheck)     as? Bool { self.namesSpellCheck     = namesSpellCheck     }
        if let namesAutocorrection = NSUserDefaults.standardUserDefaults().objectForKey(key_namesAutocorrection) as? Bool { self.namesAutocorrection = namesAutocorrection }
        if let notesCapitalize     = NSUserDefaults.standardUserDefaults().objectForKey(key_notesCapitalize)     as? Bool { self.notesCapitalize     = notesCapitalize     }
        if let notesSpellCheck     = NSUserDefaults.standardUserDefaults().objectForKey(key_notesSpellCheck)     as? Bool { self.notesSpellCheck     = notesSpellCheck     }
        if let notesAutocorrection = NSUserDefaults.standardUserDefaults().objectForKey(key_notesAutocorrection) as? Bool { self.notesAutocorrection = notesAutocorrection }
        if let picsInPrintAndEmail = NSUserDefaults.standardUserDefaults().objectForKey(key_picsInPrintAndEmail) as? Bool { self.picsInPrintAndEmail = picsInPrintAndEmail }
    }
    
    func restoreUpgradeStatus() {
        #if DEBUG
            //testing only...
            //self.appIsUpgraded = false
            //return
        #endif
        
        // restore upgrade status from user defaults
        if RealListProducts.store.isProductPurchased(RealListProducts.FullVersion) {
            self.appIsUpgraded = true
        } else {
            if (AppManager.sharedInstance.isReachable) {
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
        }
    }
    
    // iCloud sent notification of a change
    // add records to update arrays and trigger a notification processing event (if needed)
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject])
    {
        let cloudKitNotification = CKNotification(fromRemoteNotificationDictionary: userInfo as! [String : NSObject])
        
        if cloudKitNotification.notificationType == .Query {
            let queryNotification = cloudKitNotification as! CKQueryNotification
            if queryNotification.queryNotificationReason == .RecordDeleted {
                
                // if the record has been deleted in cloud then add the reference to the delete array and delete the local copy later in the batch process (processNotificationRecords)
                print("CloudKit: delete notification... \(queryNotification.recordID!.recordName)")
                if queryNotification.recordID != nil {
                    dispatch_async(dispatch_get_main_queue()) {
                        //NSLog("*** adding delete record")
                        self.deleteNotificationArray.append(queryNotification.recordID!.recordName)
                    }
                } else {
                    print("queryNotification gave nil recordID for delete...!")
                }
            } else {
                // if the record has been created or changed, we fetch the data from cloud
                guard let database = privateDatabase else { return }
                
                database.fetchRecordWithID(queryNotification.recordID!) { (record: CKRecord?, error: NSError?) -> Void in
                    if error != nil {
                        // Handle the error here
                        print("Notification error: \(error?.localizedDescription)")
                        return
                    }
                    if record != nil {
                        dispatch_async(dispatch_get_main_queue()) {
                            /*
                            if record!.recordType == ImagesRecordType {
                                //NSLog("*** adding update record: image for \(record![key_itemName])")
                            } else {
                                //NSLog("*** adding update record: \(record![key_name])")
                            }
                            */
                            self.notificationArray.append(record!)
                        }
                    }
                }
            }
            
            if !notificationProcessingEventIsPending {
                //NSLog("preparing notification processing event timer...")
                NSTimer.scheduledTimerWithTimeInterval(kNotificationProcessingDelay, target: self, selector: #selector(self.processNotificationRecords), userInfo: nil, repeats: false)
                notificationProcessingEventIsPending = true
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
        
        // check for updates while app was in the background
        fetchCloudData()
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        print("applicationDidBecomeActive...")
    }
    
    // called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground
    func applicationWillTerminate(application: UIApplication)
    {
        print("applicationWillTerminate...")
        
        // save state and data synchronously
        saveAll(false)
    }
    
////////////////////////////////////////////////////////////////
//
//  MARK: - Subscription and storage methods
//
////////////////////////////////////////////////////////////////
    
    // create subscriptions if necessary
    func createSubscriptions()
    {
        guard let database = privateDatabase else { return }
        guard iCloudIsAvailable() else { print("createSubscriptions - iCloud is not available..."); return }
        
        //print("called createSubscriptions...")
        
        // create a single subscription of the given type
        func createSubscription(recordType: String, delay: Double) {
            guard let database = privateDatabase else { return }
            
            // run later, making sure that all subscriptions have been deleted before re-subscribing...
            let predicate = NSPredicate(format: "TRUEPREDICATE")
            
            // save new subscription
            runAfterDelay(delay) {
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
        database.fetchAllSubscriptionsWithCompletionHandler() { (subscriptions, error) -> Void in
            if error == nil {
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
                // delay enables the subscriptions to be made in a single pass
                if !haveImagesSub     { createSubscription(ImagesRecordType,     delay: 0.0) }
                if !haveItemsSub      { createSubscription(ItemsRecordType,      delay: 3.0) }
                if !haveCategoriesSub { createSubscription(CategoriesRecordType, delay: 6.0) }
                if !haveListsSub      { createSubscription(ListsRecordType,      delay: 9.0) }
                
            } else {
                print("fetchAllSubscriptionsWithCompletionHandler error: \(error!.localizedDescription)")
            }
        }
    }
    
    // checks if the user has logged into their iCloud account or not
    func iCloudIsAvailable() -> Bool
    {
        var iCloudDriveOn = false
        var netReachable  = false
        var networkType   = "network not reachable"
        
        // determine if iCloudDrive is enabled for realList
        if let _ = NSFileManager.defaultManager().ubiquityIdentityToken {
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
    
    func saveState(asynchronously: Bool)
    {
        func save() {
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
        
        if asynchronously {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
                save()
            }
        } else {
            save()
        }
    }
    
    // writes any dirty objects to the cloud in a batch operation
    func saveListDataCloud(asynchronously: Bool)
    {
        updateRecords.removeAll()   // empty the updateRecords array
        guard iCloudIsAvailable() else { print("saveListDataCloud - iCloud is not available..."); return }
        
        func save() {
            // cloud batch save ready -- now send the records for batch updating
            self.batchRecordUpdate()
        }
        
        // this part must be run on the main thread to ensure that
        // we have gathered any records to be deleted before the
        // list data for the object is deleted
        if let listVC = self.listViewController {
            for list in listVC.lists {
                list.saveToCloud()
            }
        }
        
        if asynchronously {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
                save()
            }
        } else {
            save()
        }
    }
    
    // writes the complete object graph locally
    func saveListDataLocal(asynchronously: Bool)
    {
        func save() {
            if let listVC = self.listViewController {
                let successfulSave = NSKeyedArchiver.archiveRootObject(listVC.lists, toFile: self.ArchiveURL.path!)
                
                if !successfulSave {
                    print("ERROR: Failed to save list data locally...")
                } else {
                    //print("SAVE LOCAL DATA worked...!!!")
                }
            }
        }
        
        if asynchronously {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
                save()
            }
        } else {
            save()
        }
    }
    
    // Writes list data locally and to the cloud
    func saveListData(asynchronously: Bool) {
        saveListDataCloud(asynchronously)
        saveListDataLocal(asynchronously)
    }
    
    // Saves all app data.  If asynchronous then the save is put on a background thread.
    func saveAll(asynchronously: Bool) {
        saveState(asynchronously)
        saveListData(asynchronously)
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
                
                if let listVC = listViewController {
                    listVC.lists.append(newList)
                    print("added new list: \(newList.name)")
                }
            case CategoriesRecordType:
                if let list = getListFromReference(record) {
                    let newCategory = list.addCategory("", displayHeader: true, updateIndices: false, createRecord: false)
                    newCategory.updateFromRecord(record)
                    
                    print("added new category: \(newCategory.name)")
                } else {
                    print("*** ERROR: category \(record[key_name]) can't find list \(record[key_owningList])")
                }
            case ItemsRecordType:
                if let category = getCategoryFromReference(record) {
                    if category.categoryRecord != nil {
                        if let list = getListFromReference(category.categoryRecord!) {
                            let item = list.addItem(category, name: "", state: ItemState.Incomplete, updateIndices: false, createRecord: false)
                            
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
    }
    
    // deletes local data associated with the given recordName
    func deleteRecord(recordName: String)
    {
        guard let listVC = listViewController else { return }
        guard let obj = getLocalObject(recordName) else { print("deleteRecord: recordName not found...!"); return }
        
        if obj is List {
            let list = obj as! List
            let i = listVC.lists.indexOf(list)
            if i != nil {
                listVC.lists.removeAtIndex(i!)
            }
        } else if obj is Category {
            let category = obj as! Category
            let list = getListForCategory(category)
            if list != nil {
                let i = list!.categories.indexOf(category)
                if i != nil {
                    list!.categories.removeAtIndex(i!)
                }
            }
        } else if obj is Item {
            let item = obj as! Item
            let category = getCategoryForItem(item)
            if category != nil {
                let i = category!.items.indexOf(item)
                if i != nil {
                    category!.items.removeAtIndex(i!)
                }
            }
        }
    }
    
    // process the notification records
    func processNotificationRecords()
    {
        //NSLog("*** processNotificationRecords - update records: \(notificationArray.count)  delete records: \(deleteNotificationArray.count)")
        
        // separate notification records into list, category, item and image arrays
        var listRecords = [CKRecord]()
        var categoryRecords = [CKRecord]()
        var itemRecords = [CKRecord]()
        var imageRecords = [CKRecord]()
        
        for record in notificationArray {
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
        for deleteRecordIDName in deleteNotificationArray {
            deleteRecord(deleteRecordIDName)
        }
        
        // clear notification arrays and event flag
        notificationArray.removeAll()
        deleteNotificationArray.removeAll()
        notificationProcessingEventIsPending = false
        
        // now refresh the list data
        self.refreshListData()
        //NSLog("*** processNotificationRecords - finished")
    }
    
    func addToUpdateRecords(record: CKRecord, obj: AnyObject) {
        updateRecords[record] = obj
    }
    
    // these are references to items that need an updated image from the cloud
    func addToItemReferences(reference: CKReference) {
        itemReferences.append(reference)
    }
    
    // sends all records needing updating in batches to cloud storage
    func batchRecordUpdate()
    {
        guard let database = privateDatabase else { return }
        
        let batchSize = 250                                 // this number must be no greater than 400
        var ckRecords = [CKRecord](updateRecords.keys)      // initializes an array of CKRecords with the keys from the updateRecords dictionary
        var startIndex = 0                                  // start index for each loop
        var stopIndex = -1                                  // stop index for each loop
        
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
                    print("The following records had problems: \(error!.userInfo[CKPartialErrorsByItemIDKey])")
                }
            }
            
            // execute the batch save operation
            database.addOperation(saveRecordsOperation)
            
        } while stopIndex < ckRecords.count - 1
        
    }
    
    // deletes an array of records
    func batchRecordDelete(deleteRecords: [CKRecord])
    {
        guard let database = privateDatabase else { return }
        
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
    
    // pulls all list, category and item data from cloud storage
    func fetchCloudData()
    {
        //NSLog("fetchCloudData...")
        
        guard let database = privateDatabase else { return }
        guard iCloudIsAvailable() else { print("fetchCloudData - iCloud is not available..."); return }
        
        let resultCount = 0         // default value will let iCloud server decide how much to send in each block
        var itemFetchCount = 0      // holds the number of item records fetched
        let msg = NSLocalizedString("Fetching_Data", comment: "Fetching data message for the iCloud import HUD.")
        
        startHUD("iCloud", subtitle: msg + " 0")
        
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
            self.listFetchArray.append(record)
            //print("list recordFetchedBlock: \(record[key_name]) \(record[key_order]) \(record.recordID.recordName)")
        }
        
        categoryFetch.recordFetchedBlock = { (record : CKRecord!) in
            self.categoryFetchArray.append(record)
            //print("category recordFetchedBlock: \(record[key_name]) \(record[key_order]) \(record.recordID.recordName)")
        }
        
        deleteFetch.recordFetchedBlock = { (record : CKRecord!) in
            self.deleteFetchArray.append(record)
            //print("delete recordFetchedBlock: \(record[key_itemName]) \(record[key_deletedDate]) \(record.recordID.recordName)")
        }
        
        itemFetch.recordFetchedBlock = { (record : CKRecord!) in
            self.itemFetchArray.append(record)
            itemFetchCount += 1
            //print("item recordFetchedBlock: \(record[key_name]) \(record[key_order]) \(record.recordID.recordName)")
        }

        // set up completion blocks with cursors so they can recursively gather all of the records
        // also handles cascading cancellation of the operations
        
        // listFetch
        listFetch.queryCompletionBlock = { (cursor : CKQueryCursor?, error : NSError?) in
            if error != nil {
                print("listFetch error: \(error?.localizedDescription)")
            }
            
            if cursor != nil {
                print("\(self.listFetchArray.count) lists - there is more data to fetch...")
                let newOperation = CKQueryOperation(cursor: cursor!)
                newOperation.recordFetchedBlock = listFetch.recordFetchedBlock
                newOperation.queryCompletionBlock = listFetch.queryCompletionBlock
                newOperation.resultsLimit = resultCount
                listFetch = newOperation
                self.externalListFetch = listFetch
                database.addOperation(newOperation)
            } else if listFetch.cancelled {
                print("listFetch cancelled...")
                self.externalListFetch = nil
                self.externalCategoryFetch?.cancel()
                self.externalDeleteFetch?.cancel()
                self.externalItemFetch?.cancel()
                self.stopHUD()
            } else {
                //NSLog("list fetch complete")
                dispatch_async(dispatch_get_main_queue()) { self.externalListFetch = nil }
            }
        }
        
        // categoryFetch
        categoryFetch.queryCompletionBlock = { (cursor : CKQueryCursor?, error : NSError?) in
            if error != nil {
                print("categoryFetch error: \(error?.localizedDescription)")
            }
            
            if cursor != nil {
                print("\(self.categoryFetchArray.count) categories - there is more data to fetch...")
                let newOperation = CKQueryOperation(cursor: cursor!)
                newOperation.recordFetchedBlock = categoryFetch.recordFetchedBlock
                newOperation.queryCompletionBlock = categoryFetch.queryCompletionBlock
                newOperation.resultsLimit = resultCount
                categoryFetch = newOperation
                self.externalCategoryFetch = categoryFetch
                database.addOperation(newOperation)
            } else if categoryFetch.cancelled {
                print("categoryFetch cancelled...")
                self.externalCategoryFetch = nil
                self.externalDeleteFetch?.cancel()
                self.externalItemFetch?.cancel()
                self.stopHUD()
            } else {
                //NSLog("category fetch complete")
                dispatch_async(dispatch_get_main_queue()) { self.externalCategoryFetch = nil }
            }
        }
        
        // deleteFetch
        deleteFetch.queryCompletionBlock = { (cursor : CKQueryCursor?, error : NSError?) in
            if error != nil {
                print("deleteFetch error: \(error?.localizedDescription)")
            }
            
            if cursor != nil {
                print("\(self.deleteFetchArray.count) delete items - there is more data to fetch...")
                let newOperation = CKQueryOperation(cursor: cursor!)
                newOperation.recordFetchedBlock = deleteFetch.recordFetchedBlock
                newOperation.queryCompletionBlock = deleteFetch.queryCompletionBlock
                newOperation.resultsLimit = resultCount
                deleteFetch = newOperation
                self.externalDeleteFetch = deleteFetch
                database.addOperation(newOperation)
            } else if deleteFetch.cancelled {
                print("deleteFetch cancelled...")
                self.externalDeleteFetch = nil
                self.externalItemFetch?.cancel()
                self.stopHUD()
            } else {
                //NSLog("delete fetch complete")
                dispatch_async(dispatch_get_main_queue()) { self.externalDeleteFetch = nil }
            }
        }
        
        // itemFetch - passes on to mergeCloudData when complete
        itemFetch.queryCompletionBlock = { (cursor : CKQueryCursor?, error : NSError?) in
            if error != nil {
                print("itemFetch error: \(error?.localizedDescription)")
            }
            
            // update HUD
            dispatch_async(dispatch_get_main_queue()) {
                if self.hud != nil {
                    self.hud!.detailsLabel.text = msg + " \(itemFetchCount)"
                }
            }
            
            if cursor != nil {
                //print("item cursor: \(cursor)")
                print("\(self.itemFetchArray.count) items - there is more data to fetch...")
                let newOperation = CKQueryOperation(cursor: cursor!)
                newOperation.recordFetchedBlock = itemFetch.recordFetchedBlock
                newOperation.queryCompletionBlock = itemFetch.queryCompletionBlock
                newOperation.resultsLimit = resultCount
                itemFetch = newOperation
                self.externalItemFetch = itemFetch
                database.addOperation(newOperation)
            } else if itemFetch.cancelled {
                print("itemFetch cancelled...")
                self.externalItemFetch = nil
                self.stopHUD()
            } else {
                //NSLog("item fetch complete")
                
                // need to wait for all fetches before continuing to merge
                //NSLog("start fetch wait...")
                repeat {
                    // hold until other completion blocks finish
                } while self.externalListFetch != nil || self.externalCategoryFetch != nil || self.externalDeleteFetch != nil
                //NSLog("end fetch wait...")
                
                //NSLog("array counts - list: \(self.listFetchArray.count) category: \(self.categoryFetchArray.count) item: \(self.itemFetchArray.count) delete: \(self.deleteFetchArray.count)")
                
                dispatch_async(dispatch_get_main_queue())
                {
                    //NSLog("dispatch main thread merge")
                    self.externalListFetch = nil
                    self.externalCategoryFetch = nil
                    self.externalItemFetch = nil
                    self.externalDeleteFetch = nil
                    
                    // merge cloud data
                    self.mergeCloudData()
                }
            }
        }
        
        // set external fetch pointers
        externalListFetch = listFetch
        externalCategoryFetch = categoryFetch
        externalDeleteFetch = deleteFetch
        externalItemFetch = itemFetch
        
        // execute the query operations
        database.addOperation(itemFetch)
        database.addOperation(categoryFetch)
        database.addOperation(listFetch)
        database.addOperation(deleteFetch)
    }
    
    // must be called on main thread
    func cancelCloudDataFetch()
    {
        print("*** cancelCloudDataFetch ***")
        var canceled = false
        
        // executes on main thread
        if let externalListFetch = externalListFetch {
            externalListFetch.cancel()
            canceled = true
        }
        if let externalCategoryFetch = externalCategoryFetch {
            externalCategoryFetch.cancel()
            canceled = true
        }
        if let externalDeleteFetch = externalDeleteFetch {
            externalDeleteFetch.cancel()
            canceled = true
        }
        if let externalItemFetch = externalItemFetch {
            externalItemFetch.cancel()
            canceled = true
        }
        
        if canceled {
            if let itemVC = itemViewController {
                itemVC.dataFetchCanceledAlert()
            }
        }
    }
    
    // pulls image data in batches for items needing updating (itemReferences)
    func fetchImageData()
    {
        //NSLog("fetchImageData - \(itemReferences.count) items need new images...")
        
        guard let database = privateDatabase else { return }
        
        let batchSize = 50          // size of the batch request block
        var imageFetchCount = 0     // holds count of fetched images
        
        if itemReferences.count == 0 {
            print("fetchImageData = itemReferences.count == 0")
            stopHUD()
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
                stopHUD()
                return
            }
            
            // temp image record array
            var imageArray = [CKRecord]()
            
            // set up a temp arrary of references for this batch
            var batchReferences = [CKReference]()
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
                
                // update HUD
                /*
                dispatch_async(dispatch_get_main_queue()) {
                    if self.hud != nil {
                        self.hud!.detailsLabel.text = msg + " \(imageFetchCount)"
                    }
                }*/
            }
            
            imageFetch.queryCompletionBlock = { [loop, startIndex, stopIndex] (cursor : CKQueryCursor?, error : NSError?) in
                if cursor != nil {
                    print("******* ERROR:  fetchImageData - there is more data to fetch and there should not be...")
                }
                
                if error != nil {
                    print("imageFetch error: \(error?.localizedDescription)")
                }
                
                print("image record fetch operation for loop \(loop) is complete... \(startIndex+1) to \(stopIndex+1)")
                
                // send this batch of image records to the merge method on the main thread
                dispatch_async(dispatch_get_main_queue()) {
                    self.mergeImageCloudData(imageArray)
                }
            }
            
            // execute the query operation
            database.addOperation(imageFetch)
            
        } while stopIndex < itemReferences.count - 1
    }
    
    // after fetching cloud data, merge with local data
    // NOTE: this must be called from the main thread
    func mergeCloudData()
    {
        //NSLog("mergeCloudData...")
        
        for cloudList in listFetchArray {
            updateFromRecord(cloudList, forceUpdate: false)
        }
        
        for cloudCategory in categoryFetchArray {
            updateFromRecord(cloudCategory, forceUpdate: false)
        }
        
        for cloudItem in itemFetchArray {
           updateFromRecord(cloudItem, forceUpdate: false)
        }
        
        // check if any of the local objects are in the deleted list and if so delete
        processDeletedObjects()
        
        // purge old delete records from cloud storage
        purgeOldDeleteRecords()
        
        // now that items are merged we can call fetchImageData to
        // retreive any images that need updating
        fetchImageData()
        
        // refreshListData
        refreshListData()
        
        // reload list and item views and update orders
        if let itemVC = itemViewController {
            itemVC.refreshItems()
        }
        
        if let listVC = listViewController {
            listVC.tableView.reloadData()
        }
        
        resetListCategoryAndItemOrderByPosition()
        
        // clear needToSave on all objects as we are clean from local load
        if let listVC = listViewController {
            for list in listVC.lists {
                list.updateIndices()
                list.clearNeedToSave()
            }
        }
        
        // shows the completed HUD then dismisses itself
        startHUDwithDone()
    }
    
    func mergeImageCloudData(imageRecords: [CKRecord])
    {
        //NSLog("mergeImageCloudData...")
        
        //startHUD("iCloud", subtitle: NSLocalizedString("Merging_Images", comment: "Merging images message for the iCloud import HUD."))
        
        for cloudImage in imageRecords {
            updateFromRecord(cloudImage, forceUpdate: false)
        }
    }
    
    // check if any of the local objects are in the deleted list (deletedArray) and if so delete
    func processDeletedObjects()
    {
        //NSLog("processDeletedObjects...")
        
        // create an array of recordID.recordName from the cloud delete records
        var listDeleteRecordIDs = [String]()
        var categoryDeleteRecordIDs = [String]()
        var itemDeleteRecordIDs = [String]()
        
        // populate the delete record arrays by record type
        for deleteRecord in deleteFetchArray {
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
        guard let listVC = listViewController else { return }
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
    
    // purge any delete records older than one month
    func purgeOldDeleteRecords()
    {
        //NSLog("purgeOldDeleteRecords...")
        
        let now = NSDate.init()
        let userCalendar = NSCalendar.currentCalendar()
        let timeInterval = NSDateComponents()
        timeInterval.day = deletePurgeDays
        
        var purgeRecords = [CKRecord]()
        
        // collect records to be purged
        for record in deleteFetchArray {
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
    
    ////////////////////////////////////////////////////////////////
    //
    //  MARK: - HUD Methods
    //
    ////////////////////////////////////////////////////////////////
    
    // these methods may be called from background threads
    func startHUD(title: String, subtitle: String) {
        guard let theView = splitViewController!.view else { return }
        
        dispatch_async(dispatch_get_main_queue()) {
            if self.hud == nil {
                self.hud = MBProgressHUD.showHUDAddedTo(theView, animated: true)
                self.hud?.minSize = CGSize(width: 160, height: 160)
                self.hud?.offset = CGPoint(x: 0, y: -60)
                self.hud!.contentColor = UIColor.darkGrayColor()
                self.hud!.mode = MBProgressHUDMode.Indeterminate
                self.hud!.minShowTime = NSTimeInterval(1.0)
                self.hud!.button.setTitle("Cancel", forState: .Normal)
                self.hud!.button.addTarget(self, action: #selector(AppDelegate.cancelCloudDataFetch), forControlEvents: .TouchUpInside)
            }
            
            // dynamic elements
            self.hud!.label.text = title
            self.hud!.detailsLabel.text = subtitle
        }
    }
    
    // displays a done HUD for 0.8 seconds
    func startHUDwithDone() {
        guard let theView = splitViewController!.view else { return }
        
        dispatch_async(dispatch_get_main_queue()) {
            if self.hud != nil {
                self.hud!.hideAnimated(false)
                self.hud = nil
            }
            
            self.hud = MBProgressHUD.showHUDAddedTo(theView, animated: true)
            
            if let hud = self.hud {
                hud.mode = MBProgressHUDMode.CustomView
                hud.offset = CGPoint(x: 0, y: -60)
                hud.contentColor = UIColor.darkGrayColor()
                hud.minSize = CGSize(width: 160, height: 160)
                let imageView = UIImageView(image: UIImage(named: "checkbox_blue"))
                hud.customView = imageView
                hud.label.text = NSLocalizedString("Done", comment: "Done")
                hud.hideAnimated(true, afterDelay: 0.8)
                self.hud = nil
                //NSLog("HUD completed...")
            }
        }
    }
    
    func stopHUD() {
        dispatch_async(dispatch_get_main_queue()) {
            if let hud = self.hud {
                hud.hideAnimated(true)
                self.hud = nil
            }
        }
    }
    
    ////////////////////////////////////////////////////////////////
    //
    //  MARK: - List Data access methods
    //
    ////////////////////////////////////////////////////////////////
    
    // sorts all lists, categories and items and updates indices
    // called as part of the notification chain
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
    
    func resetListCategoryAndItemOrderByPosition() {
        if let listVC = listViewController {
            listVC.resetListCategoryAndItemOrderByPosition()
        }
    }
    
    func countNeedToSave() -> Int? {
        if let listVC = listViewController {
            return listVC.countNeedToSave()
        }
        
        return nil
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
    
    // returns the list that contains the given category
    func getListForCategory(searchCategory: Category) -> List?
    {
        if let listVC = listViewController {
            for list in listVC.lists {
                for category in list.categories {
                    if category === searchCategory {
                        return list
                    }
                }
            }
        }
        
        return nil
    }
    
    // returns the category that contains the given item
    func getCategoryForItem(searchItem: Item) -> Category?
    {
        if let listVC = listViewController {
            for list in listVC.lists {
                for category in list.categories {
                    for item in category.items {
                        if item === searchItem {
                            return category
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

func runAfterDelay(delay: NSTimeInterval, block: dispatch_block_t) {
    let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)))
    dispatch_after(time, dispatch_get_main_queue(), block)
}

