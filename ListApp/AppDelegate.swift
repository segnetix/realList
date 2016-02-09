//
//  AppDelegate.swift
//  ListApp
//
//  Created by Steven Gentry on 12/30/15.
//  Copyright © 2015 Steven Gentry. All rights reserved.
//

import UIKit

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
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        
        print("applicationWillResignActive...")
        
        // save current selection
        NSUserDefaults.standardUserDefaults().setObject(listViewController!.selectionIndex, forKey: "selectionIndex")
        
        // save the list data
        if let listVC = listViewController {
            let successfulSave = NSKeyedArchiver.archiveRootObject(listVC.lists, toFile: ArchiveURL.path!)
            
            if !successfulSave {
                print("Failed to save list data...")
            }
        }
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
        
        // Override point for customization after application launch.
        
        // restore the list data
        if let archivedListData = NSKeyedUnarchiver.unarchiveObjectWithFile(ArchiveURL.path!) as? [List] {
            listViewController!.lists = archivedListData
        }
        
        // restore the selected list
        if let initialListIndex = NSUserDefaults.standardUserDefaults().objectForKey("selectionIndex") as? Int {
            if initialListIndex >= 0 && initialListIndex < listViewController!.lists.count {
                itemViewController!.list = listViewController!.lists[initialListIndex]
                listViewController!.selectionIndex = initialListIndex
            } else {
                listViewController!.selectionIndex = -1
            }
        }
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        
        print("applicationWillTerminate...")
        
    }
}

