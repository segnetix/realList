//
//  SettingsViewController.swift
//  EnList
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
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    let containerView: UIView = UIView()
    let newCategoryButton: UIButton = UIButton()
    let collapseAllCategoriesButton: UIButton = UIButton()
    let expandAllCategoriesButton: UIButton = UIButton()
    let showHideCompletedButton: UIButton = UIButton()
    let showHideInactiveButton: UIButton = UIButton()
    let setAllItemsInactiveButton: UIButton = UIButton()
    let setAllItemsIncompleteButton: UIButton = UIButton()
    let closeButton: UIButton = UIButton()
    let printButton: UIButton = UIButton()
    let emailButton: UIButton = UIButton()
    let noteButton: UIButton = UIButton()
    let vertLineImage: UIImageView = UIImageView()
    var itemVC: ItemViewController?
    
    let red0Button: UIButton = UIButton()
    let green0Button: UIButton = UIButton()
    let blue0Button: UIButton = UIButton()
    let red1Button: UIButton = UIButton()
    let green1Button: UIButton = UIButton()
    let blue1Button: UIButton = UIButton()
    let red2Button: UIButton = UIButton()
    let green2Button: UIButton = UIButton()
    let blue2Button: UIButton = UIButton()
    
    // autolayout constraints
    var verticalConstraints: [NSLayoutConstraint]?
    var containerViewHorizConstraints: [NSLayoutConstraint]?
    var containerViewVertConstraints: [NSLayoutConstraint]?
    var closeButtonHorizConstraints: [NSLayoutConstraint]?
    var categoryHorizConstraints: [NSLayoutConstraint]?
    var showHideHorizConstraints: [NSLayoutConstraint]?
    var setAllItemsHorizConstraints: [NSLayoutConstraint]?
    var row0ColorButtonHorizConstraints: [NSLayoutConstraint]?
    var row1ColorButtonHorizConstraints: [NSLayoutConstraint]?
    var row2ColorButtonHorizConstraints: [NSLayoutConstraint]?
    var printCloseButtonHorizConstraints: [NSLayoutConstraint]?
    
    var showCompletedItems: Bool = true {
        didSet {
            if showCompletedItems {
                showHideCompletedButton.setImage(UIImage(named: "Show Completed"), forState: .Normal)
            } else {
                showHideCompletedButton.setImage(UIImage(named: "Hide Completed"), forState: .Normal)
            }
            
            if itemVC != nil && itemVC!.list != nil {
                itemVC!.list!.showCompletedItems = self.showCompletedItems
            }
        }
    }

    var showInactiveItems: Bool = true {
        didSet {
            if showInactiveItems {
                showHideInactiveButton.setImage(UIImage(named: "Show Inactive"), forState: .Normal)
            } else {
                showHideInactiveButton.setImage(UIImage(named: "Hide Inactive"), forState: .Normal)
            }
            
            if itemVC != nil && itemVC!.list != nil {
                itemVC!.list!.showInactiveItems = self.showInactiveItems
            }
        }
    }
    
    var showNotes: Bool = true {
        didSet {
            if showNotes {
                noteButton.setImage(UIImage(named: "Notes On"), forState: .Normal)
            } else {
                noteButton.setImage(UIImage(named: "Notes Off"), forState: .Normal)
            }
            
            appDelegate.printNotes = self.showNotes
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
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        adjustConstraints(size)
    }
    
    func adjustConstraints(size: CGSize)
    {
        // remove current constraints
        if closeButtonHorizConstraints      != nil { containerView.removeConstraints(closeButtonHorizConstraints!)      }
        if categoryHorizConstraints         != nil { containerView.removeConstraints(categoryHorizConstraints!)         }
        if showHideHorizConstraints         != nil { containerView.removeConstraints(showHideHorizConstraints!)         }
        if setAllItemsHorizConstraints      != nil { containerView.removeConstraints(setAllItemsHorizConstraints!)      }
        if row0ColorButtonHorizConstraints  != nil { containerView.removeConstraints(row0ColorButtonHorizConstraints!)  }
        if row1ColorButtonHorizConstraints  != nil { containerView.removeConstraints(row1ColorButtonHorizConstraints!)  }
        if row2ColorButtonHorizConstraints  != nil { containerView.removeConstraints(row2ColorButtonHorizConstraints!)  }
        if printCloseButtonHorizConstraints != nil { containerView.removeConstraints(printCloseButtonHorizConstraints!) }
        if verticalConstraints              != nil { containerView.removeConstraints(verticalConstraints!)              }
        
        // constraint dictionary
        let views: [String : AnyObject] = [
            "newCatButton": newCategoryButton,
            "showHideCompletedButton": showHideCompletedButton,
            "showHideInactiveButton": showHideInactiveButton,
            "collapseAllCategoriesButton": collapseAllCategoriesButton,
            "expandAllCategoriesButton": expandAllCategoriesButton,
            "setAllItemsIncompleteButton": setAllItemsIncompleteButton,
            "setAllItemsInactiveButton": setAllItemsInactiveButton,
            "red0Button": red0Button,
            "green0Button": green0Button,
            "blue0Button": blue0Button,
            "red1Button": red1Button,
            "green1Button": green1Button,
            "blue1Button": blue1Button,
            "red2Button": red2Button,
            "green2Button": green2Button,
            "blue2Button": blue2Button,
            "closeButton": closeButton,
            "printButton": printButton,
            "emailButton": emailButton,
            "noteButton": noteButton,
            "vertLine": vertLineImage]
        
        closeButtonHorizConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:[closeButton]-10-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views)
        showHideHorizConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|-[showHideCompletedButton]-[showHideInactiveButton(==showHideCompletedButton)]-|", options: [.AlignAllCenterY], metrics: nil, views: views)
        categoryHorizConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|-[collapseAllCategoriesButton(==newCatButton)]-[expandAllCategoriesButton(==newCatButton)]-[newCatButton]-|", options: [.AlignAllCenterY], metrics: nil, views: views)
        printCloseButtonHorizConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|-(>=4,<=8)-[printButton]-[emailButton(==printButton)]-[vertLine]-[noteButton]-(>=4,<=8)-|", options: [.AlignAllCenterY], metrics: nil, views: views)
        setAllItemsHorizConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|-[setAllItemsIncompleteButton]-[setAllItemsInactiveButton(==setAllItemsIncompleteButton)]-|", options: [.AlignAllCenterY], metrics: nil, views: views)
        
        // color button constraints
        row0ColorButtonHorizConstraints = NSLayoutConstraint.constraintsWithVisualFormat(
                "H:|-(<=6)-[red0Button(>=48)]-(<=6)-[green0Button(==red0Button@750)]-(<=6)-[blue0Button(==red0Button@750)]-(<=6)-|",
                options: [.AlignAllCenterY], metrics: nil, views: views)
        
        row1ColorButtonHorizConstraints = NSLayoutConstraint.constraintsWithVisualFormat(
                "H:|-(<=6)-[red1Button(>=48)]-(<=6)-[green1Button(==red1Button@750)]-(<=6)-[blue1Button(==red1Button@750)]-(<=6)-|",
                options: [.AlignAllCenterY], metrics: nil, views: views)
        
        row2ColorButtonHorizConstraints = NSLayoutConstraint.constraintsWithVisualFormat(
                "H:|-(<=6)-[red2Button(>=48)]-(<=6)-[green2Button(==red2Button@750)]-(<=6)-[blue2Button(==red2Button@750)]-(<=6)-|",
                options: [.AlignAllCenterY], metrics: nil, views: views)
        
        // set overall vertical constraints based on available height
        if size.height <= 480 {
            // small
            verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat(
                "V:|-20-[closeButton]-16-[newCatButton]-16-[showHideCompletedButton]-16-[setAllItemsIncompleteButton]-16-[red0Button]-4-[red1Button]-4-[red2Button]-(>=16)-[printButton]-16-|",
                options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views)
            
            // scale buttons
            closeButton.transform = CGAffineTransformMakeScale(0.75, 0.75)
            newCategoryButton.transform = CGAffineTransformMakeScale(0.75, 0.75)
            collapseAllCategoriesButton.transform = CGAffineTransformMakeScale(0.75, 0.75)
            expandAllCategoriesButton.transform = CGAffineTransformMakeScale(0.75, 0.75)
            showHideCompletedButton.transform = CGAffineTransformMakeScale(0.9, 0.9)
            showHideInactiveButton.transform = CGAffineTransformMakeScale(0.9, 0.9)
            setAllItemsIncompleteButton.transform = CGAffineTransformMakeScale(0.9, 0.9)
            setAllItemsInactiveButton.transform = CGAffineTransformMakeScale(0.9, 0.9)
            printButton.transform = CGAffineTransformMakeScale(0.75, 0.75)
            emailButton.transform = CGAffineTransformMakeScale(0.75, 0.75)
            noteButton.transform = CGAffineTransformMakeScale(0.9, 0.9)
            vertLineImage.transform = CGAffineTransformMakeScale(0.65, 0.65)
        } else if size.height <= 568 {
            // medium small
            verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat(
                "V:|-20-[closeButton]-20-[newCatButton]-20-[showHideCompletedButton]-20-[setAllItemsIncompleteButton]-32-[red0Button]-4-[red1Button]-4-[red2Button]-(>=24)-[printButton]-20-|",
                options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views)
            
            // scale buttons
            closeButton.transform = CGAffineTransformMakeScale(0.85, 0.85)
            newCategoryButton.transform = CGAffineTransformMakeScale(0.85, 0.85)
            collapseAllCategoriesButton.transform = CGAffineTransformMakeScale(0.85, 0.85)
            expandAllCategoriesButton.transform = CGAffineTransformMakeScale(0.85, 0.85)
            showHideCompletedButton.transform = CGAffineTransformMakeScale(1.0, 1.0)
            showHideInactiveButton.transform = CGAffineTransformMakeScale(1.0, 1.0)
            setAllItemsIncompleteButton.transform = CGAffineTransformMakeScale(1.0, 1.0)
            setAllItemsInactiveButton.transform = CGAffineTransformMakeScale(1.0, 1.0)
            printButton.transform = CGAffineTransformMakeScale(0.85, 0.85)
            emailButton.transform = CGAffineTransformMakeScale(0.85, 0.85)
            noteButton.transform = CGAffineTransformMakeScale(0.9, 0.9)
            vertLineImage.transform = CGAffineTransformMakeScale(0.75, 0.75)
        } else if size.height <= 667 {
            // medium large
            verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat(
                "V:|-20-[closeButton]-32-[newCatButton]-32-[showHideCompletedButton]-32-[setAllItemsIncompleteButton]-48-[red0Button]-4-[red1Button]-4-[red2Button]-(>=32)-[printButton]-32-|",
                options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views)
            
            // scale buttons
            closeButton.transform = CGAffineTransformMakeScale(0.85, 0.85)
            newCategoryButton.transform = CGAffineTransformMakeScale(0.85, 0.85)
            collapseAllCategoriesButton.transform = CGAffineTransformMakeScale(0.85, 0.85)
            expandAllCategoriesButton.transform = CGAffineTransformMakeScale(0.85, 0.85)
            showHideCompletedButton.transform = CGAffineTransformMakeScale(1.0, 1.0)
            showHideInactiveButton.transform = CGAffineTransformMakeScale(1.0, 1.0)
            setAllItemsIncompleteButton.transform = CGAffineTransformMakeScale(1.0, 1.0)
            setAllItemsInactiveButton.transform = CGAffineTransformMakeScale(1.0, 1.0)
            printButton.transform = CGAffineTransformMakeScale(0.9, 0.9)
            emailButton.transform = CGAffineTransformMakeScale(0.9, 0.9)
            noteButton.transform = CGAffineTransformMakeScale(1.0, 1.0)
            vertLineImage.transform = CGAffineTransformMakeScale(0.8, 0.8)
        } else {
            // large
            verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat(
                "V:|-20-[closeButton]-60-[newCatButton]-48-[showHideCompletedButton]-48-[setAllItemsIncompleteButton]-60-[red0Button]-4-[red1Button]-4-[red2Button]-(>=48)-[printButton]-32-|",
                options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views)
            
            // scale buttons
            closeButton.transform = CGAffineTransformMakeScale(1.0, 1.0)
            newCategoryButton.transform = CGAffineTransformMakeScale(1.0, 1.0)
            collapseAllCategoriesButton.transform = CGAffineTransformMakeScale(1.0, 1.0)
            expandAllCategoriesButton.transform = CGAffineTransformMakeScale(1.0, 1.0)
            showHideCompletedButton.transform = CGAffineTransformMakeScale(1.25, 1.25)
            showHideInactiveButton.transform = CGAffineTransformMakeScale(1.25, 1.25)
            setAllItemsIncompleteButton.transform = CGAffineTransformMakeScale(1.25, 1.25)
            setAllItemsInactiveButton.transform = CGAffineTransformMakeScale(1.25, 1.25)
            printButton.transform = CGAffineTransformMakeScale(1.0, 1.0)
            emailButton.transform = CGAffineTransformMakeScale(1.0, 1.0)
            noteButton.transform = CGAffineTransformMakeScale(1.0, 1.0)
            vertLineImage.transform = CGAffineTransformMakeScale(0.85, 0.85)
        }
        
        // add constraints to views
        containerView.addConstraints(closeButtonHorizConstraints!)
        containerView.addConstraints(categoryHorizConstraints!)
        containerView.addConstraints(showHideHorizConstraints!)
        containerView.addConstraints(setAllItemsHorizConstraints!)
        containerView.addConstraints(row0ColorButtonHorizConstraints!)
        containerView.addConstraints(row1ColorButtonHorizConstraints!)
        containerView.addConstraints(row2ColorButtonHorizConstraints!)
        containerView.addConstraints(printCloseButtonHorizConstraints!)
        containerView.addConstraints(verticalConstraints!)
        
        // layout
        self.view.layoutIfNeeded()
    }

    func createUI()
    {
        // set the showNotes state
        self.showNotes = appDelegate.printNotes
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = UIColor(white: 0.0, alpha: 1.0)
        view.addSubview(containerView)
        
        newCategoryButton.translatesAutoresizingMaskIntoConstraints = false
        //newCategoryButton.transform = CGAffineTransformMakeScale(0.85, 0.85)
        newCategoryButton.setImage(UIImage(named: "New Category"), forState: .Normal)
        newCategoryButton.addTarget(self, action: #selector(SettingsViewController.newCategory(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        containerView.addSubview(newCategoryButton)
        
        collapseAllCategoriesButton.translatesAutoresizingMaskIntoConstraints = false
        //collapseAllCategoriesButton.transform = CGAffineTransformMakeScale(0.85, 0.85)
        collapseAllCategoriesButton.setImage(UIImage(named: "Collapsed Categories"), forState: .Normal)
        collapseAllCategoriesButton.addTarget(self, action: #selector(SettingsViewController.collapseAllCategories(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        containerView.addSubview(collapseAllCategoriesButton)
        
        expandAllCategoriesButton.translatesAutoresizingMaskIntoConstraints = false
        //expandAllCategoriesButton.transform = CGAffineTransformMakeScale(0.85, 0.85)
        expandAllCategoriesButton.setImage(UIImage(named: "Expanded Categories"), forState: .Normal)
        expandAllCategoriesButton.addTarget(self, action: #selector(SettingsViewController.expandAllCategories(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        containerView.addSubview(expandAllCategoriesButton)
        
        showHideCompletedButton.translatesAutoresizingMaskIntoConstraints = false
        //showHideCompletedButton.transform = CGAffineTransformMakeScale(0.85, 0.85)
        showHideCompletedButton.setImage(UIImage(named: "Show Completed"), forState: .Normal)
        showHideCompletedButton.addTarget(self, action: #selector(SettingsViewController.showHideCompletedItems(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        showCompletedItems = itemVC != nil && itemVC!.list != nil ? itemVC!.list!.showCompletedItems : true
        containerView.addSubview(showHideCompletedButton)
        
        showHideInactiveButton.translatesAutoresizingMaskIntoConstraints = false
        //showHideInactiveButton.transform = CGAffineTransformMakeScale(0.85, 0.85)
        showHideInactiveButton.setImage(UIImage(named: "Show Inactive"), forState: .Normal)
        showHideInactiveButton.addTarget(self, action: #selector(SettingsViewController.showHideInactiveItems(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        showInactiveItems = itemVC != nil && itemVC!.list != nil ? itemVC!.list!.showInactiveItems : true
        containerView.addSubview(showHideInactiveButton)
        
        setAllItemsIncompleteButton.translatesAutoresizingMaskIntoConstraints = false
        //setAllItemsIncompleteButton.transform = CGAffineTransformMakeScale(0.85, 0.85)
        setAllItemsIncompleteButton.setImage(UIImage(named: "Set Incomplete"), forState: .Normal)
        setAllItemsIncompleteButton.addTarget(self, action: #selector(SettingsViewController.setAllItemsIncomplete(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        containerView.addSubview(setAllItemsIncompleteButton)
        
        setAllItemsInactiveButton.translatesAutoresizingMaskIntoConstraints = false
        //setAllItemsInactiveButton.transform = CGAffineTransformMakeScale(0.85, 0.85)
        setAllItemsInactiveButton.setImage(UIImage(named: "Set Inactive"), forState: .Normal)
        setAllItemsInactiveButton.addTarget(self, action: #selector(SettingsViewController.setAllItemsInactive(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        containerView.addSubview(setAllItemsInactiveButton)
        
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        //closeButton.transform = CGAffineTransformMakeScale(0.85, 0.85)
        closeButton.setImage(UIImage(named: "Close Window"), forState: .Normal)
        closeButton.addTarget(self, action: #selector(SettingsViewController.close), forControlEvents: UIControlEvents.TouchUpInside)
        containerView.addSubview(closeButton)
        
        noteButton.translatesAutoresizingMaskIntoConstraints = false
        if showNotes {
            noteButton.setImage(UIImage(named: "Notes On"), forState: .Normal)
        } else {
            noteButton.setImage(UIImage(named: "Notes Off"), forState: .Normal)
        }
        noteButton.addTarget(self, action: #selector(SettingsViewController.noteButtonChanged), forControlEvents: .TouchUpInside)
        //noteButton.transform = CGAffineTransformMakeScale(0.85, 0.85)
        containerView.addSubview(noteButton)
        
        vertLineImage.translatesAutoresizingMaskIntoConstraints = false
        //vertLineImage.transform = CGAffineTransformMakeScale(0.75, 0.75)
        vertLineImage.image = UIImage(named: "Vert Dash Line")
        containerView.addSubview(vertLineImage)
        
        printButton.translatesAutoresizingMaskIntoConstraints = false
        //printButton.transform = CGAffineTransformMakeScale(0.75, 0.75)
        printButton.setImage(UIImage(named: "Print"), forState: .Normal)
        printButton.addTarget(self, action: #selector(SettingsViewController.print), forControlEvents: UIControlEvents.TouchUpInside)
        printButton.enabled = UIPrintInteractionController.isPrintingAvailable()
        containerView.addSubview(printButton)
        
        emailButton.translatesAutoresizingMaskIntoConstraints = false
        //emailButton.transform = CGAffineTransformMakeScale(0.75, 0.75)
        emailButton.setImage(UIImage(named: "Email"), forState: .Normal)
        emailButton.addTarget(self, action: #selector(SettingsViewController.email), forControlEvents: UIControlEvents.TouchUpInside)
        emailButton.enabled = UIPrintInteractionController.isPrintingAvailable()
        containerView.addSubview(emailButton)
        
        red0Button.translatesAutoresizingMaskIntoConstraints = false
        red0Button.backgroundColor = red0
        red0Button.addTarget(self, action: #selector(SettingsViewController.colorButton(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        red0Button.tag = 0
        containerView.addSubview(red0Button)
        
        green0Button.translatesAutoresizingMaskIntoConstraints = false
        green0Button.backgroundColor = green0
        green0Button.addTarget(self, action: #selector(SettingsViewController.colorButton(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        green0Button.tag = 1
        containerView.addSubview(green0Button)
        
        blue0Button.translatesAutoresizingMaskIntoConstraints = false
        blue0Button.backgroundColor = blue0
        blue0Button.addTarget(self, action: #selector(SettingsViewController.colorButton(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        blue0Button.tag = 2
        containerView.addSubview(blue0Button)
        
        red1Button.translatesAutoresizingMaskIntoConstraints = false
        red1Button.backgroundColor = red1
        red1Button.addTarget(self, action: #selector(SettingsViewController.colorButton(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        red1Button.tag = 3
        containerView.addSubview(red1Button)
        
        green1Button.translatesAutoresizingMaskIntoConstraints = false
        green1Button.backgroundColor = green1
        green1Button.addTarget(self, action: #selector(SettingsViewController.colorButton(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        green1Button.tag = 4
        containerView.addSubview(green1Button)
        
        blue1Button.translatesAutoresizingMaskIntoConstraints = false
        blue1Button.backgroundColor = blue1
        blue1Button.addTarget(self, action: #selector(SettingsViewController.colorButton(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        blue1Button.tag = 5
        containerView.addSubview(blue1Button)
        
        red2Button.translatesAutoresizingMaskIntoConstraints = false
        red2Button.backgroundColor = red2
        red2Button.addTarget(self, action: #selector(SettingsViewController.colorButton(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        red2Button.tag = 6
        containerView.addSubview(red2Button)
        
        green2Button.translatesAutoresizingMaskIntoConstraints = false
        green2Button.backgroundColor = green2
        green2Button.addTarget(self, action: #selector(SettingsViewController.colorButton(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        green2Button.tag = 7
        containerView.addSubview(green2Button)
        
        blue2Button.translatesAutoresizingMaskIntoConstraints = false
        blue2Button.backgroundColor = blue2
        blue2Button.addTarget(self, action: #selector(SettingsViewController.colorButton(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        blue2Button.tag = 8
        containerView.addSubview(blue2Button)
        
        // set up container view constraints
        let views: [String : AnyObject] = ["containerView": containerView]
        containerViewHorizConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[containerView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views)
        containerViewVertConstraints  = NSLayoutConstraint.constraintsWithVisualFormat("V:|[containerView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views)
        
        view.addConstraints(containerViewHorizConstraints!)
        view.addConstraints(containerViewVertConstraints!)
        
        adjustConstraints(view.frame.size)
    }
    
    func newCategory(sender: UIButton) {
        itemVC?.addNewCategory()
        presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func collapseAllCategories(send: UIButton) {
        itemVC?.collapseAllCategories()
    }
    
    func expandAllCategories(send: UIButton) {
        itemVC?.expandAllCategories()
    }
    
    func showHideCompletedItems(sender: UIButton) {
        showCompletedItems = !showCompletedItems
        itemVC?.showHideCompletedRows()
    }
    
    func showHideInactiveItems(sender: UIButton) {
        showInactiveItems = !showInactiveItems
        itemVC?.showHideInactiveRows()
    }
    
    func setAllItemsIncomplete(sender: UIButton) {
        itemVC?.setAllItemsIncomplete()
    }
    
    func setAllItemsInactive(sender: UIButton) {
        itemVC?.setAllItemsInactive()
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
    
    func noteButtonChanged() {
        showNotes = !showNotes
    }
    
    func print()
    {
        // present the print dialog
        itemVC?.presentPrintDialog()
        
        // dismiss settings view controller
        self.itemVC?.appDelegate.saveAll()
        self.presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func email()
    {
        // schedule the email dialog
        itemVC?.scheduleEmailDialog()
        
        // dismiss settings view controller
        self.itemVC?.appDelegate.saveAll()
        self.presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func close()
    {
        itemVC?.appDelegate.saveAll()
        presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
    }
}
