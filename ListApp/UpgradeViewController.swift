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
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    @IBOutlet weak var buyButton: UIButton!
    @IBOutlet weak var purchasedCheck: UIImageView!
    @IBOutlet weak var restoreButton: UIButton!
    weak var aboutViewController: AboutViewController?
    
    var hud: MBProgressHUD?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        manager.delegate = self
        
        buyButton.backgroundColor = UIColor.clearColor()
        buyButton.layer.cornerRadius = 5
        buyButton.layer.borderWidth = 1
        buyButton.layer.borderColor = view.tintColor.CGColor
        
        restoreButton.backgroundColor = UIColor.clearColor()
        restoreButton.layer.cornerRadius = 5
        restoreButton.layer.borderWidth = 1
        restoreButton.layer.borderColor = view.tintColor.CGColor
        
        self.reload()
        
        // set up notifications for purchase and restore events
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(UpgradeViewController.handlePurchaseNotification(_:)),
                                                         name: IAPHelper.IAPHelperPurchaseNotification,
                                                         object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(UpgradeViewController.handleRestoreNotification(_:)),
                                                         name: IAPHelper.IAPHelperRestoreNotification,
                                                         object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(UpgradeViewController.handleFailedTransaction(_:)),
                                                         name: IAPHelper.IAPHelperFailedTransaction,
                                                         object: nil)
        
        if appDelegate.appIsUpgraded {
            restoreButton.enabled = false
            restoreButton.layer.borderColor = UIColor.lightGrayColor().CGColor
        } else {
            restoreButton.enabled = true
        }
    }

    override func viewDidAppear(animated: Bool)
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
            purchasedCheck.hidden = false
            buyButton.hidden = true
        } else if IAPHelper.canMakePayments() {
            // can buy
            purchasedCheck.hidden = true
            buyButton.hidden = false
            buyButton.enabled = true
            buyButton.setTitle(appDelegate.upgradePriceString, forState: .Normal)
        } else {
            // purchases not allowed
            purchasedCheck.hidden = true
            buyButton.hidden = false
            buyButton.enabled = false
            buyButton.setTitle("N/A", forState: .Normal)
        }
    }
    
    func handlePurchaseNotification(notification: NSNotification)
    {
        appDelegate.appIsUpgraded = true
        
        //stopHUD()
        
        let alertVC = UIAlertController(
            title: "Thank You",
            message: "Your purchase is confirmed.",
            preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil )
        alertVC.addAction(okAction)
        
        presentViewController(alertVC, animated: true, completion: nil)
        
        reload()
    }
    
    func handleRestoreNotification(notification: NSNotification)
    {
        //guard let productID = notification.object as? String else { return }
        
        appDelegate.appIsUpgraded = true
        
        //stopHUD()
        
        let alertVC = UIAlertController(
            title: "Thank You",
            message: "Your purchase was restored.",
            preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil )
        alertVC.addAction(okAction)
        
        presentViewController(alertVC, animated: true, completion: nil)
        
        restoreButton.enabled = false
        restoreButton.layer.borderColor = UIColor.lightGrayColor().CGColor
        
        reload()
    }
    
    func handleFailedTransaction(notification: NSNotification)
    {
        if let message = notification.object as? String {
            let alertVC = UIAlertController(
                title: "Transaction Error",
                message: message,
                preferredStyle: .Alert)
            let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil )
            alertVC.addAction(okAction)
            
            presentViewController(alertVC, animated: true, completion: nil)
        }
    }
    
    @IBAction func buyButtonTapped(sender: UIButton)
    {
        guard let product = appDelegate.upgradeProduct else {
            print("ERROR: buyButtonTapped --- product is nil...")
            return
        }
        
        //startHUD(NSLocalizedString("Purchasing", comment: "Purchasing"), subtitle: "")
        
        RealListProducts.store.buyProduct(product)
    }
    
    @IBAction func restorePurchases(sender: UIButton)
    {
        //startHUD(NSLocalizedString("Restoring_purchase", comment: ""), subtitle: "")
        
        RealListProducts.store.restorePurchases()
    }
    
    @IBAction func close(sender: AnyObject)
    {
        if let aboutVC = aboutViewController {
            aboutVC.updateUpgradeStatus()
        }
        
        presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
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
