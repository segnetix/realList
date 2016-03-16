//
//  ItemViewController.swift
//  ListApp
//
//  Created by Steven Gentry on 12/30/15.
//  Copyright © 2015 Steven Gentry. All rights reserved.
//

import UIKit
import QuartzCore
import iAd

let itemCellID     = "ItemCell"
let categoryCellID = "CategoryCell"
let addItemCellId  = "AddItemCell"

enum InsertPosition {
    case Beginning
    case Middle
    case End
}

enum MoveDirection {
    case Up
    case Down
}

enum ItemViewCellType {
    case Item
    case Category
    case AddItem
}

let kItemViewScrollRate: CGFloat = 6.0
let kItemCellHeight: CGFloat = 56.0
let kCategoryCellHeight: CGFloat = 44.0
let kAddItemCellHeight: CGFloat = 44.0

class ItemViewController: UIViewController, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, ADBannerViewDelegate
{
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var adBanner: ADBannerView!
    
    var inEditMode = false
    var deleteItemIndexPath: NSIndexPath? = nil
    var editModeRow = -1
    var longPressGestureRecognizer: UILongPressGestureRecognizer? = nil
    var sourceIndexPath: NSIndexPath? = nil
    var movingFromIndexPath: NSIndexPath? = nil
    var newCatIndexPath: NSIndexPath? = nil
    var prevLocation: CGPoint? = nil
    var snapshot: UIView? = nil
    var displayLink: CADisplayLink? = nil
    var longPressActive = false
    var editingNewItemName = false
    var editingNewCategoryName = false
    var showAdBanner = true
    let settingsTransitionDelegate = SettingsTransitioningDelegate()
    let itemDetailTransitionDelegate = ItemDetailTransitioningDelegate()
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var list: List! {
        didSet {
            if tableView != nil {
                self.refreshItems()
            }
        }
    }
    
////////////////////////////////////////////////////////////////
//
//  MARK: - Table set up methods
//
////////////////////////////////////////////////////////////////
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        adBanner.delegate = self
        
        // Uncomment the following line to preserve selection between presentations
        //self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        //self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        // set up long press gesture recognizer for the cell move functionality
        longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "longPressAction:")
        self.tableView.addGestureRecognizer(longPressGestureRecognizer!)

        // settings button
        let settingsButton: UIButton = UIButton(type: UIButtonType.Custom)
        settingsButton.setImage(UIImage(named: "settings"), forState: .Normal)
        settingsButton.frame = CGRectMake(0, 0, 30, 30)
        settingsButton.addTarget(self, action: Selector("settingsButtonTapped"), forControlEvents: .TouchUpInside)
        let rightBarButton = UIBarButtonItem()
        rightBarButton.customView = settingsButton
        self.navigationItem.rightBarButtonItem = rightBarButton
        
        // settingsVC
        modalPresentationStyle = UIModalPresentationStyle.Custom
        
        // set up keyboard show/hide notifications
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
        
        refreshItems()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        //print("viewWillTransitionToSize... \(size)")

    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
    }
    
    override func viewWillLayoutSubviews() {
        //print("viewWillLayoutSubviews with width: \(self.view.frame.width)")
        
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
////////////////////////////////////////////////////////////////
//
//  MARK: - Table view data source methods
//
////////////////////////////////////////////////////////////////
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        // return the total number of rows in our item table view (categories + items)
        if let list = list {
            let displayCount = list.totalDisplayCount()
            
            return displayCount
        } else {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let obj = list.objectForIndexPath(indexPath)
        let tag = obj != nil ? obj!.tag() : -1
        
        if obj is Item {
            // item cell
            let cell = tableView.dequeueReusableCellWithIdentifier(itemCellID, forIndexPath: indexPath) as! ItemCell
            let item = obj as! Item
            let tag = item.tag()
            
            // Configure the cell...
            cell.itemName.userInteractionEnabled = false
            cell.itemName.delegate = self
            cell.itemName.addTarget(self, action: "itemNameDidChange:", forControlEvents: UIControlEvents.EditingChanged)
            cell.itemName.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
            cell.itemName!.tag = tag
            cell.contentView.tag = tag
            
            // set up single tap gesture recognizer in cat cell to enable expand/collapse
            let singleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: "cellSingleTapAction:")
            singleTapGestureRecognizer.numberOfTapsRequired = 1
            cell.contentView.addGestureRecognizer(singleTapGestureRecognizer)
            
            // set up double tap gesture recognizer in item cell to enable cell moving
            let doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: "cellDoubleTapAction:")
            doubleTapGestureRecognizer.numberOfTapsRequired = 2
            singleTapGestureRecognizer.requireGestureRecognizerToFail(doubleTapGestureRecognizer)
            cell.contentView.addGestureRecognizer(doubleTapGestureRecognizer)

            cell.checkBox.checkBoxInit(item, list: list, itemVC: self, tag: tag)
            
            // set item name
            let title = list.titleForObjectAtIndexPath(indexPath)
            if let cellTitle = title {
                cell.itemName.text = cellTitle //+ "\(tag)"
            } else {
                cell.itemName.text = "cellTitle is nil"
            }
            
            // set item name text color
            if item.state == ItemState.Inactive {
                cell.itemName.textColor = UIColor.lightGrayColor()
            } else {
                cell.itemName.textColor = UIColor.blackColor()
            }
            
            // set item note
            cell.itemNote.text = item.note
            cell.itemNote.textColor = UIColor.lightGrayColor()
            
            // cell separator
            cell.preservesSuperviewLayoutMargins = false
            cell.separatorInset = UIEdgeInsetsZero
            cell.layoutMargins = UIEdgeInsetsZero
            
            // separator color
            if list.listColor != nil {
                self.tableView.separatorColor = list.listColor
            } else {
                self.tableView.separatorColor = UIColor.darkGrayColor()
            }
            
            cell.backgroundColor = UIColor.whiteColor()
            cell.delegate = self
            
            return cell
        } else if obj is Category  {
            // category cell
            let cell = tableView.dequeueReusableCellWithIdentifier(categoryCellID, forIndexPath: indexPath) as! CategoryCell
            let category = obj as! Category
            let tag = category.tag()
            
            // Configure the cell...
            cell.categoryName.userInteractionEnabled = false
            cell.categoryName.delegate = self
            cell.categoryName.addTarget(self, action: "itemNameDidChange:", forControlEvents: UIControlEvents.EditingChanged)
            cell.categoryName.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
            cell.categoryName!.tag = tag
            cell.contentView.tag = tag
            
            // set up single tap gesture recognizer in cat cell to enable expand/collapse
            let singleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: "cellSingleTapAction:")
            singleTapGestureRecognizer.numberOfTapsRequired = 1
            cell.contentView.addGestureRecognizer(singleTapGestureRecognizer)
            
            // set up double tap gesture recognizer in cat cell to enable cell moving
            let doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: "cellDoubleTapAction:")
            doubleTapGestureRecognizer.numberOfTapsRequired = 2
            singleTapGestureRecognizer.requireGestureRecognizerToFail(doubleTapGestureRecognizer)
            cell.contentView.addGestureRecognizer(doubleTapGestureRecognizer)
            
            // category title
            let title = list.titleForObjectAtIndexPath(indexPath)
            if let cellTitle = title {
                cell.categoryName?.text = cellTitle// + "\(tag)"
            } else {
                cell.categoryName?.text = ""
            }
            
            // catCountLabel
            cell.catCountLabel.text = categoryCountString(category)
            cell.catCountLabel.textAlignment = NSTextAlignment.Right
            
            // cell separator
            cell.preservesSuperviewLayoutMargins = false
            cell.separatorInset = UIEdgeInsetsZero
            cell.layoutMargins = UIEdgeInsetsZero
            
            // cat cell background color
            if list.listColor != nil {
                cell.backgroundColor = list.listColor
            } else {
                cell.backgroundColor = UIColor.lightGrayColor()
            }
            
            //cell.delegate = self
            
            return cell
         } else {
            // set up AddItem row
            let cell = tableView.dequeueReusableCellWithIdentifier(addItemCellId) as! AddItemCell
            
            // cell separator
            cell.preservesSuperviewLayoutMargins = false
            cell.separatorInset = UIEdgeInsetsZero
            cell.layoutMargins = UIEdgeInsetsZero
            
            // set up cell tag for later id
            cell.addItemButton.tag = tag
            
            return cell
        }
        
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let obj = list.objectForIndexPath(indexPath)
        if obj is Item {
            return kItemCellHeight
        } else if obj is Category {
            return kCategoryCellHeight
        } else {
            return kAddItemCellHeight
        }
    }
    
    /*
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if list.cellIsItem(indexPath) {
            return kItemCellHeight
        } else {
            return kItemCellHeight
        }
        //return UITableViewAutomaticDimension
    }
    */
    
    /*
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        print("didSelectRowAtIndexPath...!!!")
    }
    */
    
    // override to support conditional editing of the table view
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        let obj = list.objectForIndexPath(indexPath)
        
        return obj is Item || obj is Category
    }
    
    // override to support editing the table view
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath)
    {
        if editingStyle == .Delete {
            deleteItemIndexPath = indexPath
            let deletedItem = list.objectForIndexPath(indexPath)
            
            if deletedItem is Item {
                confirmDelete((deletedItem as! Item).name, isItem: true)
            } else if deletedItem is Category {
                confirmDelete((deletedItem as! Category).name, isItem: false)
            }
        }
    }
    

////////////////////////////////////////////////////////////////
//
//  MARK: - TextField methods
//
////////////////////////////////////////////////////////////////
    
    
    func keyboardWillShow(notification: NSNotification)
    {
        inEditMode = true
        
        var info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        let keyboardHeight = keyboardFrame.height
        
        // need to shrink the tableView height so it shows above the keyboard
        self.tableView.frame.size.height = self.view.frame.height - keyboardHeight
        
        // while the keyboard is visible
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
    }
    
    func keyboardWillHide(notification: NSNotification)
    {
        inEditMode = false
        editingNewCategoryName = false
        editingNewItemName = false
        
        // need to restore the tableView frame based on presence of the ad banner
        let bannerHeight = adBanner.frame.size.height
        let bannerXpos = self.view.frame.size.height
        
        if showAdBanner || adBanner.bannerLoaded {
            self.tableView.frame.size.height = self.view.frame.height - bannerHeight
            adBanner.frame.origin.y = bannerXpos - bannerHeight
        } else {
            self.tableView.frame.size.height = self.view.frame.height
            adBanner.frame.origin.y = bannerXpos
        }
        
        
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
    }
    
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool
    {
        let obj = list.objectForTag(textField.tag)
        
        // scroll the editing cell into view if necessary
        if obj != nil {
            let indexPath = list.displayIndexPathForObj(obj!).indexPath
            
            if indexPath != nil {
                if self.tableView.indexPathsForVisibleRows?.contains(indexPath!) == false
                {
                    tableView.scrollToRowAtIndexPath(indexPath!, atScrollPosition: UITableViewScrollPosition.Bottom, animated: false)
                }
            }
        }
        
        // this clears an initial space in a new cell name
        if textField.text == " " {
            textField.text = ""
        }
        
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool
    {
        textField.userInteractionEnabled = false
        textField.resignFirstResponder()
        self.tableView.setEditing(false, animated: true)

        // delete the newly added item if user didn't create a name
        if editingNewItemName
        {
            if textField.text!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()).isEmpty
            {
                // remove last item from category
                list.categories[list.categories.count-1].items.removeLast()
                self.tableView.reloadData()
                list.updateIndices()
            }
            editingNewItemName = false
        } else if editingNewCategoryName
        {
            if textField.text!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()).isEmpty
            {
                // remove last category from list
                list.categories.removeLast()
                self.tableView.reloadData()
                list.updateIndices()
            }
            editingNewCategoryName = false
        }
        
        appDelegate.saveListData(true)
        
        // the following code should be handled by the call above to saveListData
        /*
        // update object change in cloud
        let obj = list.objectForTag(textField.tag)
        
        if obj is Category {
            let category = obj as! Category
            if list.listRecord != nil {
                category.saveToCloud(list.listRecord!)
            }
        } else if obj is Item {
            let item = obj as! Item
            let category = list.categoryForObj(item)
            if category != nil && category?.categoryRecord != nil {
                item.saveToCloud(category!.categoryRecord!)
            }
        }
        */
        
        return true
    }
    
    func itemNameDidChange(textField: UITextField)
    {
        // update item name data with new value
        let newName = textField.text!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        list.updateObjNameAtTag(textField.tag, name: newName)
    }
    
    @IBAction func addItemButtonTapped(sender: UIButton)
    {
        // create a new item and append to the category of the add button
        let category = list.categoryForTag(sender.tag)
        var newItem: Item? = nil
        
        if let category = category {
            newItem = list.addItem(category, name: "", state: ItemState.Incomplete, updateIndices: true, createRecord: true)
        }
        
        list.updateIndices()
        self.tableView.reloadData()
        self.resetCellViewTags()
        
        if let item = newItem {
            let newItemIndexPath = list.displayIndexPathForItem(item)
            
            if let indexPath = newItemIndexPath {
                let cell = tableView.cellForRowAtIndexPath(indexPath) as! ItemCell
                
                cell.itemName.userInteractionEnabled = true
                cell.itemName.becomeFirstResponder()
                editingNewItemName = true
            }
        }
    }
    
    func addNewCategory()
    {
        var newCategory: Category
        
        if list.categories[0].displayHeader == false {
            // we will use the existing (hidden) category header
            newCategory = list.categories[0]
            newCategory.displayHeader = true
            newCatIndexPath = NSIndexPath(forRow: 0, inSection: 0)
        } else  {
            // we need a new category
            newCategory = list.addCategory("", displayHeader: true, updateIndices: true, createRecord: true)
            newCatIndexPath = list.displayIndexPathForCategory(newCategory)
        }
        
        list.updateIndices()
        self.tableView.reloadData()
        
        if let indexPath = newCatIndexPath
        {
            // need to scroll the target cell into view so the tags can be updated
            if self.tableView.indexPathsForVisibleRows?.contains(indexPath) == false
            {
                self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: indexPath.row, inSection: 0), atScrollPosition: UITableViewScrollPosition.Bottom, animated: false)
                self.resetCellViewTags()
                
                // set up a selector event to fire when the new cell has scrolled into place
                NSObject.cancelPreviousPerformRequestsWithTarget(self)
                self.performSelector("scrollToCategoryEnded:", withObject: nil, afterDelay: 0.5)
            } else {
                // new cell is already visible
                print("new cell is already visible")
                let cell = tableView.cellForRowAtIndexPath(indexPath) as! CategoryCell
                
                cell.categoryName.userInteractionEnabled = true
                cell.categoryName.becomeFirstResponder()
                editingNewCategoryName = true
                editingNewItemName = false
                newCatIndexPath = nil
            }
        }
        
        appDelegate.saveAll()
    }
    
    func collapseAllCategories() {
        print("collapseAllCategories")
        
        for category in list.categories {
            if category.expanded == true {
                category.expanded = false
                handleCategoryCollapseExpand(category)
            }
        }
    }
    
    func expandAllCategories() {
        print("expandAllCategories")
        
        for category in list.categories {
            if category.expanded == false {
                category.expanded = true
                handleCategoryCollapseExpand(category)
            }
        }
    }
    
    func scrollToCategoryEnded(scrollView: UIScrollView)
    {
        NSObject.cancelPreviousPerformRequestsWithTarget(self)
        
        let cell = tableView.cellForRowAtIndexPath(newCatIndexPath!) as! CategoryCell
        
        cell.categoryName.userInteractionEnabled = true
        cell.categoryName.becomeFirstResponder()
        editingNewCategoryName = true
        editingNewItemName = false
        newCatIndexPath = nil
    }
    
    func categoryCountString(category: Category) -> String
    {
        return "\(category.itemsComplete())/\(category.items.count)"
    }

    func handleCategoryCollapseExpand(category: Category)
    {
        // get display index paths for this category
        let indexPaths = list.displayIndexPathsForCategory(category, includeAddItemIndexPath: true)    // includes AddItem cell path
        
        self.tableView.beginUpdates()
        if category.expanded {
            // insert the expanded rows into the table view
            self.tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: UITableViewRowAnimation.Automatic)
        } else {
            // remove the collapsed rows from the table view
            self.tableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: UITableViewRowAnimation.Automatic)
        }
        self.tableView.endUpdates()
    }
    
////////////////////////////////////////////////////////////////
//
//  MARK: - Gesture Recognizer methods
//
////////////////////////////////////////////////////////////////
    
    /// Respond to a single tap (toggle expand/collapse state of category).
    func cellSingleTapAction(sender: UITapGestureRecognizer)
    {
        if sender.view != nil
        {
            let tag = sender.view!.tag
            let obj = list.objectForTag(tag)
            
            if obj is Category
            {
                if !inEditMode
                {
                    let category = obj as! Category
                    
                    // flip expanded state
                    category.expanded = !category.expanded
                    
                    handleCategoryCollapseExpand(category)
                    
                    if category.expanded {
                        // scroll the newly expanded header to the top so items can be seen
                        let indexPath = list.displayIndexPathForCategory(category)
                        if indexPath != nil {
                            self.tableView.scrollToRowAtIndexPath(indexPath!, atScrollPosition: UITableViewScrollPosition.Top, animated: true)
                        }
                    }
                    
                    //need to update the cellTypeArray after collapse/expand event
                    list.updateIndices()
                    
                    // this is needed so that operations that rely on view.tag (like this one!) will function correctly
                    self.resetCellViewTags()
                } else {
                    print("no toggle - inEditMode!")
                }
                
                // save expanded state change to the clould
                appDelegate.saveListData(true)
            } else if obj is Item {
                self.loadItemDetailView(obj as! Item)
            }
        } else {
            print("ERROR: cellSingleTapAction received a nil sender.view!")
        }
    }
    
    /// Respond to a double tap (cell name edit).
    func cellDoubleTapAction(sender: UITapGestureRecognizer)
    {
        if sender.view != nil {
            let obj = list.objectForTag(sender.view!.tag)
            let pathResult = list.displayIndexPathForObj(obj!)
            
            if let indexPath = pathResult.indexPath {
                if obj is Item {
                    let cell = tableView.cellForRowAtIndexPath(indexPath) as! ItemCell
                    
                    cell.itemName.userInteractionEnabled = true
                    cell.itemName.becomeFirstResponder()
                } else if obj is Category {
                    let cell = tableView.cellForRowAtIndexPath(indexPath) as! CategoryCell
                    
                    cell.categoryName.userInteractionEnabled = true
                    cell.categoryName.becomeFirstResponder()
                }
            }
        }
    }

    /// Handle long press gesture (cell move).
    func longPressAction(gesture: UILongPressGestureRecognizer)
    {
        let state: UIGestureRecognizerState = gesture.state
        let location: CGPoint = gesture.locationInView(tableView)
        let topBarHeight = getTopBarHeight()
        var indexPath: NSIndexPath? = tableView.indexPathForRowAtPoint(location)
        
        // prevent long press action on an AddItem cell
        if indexPath != nil {
            let cell = tableView.cellForRowAtIndexPath(indexPath!)
            
            if cell is AddItemCell
            {
                // we got a long press action on the AddItem cell...
                
                // if it is the last AddItem cell, then we are moving down past the bottom of the tableView, so end the long press
                if list.indexPathIsLastRowDisplayed(indexPath!) && longPressActive
                {
                    longPressEnded(movingFromIndexPath, location: location)
                    return
                }
            }
        }
        
        // check if we need to end scrolling
        let touchLocationInWindow = tableView.convertPoint(location, toView: tableView.window)
        
        // we need to end the long press if we move above the top cell and into the top bar
        if touchLocationInWindow.y <= topBarHeight && location.y <= 0
        {
            // if we moved above the table view then set the destination to the top cell and end the long press
            if longPressActive {
                indexPath = NSIndexPath(forRow: 0, inSection: 0)
                longPressEnded(indexPath, location: location)
            }
            return
        }
        
        // check if we need to scroll tableView
        let touchLocation = gesture.locationInView(gesture.view!.window)
        
        if touchLocation.y > (tableView.bounds.height - kScrollZoneHeight) {
            // need to scroll down
            if displayLink == nil {
                displayLink = CADisplayLink(target: self, selector: Selector("scrollDownLoop"))
                displayLink!.frameInterval = 1
                displayLink!.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
            }
        } else if touchLocation.y < (topBarHeight + kScrollZoneHeight) {
            // need to scroll up
            if displayLink == nil {
                displayLink = CADisplayLink(target: self, selector: Selector("scrollUpLoop"))
                displayLink!.frameInterval = 1
                displayLink!.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
            }
        } else if displayLink != nil {
            // check if we need to cancel a current scroll update because the touch moved out of scroll area
            if touchLocation.y < (tableView.bounds.height - kScrollZoneHeight) {
                displayLink!.invalidate()
                displayLink = nil
            } else if touchLocation.y > (topBarHeight + kScrollZoneHeight) {
                displayLink!.invalidate()
                displayLink = nil
            }
        }

        // if indexPath is null then we took our dragged cell some direction off the table
        if indexPath == nil {
            if gesture.state != .Cancelled {
                gesture.enabled = false
                gesture.enabled = true
                longPressEnded(movingFromIndexPath, location: location)
            }
            
            return
        }
        
        // also need to prevent moving above the top category cell if we are moving an item
        // this will effectively fix the top category to the top of the view
        indexPath = adjustIndexPathIfItemMovingAboveTopRow(indexPath!)
        
        switch (state)
        {
        case UIGestureRecognizerState.Began:
            self.longPressBegan(indexPath!, location: location)
            prevLocation = location
            
        case UIGestureRecognizerState.Changed:
            // long press has moved - call move method
            self.longPressMoved(indexPath!, location: location)
            prevLocation = location
            
        default:
            // long press has ended - call clean up method
            self.longPressEnded(indexPath!, location: location)
            prevLocation = nil
            
        }   // end switch
        
    }
    
    func longPressBegan(indexPath: NSIndexPath, location: CGPoint)
    {
        longPressActive = true
        sourceIndexPath = indexPath
        movingFromIndexPath = indexPath
        let cell = tableView.cellForRowAtIndexPath(indexPath)!
        snapshot = snapshotFromView(cell)
        
        let obj = list.objectForIndexPath(indexPath)
        
        if obj is Item || obj is Category {
            var center = cell.center
            snapshot?.center = center
            snapshot?.alpha = 0.0
            tableView.addSubview(snapshot!)
            
            UIView.animateWithDuration(0.25, animations: { () -> Void in
                center.y = location.y
                self.snapshot?.center = center
                self.snapshot?.transform = CGAffineTransformMakeScale(1.05, 1.05)
                self.snapshot?.alpha = 0.98
                cell.alpha = 0.0
                }, completion: { (finished: Bool) -> Void in
                    cell.hidden = true      // hides the real cell while moving
            })
        }
    }
    
    func longPressMoved(var indexPath: NSIndexPath?, location: CGPoint)
    {
        if prevLocation == nil {
            return  
        }
        
        if indexPath != nil {
            // if an item, then adjust indexPath if necessary so we don't move above top-most category
            indexPath = adjustIndexPathIfItemMovingAboveTopRow(indexPath!)
        }
        
        if snapshot != nil {
            var center: CGPoint = snapshot!.center
            center.y = location.y
            snapshot?.center = center
            
            if indexPath != nil && location.y > 0 {
                // check if destination is different from source and valid then move the cell in the tableView
                if indexPath != sourceIndexPath && movingFromIndexPath != nil
                {
                    // adjust dest index path if we moved over an AddCell/Category pair (which should be kept together)
                    if cellAtIndexPathIsAddCellCategoryPair(indexPath!)
                    {
                        let moveDirection = location.y < prevLocation!.y ? MoveDirection.Up : MoveDirection.Down
                        
                        if moveDirection == .Down {
                            let rowCount = list.totalDisplayCount()
                            // this is to prevent dragging past the last row
                            if indexPath!.row < rowCount-1 {
                                indexPath = NSIndexPath(forRow: indexPath!.row + 1, inSection: 0)
                            } else {
                                indexPath = NSIndexPath(forRow: indexPath!.row, inSection: 0)
                            }
                        } else {
                            indexPath = NSIndexPath(forRow: indexPath!.row - 1, inSection: 0)
                        }
                    }
                    
                    // ... move the rows
                    tableView.moveRowAtIndexPath(movingFromIndexPath!, toIndexPath: indexPath!)

                    // ... and update movingFromIndexPath so it is in sync with UI changes
                    movingFromIndexPath = indexPath
                }
            }
        }
    }
    
    /// Clean up after a long press gesture.
    func longPressEnded(indexPath: NSIndexPath?, location: CGPoint)
    {
        longPressActive = false
        
        // cancel any scroll loop
        displayLink?.invalidate()
        displayLink = nil
        
        // finalize list data with new location for srcIndexObj
        if sourceIndexPath != nil
        {
            var center: CGPoint = snapshot!.center
            center.y = location.y
            snapshot?.center = center
            
            // check if destination is different from source and is valid
            if indexPath != nil && indexPath != sourceIndexPath
            {
                let moveDirection = sourceIndexPath!.row >  indexPath!.row ? MoveDirection.Up : MoveDirection.Down
                let srcDataObj = list.objectForIndexPath(sourceIndexPath!)
                let destDataObj = list.objectForIndexPath(indexPath!)
                
                // move cells, update the list data source, move items and categories differently
                if srcDataObj is Item
                {
                    let srcItem = srcDataObj as! Item
                    
                    // we are moving an item
                    tableView.beginUpdates()
                    
                    // remove the item from its original location
                    list.removeItem(srcItem, updateIndices: true)
                    //print("removeItem... \(srcItem.name)")
                    
                    // insert the item at its new location
                    if destDataObj is Item
                    {
                        let destItem = destDataObj as! Item
                        if moveDirection == .Down {
                            list.insertItem(srcItem, afterObj: destItem, updateIndices: true)
                        } else {
                            list.insertItem(srcItem, beforeObj: destItem, updateIndices: true)
                        }
                        //print("insertItem... \(destItem.name)")
                    }
                    else if destDataObj is Category
                    {
                        var destCat = destDataObj as! Category
                        
                        if moveDirection == .Down {
                            list.insertItem(srcItem, afterObj: destCat, updateIndices: true)
                        } else {
                            destCat = list.insertItem(srcItem, beforeObj: destCat, updateIndices: true)
                        }
                        
                        // if moving to a collapsed category, then need to remove the row from the table as it will no longer be displayed
                        if destCat.expanded == false {
                            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
                        }
                    }
                    else if destDataObj is AddItem
                    {
                        let addItem = destDataObj as! AddItem
                        
                        // moving to AddItem cell, so drop just above the AddItem cell
                        let destCat = list.categoryForObj(addItem)
                        
                        if destCat != nil {
                            list.insertItem(srcItem, inCategory: destCat!, atPosition: .End, updateIndices: true)
                        }
                    }
                    
                    //print("moving row from \(sourceIndexPath?.row) to \(indexPath!.row)")
                    
                    tableView.endUpdates()
                }
                else if srcDataObj is Category
                {
                    // we are moving a category
                    let srcCategory = srcDataObj as! Category
                    let srcCategoryIndex = srcCategory.categoryIndex
                    var dstCategoryIndex = destDataObj!.categoryIndex
                    
                    // this is so dropping a category on an item will only move the category if the item is above the dest category when moving up
                    let moveDirection = sourceIndexPath!.row >  indexPath!.row ? MoveDirection.Up : MoveDirection.Down
                    
                    if moveDirection == .Up && destDataObj is Item && dstCategoryIndex >= 0 {
                        ++dstCategoryIndex
                    }
                    
                    //print("srcCategoryIndex: \(srcCategoryIndex)  dstCategoryIndex: \(dstCategoryIndex)")
                    
                    if srcCategoryIndex >= 0 && dstCategoryIndex >= 0 {
                        tableView.beginUpdates()
                        
                        // remove the category from its original location
                        list.removeCatetoryAtIndex(srcCategoryIndex)
                        
                        list.insertCategory(srcCategory, atIndex: dstCategoryIndex)
                        
                        tableView.endUpdates()
                    }
                }
            }
        } else {
            print("sourceIndexPath is nil...")
        }
        
        // clean up any snapshot views or displayLink scrolls
        var cell: UITableViewCell? = nil
        
        if indexPath != nil {
            cell = tableView.cellForRowAtIndexPath(indexPath!)
        }
        
        cell?.alpha = 0.0
        UIView.animateWithDuration(0.25, animations: { () -> Void in
            if cell != nil {
                self.snapshot?.center = cell!.center
            }
            self.snapshot?.transform = CGAffineTransformIdentity
            self.snapshot?.alpha = 0.0
            
            // undo fade out
            cell?.alpha = 1.0
            }, completion: { (finished: Bool) -> Void in
                self.sourceIndexPath = nil
                self.snapshot?.removeFromSuperview()
                self.snapshot = nil
                self.tableView.reloadData()
        })
        
        self.prevLocation = nil
        self.displayLink?.invalidate()
        self.displayLink = nil
        
        appDelegate.saveListData(true)
    }
    
    func scrollUpLoop()
    {
        let currentOffset = tableView.contentOffset
        let topBarHeight = getTopBarHeight()
        let newOffsetY = max(currentOffset.y - kItemViewScrollRate, -topBarHeight)
        let location: CGPoint = longPressGestureRecognizer!.locationInView(tableView)
        let indexPath: NSIndexPath? = tableView.indexPathForRowAtPoint(location)
        
        self.tableView.setContentOffset(CGPoint(x: currentOffset.x, y: newOffsetY), animated: false)
        
        if let path = indexPath {
            longPressMoved(path, location: location)
            prevLocation = location
        }
    }
    
    func scrollDownLoop()
    {
        let currentOffset = tableView.contentOffset
        let lastCellIndex = NSIndexPath(forRow: list.totalDisplayCount() - 1, inSection: 0)
        let lastCell = tableView.cellForRowAtIndexPath(lastCellIndex)
        
        if lastCell == nil {
            self.tableView.setContentOffset(CGPoint(x: currentOffset.x, y: currentOffset.y + kItemViewScrollRate), animated: false)
            
            let location: CGPoint = longPressGestureRecognizer!.locationInView(tableView)
            let indexPath: NSIndexPath? = tableView.indexPathForRowAtPoint(location)
            
            if let path = indexPath {
                longPressMoved(path, location: location)
                prevLocation = location
            }
        } else {
            self.tableView.scrollToRowAtIndexPath(lastCellIndex, atScrollPosition: .Bottom, animated: true)
        }
    }
    
////////////////////////////////////////////////////////////////
//
//  MARK: - Delete methods
//
////////////////////////////////////////////////////////////////
    
    func confirmDelete(objName: String, isItem: Bool)
    {
        let DeleteItemTitle = NSLocalizedString("Delete_Item_Title", comment: "A title in an alert asking if the user wants to delete an item.")
        let DeleteItemMessage = String(format: NSLocalizedString("Delete_Item_Message", comment: "Are you sure you want to permanently delete the item %@?"), objName)
        let DeleteCategoryTitle = NSLocalizedString("Delete_Category_Title", comment: "A title in an alert asking if the user wants to delete a category.")
        let DeleteCategoryMessage = String(format: NSLocalizedString("Delete_Category_Message", comment: "Are you sure you want to permanently delete the category %@ and all of the items in it?"), objName)
        
        let alert = UIAlertController(title: isItem ? DeleteItemTitle : DeleteCategoryTitle, message: isItem ? DeleteItemMessage : DeleteCategoryMessage, preferredStyle: .Alert)
        let deleteAction = UIAlertAction(title: NSLocalizedString("Delete", comment: "The Delete button title"), style: .Destructive, handler: handleDeleteItem)
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "The Cancel button title"), style: .Cancel, handler: cancelDeleteItem)
        
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        
        // Support display in iPad
        alert.popoverPresentationController?.sourceView = self.view
        alert.popoverPresentationController?.sourceRect = CGRectMake(self.view.bounds.size.width / 2.0, self.view.bounds.size.height / 2.0, 1.0, 1.0)
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func handleDeleteItem(alertAction: UIAlertAction!) -> Void
    {
        if let indexPath = deleteItemIndexPath, currentList = list
        {
            tableView.beginUpdates()
            
            // Delete the row(s) from the data source and return display paths of the removed rows
            var removedPaths: [NSIndexPath]
            var preserveCat = true
            
            let deleteObj = currentList.objectForIndexPath(indexPath)
            
            if deleteObj is Category {
                preserveCat = false
                let cat = deleteObj as! Category
                cat.deleteFromCloud()
            } else if deleteObj is Item {
                let item = deleteObj as! Item
                item.deleteFromCloud()
            }
            
            // model delete
            removedPaths = currentList.removeItemAtIndexPath(indexPath, preserveCategories: preserveCat, updateIndices: true)
            
            // table view delete
            tableView.deleteRowsAtIndexPaths(removedPaths, withRowAnimation: .Automatic)
            
            deleteItemIndexPath = nil
            
            tableView.endUpdates()
            
            resetCellViewTags()
        } else {
            print("ERROR: handleDeleteItem received a null indexPath or list!")
        }
    }
    
    func cancelDeleteItem(alertAction: UIAlertAction!)
    {
        deleteItemIndexPath = nil
        self.tableView.setEditing(false, animated: true)
    }
    
////////////////////////////////////////////////////////////////
//
//  MARK: - Helper methods
//
////////////////////////////////////////////////////////////////
    
    func refreshItems()
    {
        if list != nil {
            self.title = list!.name
            tableView.reloadData()
        } else {
            self.title = NSLocalizedString("Items", comment: "Items - the view controller title for and empty list of items.")
            tableView.reloadData()
        }
    }
    
    func colorForIndex(index: Int) -> UIColor
    {
        return UIColor.whiteColor()
        /*
        let itemCount = list.totalDisplayCount() - 1
        let val = (CGFloat(index) / CGFloat(itemCount)) * 0.99
        return UIColor(red: 0.0, green: val, blue: 1.0, alpha: 0.5)
        */
    }

    func snapshotFromView(inputView: UIView) -> UIView
    {
        // Make an image from the input view.
        UIGraphicsBeginImageContextWithOptions(inputView.bounds.size, false, 0)
        if let context = UIGraphicsGetCurrentContext()
        {
            inputView.layer.renderInContext(context)
        }
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // Create an image view.
        let snapshot = UIImageView(image: image)
        snapshot.layer.masksToBounds = false
        snapshot.layer.cornerRadius = 0.0
        snapshot.layer.shadowOffset = CGSize(width: -5.0, height: 0.0)
        snapshot.layer.shadowRadius = 5.0
        snapshot.layer.shadowOpacity = 0.4
        
        return snapshot
    }
    
    // resets the cell's tags after a collapse/expand event
    // NOTE: this only updates the tags for visible cells
    func resetCellViewTags()
    {
        if list != nil {
            var cell: UITableViewCell? = nil
            var index = -1
            
            repeat {
                let indexPath = NSIndexPath(forRow: ++index, inSection: 0)
                cell = tableView.cellForRowAtIndexPath(indexPath)
                    
                if cell != nil {
                    let tag = list.tagValueForIndexPath(indexPath)
                    
                    if cell is ItemCell {
                        let itemCell = cell as! ItemCell
                        itemCell.itemName!.tag = tag
                        itemCell.checkBox!.tag = tag
                    } else if cell is CategoryCell {
                        (cell as! CategoryCell).categoryName!.tag = tag
                    } else if cell is AddItemCell {
                        (cell as! AddItemCell).addItemButton.tag = tag
                    }
                    
                    cell!.contentView.tag = tag
                }
                
            } while index < list.totalDisplayCount()
        }
    }
    
    func rowAtIndexPathIsVisible(indexPath: NSIndexPath) -> Bool
    {
        let indicies = self.tableView.indexPathsForVisibleRows
        
        if indicies != nil {
            return indicies!.contains(indexPath)
        }
        
        return false
    }
    
    func adjustIndexPathIfItemMovingAboveTopRow(var indexPath: NSIndexPath) -> NSIndexPath
    {
        if sourceIndexPath != nil
        {
            let srcObj = tableView.cellForRowAtIndexPath(sourceIndexPath!)
        
            if srcObj is ItemCell && indexPath.row == 0
            {
                let obj = tableView.cellForRowAtIndexPath(indexPath)
                
                if obj is CategoryCell {
                    indexPath = NSIndexPath(forRow: 1, inSection: 0)
                }
            }
        }
        
        return indexPath
    }
    
    /// Returns true if the cell at the given index path is part of an AddCell/Category pair.
    func cellAtIndexPathIsAddCellCategoryPair(indexPath: NSIndexPath) -> Bool
    {
        let row = indexPath.row
        let nextRow = row + 1
        let prevRow = row - 1
        var isPair = false
        
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        let nextCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: nextRow, inSection: 0))
        let prevCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: prevRow, inSection: 0))
        
        if cell is ItemCell {
            return false
        }
        
        if cell is AddItemCell && nextCell is CategoryCell {
            isPair = true
        } else if cell is CategoryCell && prevCell is AddItemCell {
            isPair = true
        }
        
        return isPair
    }

    // calculates the top bar height, inlcuding the status bar and nav bar (if present)
    func getTopBarHeight() -> CGFloat
    {
        let statusBarHeight = UIApplication.sharedApplication().statusBarFrame.size.height
        let navBarHeight = self.navigationController!.navigationBar.frame.size.height
        
        return statusBarHeight + navBarHeight
    }

    func settingsButtonTapped()
    {
        //print("settings button tapped...")
        
        if let list = list {
            transitioningDelegate = settingsTransitionDelegate
            let vc = SettingsViewController()
            vc.transitioningDelegate = settingsTransitionDelegate
            vc.showCompletedItems = list.showCompletedItems
            vc.showInactiveItems = list.showInactiveItems
            vc.itemVC = self
            presentViewController(vc, animated: true, completion: nil)
        }

    }
    
    func loadItemDetailView(item: Item)
    {
        transitioningDelegate = itemDetailTransitionDelegate
        
        let vc = ItemDetailViewController(item: item, list: list, itemVC: self)      // pass item by reference to
        vc.transitioningDelegate = itemDetailTransitionDelegate
        
        presentViewController(vc, animated: true, completion: nil)
    }
    
////////////////////////////////////////////////////////////////
//
//  MARK: - ShowHideCompleted methods
//
////////////////////////////////////////////////////////////////
    
    /// Refreshes the ItemVC item rows with animation after a change to showHideCompleted
    func showHideCompletedRows()
    {
        // gets array of paths
        let indexPaths = list.indexPathsForCompletedRows()
        
        if list.showCompletedItems == false
        {
            // remove the completed rows
            self.tableView.beginUpdates()
            self.tableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: UITableViewRowAnimation.Automatic)
            self.tableView.endUpdates()
        }
        else
        {
            // insert the complete rows
            self.tableView.beginUpdates()
            self.tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: UITableViewRowAnimation.Automatic)
            self.tableView.endUpdates()
        }
   
        // need to update the cellTypeArray after show/hide event
        list.updateIndices()
    }
    
    /// Refreshes the ItemVC item rows with animation after a change to showHideInactive
    func showHideInactiveRows()
    {
        let indexPaths = list.indexPathsForInactiveRows()
        
        if list.showInactiveItems == false
        {
            // remove the inactive rows
            self.tableView.beginUpdates()
            self.tableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: UITableViewRowAnimation.Automatic)
            self.tableView.endUpdates()
        }
        else
        {
            // insert the inactive rows
            self.tableView.beginUpdates()
            self.tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: UITableViewRowAnimation.Automatic)
            self.tableView.endUpdates()
        }
        
        // need to update the cellTypeArray after show/hide event
        list.updateIndices()
    }
    
    func setAllItemsIncomplete() {
        list.setAllItemsIncomplete()
        tableView.reloadData()
    }
    
    func setAllItemsInactive() {
        list.setAllItemsInactive()
        tableView.reloadData()
    }
    
    // called from the checkBox button when it is tapped
    func checkButtonTapped(checkBox: CheckBox) {
        print("checkButtonTapped: \(checkBox.tag)")
        let senderItem = list.objectForTag(checkBox.tag)
        var indexPath: NSIndexPath? = nil
        
        if senderItem is Item {
            let item = senderItem as! Item
            indexPath = list.displayIndexPathForItem(item)
            
            // cycle item state
            item.state.next()
            
            // instead we will call saveListData - cloudOnly mode
            appDelegate.saveListData(true)
            
            // set item name text color
            if indexPath != nil {
                let cell = tableView.cellForRowAtIndexPath(indexPath!) as! ItemCell
                if item.state == ItemState.Inactive {
                    cell.itemName.textColor = UIColor.lightGrayColor()
                } else {
                    cell.itemName.textColor = UIColor.blackColor()
                }
            }
            
            // remove a newly completed row if we are hiding completed items
            if list.showCompletedItems == false && item.state == ItemState.Complete {
                if indexPath != nil {
                    self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
                }
            }
            
            // remove a newly inactive row if we are hiding inactive items
            if list.showInactiveItems == false && item.state == ItemState.Inactive {
                if indexPath != nil {
                    self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
                }
            }
            
            // need to update the counts in the cat cell count label
            if let category = list.categoryForObj(item) {
                if let catIndexPath = list.displayIndexPathForCategory(category) {
                    if self.tableView.indexPathsForVisibleRows?.contains(catIndexPath) == true {
                        let catCell = tableView.cellForRowAtIndexPath(catIndexPath) as! CategoryCell
                        catCell.catCountLabel.text = self.categoryCountString(category)
                    }
                }
            }
        } else {
            print("ERROR: checkButtonTapped received an index path that points to a non-item object!")
        }

    }
    
    // called after the item state has changed
    func checkButtonTapped_postStateChange(checkBox: CheckBox)
    {
        print("checkButtonTapped: \(checkBox.tag)")
        let senderItem = list.objectForTag(checkBox.tag)
        var indexPath: NSIndexPath? = nil
        
        if senderItem is Item {
            let item = senderItem as! Item
            indexPath = list.displayIndexPathForItem(item)
            
            // set item name text color
            if indexPath != nil {
                let cell = tableView.cellForRowAtIndexPath(indexPath!) as! ItemCell
                if item.state == ItemState.Inactive {
                    cell.itemName.textColor = UIColor.lightGrayColor()
                } else {
                    cell.itemName.textColor = UIColor.blackColor()
                }
            }
            
            // remove a newly completed row if we are hiding completed items
            if list.showCompletedItems == false && item.state == ItemState.Complete {
                if indexPath != nil {
                    self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
                }
            }
            
            // remove a newly inactive row if we are hiding inactive items
            if list.showInactiveItems == false && item.state == ItemState.Inactive {
                if indexPath != nil {
                    self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
                }
            }
            
            // need to update the counts in the cat cell count label
            if let category = list.categoryForObj(item) {
                if let catIndexPath = list.displayIndexPathForCategory(category) {
                    if self.tableView.indexPathsForVisibleRows?.contains(catIndexPath) == true {
                        let catCell = tableView.cellForRowAtIndexPath(catIndexPath) as! CategoryCell
                        catCell.catCountLabel.text = self.categoryCountString(category)
                    }
                }
            }
            
            // update the row after changes
            //if indexPath != nil {
            //    print("reloadRowsAtIndexPaths: \(indexPath!.row)")
            //    tableView.reloadRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
            //}
        } else {
            print("ERROR: checkButtonTapped received an index path that points to a non-item object!")
        }
    }
    
    // item array helper methods
    func arrayContainsItem(itemArray: [Item], item: Item) -> Bool
    {
        return indexOfItemInArray(itemArray, item: item) > -1
    }
    
    func indexOfItemInArray(itemArray: [Item], item: Item) -> Int
    {
        var i = -1
        
        for obj in itemArray {
            ++i
            if obj === item {
                return i
            }
        }
        return -1
    }
    
////////////////////////////////////////////////////////////////
//
//  MARK: - AdBanner methods
//
////////////////////////////////////////////////////////////////
    
    func bannerViewActionShouldBegin(banner: ADBannerView!, willLeaveApplication willLeave: Bool) -> Bool
    {
        print("Banner view is beginning an ad action")
        let shouldExecuteAction = self.allowActionToRun()     // your app implements this method
        
        if !willLeave && shouldExecuteAction
        {
            // insert code here to suspend any services that might conflict with the advertisement
        }
        
        return shouldExecuteAction;
    }
    
    func bannerViewActionDidFinish(banner: ADBannerView!) {
        // insert code here to resume any services paused by the ad banner action
        // must execute quickly
        print("bannerViewActionDidFinish")
    }
    
    func bannerViewDidLoadAd(banner: ADBannerView!) {
        //print("bannerViewDidLoadAd")
        self.adBanner.hidden = false
        
        self.layoutAnimated(true)
    }
    
    func bannerView(banner: ADBannerView!, didFailToReceiveAdWithError error: NSError!) {
        //print("didFailToReceiveAdWithError: \(error)")
        self.adBanner.hidden = true
        
        self.layoutAnimated(true)
    }
    
    func allowActionToRun() -> Bool {
        // determine if we will allow an add action to take over the screen

        return true
    }
    
    // move the adBanner on and off the screen
    func layoutAnimated(animated: Bool) {
        let bannerHeight = adBanner.frame.size.height
        let bannerXpos = self.view.frame.size.height
        
        if showAdBanner && adBanner.bannerLoaded {
            self.tableView.frame.size.height = self.view.frame.height - bannerHeight
            adBanner.frame.origin.y = bannerXpos - bannerHeight
        } else {
            self.tableView.frame.size.height = self.view.frame.height
            adBanner.frame.origin.y = bannerXpos
        }
        
        //print("showAdBanner: xPos \(adBanner.frame.origin.y)")
        
        UIView.animateWithDuration(animated ? 0.5 : 0.0, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
    }
    
}


////////////////////////////////////////////////////////////////
//
//  MARK: - Internal delegate methods
//
////////////////////////////////////////////////////////////////

// ListSelectionDelegate methods
extension ItemViewController: ListSelectionDelegate
{
    // called when the ListController changes the selected list
    func listSelected(newList: List) {
        list = newList
    }
    
    // called when the ListController changes the name of the list
    func listNameChanged(newName: String) {
        if list != nil {
            self.title = list!.name
        }
    }
    
    // called when the ListController deletes a list
    func listDeleted(deletedList: List) {
        if deletedList === list {
            // our current list is being deleted
            list = nil
        }
    }
}

// ItemCellDelegate methods
extension ItemViewController: ItemCellDelegate
{
    // gesture action methods called from the item cell
    /*
    func itemSingleTapAction(sender: UIGestureRecognizer)
    {
        // no action for items yet
    }
    */
    
    /*
    func itemDoubleTapAction(textField: UITextField)
    {
        print("item textField double tapped: '\(textField.text)'")
        cellDoubleTappedAction(textField)
    }
    */
}

// CategoryCellDelegate methods
extension ItemViewController: CategoryCellDelegate
{
    // gesture action methods called from the category cell
    
    /*
    func categorySingleTapAction(sender: UIGestureRecognizer)
    {
        cellSingleTappedAction(sender)
    }
    */
    
    /*
    func categoryDoubleTapAction(textField: UITextField)
    {
        print("cat textField double tapped: '\(textField.text)'")
        cellDoubleTappedAction(textField)
    }
    */
    
    /*
    func categoryLongPressAction(sender: UILongPressGestureRecognizer)
    {
        longPressedAction(sender)
    }
    */
}
