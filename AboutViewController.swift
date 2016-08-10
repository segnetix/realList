//
//  AboutViewController.swift
//  EnList
//
//  Created by Steven Gentry on 3/22/16.
//  Copyright © 2016 Steven Gentry. All rights reserved.
//

import UIKit

enum PermissionStatus: Int, CustomStringConvertible {
    case Authorized, Unauthorized, Unknown, Disabled
    
    var description: String {
        switch self {
        case .Authorized:   return "Authorized"
        case .Unauthorized: return "Unauthorized"
        case .Unknown:      return "Unknown"
        case .Disabled:     return "Disabled" // System-level
        }
    }
}

class AboutViewController: UIAppViewController
{
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var cloudButton: UIButton!
    @IBOutlet weak var upgradeButton: UIButton!
    
    var listVC: ListViewController?
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        manager.delegate = self
        appDelegate.aboutViewController = self
        
        // get the bundle version string
        let version = NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as? String
        
        if var version = version {
            version = "v" + version
            
            #if DEBUG
                let bundle = NSBundle.mainBundle().infoDictionary?["CFBundleVersion"] as? String
                if let bundle = bundle {
                    version += " (" + bundle + ")"
                }
            #endif
            
            versionLabel.text = version
        }
        
        updateCloudStatus()
        updateUpgradeStatus()
    }
    
    func updateCloudStatus() {
        if appDelegate.iCloudIsAvailable() {
            cloudButton.setImage(UIImage(named: "Cloud_check"), forState: .Normal)
        } else {
            cloudButton.setImage(UIImage(named: "Cloud"), forState: .Normal)
        }
    }
    
    func updateUpgradeStatus() {
        if appDelegate.appIsUpgraded {
            upgradeButton.setImage(UIImage(named: "Upgraded"), forState: .Normal)
        } else {
            upgradeButton.setImage(UIImage(named: "Upgrade"), forState: .Normal)
        }
    }
    
    // callback function for network status change
    override func reachabilityStatusChangeHandler(reachability: Reachability)
    {
        super.reachabilityStatusChangeHandler(reachability)
        updateCloudStatus()
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    ///////////////////////////////////////////////////////
    //
    //  MARK: Actions
    //
    ///////////////////////////////////////////////////////
    
    @IBAction func goToiCloudSettings(sender: AnyObject)
    {
        UIApplication.sharedApplication().openURL(NSURL(string:"prefs:root=CASTLE")!)
    }
    
    @IBAction func goToNotificationSettings(sender: AnyObject)
    {
        if let appSettings = NSURL(string: UIApplicationOpenSettingsURLString) {
            UIApplication.sharedApplication().openURL(appSettings)
        }
    }
    
    @IBAction func appSettings(sender: UIButton)
    {
        print("app settings")
        let appSettingsVC = AppSettingsViewController()
        presentViewController(appSettingsVC, animated: true, completion: nil)
    }
    
    @IBAction func addTutorial(sender: AnyObject)
    {
        if let listVC = listVC {
            // generates the tutorial and selects it
            listVC.generateTutorial()
            
            // delay presentation of the itemVC until after dismissal of the About view
            let delay = 0.20 * Double(NSEC_PER_SEC)
            let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
            
            dispatch_after(time, dispatch_get_main_queue(), {
                if let itemVC = listVC.delegate as? ItemViewController {
                    listVC.splitViewController?.showDetailViewController(itemVC.navigationController!, sender: nil)
                }
            })
        }
        
        presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func upgrade(sender: UIButton)
    {
        print("upgrade...")
        let upgradeVC = UpgradeViewController()
        upgradeVC.aboutViewController = self
        presentViewController(upgradeVC, animated: true, completion: nil)
    }
    
    @IBAction func close(sender: UIButton)
    {
        appDelegate.aboutViewController = nil
        presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
    }
}
