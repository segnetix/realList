//
//  SettingsViewController.swift
//  EnList
//
//  Created by Steven Gentry on 2/5/16.
//  Copyright © 2016 Steven Gentry. All rights reserved.
//

import UIKit

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
    
    // color buttons
    let r1_1: UIButton = UIButton()
    let r1_2: UIButton = UIButton()
    let r1_3: UIButton = UIButton()
    let r2_1: UIButton = UIButton()
    let r2_2: UIButton = UIButton()
    let r2_3: UIButton = UIButton()
    let r3_1: UIButton = UIButton()
    let r3_2: UIButton = UIButton()
    let r3_3: UIButton = UIButton()
    let r4_1: UIButton = UIButton()
    let r4_2: UIButton = UIButton()
    let r4_3: UIButton = UIButton()
    var colorButtons = [UIButton: UIColor]()
    var colorButtonIndex = [UIButton: Int]()
    
    // autolayout constraints
    var verticalConstraints: [NSLayoutConstraint]?
    var containerViewHorizConstraints: [NSLayoutConstraint]?
    var containerViewVertConstraints: [NSLayoutConstraint]?
    var closeButtonHorizConstraints: [NSLayoutConstraint]?
    var categoryHorizConstraints: [NSLayoutConstraint]?
    var showHideHorizConstraints: [NSLayoutConstraint]?
    var setAllItemsHorizConstraints: [NSLayoutConstraint]?
    var row1ColorButtonHorizConstraints: [NSLayoutConstraint]?
    var row2ColorButtonHorizConstraints: [NSLayoutConstraint]?
    var row3ColorButtonHorizConstraints: [NSLayoutConstraint]?
    var row4ColorButtonHorizConstraints: [NSLayoutConstraint]?
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
    
    init(itemVC: ItemViewController, showCompletedItems: Bool, showInactiveItems: Bool) {
        super.init(nibName: nil, bundle: nil)
        
        self.itemVC = itemVC
        self.showCompletedItems = showCompletedItems
        self.showInactiveItems = showInactiveItems
        
        modalPresentationStyle = UIModalPresentationStyle.Custom
        createUI()
        selectInitialColorButton(self.itemVC?.list.listColorName)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func selectInitialColorButton(colorName: String?)
    {
        // initial color button selection
        var colorButton = r1_1
        
        if let colorName = colorName {
            switch colorName {
            case "r1_1": colorButton = r1_1
            case "r1_2": colorButton = r1_2
            case "r1_3": colorButton = r1_3
            case "r2_1": colorButton = r2_1
            case "r2_2": colorButton = r2_2
            case "r2_3": colorButton = r2_3
            case "r3_1": colorButton = r3_1
            case "r3_2": colorButton = r3_2
            case "r3_3": colorButton = r3_3
            case "r4_1": colorButton = r4_1
            case "r4_2": colorButton = r4_2
            case "r4_3": colorButton = r4_3
            default: colorButton = r1_1
            }
        }
        
        self.highlightSelectedColorBox(colorButton)
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
        if row1ColorButtonHorizConstraints  != nil { containerView.removeConstraints(row1ColorButtonHorizConstraints!)  }
        if row2ColorButtonHorizConstraints  != nil { containerView.removeConstraints(row2ColorButtonHorizConstraints!)  }
        if row3ColorButtonHorizConstraints  != nil { containerView.removeConstraints(row3ColorButtonHorizConstraints!)  }
        if row4ColorButtonHorizConstraints  != nil { containerView.removeConstraints(row4ColorButtonHorizConstraints!)  }
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
            "r1_1": r1_1,
            "r1_2": r1_2,
            "r1_3": r1_3,
            "r2_1": r2_1,
            "r2_2": r2_2,
            "r2_3": r2_3,
            "r3_1": r3_1,
            "r3_2": r3_2,
            "r3_3": r3_3,
            "r4_1": r4_1,
            "r4_2": r4_2,
            "r4_3": r4_3,
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
        row1ColorButtonHorizConstraints = NSLayoutConstraint.constraintsWithVisualFormat(
            "H:|-(<=6)-[r1_1(>=48)]-(<=6)-[r1_2(==r1_1@750)]-(<=6)-[r1_3(==r1_1@750)]-(<=6)-|",
            options: [.AlignAllCenterY], metrics: nil, views: views)
        
        row2ColorButtonHorizConstraints = NSLayoutConstraint.constraintsWithVisualFormat(
            "H:|-(<=6)-[r2_1(>=48)]-(<=6)-[r2_2(==r2_1@750)]-(<=6)-[r2_3(==r2_1@750)]-(<=6)-|",
            options: [.AlignAllCenterY], metrics: nil, views: views)
        
        row3ColorButtonHorizConstraints = NSLayoutConstraint.constraintsWithVisualFormat(
            "H:|-(<=6)-[r3_1(>=48)]-(<=6)-[r3_2(==r3_1@750)]-(<=6)-[r3_3(==r3_1@750)]-(<=6)-|",
            options: [.AlignAllCenterY], metrics: nil, views: views)
        
        row4ColorButtonHorizConstraints = NSLayoutConstraint.constraintsWithVisualFormat(
            "H:|-(<=6)-[r4_1(>=48)]-(<=6)-[r4_2(==r4_1@750)]-(<=6)-[r4_3(==r4_1@750)]-(<=6)-|",
            options: [.AlignAllCenterY], metrics: nil, views: views)
        
        // set overall vertical constraints based on available height
        if size.height <= 480 {
            // small
            verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat(
                "V:|-20-[closeButton]-16-[newCatButton]-16-[showHideCompletedButton]-16-[setAllItemsIncompleteButton]-16-[r1_1][r2_1][r3_1][r4_1]-(>=16)-[printButton]-16-|",
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
                "V:|-20-[closeButton]-20-[newCatButton]-20-[showHideCompletedButton]-20-[setAllItemsIncompleteButton]-32-[r1_1][r2_1][r3_1][r4_1]-(>=24)-[printButton]-20-|",
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
                "V:|-20-[closeButton]-32-[newCatButton]-32-[showHideCompletedButton]-32-[setAllItemsIncompleteButton]-48-[r1_1][r2_1][r3_1][r4_1]-(>=32)-[printButton]-32-|",
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
                "V:|-20-[closeButton]-60-[newCatButton]-48-[showHideCompletedButton]-48-[setAllItemsIncompleteButton]-60-[r1_1][r2_1][r3_1][r4_1]-(>=48)-[printButton]-32-|",
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
        containerView.addConstraints(row1ColorButtonHorizConstraints!)
        containerView.addConstraints(row2ColorButtonHorizConstraints!)
        containerView.addConstraints(row3ColorButtonHorizConstraints!)
        containerView.addConstraints(row4ColorButtonHorizConstraints!)
        containerView.addConstraints(printCloseButtonHorizConstraints!)
        containerView.addConstraints(verticalConstraints!)
        
        // layout
        self.view.layoutIfNeeded()
    }

    func createUI()
    {
        // set the showNotes state
        self.showNotes = appDelegate.printNotes
        
        colorButtons = [r1_1: color1_1, r1_2: color1_2, r1_3: color1_3, r2_1: color2_1, r2_2: color2_2, r2_3: color2_3, r3_1: color3_1, r3_2: color3_2, r3_3: color3_3, r4_1: color4_1, r4_2: color4_2, r4_3: color4_3]
        colorButtonIndex = [r1_1: 1, r1_2: 2, r1_3: 3, r2_1: 4, r2_2: 5, r2_3: 6, r3_1: 7, r3_2: 8, r3_3: 9, r4_1: 10, r4_2: 11, r4_3: 12]
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = UIColor(white: 0.0, alpha: 1.0)
        view.addSubview(containerView)
        
        newCategoryButton.translatesAutoresizingMaskIntoConstraints = false
        newCategoryButton.setImage(UIImage(named: "New Category"), forState: .Normal)
        newCategoryButton.addTarget(self, action: #selector(SettingsViewController.newCategory(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        containerView.addSubview(newCategoryButton)
        
        collapseAllCategoriesButton.translatesAutoresizingMaskIntoConstraints = false
        collapseAllCategoriesButton.setImage(UIImage(named: "Collapsed Categories"), forState: .Normal)
        collapseAllCategoriesButton.addTarget(self, action: #selector(SettingsViewController.collapseAllCategories(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        containerView.addSubview(collapseAllCategoriesButton)
        
        expandAllCategoriesButton.translatesAutoresizingMaskIntoConstraints = false
        expandAllCategoriesButton.setImage(UIImage(named: "Expanded Categories"), forState: .Normal)
        expandAllCategoriesButton.addTarget(self, action: #selector(SettingsViewController.expandAllCategories(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        containerView.addSubview(expandAllCategoriesButton)
        
        showHideCompletedButton.translatesAutoresizingMaskIntoConstraints = false
        showHideCompletedButton.setImage(UIImage(named: "Show Completed"), forState: .Normal)
        showHideCompletedButton.addTarget(self, action: #selector(SettingsViewController.showHideCompletedItems(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        showCompletedItems = itemVC != nil && itemVC!.list != nil ? itemVC!.list!.showCompletedItems : true
        containerView.addSubview(showHideCompletedButton)
        
        showHideInactiveButton.translatesAutoresizingMaskIntoConstraints = false
        showHideInactiveButton.setImage(UIImage(named: "Show Inactive"), forState: .Normal)
        showHideInactiveButton.addTarget(self, action: #selector(SettingsViewController.showHideInactiveItems(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        showInactiveItems = itemVC != nil && itemVC!.list != nil ? itemVC!.list!.showInactiveItems : true
        containerView.addSubview(showHideInactiveButton)
        
        setAllItemsIncompleteButton.translatesAutoresizingMaskIntoConstraints = false
        setAllItemsIncompleteButton.setImage(UIImage(named: "Set Incomplete"), forState: .Normal)
        setAllItemsIncompleteButton.addTarget(self, action: #selector(SettingsViewController.setAllItemsIncomplete(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        containerView.addSubview(setAllItemsIncompleteButton)
        
        setAllItemsInactiveButton.translatesAutoresizingMaskIntoConstraints = false
        setAllItemsInactiveButton.setImage(UIImage(named: "Set Inactive"), forState: .Normal)
        setAllItemsInactiveButton.addTarget(self, action: #selector(SettingsViewController.setAllItemsInactive(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        containerView.addSubview(setAllItemsInactiveButton)
        
        closeButton.translatesAutoresizingMaskIntoConstraints = false
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
        containerView.addSubview(noteButton)
        
        vertLineImage.translatesAutoresizingMaskIntoConstraints = false
        vertLineImage.image = UIImage(named: "Vert Dash Line")
        containerView.addSubview(vertLineImage)
        
        printButton.translatesAutoresizingMaskIntoConstraints = false
        printButton.setImage(UIImage(named: "Print"), forState: .Normal)
        printButton.addTarget(self, action: #selector(SettingsViewController.print), forControlEvents: UIControlEvents.TouchUpInside)
        printButton.enabled = UIPrintInteractionController.isPrintingAvailable()
        containerView.addSubview(printButton)
        
        emailButton.translatesAutoresizingMaskIntoConstraints = false
        emailButton.setImage(UIImage(named: "Email"), forState: .Normal)
        emailButton.addTarget(self, action: #selector(SettingsViewController.email), forControlEvents: UIControlEvents.TouchUpInside)
        emailButton.enabled = UIPrintInteractionController.isPrintingAvailable()
        containerView.addSubview(emailButton)
        
        // color buttons setup
        for (button, color) in colorButtons {
            button.translatesAutoresizingMaskIntoConstraints = false
            button.backgroundColor = color
            button.addTarget(self, action: #selector(SettingsViewController.colorButton(_:)), forControlEvents: UIControlEvents.TouchUpInside)
            button.tag = colorButtonIndex[button]!
            containerView.addSubview(button)
        }
        
        // draw corners on each color button
        for (button, _) in colorButtons {
            button.layer.borderWidth = 2
            button.layer.cornerRadius = 5.0
            button.layer.borderColor = UIColor(red:0.0, green:0.0, blue:0.0, alpha: 1.0).CGColor
        }
        
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
        var color = "r1_2"
        var selectedButton: UIButton?
        
        switch sender.tag {
            case  1: color = "r1_1"; selectedButton = r1_1
            case  2: color = "r1_2"; selectedButton = r1_2
            case  3: color = "r1_3"; selectedButton = r1_3
            case  4: color = "r2_1"; selectedButton = r2_1
            case  5: color = "r2_2"; selectedButton = r2_2
            case  6: color = "r2_3"; selectedButton = r2_3
            case  7: color = "r3_1"; selectedButton = r3_1
            case  8: color = "r3_2"; selectedButton = r3_2
            case  9: color = "r3_3"; selectedButton = r3_3
            case 10: color = "r4_1"; selectedButton = r4_1
            case 11: color = "r4_2"; selectedButton = r4_2
            case 12: color = "r4_3"; selectedButton = r4_3
            default: color = "r1_2"; selectedButton = r1_2
        }
        
        // put a white box around the selected color button
        self.highlightSelectedColorBox(selectedButton!)
        
        itemVC?.list.listColorName = color
        itemVC?.tableView.reloadData()
    }
    
    func highlightSelectedColorBox(selectedButton: UIButton)
    {
        // erase any current borders
        for (button, _) in colorButtons {
            button.layer.borderColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0).CGColor
        }
        
        // highlight the new selected color box
        selectedButton.layer.borderColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0).CGColor
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
