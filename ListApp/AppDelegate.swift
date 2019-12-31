//  AppDelegate.swift
//  EnList
//
//  Created by Steven Gentry on 12/30/15.
//  Copyright © 2015 Steven Gentry. All rights reserved.
//

import UIKit
import CloudKit
import StoreKit
import UserNotifications

// display link scroll loop updates per second
let kFramesPerSecond         = 60

// price formatter function
let priceFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.formatterBehavior = .behavior10_4
    formatter.numberStyle = .currency
    return formatter
}()

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    var window: UIWindow?
    var splitViewController: UISplitViewController?
    var leftNavController: UINavigationController?
    var listViewController: ListViewController?
    var rightNavController: UINavigationController?
    var itemViewController: ItemViewController?
    var aboutViewController: AboutViewController?
    
    // notification record arrays
    var notificationArray = [CKRecord]()
    var deleteNotificationArray = [String]()
    
    // notification processing delay
    let kNotificationProcessingDelay = 2.0
    
    var notificationProcessingEventIsPending = false
    var printNotes = true
    
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
    
    // reachability manager
    var manager: AppManager = AppManager.sharedInstance
    
    // migration - execute a save after both the list data and the image data have been downloaded and merged
    var needsDataSaveOnMigration = false
    var listDataMergeComplete = false {
        didSet {
            if needsDataSaveOnMigration && imageDataMergeComplete {
                DataPersistenceCoordinator.saveAll(async: true)
                needsDataSaveOnMigration = false
                CloudCoordinator.deleteAllRecordsInDefaultZone()
            }
        }
    }
    var imageDataMergeComplete = false {
        didSet {
            if needsDataSaveOnMigration && listDataMergeComplete {
                DataPersistenceCoordinator.saveAll(async: true)
                needsDataSaveOnMigration = false
                CloudCoordinator.deleteAllRecordsInDefaultZone()
            }
        }
    }
    
    // HUD
    var hud: MBProgressHUD?
    var isUpdating = false
    var refreshLabel: UILabel?
    var refreshEnd: () -> Void = { }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // set up controller access for application state persistence
        splitViewController = self.window!.rootViewController as? UISplitViewController
        leftNavController   = (splitViewController!.viewControllers.first as! UINavigationController)
        listViewController  = (leftNavController!.topViewController as! ListViewController)
        rightNavController  = (splitViewController!.viewControllers.last as! UINavigationController)
        itemViewController  = (rightNavController!.topViewController as! ItemViewController)
        
        listViewController!.delegate = itemViewController
        itemViewController!.navigationItem.leftItemsSupplementBackButton = true
        itemViewController!.navigationItem.leftBarButtonItem = splitViewController!.displayModeButtonItem
                
        // show both list and item view controllers if possible
        splitViewController!.preferredDisplayMode = UISplitViewController.DisplayMode.allVisible
        
        // init the reachability monitor
        AppManager.sharedInstance.initReachabilityMonitor()
        
        // DEVELOPMENT ONLY: delete the shared zone and all the data in the zone
        // NOTE: Zone deletion can also be done from the CloudKit Dashboard
        // CloudCoordinator.deleteSharedZone()
        // return true
        
        // check for existing shared zone and proceed with app setup
        CloudCoordinator.sharedZoneExists() { sharedZoneExists, error in
            if let error = error {
                print("***** sharedZoneExists - ERROR: \(error.localizedDescription)")
            } else {
                if sharedZoneExists {
                    self.finishAppSetup(application, sharedZoneWasJustSetup: false)
                } else {
                    CloudCoordinator.setupSharedZone() { zoneWasSetup, error in
                        if let error = error {
                            print("***** setupSharedZone - ERROR: \(error.localizedDescription)")
                            DispatchQueue.main.async {
                                self.handleSharedZoneError(error)
                            }
                        } else {
                            print("shared zone was setup...")
                            
                            // app setup after zone created
                            self.finishAppSetup(application, sharedZoneWasJustSetup: zoneWasSetup)
                        }
                    }
                }
            }
        }
        
        return true
    }
    
    func finishAppSetup(_ application: UIApplication, sharedZoneWasJustSetup: Bool) {
        DispatchQueue.main.async {
            // if zone was newly created then we will need a local and cloud data save after merge
            self.needsDataSaveOnMigration = sharedZoneWasJustSetup
            application.registerForRemoteNotifications()            // register for silent notifications
            self.restoreListDataFromLocalStorage()                  // gets list data from local storage
            self.restoreAppSettings()                               // restores the general app settings
            CloudCoordinator.fetchCloudData(nil, refreshEnd: {} )   // gets cloud data and merges with local data including cloud deletes
        }
    }
    
    // TODO: Fix this!!!
    // This does not work because the itemViewController is not ready to present alerts and alerts must be presented from a view controller.
    func handleSharedZoneError(_ error: Error) {
        guard let viewController = itemViewController else { return }
        
        let alertController = UIAlertController(title: "Error Setting Up iCloud", message: "There was an error encountered while attempting to set up the shared data zone in iCloud.  Please quit realList and re-launch.\n\nERROR: \(error.localizedDescription)", preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default) { (action) in
            // No action
        }
        alertController.addAction(OKAction)
        
        viewController.present(alertController, animated: true, completion: nil)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("*** didFailToRegisterForRemoteNotificationsWithError: \(error)")
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        //print("*** didRegisterForRemoteNotificationsWithDeviceToken: \(deviceToken)")
        
        // create subscriptions if necessary
        SubscriptionManager.manageSubscriptions()
    }
    
    func restoreListDataFromLocalStorage() {
        guard let listViewController = listViewController else { return }
        guard let itemViewController = itemViewController else { return }
        
        // check for old local data which is no longer compatible with v1.2 local serialization
        guard UserDefaults.standard.bool(forKey: SubscriptionManager.key_subscribedToPrivateData) else {
            // this is a first load after upgrade to v1.2 so need to delete local data
            do {
                try FileManager.default.removeItem(atPath: ListData.filePath(key: key_listData))
            } catch {
                print("file delete error")
            }
            return
        }
        
        // restore the list data from local storage
        if ListData.loadLocal() {
            if let initialListIndex = UserDefaults.standard.object(forKey: key_selectionIndex) as? Int {
                if initialListIndex >= 0 && initialListIndex < ListData.listCount {
                    itemViewController.list = ListData.list(initialListIndex)
                    listViewController.selectionIndex = initialListIndex
                } else {
                    listViewController.selectionIndex = -1
                }
            }
        } else {
            // temp - comment out the tutorial generation line below for development
            listViewController.generateTutorial()
            listViewController.selectList(0)
        }
    }
    
    func restoreAppSettings() {
        // restore app settings
        if let printNotes          = UserDefaults.standard.object(forKey: key_printNotes)          as? Bool { self.printNotes          = printNotes          }
        if let namesCapitalize     = UserDefaults.standard.object(forKey: key_namesCapitalize)     as? Bool { self.namesCapitalize     = namesCapitalize     }
        if let namesSpellCheck     = UserDefaults.standard.object(forKey: key_namesSpellCheck)     as? Bool { self.namesSpellCheck     = namesSpellCheck     }
        if let namesAutocorrection = UserDefaults.standard.object(forKey: key_namesAutocorrection) as? Bool { self.namesAutocorrection = namesAutocorrection }
        if let notesCapitalize     = UserDefaults.standard.object(forKey: key_notesCapitalize)     as? Bool { self.notesCapitalize     = notesCapitalize     }
        if let notesSpellCheck     = UserDefaults.standard.object(forKey: key_notesSpellCheck)     as? Bool { self.notesSpellCheck     = notesSpellCheck     }
        if let notesAutocorrection = UserDefaults.standard.object(forKey: key_notesAutocorrection) as? Bool { self.notesAutocorrection = notesAutocorrection }
        if let picsInPrintAndEmail = UserDefaults.standard.object(forKey: key_picsInPrintAndEmail) as? Bool { self.picsInPrintAndEmail = picsInPrintAndEmail }
    }
    
    // iCloud sent notification of a change
    // add records to update arrays and trigger a notification processing event (if needed)
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        let cloudKitNotification = CKNotification(fromRemoteNotificationDictionary: userInfo as! [String : NSObject])!
        
        if cloudKitNotification.notificationType == .query {
            let queryNotification = cloudKitNotification as! CKQueryNotification
            if queryNotification.queryNotificationReason == .recordDeleted {
                
                // if the record has been deleted in cloud then add the reference to the delete array and delete the local copy later in the batch process (processNotificationRecords)
                print("CloudKit: delete notification... \(queryNotification.recordID!.recordName)")
                if queryNotification.recordID != nil {
                    DispatchQueue.main.async {
                        //NSLog("*** adding delete record")
                        self.deleteNotificationArray.append(queryNotification.recordID!.recordName)
                    }
                } else {
                    print("queryNotification gave nil recordID for delete...!")
                }
            } else {
                // if the record has been created or changed, we fetch the data from cloud
                let database = CloudCoordinator.privateDatabase
                
                database.fetch(withRecordID: queryNotification.recordID!) { (record: CKRecord?, error: Error?) -> Void in
                    if error != nil {
                        // Handle the error here
                        print("Notification error: \(String(describing: error?.localizedDescription))")
                        return
                    }
                    if record != nil {
                        DispatchQueue.main.async {
                            self.notificationArray.append(record!)
                        }
                    }
                }
            }
            
            if !notificationProcessingEventIsPending {
                NSLog("preparing notification processing event timer...")
                Timer.scheduledTimer(timeInterval: kNotificationProcessingDelay, target: self, selector: #selector(processNotificationRecords), userInfo: nil, repeats: false)
                notificationProcessingEventIsPending = true
            }
        }
    }
    
    @objc func processNotificationRecords() {
        DataPersistenceCoordinator.processNotificationRecords()
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        
        print("applicationWillResignActive...")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        print("applicationDidEnterBackground...")
        
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        
        print("applicationWillEnterForeground...")
        
        // check for updates while app was in the background
        //fetchCloudData()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        print("applicationDidBecomeActive...")
    }
    
    // called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground
    func applicationWillTerminate(_ application: UIApplication) {
        print("applicationWillTerminate...")
        
        // save state and data synchronously
        DataPersistenceCoordinator.saveAll(async: false)
    }
    
    
    // MARK:-
    
    func passGestureToListVC(_ gesture: UILongPressGestureRecognizer, obj: ListObj?) {
        if let listVC = self.listViewController {
            listVC.processGestureFromItemVC(gesture, listObj: obj)
        }
    }
    
}

