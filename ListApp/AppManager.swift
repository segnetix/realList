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
    func reachabilityStatusChangeHandler(_ reachability:Reachability)
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
    fileprivate var _useClosures: Bool = false
    fileprivate var reachability: Reachability?
    fileprivate var _isReachable: Bool = false
    fileprivate var _reachabiltyNetworkType: String?
    
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
        } catch ReachabilityError.failedToCreateWithAddress(let address) {
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
    
    fileprivate func notifyReachability(_ reachability: Reachability) {
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(AppManager.reachabilityChanged(_:)), name: NSNotification.Name(rawValue: ReachabilityChangedNotification), object: reachability)
    }
    
    func reachabilityChanged(_ note: Notification) {
        let reachability = note.object as! Reachability
        notifyReachability(reachability)
        
        // print("*** reachability changed to \(isReachable) - networkType change to \(reachabiltyNetworkType)")
        
        DispatchQueue.main.async {
            self.delegate?.reachabilityStatusChangeHandler(reachability)
        }
    }
    
    deinit {
        reachability?.stopNotifier()
        if (!_useClosures) {
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: ReachabilityChangedNotification), object: nil)
        }
    }
}
