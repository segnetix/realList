//
//  SettingsViewController.swift
//  ListApp
//
//  Created by Steven Gentry on 2/5/16.
//  Copyright © 2016 Steven Gentry. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController
{
    var containerView: UIView = UIView()
    var newCategoryButton: UIButton = UIButton()
    var showHideCompletedButton: UIButton = UIButton()
    var showHideInactiveButton: UIButton = UIButton()
    var closeButton: UIButton = UIButton()
    var titleLabel: UILabel = UILabel()
    weak var itemVC: ItemViewController?
    
    var showCompletedItems: Bool = true {
        didSet(newShow) {
            if showCompletedItems {
                showHideCompletedButton.setTitle("Hide Completed", forState: UIControlState.Normal)
            } else {
                showHideCompletedButton.setTitle("Show Completed", forState: UIControlState.Normal)
            }
            
            if itemVC != nil {
                itemVC!.showCompletedItems = self.showCompletedItems
            }
        }
    }

    var showInactiveItems: Bool = true {
        didSet(newShow) {
            if showInactiveItems {
                showHideInactiveButton.setTitle("Hide Inactive", forState: UIControlState.Normal)
            } else {
                showHideInactiveButton.setTitle("Show Inactive", forState: UIControlState.Normal)
            }
            
            if itemVC != nil {
                itemVC!.showInactiveItems = self.showInactiveItems
            }
        }
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
        
        modalPresentationStyle = UIModalPresentationStyle.Custom
        createUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createUI()
    {
        titleLabel.text = "Settings";
        //infoLabel.text = "Here we will give the option to Add a Category, and control various settings such as Show/Hide Completed Items, change the list color, share the list, etc.  and dismiss the settings view.";
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = UIColor(white: 0.0, alpha: 0.7)
        view.addSubview(containerView)
        
        // Set some constants to use when creating constraints
        let titleFontSize: CGFloat = view.bounds.size.width > 667.0 ? 40.0 : 22.0
        let bodyFontSize: CGFloat = view.bounds.size.width > 667.0 ? 20.0 : 12.0
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.backgroundColor = UIColor.clearColor()
        titleLabel.font = UIFont.boldSystemFontOfSize(titleFontSize)
        titleLabel.textColor = UIColor.whiteColor()
        titleLabel.textAlignment = NSTextAlignment.Center
        containerView.addSubview(titleLabel)
        
        newCategoryButton.translatesAutoresizingMaskIntoConstraints = false
        newCategoryButton.setTitle("New Category", forState: UIControlState.Normal)
        newCategoryButton.tintColor = UIColor.whiteColor()
        newCategoryButton.titleLabel!.font = UIFont.systemFontOfSize(bodyFontSize)
        newCategoryButton.addTarget(self, action: "newCategory:", forControlEvents: UIControlEvents.TouchUpInside)
        containerView.addSubview(newCategoryButton)
        
        showHideCompletedButton.translatesAutoresizingMaskIntoConstraints = false
        showHideCompletedButton.setTitle("Hide Completed Items", forState: UIControlState.Normal)
        showHideCompletedButton.tintColor = UIColor.whiteColor()
        showHideCompletedButton.titleLabel!.font = UIFont.systemFontOfSize(bodyFontSize)
        showHideCompletedButton.addTarget(self, action: "showHideCompletedItems:", forControlEvents: UIControlEvents.TouchUpInside)
        containerView.addSubview(showHideCompletedButton)
        
        showHideInactiveButton.translatesAutoresizingMaskIntoConstraints = false
        showHideInactiveButton.setTitle("Hide Inactive Items", forState: UIControlState.Normal)
        showHideInactiveButton.tintColor = UIColor.whiteColor()
        showHideInactiveButton.titleLabel!.font = UIFont.systemFontOfSize(bodyFontSize)
        showHideInactiveButton.addTarget(self, action: "showHideInactiveItems:", forControlEvents: UIControlEvents.TouchUpInside)
        containerView.addSubview(showHideInactiveButton)
        
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setTitle("Close", forState: UIControlState.Normal)
        closeButton.tintColor = UIColor.whiteColor()
        closeButton.titleLabel!.font = UIFont.systemFontOfSize(bodyFontSize)
        closeButton.addTarget(self, action: "close:", forControlEvents: UIControlEvents.TouchUpInside)
        containerView.addSubview(closeButton)
        
        
        let views: [String : AnyObject] = [
            "containerView": containerView,
            "titleLabel": titleLabel,
            "newCatButton": newCategoryButton,
            "showHideCompletedButton": showHideCompletedButton,
            "showHideInactiveButton": showHideInactiveButton,
            "closeButton": closeButton]
        
        view.addConstraints(
            NSLayoutConstraint.constraintsWithVisualFormat(
                "H:|[containerView]|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: nil,
                views: views))
        
        view.addConstraints(
            NSLayoutConstraint.constraintsWithVisualFormat(
                "V:|[containerView]|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: nil,
                views: views))
        
        containerView.addConstraints(
            NSLayoutConstraint.constraintsWithVisualFormat(
                "H:|[titleLabel]|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: nil,
                views: views))
        
        containerView.addConstraints(
            NSLayoutConstraint.constraintsWithVisualFormat(
                "H:|[newCatButton]|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: nil,
                views: views))
        
        containerView.addConstraints(
            NSLayoutConstraint.constraintsWithVisualFormat(
                "H:|[showHideCompletedButton]|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: nil,
                views: views))
        
        containerView.addConstraints(
            NSLayoutConstraint.constraintsWithVisualFormat(
                "H:|[showHideInactiveButton]|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: nil,
                views: views))
        
        containerView.addConstraints(
            NSLayoutConstraint.constraintsWithVisualFormat(
                "H:|[closeButton]|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: nil,
                views: views))
        
        containerView.addConstraints(
            NSLayoutConstraint.constraintsWithVisualFormat(
                "V:|-[titleLabel]-40-[newCatButton]-25-[showHideCompletedButton]-25-[showHideInactiveButton]-(>=40)-[closeButton]-25-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: nil,
                views: views))
        
    }
    
    func newCategory(sender: UIButton) {
        print("newCategory...")
        itemVC?.addNewCategory()
        presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func showHideCompletedItems(sender: UIButton) {
        print("showHideCompletedItems...")
        showCompletedItems = !showCompletedItems
    }
    
    func showHideInactiveItems(sender: UIButton) {
        print("showHideInactiveItems...")
        showInactiveItems = !showInactiveItems
    }
    
    func close(sender: UIButton) {
        presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
    }
    
}

