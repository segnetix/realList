//
//  UpgradeViewController.swift
//  EnList
//
//  Created by Steven Gentry on 4/17/16.
//  Copyright © 2016 Steven Gentry. All rights reserved.
//

import UIKit

class UpgradeViewController: UIAppViewController
{
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    @IBOutlet weak var buyButton: UIButton!
    @IBOutlet weak var purchasedCheck: UIImageView!
    @IBOutlet weak var restoreButton: UIButton!
    weak var aboutViewController: AboutViewController?
    
    var hud: MBProgressHUD?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        manager.delegate = self
        
        buyButton.backgroundColor = UIColor.clear
        buyButton.layer.cornerRadius = 5
        buyButton.layer.borderWidth = 1
        buyButton.layer.borderColor = view.tintColor.cgColor
        
        restoreButton.backgroundColor = UIColor.clear
        restoreButton.layer.cornerRadius = 5
        restoreButton.layer.borderWidth = 1
        restoreButton.layer.borderColor = view.tintColor.cgColor
        
        self.reload()
        
        // set up notifications for purchase and restore events
        NotificationCenter.default.addObserver(self, selector: #selector(UpgradeViewController.handlePurchaseNotification(_:)),
                                                         name: NSNotification.Name(rawValue: IAPHelper.IAPHelperPurchaseNotification),
                                                         object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(UpgradeViewController.handleRestoreNotification(_:)),
                                                         name: NSNotification.Name(rawValue: IAPHelper.IAPHelperRestoreNotification),
                                                         object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(UpgradeViewController.handleFailedTransaction(_:)),
                                                         name: NSNotification.Name(rawValue: IAPHelper.IAPHelperFailedTransaction),
                                                         object: nil)
        
        if appDelegate.appIsUpgraded {
            restoreButton.isEnabled = false
            restoreButton.layer.borderColor = UIColor.lightGray.cgColor
        } else {
            restoreButton.isEnabled = true
        }
    }

    override func viewDidAppear(_ animated: Bool)
    {
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func reload()
    {
        if appDelegate.appIsUpgraded {
            // already purchased
            purchasedCheck.isHidden = false
            buyButton.isHidden = true
        } else if IAPHelper.canMakePayments() {
            // can buy
            purchasedCheck.isHidden = true
            buyButton.isHidden = false
            buyButton.isEnabled = true
            buyButton.setTitle(appDelegate.upgradePriceString, for: UIControlState())
        } else {
            // purchases not allowed
            purchasedCheck.isHidden = true
            buyButton.isHidden = false
            buyButton.isEnabled = false
            buyButton.setTitle("N/A", for: UIControlState())
        }
    }
    
    func handlePurchaseNotification(_ notification: Notification)
    {
        appDelegate.appIsUpgraded = true
        
        reload()
    }
    
    func handleRestoreNotification(_ notification: Notification)
    {
        appDelegate.appIsUpgraded = true
        
        let alertVC = UIAlertController(
            title: "Thank You",
            message: "Your purchase was restored.",
            preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil )
        alertVC.addAction(okAction)
        
        present(alertVC, animated: true, completion: nil)
        
        restoreButton.isEnabled = false
        restoreButton.layer.borderColor = UIColor.lightGray.cgColor
        
        reload()
    }
    
    func handleFailedTransaction(_ notification: Notification)
    {
        if let message = notification.object as? String {
            let alertVC = UIAlertController(
                title: "Transaction Error",
                message: message,
                preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil )
            alertVC.addAction(okAction)
            
            present(alertVC, animated: true, completion: nil)
        }
    }
    
    @IBAction func buyButtonTapped(_ sender: UIButton)
    {
        guard let product = appDelegate.upgradeProduct else {
            print("ERROR: buyButtonTapped --- product is nil...")
            return
        }
        
        //startHUD(NSLocalizedString("Purchasing", comment: "Purchasing"), subtitle: "")
        
        RealListProducts.store.buyProduct(product)
    }
    
    @IBAction func restorePurchases(_ sender: UIButton)
    {
        //startHUD(NSLocalizedString("Restoring_purchase", comment: ""), subtitle: "")
        
        RealListProducts.store.restorePurchases()
    }
    
    @IBAction func close(_ sender: AnyObject)
    {
        if let aboutVC = aboutViewController {
            aboutVC.updateUpgradeStatus()
        }
        
        presentingViewController!.dismiss(animated: true, completion: nil)
    }
    
    ////////////////////////////////////////////////////////////////
    //
    //  MARK: - HUD Methods
    //
    ////////////////////////////////////////////////////////////////
    
    /*
    // these methods may be called from background threads
    func startHUD(title: String, subtitle: String) {
        dispatch_async(dispatch_get_main_queue()) {
            if self.hud == nil {
                self.hud = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
                self.hud?.minSize = CGSize(width: 150, height: 150)
            }
            
            self.hud!.mode = MBProgressHUDMode.Indeterminate
            self.hud!.label.text = title
            self.hud!.detailsLabel.text = subtitle
        }
    }
    
    // displays a done HUD for 1.5 seconds
    func startHUDwithDone() {
        dispatch_async(dispatch_get_main_queue()) {
            if self.hud != nil {
                self.hud!.hideAnimated(false)
                self.hud = nil
            }
            
            self.hud = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
            
            if let hud = self.hud {
                hud.mode = MBProgressHUDMode.CustomView
                hud.minSize = CGSize(width: 150, height: 150)
                let imageView = UIImageView(image: UIImage(named: "checkbox_blue"))
                hud.customView = imageView
                hud.label.text = NSLocalizedString("Done", comment: "Done")
                hud.hideAnimated(true, afterDelay: 1.5)
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
    */
}
