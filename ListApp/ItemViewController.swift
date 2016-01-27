//
//  ItemViewController.swift
//  ListApp
//
//  Created by Steven Gentry on 12/30/15.
//  Copyright © 2015 Steven Gentry. All rights reserved.
//

import UIKit
import QuartzCore
//import iAd

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
let kItemViewCellHeight: CGFloat = 52.0

class ItemViewController: UITableViewController, UITextFieldDelegate
{
    @IBOutlet weak var newCategoryButton: UIBarButtonItem!
    @IBOutlet weak var showHideCompletedButton: UIBarButtonItem!
    
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
    var scrollLoopCount = 0     // debugging var
    var longPressActive = false
    var editingNewItemName = false
    var editingNewCategoryName = false
    
    var list: List! {
        didSet (newList) {
            self.refreshItems()
        }
    }
    
    var showCompletedItems: Bool = true {
        didSet(newShow) {
            if showCompletedItems {
                showHideCompletedButton.title = "hide completed"
            } else {
                showHideCompletedButton.title = "show completed"
                // need to clear the array when first hiding completed items
                //itemsCompletedInHideCompletedItemsMode.removeAll()
            }
            
            if list != nil {
                list.showCompletedItems = self.showCompletedItems
            }
            
            self.updateShowHideCompletedRows()
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
        
        // Uncomment the following line to preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        //self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        // set up long press gesture recognizer for the cell move functionality
        longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "longPressAction:")
        self.tableView.addGestureRecognizer(longPressGestureRecognizer!)
        
        //self.tableView.estimatedRowHeight = kItemViewCellHeight
        //self.tableView.rowHeight = UITableViewAutomaticDimension
        
        //self.tableView.backgroundColor = UIColor.clearColor()
        
        //self.navigationController?.setToolbarHidden(false, animated: false)

        /*
        bannerView = ADBannerView(adType: .Banner)
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        bannerView.delegate = self
        bannerView.hidden = true
        view.addSubview(bannerView)
        
        let viewsDictionary = ["bannerView": bannerView]
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[bannerView]|", options: [], metrics: nil, views: viewsDictionary))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[bannerView]|", options: [], metrics: nil, views: viewsDictionary))
        */
        
        //let bannerHeight = bannerView.frame.height
        
        // adjust tableView for iAD banner
        //let insets = UIEdgeInsets(top: 100, left: 20, bottom: 100, right: 20)
        //self.tableView.contentInset = insets
        
        // Setting button
        //let settingsButton = UIButton()
        let settingsButton: UIButton = UIButton(type: UIButtonType.Custom)
        settingsButton.setImage(UIImage(named: "settings"), forState: .Normal)
        settingsButton.frame = CGRectMake(0, 0, 30, 30)
        settingsButton.addTarget(self, action: Selector("settingsButtonTapped"), forControlEvents: .TouchUpInside)
        let rightBarButton = UIBarButtonItem()
        rightBarButton.customView = settingsButton
        self.navigationItem.rightBarButtonItem = rightBarButton
        
        // set up keyboard show/hide notifications
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardDidShow", name: UIKeyboardDidShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardDidHide", name: UIKeyboardDidHideNotification, object: nil)
        
        refreshItems()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        //navigationController?.hidesBarsOnSwipe = true
        
        // in this case, it's good to combine hidesBarsOnTap with hidesBarsWhenKeyboardAppears
        // so the user can get back to the navigation bar to save
        //navigationController?.hidesBarsOnTap = true
        //navigationController?.hidesBarsWhenKeyboardAppears = true
        //navigationController?.hidesBarsOnSwipe = false
        
        // showHideCompletedButton state
        //self.setShowHideCompleted(true)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    required init(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)!
    }
    
////////////////////////////////////////////////////////////////
//
//  MARK: - Table view data source methods
//
////////////////////////////////////////////////////////////////
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        // return the total number of rows in our item table view (categories + items)
        if let list = list {
            let displayCount = list.totalDisplayCount()

            /*
            if itemsCompletedInHideCompletedItemsMode.count > 0 {
                print("tableView:numberOfRowsInSection itemsCompletedInHideCompletedItemsMode.count is > 0...!!!")
            }
            displayCount += itemsCompletedInHideCompletedItemsMode.count
            */
            
            return displayCount
        } else {
            return 0
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
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

            // set tempCheckButton state
            switch item.state {
            case ItemState.Inactive:
                cell.tempCheckButton.setTitle("INACT", forState: .Normal)
            case ItemState.Incomplete:
                cell.tempCheckButton.setTitle("INCMP", forState: .Normal)
            case ItemState.Complete:
                cell.tempCheckButton.setTitle("COMPL", forState: .Normal)
            }
            
            cell.tempCheckButton.tag = tag
            
            // item title
            let title = list.titleForObjectAtIndexPath(indexPath)
            if let cellTitle = title {
                cell.itemName.attributedText = makeAttributedString(title: cellTitle, subtitle: "\(cell.itemName.tag)")    // for debugging
                //cell.itemName.attributedText = makeAttributedString(title: cellTitle, subtitle: "")                      // for production
            } else {
                cell.itemName.attributedText = makeAttributedString(title: "cellTitle is nil", subtitle: "")
            }
            
            // cell separator
            cell.preservesSuperviewLayoutMargins = false
            cell.separatorInset = UIEdgeInsetsZero
            cell.layoutMargins = UIEdgeInsetsZero
            
            cell.backgroundColor = colorForIndex(indexPath.row)
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
                cell.categoryName?.attributedText = makeAttributedString(title: cellTitle, subtitle: "\(cell.categoryName.tag)")
                //cell.itemName?.attributedText = makeAttributedString(title: cellTitle, subtitle: "")
            } else {
                cell.categoryName?.attributedText = makeAttributedString(title: "", subtitle: "")
            }
            
            // catCountLabel
            cell.catCountLabel.attributedText = categoryCountString(category)
            cell.catCountLabel.textAlignment = NSTextAlignment.Right
            
            // cell separator
            cell.preservesSuperviewLayoutMargins = false
            cell.separatorInset = UIEdgeInsetsZero
            cell.layoutMargins = UIEdgeInsetsZero
            
            cell.backgroundColor = UIColor.lightGrayColor()
            cell.delegate = self
            
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
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let obj = list.objectForIndexPath(indexPath)
        if obj is Item {
            return kItemViewCellHeight
        } else if obj is Category {
            return kItemViewCellHeight - 8
        } else {
            return kItemViewCellHeight - 8
        }
    }
    
    /*
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if list.cellIsItem(indexPath) {
            return kItemViewCellHeight
        } else {
            return kItemViewCellHeight
        }
        //return UITableViewAutomaticDimension
    }
    */
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        print("didSelectRowAtIndexPath...!!!")
    }
    
    // override to support conditional editing of the table view
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        let obj = list.objectForIndexPath(indexPath)
        
        return obj is Item || obj is Category
        //return list.cellTypeAtIndex(indexPath.row) != ItemViewCellType.AddItem
    }
    
    // override to support editing the table view
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath)
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
    
    
    func keyboardDidShow() {
        //print("keyboardDidShow")
        inEditMode = true
    }
    
    func keyboardDidHide() {
        //print("keyboardDidHide")
        inEditMode = false
        editingNewCategoryName = false
        editingNewItemName = false
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool
    {
        textField.userInteractionEnabled = false
        textField.resignFirstResponder()
        self.tableView.setEditing(false, animated: true)

        // delete the newly added item if user didn't create a name
        if editingNewItemName
        {
            if textField.text!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()) == ""
            {
                // remove last item from category
                list.categories[list.categories.count-1].items.removeLast()
                self.tableView.reloadData()
                list.updateIndices()
            }
            editingNewItemName = false
        } else if editingNewCategoryName
        {
            if textField.text!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()) == ""
            {
                // remove last category from list
                list.categories.removeLast()
                self.tableView.reloadData()
                list.updateIndices()
            }
            editingNewCategoryName = false
        }
        
        // do we need this???
        UIView.animateWithDuration(0.25) {
            self.navigationController?.navigationBarHidden = false
        }
        
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
            newItem = list.addItem(category, name: "", state: ItemState.Incomplete, updateIndices: true)
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
    
    @IBAction func addCategoryButtonTapped(sender: UIButton)
    {
        var newCategory: Category
        
        if list.categories[0].displayHeader == false {
            // we will use the existing (hidden) category header
            newCategory = list.categories[0]
            newCategory.displayHeader = true
            newCatIndexPath = NSIndexPath(forRow: 0, inSection: 0)
        } else  {
            // we need a new category
            newCategory = list.addCategory("", displayHeader: true, updateIndices: true)
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
                self.performSelector("scrollToCategoryEnded:", withObject: nil, afterDelay: 0.1)
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
    
    func makeAttributedString(title title: String, subtitle: String) -> NSAttributedString {
        let titleAttributes = [NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleBody), NSForegroundColorAttributeName: UIColor.blackColor()]
        let subtitleAttributes = [NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleSubheadline)]
        
        let titleString = NSMutableAttributedString(string: "\(title)\n", attributes: titleAttributes)
        let subtitleString = NSAttributedString(string: subtitle, attributes: subtitleAttributes)
        
        titleString.appendAttributedString(subtitleString)
        
        return titleString
    }
    
    func categoryCountString(category: Category) -> NSAttributedString
    {
        return makeAttributedString(title: String("\(category.itemsComplete())/\(category.items.count)"), subtitle: "")
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
                    
                    category.expanded = !category.expanded
                    print("cellSingleTapAction was hit for category '\(obj!.name)' with tag \(tag)")
                    
                    // get display index paths for this category
                    let indexPaths = list.displayIndexPathsForCategory(category)    // includes AddItem cell path
                    
                    self.tableView.beginUpdates()
                    if category.expanded {
                        // insert the expanded rows into the table view
                        self.tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: UITableViewRowAnimation.Automatic)
                    } else {
                        // delete the collapsed rows from the table view
                        self.tableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: UITableViewRowAnimation.Automatic)
                    }
                    self.tableView.endUpdates()
                    
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
            } else if obj is Item {
                print("cellSingleTapAction on \(obj!.name)")
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
                scrollLoopCount = 0
            } else if touchLocation.y > (topBarHeight + kScrollZoneHeight) {
                displayLink!.invalidate()
                displayLink = nil
                scrollLoopCount = 0
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
                        
                        //print("cellAtIndexPathIsAddCellCategoryPair", indexPath!.row, moveDirection)
                        
                        if moveDirection == .Down {
                            indexPath = NSIndexPath(forRow: indexPath!.row + 1, inSection: 0)
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
        scrollLoopCount = 0
        
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
                    print("removeItem... \(srcItem.name)")
                    
                    // insert the item at its new location
                    if destDataObj is Item
                    {
                        let destItem = destDataObj as! Item
                        if moveDirection == .Down {
                            list.insertItem(srcItem, afterObj: destItem, updateIndices: true)
                        } else {
                            list.insertItem(srcItem, beforeObj: destItem, updateIndices: true)
                        }
                        print("insertItem... \(destItem.name)")
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
                    
                    print("moving row from \(sourceIndexPath?.row) to \(indexPath!.row)")
                    
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
                    
                    print("srcCategoryIndex: \(srcCategoryIndex)  dstCategoryIndex: \(dstCategoryIndex)")
                    
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

    }
    
    /*
    //////  ORIGINAL VERSION   ///////
    /// Clean up after a long press gesture.
    func longPressEnded(indexPath: NSIndexPath?, location: CGPoint)
    {
        longPressActive = false
        
        // cancel any scroll loop
        displayLink?.invalidate()
        displayLink = nil
        scrollLoopCount = 0
        
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
                let altIndexPath = indexPath!.row > 0 ? NSIndexPath(forRow: indexPath!.row - 1, inSection: 0) : indexPath!
                let srcDataObj = list.objectForIndexPath(sourceIndexPath!)
                //let destDataObj = moveDirection == .Down ? list.objectForIndexPath(indexPath!) : list.objectForIndexPath(altIndexPath)
                var destDataObj = list.objectForIndexPath(indexPath!)
                
                // move cells, update the list data source, move items and categories differently
                if srcDataObj is Item
                {
                    let srcItem = srcDataObj as! Item
                    
                    // we are moving an item
                    tableView.beginUpdates()
                    
                    // remove the item from its original location
                    //list.removeItemAtIndexPath(sourceIndexPath!, preserveCategories: true, updateIndices: true)
                    list.removeItem(srcItem, updateIndices: true)
                    print("removeItem... \(srcItem.name)")
                    
                    // insert the item at its new location
                    if destDataObj is Item
                    {
                        let destItem = destDataObj as! Item
                        
                        // replace with insertItemAfterItem ???
                        //list.insertItemAtIndexPath(srcItem, indexPath: indexPath!, atPosition: .Middle, updateIndices: true)
                        list.insertItem(srcItem, afterObj: destItem, updateIndices: true)
                        print("insertItem... \(destItem.name)")
                    }
                    else if destDataObj is Category || destDataObj is AddItem
                    {
                        // use altIndexPath if moving up to a category
                        if moveDirection == .Up {
                            destDataObj = list.objectForIndexPath(altIndexPath)
                        }
                        
                        // use dirModifier to jump over a dest category when moving up (down is handled by landing on the new category)
                        var position = (moveDirection == .Down) ? InsertPosition.Beginning : InsertPosition.End
                        
                        // are we are moving above top row (then reset dest position to beginning)
                        if indexPath!.row == 0 {
                            position = .Beginning
                        }
                        
                        // cell moved down past the last row, drop at end of last category
                        if destDataObj is AddItem {
                            position = .End
                            //altIndexPath = indexPath!
                        }
                        
                        // check if dest cat is collapsed
                        if destDataObj is Category {
                            let destCat = destDataObj as! Category
                            
                            if destCat.expanded == false {
                                // need to alter path to land on the collapsed category
                                list.insertItemAtIndexPath(srcItem, indexPath: altIndexPath, atPosition: .End, updateIndices: true)
                                
                                // also need to remove the row from the table as it will no longer be displayed
                                tableView.deleteRowsAtIndexPaths([altIndexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
                            } else {
                                list.insertItemAtIndexPath(srcItem, indexPath: altIndexPath, atPosition: position, updateIndices: true)
                            }
                        } else {
                            // moving to AddItem cell, so drop just above the AddItem cell
                            list.insertItemAtIndexPath(srcItem, indexPath: altIndexPath, atPosition: position, updateIndices: true)
                        }
                    }
                    
                    //list.updateIndices()
                    
                    print("moving row from \(sourceIndexPath?.row) to \(indexPath!.row)")
                    
                    tableView.endUpdates()
                }
                else if srcDataObj is Category
                {
                    // we are moving a category
                    let srcCategory = srcDataObj as! Category
                    let srcCategoryIndex = srcCategory.categoryIndex
                    var dstCategoryIndex = destDataObj!.categoryIndex
                    
                    //let srcCategoryIndex = list.indicesForObjectAtIndexPath(sourceIndexPath!).categoryIndex
                    //var dstCategoryIndex = list.indicesForObjectAtIndexPath(indexPath!).categoryIndex
                    
                    // this is so dropping a category on an item will only move the category if the item is above the dest category when moving up
                    let moveDirection = sourceIndexPath!.row >  indexPath!.row ? MoveDirection.Up : MoveDirection.Down

                    if moveDirection == .Up && destDataObj is Item && dstCategoryIndex >= 0 {
                        ++dstCategoryIndex
                    }
                    
                    print("srcCategoryIndex: \(srcCategoryIndex)  dstCategoryIndex: \(dstCategoryIndex)")
                    
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
    }
    */
    
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
        let objType = isItem ? "item" : "category"
        let alert = UIAlertController(title: "Delete \(objType.capitalizedString)", message: "Are you sure you want to permanently delete the \(objType) \(objName)?", preferredStyle: .Alert)
        
        let DeleteAction = UIAlertAction(title: "Delete", style: .Destructive, handler: handleDeleteItem)
        let CancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: cancelDeleteItem)
        
        alert.addAction(DeleteAction)
        alert.addAction(CancelAction)
        
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
            
            if list.objectForIndexPath(indexPath) is Category {
                preserveCat = false
            }
            
            removedPaths = currentList.removeItemAtIndexPath(indexPath, preserveCategories: preserveCat, updateIndices: true)
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
            list.showCompletedItems = self.showCompletedItems
            tableView.reloadData()
        } else {
            self.title = "<no selection>"
            tableView.reloadData()
        }
    }
    
    func colorForIndex(index: Int) -> UIColor
    {
        let itemCount = list.totalDisplayCount() - 1
        let val = (CGFloat(index) / CGFloat(itemCount)) * 0.99
        return UIColor(red: 0.0, green: val, blue: 1.0, alpha: 0.5)
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
                    itemCell.tempCheckButton!.tag = tag
                } else if cell is CategoryCell {
                    (cell as! CategoryCell).categoryName!.tag = tag
                } else if cell is AddItemCell {
                    (cell as! AddItemCell).addItemButton.tag = tag
                }
                
                cell!.contentView.tag = tag
            }
            
        } while index < list.totalDisplayCount()
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
            //print("isPair...")
        } else if cell is CategoryCell && prevCell is AddItemCell {
            isPair = true
            //print("isPair...")
        }
        
        return isPair
    }

    // calculates the top bar height, inlcuding the status bar and nav bar (if present)
    func getTopBarHeight() -> CGFloat {
        let statusBarHeight = UIApplication.sharedApplication().statusBarFrame.size.height
        let navBarHeight = self.navigationController!.navigationBar.frame.size.height
        
        return statusBarHeight + navBarHeight
    }

    func settingsButtonTapped() {
        print("settings button tapped...")
    }
    
////////////////////////////////////////////////////////////////
//
//  MARK: - ShowHideCompleted methods
//
////////////////////////////////////////////////////////////////
    
    @IBAction func showHideCategoryButtonTapped(sender: UIBarButtonItem)
    {
        showCompletedItems = !showCompletedItems
    }
    
    func setShowHideCompleted(show: Bool) {
        showCompletedItems = show
    }
    
    /// Refreshes the ItemVC item rows with animation after a change to showHideCompleted
    func updateShowHideCompletedRows()
    {
        let indexPaths = list.indexPathsForCompletedRows()
        
        if showCompletedItems == false
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
        
        // this is needed so that operations that rely on view.tag will function correctly
        //self.resetCellViewTags()
        
        //self.tableView.reloadData()
    }
    
    // called when the check button is tapped
    @IBAction func checkButtonTapped(sender: UIButton)
    {
        //let senderItem = list.objectForIndexPath(NSIndexPath(forRow: i, inSection: 0))
        let senderItem = list.objectForTag(sender.tag)
        var indexPath: NSIndexPath? = nil
        
        if senderItem is Item {
            let item = senderItem as! Item
            
            // cycle through the item states
            switch item.state {
            case ItemState.Inactive:
                item.state = ItemState.Incomplete
                sender.setTitle("INCMP", forState: .Normal)
            case ItemState.Incomplete:
                indexPath = list.displayIndexPathForItem(item)
                item.state = ItemState.Complete
                sender.setTitle("COMPL", forState: .Normal)
            case ItemState.Complete:
                item.state = ItemState.Inactive
                sender.setTitle("INACT", forState: .Normal)
            }
            
            print("item: \(item.name) is set to \(sender.titleForState(.Normal))")
            
            // remove a newly completed row if we are hiding completed items
            if showCompletedItems == false && item.state == ItemState.Complete {
                if indexPath != nil {
                    self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
                }
            }
            
            // need to update the counts in the cat cell count label
            if let category = list.categoryForObj(item) {
                if let catIndexPath = list.displayIndexPathForCategory(category) {
                    if self.tableView.indexPathsForVisibleRows?.contains(catIndexPath) == true {
                        let catCell = tableView.cellForRowAtIndexPath(catIndexPath) as! CategoryCell
                        catCell.catCountLabel.attributedText = self.categoryCountString(category)
                    }
                }
            }
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
    
    /*
    func bannerViewActionShouldBegin(banner: ADBannerView!, willLeaveApplication willLeave: Bool) -> Bool {
        print("bannerViewActionShouldBegin")
        return true
    }
    
    func bannerViewDidLoadAd(banner: ADBannerView!) {
        print("bannerViewDidLoadAd")
        self.bannerView.hidden = false
    }
    
    func bannerView(banner: ADBannerView!, didFailToReceiveAdWithError error: NSError!) {
        print("didFailToReceiveAdWithError")
        self.bannerView.hidden = true
    }
    */
    
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
        self.title = list!.name
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
