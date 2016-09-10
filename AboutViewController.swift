//
//  AboutViewController.swift
//  EnList
//
//  Created by Steven Gentry on 3/22/16.
//  Copyright © 2016 Steven Gentry. All rights reserved.
//

import UIKit

enum PermissionStatus: Int, CustomStringConvertible {
    case authorized, unauthorized, unknown, disabled
    
    var description: String {
        switch self {
        case .authorized:   return "Authorized"
        case .unauthorized: return "Unauthorized"
        case .unknown:      return "Unknown"
        case .disabled:     return "Disabled" // System-level
        }
    }
}

class AboutViewController: UIAppViewController
{
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var cloudButton: UIButton!
    @IBOutlet weak var upgradeButton: UIButton!
    
    var listVC: ListViewController?
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        manager.delegate = self
        appDelegate.aboutViewController = self
        
        // get the bundle version string
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        
        if var version = version {
            version = "v" + version
            
            #if DEBUG
                let bundle = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
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
            cloudButton.setImage(UIImage(named: "Cloud_check"), for: UIControlState())
        } else {
            cloudButton.setImage(UIImage(named: "Cloud"), for: UIControlState())
        }
    }
    
    func updateUpgradeStatus() {
        if appDelegate.appIsUpgraded {
            upgradeButton.setImage(UIImage(named: "Upgraded"), for: UIControlState())
        } else {
            upgradeButton.setImage(UIImage(named: "Upgrade"), for: UIControlState())
        }
    }
    
    // callback function for network status change
    override func reachabilityStatusChangeHandler(_ reachability: Reachability)
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
    
    @IBAction func goToiCloudSettings(_ sender: AnyObject)
    {
        UIApplication.shared.openURL(URL(string:"prefs:root=CASTLE")!)
    }
    
    @IBAction func goToNotificationSettings(_ sender: AnyObject)
    {
        if let appSettings = URL(string: UIApplicationOpenSettingsURLString) {
            UIApplication.shared.openURL(appSettings)
        }
    }
    
    @IBAction func appSettings(_ sender: UIButton)
    {
        print("app settings")
        let appSettingsVC = AppSettingsViewController()
        present(appSettingsVC, animated: true, completion: nil)
    }
    
    @IBAction func addTutorial(_ sender: AnyObject)
    {
        if let listVC = listVC {
            // generates the tutorial and selects it
            listVC.generateTutorial()
            
            // delay presentation of the itemVC until after dismissal of the About view
            let delay = 0.20 * Double(NSEC_PER_SEC)
            let time = DispatchTime.now() + Double(Int64(delay)) / Double(NSEC_PER_SEC)
            
            DispatchQueue.main.asyncAfter(deadline: time, execute: {
                if let itemVC = listVC.delegate as? ItemViewController {
                    listVC.splitViewController?.showDetailViewController(itemVC.navigationController!, sender: nil)
                }
            })
        }
        
        presentingViewController!.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func upgrade(_ sender: UIButton)
    {
        print("upgrade...")
        let upgradeVC = UpgradeViewController()
        upgradeVC.aboutViewController = self
        present(upgradeVC, animated: true, completion: nil)
    }
    
    @IBAction func close(_ sender: UIButton)
    {
        appDelegate.aboutViewController = nil
        presentingViewController!.dismiss(animated: true, completion: nil)
    }
}
