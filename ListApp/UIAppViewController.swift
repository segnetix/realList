//
//  UIAppViewController.swift
//  EnList
//
//  Created by Steven Gentry on 5/4/16.
//  Copyright © 2016 Steven Gentry. All rights reserved.
//

//  UIAppViewController.swift

import UIKit

class UIAppViewController: UIViewController, AppManagerDelegate
{
    var manager:AppManager = AppManager.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        manager.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func reachabilityStatusChangeHandler(_ reachability: Reachability) {
        if reachability.isReachable() {
            print("isReachable")
        } else {
            print("notReachable")
        }
    }
}
