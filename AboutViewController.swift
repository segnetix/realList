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

class AboutViewController: UIViewController
{
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var cloudButton: UIButton!
    @IBOutlet weak var upgradeButton: UIButton!
    
    var listVC: ListViewController?
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        appDelegate.aboutViewController = self
        
        // get the bundle version string
        if let text = NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as? String {
            versionLabel.text = "v" + text
        }
        
        updateCloudStatus()
    }
    
    func updateCloudStatus() {
        if appDelegate.iCloudIsAvailable() {
            cloudButton.setImage(UIImage(named: "Cloud_check"), forState: .Normal)
        } else {
            cloudButton.setImage(UIImage(named: "Cloud"), forState: .Normal)
        }
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
            listVC.generateTutorial()
        }
        
        presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func upgrade(sender: UIButton)
    {
        print("upgrade...")
        let upgradeVC = UpgradeViewController()
        presentViewController(upgradeVC, animated: true, completion: nil)
    }
    
    @IBAction func close(sender: UIButton)
    {
        appDelegate.aboutViewController = nil
        presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
    }
}
