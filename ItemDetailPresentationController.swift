//
//  ItemDetailPresentationController.swift
//  EnList
//
//  Created by Steven Gentry on 2/5/16.
//  Copyright © 2016 Steven Gentry. All rights reserved.
//

import UIKit

class ItemDetailPresentationController: UIPresentationController, UIAdaptivePresentationControllerDelegate {
    
    var chromeView: UIView = UIView()
    
    override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController:presentedViewController, presenting:presentingViewController)
        chromeView.backgroundColor = UIColor.white
        chromeView.alpha = 1.0
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(ItemDetailPresentationController.chromeViewTapped(_:)))
        chromeView.addGestureRecognizer(tap)
    }
    
    @objc func chromeViewTapped(_ gesture: UIGestureRecognizer) {
        if (gesture.state == UIGestureRecognizer.State.ended) {
            presentingViewController.dismiss(animated: true, completion: nil)
        }
    }
    
    override var frameOfPresentedViewInContainerView : CGRect {
        var presentedViewFrame = CGRect.zero
        let containerBounds = containerView!.bounds
        presentedViewFrame.size = size(forChildContentContainer: presentedViewController, withParentContainerSize: containerBounds.size)
        presentedViewFrame.origin.x = containerBounds.size.width - presentedViewFrame.size.width
        
        return presentedViewFrame
    }
    
    override func size(forChildContentContainer container: UIContentContainer, withParentContainerSize parentSize: CGSize) -> CGSize {
        // adaptive sizing width, min 100, max 200
        //let parentWidth = parentSize.width
        //let childWidth = min(max(parentWidth/3.0, 120), 200)
        
        //return CGSizeMake(CGFloat((floorf(Float(childWidth)))), parentSize.height)
        return CGSize(width: parentSize.width, height: parentSize.height)
    }
    
    override func presentationTransitionWillBegin() {
        chromeView.frame = self.containerView!.bounds
        chromeView.alpha = 0.0
        containerView!.insertSubview(chromeView, at:0)
        let coordinator = presentedViewController.transitionCoordinator
        if (coordinator != nil) {
            coordinator!.animate(alongsideTransition: {
                (context:UIViewControllerTransitionCoordinatorContext!) -> Void in
                self.chromeView.alpha = 1.0
                }, completion:nil)
        } else {
            chromeView.alpha = 1.0
        }
    }
    
    override func dismissalTransitionWillBegin() {
        let coordinator = presentedViewController.transitionCoordinator
        if (coordinator != nil) {
            coordinator!.animate(alongsideTransition: {
                (context:UIViewControllerTransitionCoordinatorContext!) -> Void in
                self.chromeView.alpha = 0.0
                }, completion:nil)
        } else {
            chromeView.alpha = 0.0
        }
    }
    
    override func containerViewWillLayoutSubviews() {
        chromeView.frame = containerView!.bounds
        presentedView!.frame = frameOfPresentedViewInContainerView
    }
    
    override var shouldPresentInFullscreen : Bool {
        return true
    }
    
    override var adaptivePresentationStyle : UIModalPresentationStyle {
        return UIModalPresentationStyle.overFullScreen
    }
    
    //func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
    //    return UIModalPresentationStyle.OverFullScreen
    //}
    
}

