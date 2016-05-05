//
//  AppManager.swift
//  EnList
//
//  Created by Steven Gentry on 5/4/16.
//  Copyright © 2016 Steven Gentry. All rights reserved.
//

// This class handles network reachability notification

import UIKit
import Foundation

// AppManagerDelegate
@objc protocol AppManagerDelegate: NSObjectProtocol
{
    func reachabilityStatusChangeHandler(reachability:Reachability)
}

enum CONNECTION_NETWORK_TYPE : String
{
    case WIFI_NETWORK = "Wifi"
    case WWAN_NETWORK = "Cellular"
    case OTHER = "Other"
}

class AppManager: NSObject
{
    var delegate:AppManagerDelegate? = nil
    private var _useClosures: Bool = false
    private var reachability: Reachability?
    private var _isReachable: Bool = false
    private var _reachabiltyNetworkType: String?
    
    var isReachable: Bool {
        get { return _isReachable }
    }
    var reachabiltyNetworkType: String {
        get { return _reachabiltyNetworkType! }
    }
    
    // Create a shared instance of AppManager
    final  class var sharedInstance : AppManager {
        struct Static {
            static var instance : AppManager?
        }
        if !(Static.instance != nil) {
            Static.instance = AppManager()
            
        }
        return Static.instance!
    }
    
    // Reachability Methods
    func initReachabilityMonitor() {
        print("initialize reachability...")
        
        do {
            let reachability = try Reachability.reachabilityForInternetConnection()
            self.reachability = reachability
        } catch ReachabilityError.FailedToCreateWithAddress(let address) {
            print("Unable to create\nReachability with address:\n\(address)")
            return
        } catch {}
        if (_useClosures) {
            reachability?.whenReachable = { reachability in
                self.notifyReachability(reachability)
            }
            reachability?.whenUnreachable = { reachability in
                self.notifyReachability(reachability)
            }
        } else {
            self.notifyReachability(reachability!)
        }
        
        do {
            try reachability?.startNotifier()
        } catch {
            print("unable to start notifier")
            return
        }
    }
    
    private func notifyReachability(reachability: Reachability) {
        if reachability.isReachable() {
            self._isReachable = true
            
            // determine network type
            if reachability.isReachableViaWiFi() {
                self._reachabiltyNetworkType = CONNECTION_NETWORK_TYPE.WIFI_NETWORK.rawValue
            } else {
                self._reachabiltyNetworkType = CONNECTION_NETWORK_TYPE.WWAN_NETWORK.rawValue
            }
            
        } else {
            self._isReachable = false
            self._reachabiltyNetworkType = CONNECTION_NETWORK_TYPE.OTHER.rawValue
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AppManager.reachabilityChanged(_:)), name: ReachabilityChangedNotification, object: reachability)
    }
    
    func reachabilityChanged(note: NSNotification) {
        let reachability = note.object as! Reachability
        notifyReachability(reachability)
        
        print("*** reachability changed to \(isReachable) - networkType change to \(reachabiltyNetworkType)")
        
        dispatch_async(dispatch_get_main_queue()) {
            self.delegate?.reachabilityStatusChangeHandler(reachability)
        }
    }
    
    deinit {
        reachability?.stopNotifier()
        if (!_useClosures) {
            NSNotificationCenter.defaultCenter().removeObserver(self, name: ReachabilityChangedNotification, object: nil)
        }
    }
}