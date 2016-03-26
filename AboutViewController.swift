//
//  AboutViewController.swift
//  EnList
//
//  Created by Steven Gentry on 3/22/16.
//  Copyright © 2016 Steven Gentry. All rights reserved.
//

import UIKit

class AboutViewController: UIViewController
{
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var iCloudLabel: UILabel!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // get the bundle version string
        if let text = NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as? String {
            versionLabel.text = "v" + text
        }
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        if appDelegate.iCloudIsAvailable() {
            iCloudLabel.text = "YES"
        } else {
            iCloudLabel.text = "NO"
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
    
    @IBAction func close(sender: UIButton)
    {
       presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
    }
}
