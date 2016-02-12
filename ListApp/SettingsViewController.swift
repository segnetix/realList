//
//  SettingsViewController.swift
//  ListApp
//
//  Created by Steven Gentry on 2/5/16.
//  Copyright © 2016 Steven Gentry. All rights reserved.
//

import UIKit

let red0 = UIColor(colorLiteralRed: 1.0, green: 0.5, blue: 0.25, alpha: 0.75)
let green0 = UIColor(colorLiteralRed: 0.75, green: 1.0, blue: 0.5, alpha: 0.75)
var blue0 = UIColor(colorLiteralRed: 0.5, green: 0.75, blue: 1.0, alpha: 0.75)

let red1 = UIColor(colorLiteralRed: 0.75, green: 0.5, blue: 0.5, alpha: 0.75)
let green1 = UIColor(colorLiteralRed: 0.5, green: 0.75, blue: 0.5, alpha: 0.75)
let blue1 = UIColor(colorLiteralRed: 0.5, green: 0.5, blue: 0.75, alpha: 0.75)

let red2 = UIColor(colorLiteralRed: 0.75, green: 0.5, blue: 0.75, alpha: 0.75)
let green2 = UIColor(colorLiteralRed: 0.75, green: 0.75, blue: 0.5, alpha: 0.75)
let blue2 = UIColor(colorLiteralRed: 0.5, green: 0.75, blue: 0.75, alpha: 0.75)

class SettingsViewController: UIViewController
{
    var containerView: UIView = UIView()
    var newCategoryButton: UIButton = UIButton()
    var showHideCompletedButton: UIButton = UIButton()
    var showHideInactiveButton: UIButton = UIButton()
    var closeButton: UIButton = UIButton()
    var titleLabel: UILabel = UILabel()
    weak var itemVC: ItemViewController?
    
    var red0Button: UIButton = UIButton()
    var green0Button: UIButton = UIButton()
    var blue0Button: UIButton = UIButton()
    var red1Button: UIButton = UIButton()
    var green1Button: UIButton = UIButton()
    var blue1Button: UIButton = UIButton()
    var red2Button: UIButton = UIButton()
    var green2Button: UIButton = UIButton()
    var blue2Button: UIButton = UIButton()
    
    // autolayout constraints
    var verticalConstraints: [NSLayoutConstraint]?
    var containerViewHorizConstraints: [NSLayoutConstraint]?
    var containerViewVertConstraints: [NSLayoutConstraint]?
    var titleLabelHorizConstraints: [NSLayoutConstraint]?
    var newCatButtonHorizConstraints: [NSLayoutConstraint]?
    var showHideCompletedButtonHorizConstraints: [NSLayoutConstraint]?
    var showHideInactiveButtonHorizConstraints: [NSLayoutConstraint]?
    var row0ColorButtonHorizConstraints: [NSLayoutConstraint]?
    var row1ColorButtonHorizConstraints: [NSLayoutConstraint]?
    var row2ColorButtonHorizConstraints: [NSLayoutConstraint]?
    var closeButtonHorizConstraints: [NSLayoutConstraint]?
    
    var showCompletedItems: Bool = true {
        didSet(newShow) {
            if showCompletedItems {
                showHideCompletedButton.setTitle(NSLocalizedString("Hide_Completed", comment: "Button title to hide completed items."), forState: UIControlState.Normal)
            } else {
                showHideCompletedButton.setTitle(NSLocalizedString("Show_Completed", comment: "Button title to show completed items."), forState: UIControlState.Normal)
            }
            
            if itemVC != nil && itemVC!.list != nil {
                itemVC!.list!.showCompletedItems = self.showCompletedItems
            }
        }
    }

    var showInactiveItems: Bool = true {
        didSet(newShow) {
            if showInactiveItems {
                showHideInactiveButton.setTitle(NSLocalizedString("Hide_Inactive", comment: "Button title to hide inactive items."), forState: UIControlState.Normal)
            } else {
                showHideInactiveButton.setTitle(NSLocalizedString("Show_Inactive", comment: "Button title to show inactive items."), forState: UIControlState.Normal)
            }
            
            if itemVC != nil && itemVC!.list != nil {
                itemVC!.list!.showInactiveItems = self.showInactiveItems
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
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        adjustConstraints(size)
    }
    
    func adjustConstraints(size: CGSize)
    {
        // remove current constraints
        if titleLabelHorizConstraints != nil { containerView.removeConstraints(titleLabelHorizConstraints!) }
        if newCatButtonHorizConstraints != nil { containerView.removeConstraints(newCatButtonHorizConstraints!) }
        if showHideCompletedButtonHorizConstraints != nil { containerView.removeConstraints(showHideCompletedButtonHorizConstraints!) }
        if showHideInactiveButtonHorizConstraints != nil { containerView.removeConstraints(showHideInactiveButtonHorizConstraints!) }
        if row0ColorButtonHorizConstraints != nil { containerView.removeConstraints(row0ColorButtonHorizConstraints!) }
        if row1ColorButtonHorizConstraints != nil { containerView.removeConstraints(row1ColorButtonHorizConstraints!) }
        if row2ColorButtonHorizConstraints != nil { containerView.removeConstraints(row2ColorButtonHorizConstraints!) }
        if closeButtonHorizConstraints != nil { containerView.removeConstraints(closeButtonHorizConstraints!) }
        if verticalConstraints != nil { containerView.removeConstraints(verticalConstraints!) }
        
        // constraint dictionary
        let views: [String : AnyObject] = [
            "titleLabel": titleLabel,
            "newCatButton": newCategoryButton,
            "showHideCompletedButton": showHideCompletedButton,
            "showHideInactiveButton": showHideInactiveButton,
            "red0Button": red0Button,
            "green0Button": green0Button,
            "blue0Button": blue0Button,
            "red1Button": red1Button,
            "green1Button": green1Button,
            "blue1Button": blue1Button,
            "red2Button": red2Button,
            "green2Button": green2Button,
            "blue2Button": blue2Button,
            "closeButton": closeButton]
        
        titleLabelHorizConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[titleLabel]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views)
        newCatButtonHorizConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[newCatButton]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views)
        showHideCompletedButtonHorizConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[showHideCompletedButton]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views)
        showHideInactiveButtonHorizConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[showHideInactiveButton]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views)
        closeButtonHorizConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[closeButton]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views)
        
        // color button constraints
        row0ColorButtonHorizConstraints = NSLayoutConstraint.constraintsWithVisualFormat(
                "H:|-[red0Button(>=44)]-4-[green0Button(==red0Button)]-4-[blue0Button(==red0Button)]-|",
                options: [.AlignAllCenterY], metrics: nil, views: views)
        
        row1ColorButtonHorizConstraints = NSLayoutConstraint.constraintsWithVisualFormat(
                "H:|-[red1Button(>=44)]-4-[green1Button(==red1Button)]-4-[blue1Button(==red1Button)]-|",
                options: [.AlignAllCenterY], metrics: nil, views: views)
        
        row2ColorButtonHorizConstraints = NSLayoutConstraint.constraintsWithVisualFormat(
                "H:|-[red2Button(>=44)]-4-[green2Button(==red2Button)]-4-[blue2Button(==red2Button)]-|",
                options: [.AlignAllCenterY], metrics: nil, views: views)
        
        // set overall vertical constraints based on available height
        if size.height < 568 {
            verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat(
                "V:|-8-[titleLabel]-8-[newCatButton][showHideCompletedButton][showHideInactiveButton]-8-[red0Button]-4-[red1Button]-4-[red2Button]-(>=12)-[closeButton]-8-|",
                options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views)
        } else {
            verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat(
                "V:|-16-[titleLabel]-32-[newCatButton]-16-[showHideCompletedButton]-16-[showHideInactiveButton]-32-[red0Button]-4-[red1Button]-4-[red2Button]-(>=36)-[closeButton]-(>=24)-|",
                options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views)
        }
        
        // add constraints to views
        containerView.addConstraints(titleLabelHorizConstraints!)
        containerView.addConstraints(newCatButtonHorizConstraints!)
        containerView.addConstraints(showHideCompletedButtonHorizConstraints!)
        containerView.addConstraints(showHideInactiveButtonHorizConstraints!)
        containerView.addConstraints(row0ColorButtonHorizConstraints!)
        containerView.addConstraints(row1ColorButtonHorizConstraints!)
        containerView.addConstraints(row2ColorButtonHorizConstraints!)
        containerView.addConstraints(closeButtonHorizConstraints!)
        containerView.addConstraints(verticalConstraints!)
        
        // layout
        self.view.layoutIfNeeded()
    }

    func createUI()
    {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = UIColor(white: 0.0, alpha: 1.0)
        view.addSubview(containerView)
        
        // set font size constants
        let titleFontSize: CGFloat = view.bounds.size.width > 400 ? 24 : 20.0
        let buttonFontSize: CGFloat = view.bounds.size.width > 400 ? 20.0 : 16.0
        let closeButtonFontSize: CGFloat = 20.0
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = NSLocalizedString("Settings", comment: "Title for the Settings view.")
        titleLabel.font = UIFont.boldSystemFontOfSize(titleFontSize)
        titleLabel.textColor = UIColor.whiteColor()
        titleLabel.textAlignment = NSTextAlignment.Center
        containerView.addSubview(titleLabel)
        
        newCategoryButton.translatesAutoresizingMaskIntoConstraints = false
        newCategoryButton.setTitle(NSLocalizedString("New_Category", comment: "Title for the New Category button."), forState: UIControlState.Normal)
        newCategoryButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        newCategoryButton.titleLabel!.font = UIFont.systemFontOfSize(buttonFontSize)
        newCategoryButton.addTarget(self, action: "newCategory:", forControlEvents: UIControlEvents.TouchUpInside)
        containerView.addSubview(newCategoryButton)
        
        showHideCompletedButton.translatesAutoresizingMaskIntoConstraints = false
        //showHideCompletedButton.setTitle("Hide Completed Items", forState: UIControlState.Normal)
        showHideCompletedButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        showHideCompletedButton.titleLabel!.font = UIFont.systemFontOfSize(buttonFontSize)
        showHideCompletedButton.addTarget(self, action: "showHideCompletedItems:", forControlEvents: UIControlEvents.TouchUpInside)
        showCompletedItems = itemVC != nil && itemVC!.list != nil ? itemVC!.list!.showCompletedItems : true
        containerView.addSubview(showHideCompletedButton)
        
        showHideInactiveButton.translatesAutoresizingMaskIntoConstraints = false
        //showHideInactiveButton.setTitle("Hide Inactive Items", forState: UIControlState.Normal)
        showHideInactiveButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        showHideInactiveButton.tintColor = UIColor.blackColor()
        showHideInactiveButton.titleLabel!.font = UIFont.systemFontOfSize(buttonFontSize)
        showHideInactiveButton.addTarget(self, action: "showHideInactiveItems:", forControlEvents: UIControlEvents.TouchUpInside)
        showInactiveItems = itemVC != nil && itemVC!.list != nil ? itemVC!.list!.showInactiveItems : true
        containerView.addSubview(showHideInactiveButton)
        
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setTitle(NSLocalizedString("Close", comment: "Close - title for a button to dismiss a view."), forState: UIControlState.Normal)
        closeButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        closeButton.titleLabel!.font = UIFont.systemFontOfSize(closeButtonFontSize)
        closeButton.addTarget(self, action: "close:", forControlEvents: UIControlEvents.TouchUpInside)
        containerView.addSubview(closeButton)
        
        red0Button.translatesAutoresizingMaskIntoConstraints = false
        red0Button.backgroundColor = red0
        red0Button.addTarget(self, action: "colorButton:", forControlEvents: UIControlEvents.TouchUpInside)
        red0Button.tag = 0
        containerView.addSubview(red0Button)
        
        green0Button.translatesAutoresizingMaskIntoConstraints = false
        green0Button.backgroundColor = green0
        green0Button.addTarget(self, action: "colorButton:", forControlEvents: UIControlEvents.TouchUpInside)
        green0Button.tag = 1
        containerView.addSubview(green0Button)
        
        blue0Button.translatesAutoresizingMaskIntoConstraints = false
        blue0Button.backgroundColor = blue0
        blue0Button.addTarget(self, action: "colorButton:", forControlEvents: UIControlEvents.TouchUpInside)
        blue0Button.tag = 2
        containerView.addSubview(blue0Button)
        
        red1Button.translatesAutoresizingMaskIntoConstraints = false
        red1Button.backgroundColor = red1
        red1Button.addTarget(self, action: "colorButton:", forControlEvents: UIControlEvents.TouchUpInside)
        red1Button.tag = 3
        containerView.addSubview(red1Button)
        
        green1Button.translatesAutoresizingMaskIntoConstraints = false
        green1Button.backgroundColor = green1
        green1Button.addTarget(self, action: "colorButton:", forControlEvents: UIControlEvents.TouchUpInside)
        green1Button.tag = 4
        containerView.addSubview(green1Button)
        
        blue1Button.translatesAutoresizingMaskIntoConstraints = false
        blue1Button.backgroundColor = blue1
        blue1Button.addTarget(self, action: "colorButton:", forControlEvents: UIControlEvents.TouchUpInside)
        blue1Button.tag = 5
        containerView.addSubview(blue1Button)
        
        red2Button.translatesAutoresizingMaskIntoConstraints = false
        red2Button.backgroundColor = red2
        red2Button.addTarget(self, action: "colorButton:", forControlEvents: UIControlEvents.TouchUpInside)
        red2Button.tag = 6
        containerView.addSubview(red2Button)
        
        green2Button.translatesAutoresizingMaskIntoConstraints = false
        green2Button.backgroundColor = green2
        green2Button.addTarget(self, action: "colorButton:", forControlEvents: UIControlEvents.TouchUpInside)
        green2Button.tag = 7
        containerView.addSubview(green2Button)
        
        blue2Button.translatesAutoresizingMaskIntoConstraints = false
        blue2Button.backgroundColor = blue2
        blue2Button.addTarget(self, action: "colorButton:", forControlEvents: UIControlEvents.TouchUpInside)
        blue2Button.tag = 8
        containerView.addSubview(blue2Button)
        
        // set up container view constraints
        let views: [String : AnyObject] = ["containerView": containerView]
        containerViewHorizConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[containerView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views)
        containerViewVertConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[containerView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views)
        
        view.addConstraints(containerViewHorizConstraints!)
        view.addConstraints(containerViewVertConstraints!)
        
        adjustConstraints(view.frame.size)
    }
    
    func newCategory(sender: UIButton) {
        itemVC?.addNewCategory()
        presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func showHideCompletedItems(sender: UIButton) {
        showCompletedItems = !showCompletedItems
        itemVC?.showHideCompletedRows()
    }
    
    func showHideInactiveItems(sender: UIButton) {
        showInactiveItems = !showInactiveItems
        itemVC?.showHideInactiveRows()
    }
    
    func colorButton(sender: UIButton) {
        var color: UIColor
        
        switch sender.tag {
            case 0: color = red0
            case 1: color = green0
            case 2: color = blue0
            case 3: color = red1
            case 4: color = green1
            case 5: color = blue1
            case 6: color = red2
            case 7: color = green2
            case 8: color = blue2
            default: color = UIColor.grayColor()
        }
        
        itemVC?.list.listColor = color
        itemVC?.tableView.reloadData()
    }
    
    func close(sender: UIButton) {
        itemVC?.appDelegate.saveAll()
        presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
    }
    
}

