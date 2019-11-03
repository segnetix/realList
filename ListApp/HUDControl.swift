//
//  HUDControl.swift
//  EnList
//
//  Created by Steven Gentry on 11/3/19.
//  Copyright © 2019 Steven Gentry. All rights reserved.
//

import Foundation


class HUDControl {
    // these methods may be called from background threads
    static func startHUD(_ title: String, subtitle: String) {
        guard let theView = appDelegate.splitViewController!.view else { return }
        
        DispatchQueue.main.async {
            if appDelegate.hud == nil {
                appDelegate.hud = MBProgressHUD.showAdded(to: theView, animated: true)
                appDelegate.hud?.minSize = CGSize(width: 160, height: 160)
                appDelegate.hud?.offset = CGPoint(x: 0, y: -60)
                appDelegate.hud!.contentColor = UIColor.darkGray
                appDelegate.hud!.mode = MBProgressHUDMode.indeterminate
                appDelegate.hud!.minShowTime = TimeInterval(1.0)
                appDelegate.hud!.button.setTitle("Cancel", for: UIControl.State())
                appDelegate.hud!.button.addTarget(self, action: #selector(CloudCoordinator.cancelCloudDataFetch), for: .touchUpInside)
            }
            
            // dynamic elements
            appDelegate.hud!.label.text = title
            appDelegate.hud!.detailsLabel.text = subtitle
        }
    }
    
    // displays a done HUD for 0.8 seconds
    static func startHUDwithDone() {
        guard let theView = appDelegate.splitViewController!.view else { return }
        
        DispatchQueue.main.async {
            if appDelegate.hud != nil {
                appDelegate.hud!.hide(animated: false)
                appDelegate.hud = nil
            }
            
            appDelegate.hud = MBProgressHUD.showAdded(to: theView, animated: true)
            
            if let hud = appDelegate.hud {
                hud.mode = MBProgressHUDMode.customView
                hud.offset = CGPoint(x: 0, y: -60)
                hud.contentColor = UIColor.darkGray
                hud.minSize = CGSize(width: 160, height: 160)
                let imageView = UIImageView(image: UIImage(named: "checkbox_blue"))
                hud.customView = imageView
                hud.label.text = NSLocalizedString("Done", comment: "Done")
                hud.hide(animated: true, afterDelay: 1.0)
                appDelegate.hud = nil
                //NSLog("HUD completed...")
            }
        }
    }
    
    static func stopHUD() {
        DispatchQueue.main.async {
            if let hud = appDelegate.hud {
                hud.hide(animated: true)
                appDelegate.hud = nil
            }
        }
    }
}
