//
//  SettingsViewController.swift
//  EnList
//
//  Created by Steven Gentry on 2/5/16.
//  Copyright © 2016 Steven Gentry. All rights reserved.
//

import UIKit

class SettingsViewController: UIAppViewController {
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
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
    let cb1_1: UIButton = UIButton()
    let cb1_2: UIButton = UIButton()
    let cb1_3: UIButton = UIButton()
    let cb2_1: UIButton = UIButton()
    let cb2_2: UIButton = UIButton()
    let cb2_3: UIButton = UIButton()
    let cb3_1: UIButton = UIButton()
    let cb3_2: UIButton = UIButton()
    let cb3_3: UIButton = UIButton()
    let cb4_1: UIButton = UIButton()
    let cb4_2: UIButton = UIButton()
    let cb4_3: UIButton = UIButton()
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
                showHideCompletedButton.setImage(UIImage(named: "Show Completed"), for: UIControl.State())
            } else {
                showHideCompletedButton.setImage(UIImage(named: "Hide Completed"), for: UIControl.State())
            }
            
            if itemVC != nil && itemVC!.list != nil {
                itemVC!.list!.showCompletedItems = self.showCompletedItems
            }
        }
    }

    var showInactiveItems: Bool = true {
        didSet {
            if showInactiveItems {
                showHideInactiveButton.setImage(UIImage(named: "Show Inactive"), for: UIControl.State())
            } else {
                showHideInactiveButton.setImage(UIImage(named: "Hide Inactive"), for: UIControl.State())
            }
            
            if itemVC != nil && itemVC!.list != nil {
                itemVC!.list!.showInactiveItems = self.showInactiveItems
            }
        }
    }
    
    var showNotes: Bool = true {
        didSet {
            if showNotes {
                noteButton.setImage(UIImage(named: "Notes On"), for: UIControl.State())
            } else {
                noteButton.setImage(UIImage(named: "Notes Off"), for: UIControl.State())
            }
            
            appDelegate.printNotes = self.showNotes
        }
    }
    
    init(itemVC: ItemViewController, showCompletedItems: Bool, showInactiveItems: Bool) {
        super.init(nibName: nil, bundle: nil)
        
        self.itemVC = itemVC
        self.showCompletedItems = showCompletedItems
        self.showInactiveItems = showInactiveItems
        
        modalPresentationStyle = UIModalPresentationStyle.custom
        createUI()
        selectInitialColorButton(self.itemVC?.list.listColorName)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func selectInitialColorButton(_ colorName: String?) {
        // initial color button selection
        var colorButton = cb1_2
        
        if let colorName = colorName {
            switch colorName {
            case r1_1: colorButton = cb1_1
            case r1_2: colorButton = cb1_2
            case r1_3: colorButton = cb1_3
            case r2_1: colorButton = cb2_1
            case r2_2: colorButton = cb2_2
            case r2_3: colorButton = cb2_3
            case r3_1: colorButton = cb3_1
            case r3_2: colorButton = cb3_2
            case r3_3: colorButton = cb3_3
            case r4_1: colorButton = cb4_1
            case r4_2: colorButton = cb4_2
            case r4_3: colorButton = cb4_3
            default:   colorButton = cb1_2
            }
        }
        
        self.highlightSelectedColorBox(colorButton)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        adjustConstraints(size)
    }
    
    func adjustConstraints(_ size: CGSize) {
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
            "r1_1": cb1_1,
            "r1_2": cb1_2,
            "r1_3": cb1_3,
            "r2_1": cb2_1,
            "r2_2": cb2_2,
            "r2_3": cb2_3,
            "r3_1": cb3_1,
            "r3_2": cb3_2,
            "r3_3": cb3_3,
            "r4_1": cb4_1,
            "r4_2": cb4_2,
            "r4_3": cb4_3,
            "closeButton": closeButton,
            "printButton": printButton,
            "emailButton": emailButton,
            "noteButton": noteButton,
            "vertLine": vertLineImage]
        
        closeButtonHorizConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:[closeButton]-10-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: views)
        showHideHorizConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-[showHideCompletedButton]-[showHideInactiveButton(==showHideCompletedButton)]-|", options: [.alignAllCenterY], metrics: nil, views: views)
        categoryHorizConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-[collapseAllCategoriesButton(==newCatButton)]-[expandAllCategoriesButton(==newCatButton)]-[newCatButton]-|", options: [.alignAllCenterY], metrics: nil, views: views)
        printCloseButtonHorizConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-(>=4,<=8)-[printButton]-[emailButton(==printButton)]-[vertLine]-[noteButton]-(>=4,<=8)-|", options: [.alignAllCenterY], metrics: nil, views: views)
        setAllItemsHorizConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-[setAllItemsIncompleteButton]-[setAllItemsInactiveButton(==setAllItemsIncompleteButton)]-|", options: [.alignAllCenterY], metrics: nil, views: views)
        
        // color button constraints
        row1ColorButtonHorizConstraints = NSLayoutConstraint.constraints(
            withVisualFormat: "H:|-(<=6)-[r1_1(>=48)]-(<=6)-[r1_2(==r1_1@750)]-(<=6)-[r1_3(==r1_1@750)]-(<=6)-|",
            options: [.alignAllCenterY], metrics: nil, views: views)
        
        row2ColorButtonHorizConstraints = NSLayoutConstraint.constraints(
            withVisualFormat: "H:|-(<=6)-[r2_1(>=48)]-(<=6)-[r2_2(==r2_1@750)]-(<=6)-[r2_3(==r2_1@750)]-(<=6)-|",
            options: [.alignAllCenterY], metrics: nil, views: views)
        
        row3ColorButtonHorizConstraints = NSLayoutConstraint.constraints(
            withVisualFormat: "H:|-(<=6)-[r3_1(>=48)]-(<=6)-[r3_2(==r3_1@750)]-(<=6)-[r3_3(==r3_1@750)]-(<=6)-|",
            options: [.alignAllCenterY], metrics: nil, views: views)
        
        row4ColorButtonHorizConstraints = NSLayoutConstraint.constraints(
            withVisualFormat: "H:|-(<=6)-[r4_1(>=48)]-(<=6)-[r4_2(==r4_1@750)]-(<=6)-[r4_3(==r4_1@750)]-(<=6)-|",
            options: [.alignAllCenterY], metrics: nil, views: views)
        
        // set overall vertical constraints based on available height
        if size.height <= 480 {
            // small
            verticalConstraints = NSLayoutConstraint.constraints(
                withVisualFormat: "V:|-20-[closeButton]-16-[newCatButton]-16-[showHideCompletedButton]-16-[setAllItemsIncompleteButton]-16-[r1_1][r2_1][r3_1][r4_1]-(>=16)-[printButton]-16-|",
                options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: views)
            
            // scale buttons
            closeButton.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
            newCategoryButton.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
            collapseAllCategoriesButton.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
            expandAllCategoriesButton.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
            showHideCompletedButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            showHideInactiveButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            setAllItemsIncompleteButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            setAllItemsInactiveButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            printButton.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
            emailButton.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
            noteButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            vertLineImage.transform = CGAffineTransform(scaleX: 0.65, y: 0.65)
        } else if size.height <= 568 {
            // medium small
            verticalConstraints = NSLayoutConstraint.constraints(
                withVisualFormat: "V:|-20-[closeButton]-20-[newCatButton]-20-[showHideCompletedButton]-20-[setAllItemsIncompleteButton]-32-[r1_1][r2_1][r3_1][r4_1]-(>=24)-[printButton]-20-|",
                options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: views)
            
            // scale buttons
            closeButton.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
            newCategoryButton.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
            collapseAllCategoriesButton.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
            expandAllCategoriesButton.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
            showHideCompletedButton.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            showHideInactiveButton.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            setAllItemsIncompleteButton.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            setAllItemsInactiveButton.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            printButton.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
            emailButton.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
            noteButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            vertLineImage.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        } else if size.height <= 667 {
            // medium large
            verticalConstraints = NSLayoutConstraint.constraints(
                withVisualFormat: "V:|-20-[closeButton]-32-[newCatButton]-32-[showHideCompletedButton]-32-[setAllItemsIncompleteButton]-48-[r1_1][r2_1][r3_1][r4_1]-(>=32)-[printButton]-32-|",
                options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: views)
            
            // scale buttons
            closeButton.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
            newCategoryButton.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
            collapseAllCategoriesButton.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
            expandAllCategoriesButton.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
            showHideCompletedButton.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            showHideInactiveButton.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            setAllItemsIncompleteButton.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            setAllItemsInactiveButton.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            printButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            emailButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            noteButton.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            vertLineImage.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        } else {
            // large
            verticalConstraints = NSLayoutConstraint.constraints(
                withVisualFormat: "V:|-20-[closeButton]-60-[newCatButton]-48-[showHideCompletedButton]-48-[setAllItemsIncompleteButton]-60-[r1_1][r2_1][r3_1][r4_1]-(>=48)-[printButton]-32-|",
                options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: views)
            
            // scale buttons
            closeButton.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            newCategoryButton.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            collapseAllCategoriesButton.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            expandAllCategoriesButton.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            showHideCompletedButton.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
            showHideInactiveButton.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
            setAllItemsIncompleteButton.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
            setAllItemsInactiveButton.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
            printButton.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            emailButton.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            noteButton.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            vertLineImage.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
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

    func createUI() {
        // set the showNotes state
        self.showNotes = appDelegate.printNotes
        
        colorButtons = [cb1_1: color1_1, cb1_2: color1_2, cb1_3: color1_3, cb2_1: color2_1, cb2_2: color2_2, cb2_3: color2_3, cb3_1: color3_1, cb3_2: color3_2, cb3_3: color3_3, cb4_1: color4_1, cb4_2: color4_2, cb4_3: color4_3]
        colorButtonIndex = [cb1_1: 1, cb1_2: 2, cb1_3: 3, cb2_1: 4, cb2_2: 5, cb2_3: 6, cb3_1: 7, cb3_2: 8, cb3_3: 9, cb4_1: 10, cb4_2: 11, cb4_3: 12]
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = UIColor(white: 0.0, alpha: 1.0)
        view.addSubview(containerView)
        
        newCategoryButton.translatesAutoresizingMaskIntoConstraints = false
        newCategoryButton.setImage(UIImage(named: "New Category"), for: UIControl.State())
        newCategoryButton.addTarget(self, action: #selector(SettingsViewController.newCategory(_:)), for: UIControl.Event.touchUpInside)
        containerView.addSubview(newCategoryButton)
        
        collapseAllCategoriesButton.translatesAutoresizingMaskIntoConstraints = false
        collapseAllCategoriesButton.setImage(UIImage(named: "Collapsed Categories"), for: UIControl.State())
        collapseAllCategoriesButton.addTarget(self, action: #selector(SettingsViewController.collapseAllCategories(_:)), for: UIControl.Event.touchUpInside)
        containerView.addSubview(collapseAllCategoriesButton)
        
        expandAllCategoriesButton.translatesAutoresizingMaskIntoConstraints = false
        expandAllCategoriesButton.setImage(UIImage(named: "Expanded Categories"), for: UIControl.State())
        expandAllCategoriesButton.addTarget(self, action: #selector(SettingsViewController.expandAllCategories(_:)), for: UIControl.Event.touchUpInside)
        containerView.addSubview(expandAllCategoriesButton)
        
        showHideCompletedButton.translatesAutoresizingMaskIntoConstraints = false
        showHideCompletedButton.setImage(UIImage(named: "Show Completed"), for: UIControl.State())
        showHideCompletedButton.addTarget(self, action: #selector(SettingsViewController.showHideCompletedItems(_:)), for: UIControl.Event.touchUpInside)
        showCompletedItems = itemVC != nil && itemVC!.list != nil ? itemVC!.list!.showCompletedItems : true
        containerView.addSubview(showHideCompletedButton)
        
        showHideInactiveButton.translatesAutoresizingMaskIntoConstraints = false
        showHideInactiveButton.setImage(UIImage(named: "Show Inactive"), for: UIControl.State())
        showHideInactiveButton.addTarget(self, action: #selector(SettingsViewController.showHideInactiveItems(_:)), for: UIControl.Event.touchUpInside)
        showInactiveItems = itemVC != nil && itemVC!.list != nil ? itemVC!.list!.showInactiveItems : true
        containerView.addSubview(showHideInactiveButton)
        
        setAllItemsIncompleteButton.translatesAutoresizingMaskIntoConstraints = false
        setAllItemsIncompleteButton.setImage(UIImage(named: "Set Incomplete"), for: UIControl.State())
        setAllItemsIncompleteButton.addTarget(self, action: #selector(SettingsViewController.setAllItemsIncomplete(_:)), for: UIControl.Event.touchUpInside)
        containerView.addSubview(setAllItemsIncompleteButton)
        
        setAllItemsInactiveButton.translatesAutoresizingMaskIntoConstraints = false
        setAllItemsInactiveButton.setImage(UIImage(named: "Set Inactive"), for: UIControl.State())
        setAllItemsInactiveButton.addTarget(self, action: #selector(SettingsViewController.setAllItemsInactive(_:)), for: UIControl.Event.touchUpInside)
        containerView.addSubview(setAllItemsInactiveButton)
        
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setImage(UIImage(named: "Close Window"), for: UIControl.State())
        closeButton.addTarget(self, action: #selector(SettingsViewController.close), for: UIControl.Event.touchUpInside)
        containerView.addSubview(closeButton)
        
        noteButton.translatesAutoresizingMaskIntoConstraints = false
        if showNotes {
            noteButton.setImage(UIImage(named: "Notes On"), for: UIControl.State())
        } else {
            noteButton.setImage(UIImage(named: "Notes Off"), for: UIControl.State())
        }
        noteButton.addTarget(self, action: #selector(SettingsViewController.noteButtonChanged), for: .touchUpInside)
        containerView.addSubview(noteButton)
        
        vertLineImage.translatesAutoresizingMaskIntoConstraints = false
        vertLineImage.image = UIImage(named: "Vert Dash Line")
        containerView.addSubview(vertLineImage)
        
        printButton.translatesAutoresizingMaskIntoConstraints = false
        printButton.setImage(UIImage(named: "Print"), for: UIControl.State())
        printButton.addTarget(self, action: #selector(SettingsViewController.print), for: UIControl.Event.touchUpInside)
        printButton.isEnabled = UIPrintInteractionController.isPrintingAvailable
        containerView.addSubview(printButton)
        
        emailButton.translatesAutoresizingMaskIntoConstraints = false
        emailButton.setImage(UIImage(named: "Email"), for: UIControl.State())
        emailButton.addTarget(self, action: #selector(SettingsViewController.email), for: UIControl.Event.touchUpInside)
        emailButton.isEnabled = UIPrintInteractionController.isPrintingAvailable
        containerView.addSubview(emailButton)
        
        // color buttons setup
        for (button, color) in colorButtons {
            button.translatesAutoresizingMaskIntoConstraints = false
            button.backgroundColor = color
            button.addTarget(self, action: #selector(SettingsViewController.colorButton(_:)), for: UIControl.Event.touchUpInside)
            button.tag = colorButtonIndex[button]!
            containerView.addSubview(button)
        }
        
        // draw corners on each color button
        for (button, _) in colorButtons {
            button.layer.borderWidth = 2
            button.layer.cornerRadius = 5.0
            button.layer.borderColor = UIColor(red:0.0, green:0.0, blue:0.0, alpha: 1.0).cgColor
        }
        
        // set up container view constraints
        let views: [String : AnyObject] = ["containerView": containerView]
        containerViewHorizConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[containerView]|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: views)
        containerViewVertConstraints  = NSLayoutConstraint.constraints(withVisualFormat: "V:|[containerView]|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: views)
        
        view.addConstraints(containerViewHorizConstraints!)
        view.addConstraints(containerViewVertConstraints!)
        
        adjustConstraints(view.frame.size)
    }
    
    @objc func newCategory(_ sender: UIButton) {
        itemVC?.addNewCategory()
        close()
    }
    
    @objc func collapseAllCategories(_ send: UIButton) {
        itemVC?.collapseAllCategories()
    }
    
    @objc func expandAllCategories(_ send: UIButton) {
        itemVC?.expandAllCategories()
    }
    
    @objc func showHideCompletedItems(_ sender: UIButton) {
        showCompletedItems = !showCompletedItems
        itemVC?.showHideCompletedRows()
    }
    
    @objc func showHideInactiveItems(_ sender: UIButton) {
        showInactiveItems = !showInactiveItems
        itemVC?.showHideInactiveRows()
    }
    
    @objc func setAllItemsIncomplete(_ sender: UIButton) {
        itemVC?.setAllItemsIncomplete()
    }
    
    @objc func setAllItemsInactive(_ sender: UIButton) {
        itemVC?.setAllItemsInactive()
    }
    
    @objc func colorButton(_ sender: UIButton) {
        var color = "r1_2"
        var selectedButton: UIButton?
        
        switch sender.tag {
            case  1: color = r1_1; selectedButton = cb1_1
            case  2: color = r1_2; selectedButton = cb1_2
            case  3: color = r1_3; selectedButton = cb1_3
            case  4: color = r2_1; selectedButton = cb2_1
            case  5: color = r2_2; selectedButton = cb2_2
            case  6: color = r2_3; selectedButton = cb2_3
            case  7: color = r3_1; selectedButton = cb3_1
            case  8: color = r3_2; selectedButton = cb3_2
            case  9: color = r3_3; selectedButton = cb3_3
            case 10: color = r4_1; selectedButton = cb4_1
            case 11: color = r4_2; selectedButton = cb4_2
            case 12: color = r4_3; selectedButton = cb4_3
            default: color = r1_2; selectedButton = cb1_2
        }
        
        // put a white box around the selected color button
        self.highlightSelectedColorBox(selectedButton!)
        
        itemVC?.list.listColorName = color
        itemVC?.tableView.reloadData()
        
        // update the list color bar
        if let listVC = appDelegate.listViewController?.tableView {
            listVC.reloadData()
            itemVC?.appDelegate.saveListData(async: true)
        }
    }
    
    func highlightSelectedColorBox(_ selectedButton: UIButton) {
        // erase any current borders
        for (button, _) in colorButtons {
            button.layer.borderColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0).cgColor
        }
        
        // highlight the new selected color box
        selectedButton.layer.borderColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0).cgColor
    }
    
    @objc func noteButtonChanged() {
        showNotes = !showNotes
    }
    
    @objc func print() {
        // present the print dialog
        itemVC?.presentPrintDialog()
        
        // dismiss settings view controller
        close()
    }
    
    @objc func email() {
        // schedule the email dialog
        itemVC?.scheduleEmailDialog()
        
        // dismiss settings view controller
        close()
    }
    
    @objc func close() {
        itemVC?.appDelegate.saveListData(async: true)
        presentingViewController!.dismiss(animated: true, completion: nil)
    }
}
