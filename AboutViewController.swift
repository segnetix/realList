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

class AboutViewController: UIAppViewController {
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var cloudButton: UIButton!
    @IBOutlet weak var upgradeButton: UIButton!
    @IBOutlet weak var doneButton: UIButton!
    
    var listVC: ListViewController?
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
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
                    versionLabel.font = versionLabel.font.withSize(12)
                }
            #endif
            
            versionLabel.text = version
        }
        
        doneButton.backgroundColor = UIColor.clear
        doneButton.layer.cornerRadius = 5
        doneButton.layer.borderWidth = 1
        doneButton.layer.borderColor = doneButton.tintColor.cgColor
        
        updateCloudStatus()
    }
    
    func updateCloudStatus() {
        if CloudCoordinator.iCloudIsAvailable() {
            cloudButton.setImage(UIImage(named: "Cloud_check"), for: UIControl.State())
        } else {
            cloudButton.setImage(UIImage(named: "Cloud"), for: UIControl.State())
        }
    }
    
    // callback function for network status change
    override func reachabilityStatusChangeHandler(_ reachability: Reachability) {
        super.reachabilityStatusChangeHandler(reachability)
        updateCloudStatus()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    ///////////////////////////////////////////////////////
    //
    //  MARK: Actions
    //
    ///////////////////////////////////////////////////////
    
    @IBAction func goToiCloudSettings(_ sender: AnyObject) {
        // NOTE: iOS no longer allows accessing iCould Settings via this method
//        if let cloudSettings = URL(string:"prefs:root=CASTLE") {
//            let success = UIApplication.shared.openURL(cloudSettings)
//            UIApplication.shared.open(cloudSettings)
//        }
        
        // use this to add a handler to open to app settings
        func openSettings(alert: UIAlertAction!) {
            if let url = URL.init(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }

        var message = "Please enable iCloud to let realList save lists in your iCloud account and share lists between devices."
        if CloudCoordinator.iCloudIsAvailable() {
            message = "Your iCloud account is all set for realList to save and share lists between devices."
        }
        
        let alert = UIAlertController(title: "iCloud Settings",
                                      message: message,
                                      preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "Open Settings",
//                                      style: UIAlertAction.Style.default,
//                                      handler: openSettings))
        alert.addAction(UIAlertAction(title: "OK",
                                      style: UIAlertAction.Style.default,
                                      handler: nil))

        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func appSettings(_ sender: UIButton) {
        print("app settings")
        let appSettingsVC = AppSettingsViewController()
        appSettingsVC.modalPresentationStyle = .fullScreen
        present(appSettingsVC, animated: true, completion: nil)
    }
    
    @IBAction func addTutorial(_ sender: AnyObject) {
        if let listVC = listVC {
            // generates the tutorial and selects it
            listVC.generateTutorial()
            
            // present the tutorial in the listVC after dismissing the aboutVC
            presentingViewController!.dismiss(animated: true) {
                if let itemVC = listVC.delegate as? ItemViewController {
                   listVC.splitViewController?.showDetailViewController(itemVC.navigationController!, sender: nil)
                }
            }
        } else {
            presentingViewController!.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func close(_ sender: UIButton) {
        appDelegate.aboutViewController = nil
        presentingViewController!.dismiss(animated: true, completion: nil)
    }
}
