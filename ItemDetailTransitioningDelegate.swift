//
//  ItemDetailTransitioningDelegate.swift
//  EnList
//
//  Created by Steven Gentry on 2/6/16.
//  Copyright © 2016 Steven Gentry. All rights reserved.
//

import UIKit

class ItemDetailTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let presentationController = ItemDetailPresentationController(presentedViewController:presented, presenting:presenting)
        
        return presentationController
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let animationController = ItemDetailAnimatedTransitioning()
        animationController.isPresentation = true
        return animationController
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let animationController = ItemDetailAnimatedTransitioning()
        animationController.isPresentation = false
        return animationController
    }
    
}

