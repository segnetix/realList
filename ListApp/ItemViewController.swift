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
    var itemsCompletedInHideCompletedItemsMode = [Item]()
    
    var list: List! {
        didSet (newList) {
            list.showCompletedItems = self.showCompletedItems
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
                itemsCompletedInHideCompletedItemsMode.removeAll()
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
            var displayCount = list.totalDisplayCount()

            if itemsCompletedInHideCompletedItemsMode.count > 0 {
                print("tableView:numberOfRowsInSection itemsCompletedInHideCompletedItemsMode.count is > 0...!!!")
            }
            displayCount += itemsCompletedInHideCompletedItemsMode.count
            
            return displayCount
        } else {
            return 0
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cellType = list.cellTypeAtIndex(indexPath.row)
        
        if cellType == ItemViewCellType.Item {
            // item cell
            let cell = tableView.dequeueReusableCellWithIdentifier(itemCellID, forIndexPath: indexPath) as! ItemCell
            
            // Configure the cell...
            cell.itemName.userInteractionEnabled = false
            cell.itemName.delegate = self
            cell.itemName.addTarget(self, action: "itemNameDidChange:", forControlEvents: UIControlEvents.EditingChanged)
            cell.itemName!.tag = indexPath.row
            cell.contentView.tag = indexPath.row
            
            // set up single tap gesture recognizer in cat cell to enable expand/collapse
            let singleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: "cellSingleTapAction:")
            singleTapGestureRecognizer.numberOfTapsRequired = 1
            cell.contentView.addGestureRecognizer(singleTapGestureRecognizer)
            
            // set up double tap gesture recognizer in item cell to enable cell moving
            let doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: "cellDoubleTapAction:")
            doubleTapGestureRecognizer.numberOfTapsRequired = 2
            singleTapGestureRecognizer.requireGestureRecognizerToFail(doubleTapGestureRecognizer)
            cell.contentView.addGestureRecognizer(doubleTapGestureRecognizer)

            // check switch
            let item = list.objectAtIndexPath(indexPath) as! Item
            cell.checkSwitch.setOn(item.completed, animated: false)
            cell.checkSwitch.tag = indexPath.row
            
            // item title
            let title = list?.cellTitle(indexPath)
            if let cellTitle = title {
                cell.itemName?.attributedText = makeAttributedString(title: cellTitle, subtitle: "\(cell.itemName.tag)")    // for debugging
                //cell.itemName?.attributedText = makeAttributedString(title: cellTitle, subtitle: "")                      // for production
            } else {
                cell.itemName?.attributedText = makeAttributedString(title: "", subtitle: "")
            }
            
            // cell separator
            cell.preservesSuperviewLayoutMargins = false
            cell.separatorInset = UIEdgeInsetsZero
            cell.layoutMargins = UIEdgeInsetsZero
            
            cell.backgroundColor = colorForIndex(indexPath.row)
            cell.delegate = self
            
            return cell
        } else if cellType == ItemViewCellType.Category  {
            // category cell
            let cell = tableView.dequeueReusableCellWithIdentifier(categoryCellID, forIndexPath: indexPath) as! CategoryCell
            
            // Configure the cell...
            cell.categoryName.userInteractionEnabled = false
            cell.categoryName.delegate = self
            cell.categoryName.addTarget(self, action: "itemNameDidChange:", forControlEvents: UIControlEvents.EditingChanged)
            cell.categoryName!.tag = indexPath.row
            cell.contentView.tag = indexPath.row
            
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
            let title = list?.cellTitle(indexPath)
            if let cellTitle = title {
                cell.categoryName?.attributedText = makeAttributedString(title: cellTitle, subtitle: "\(cell.categoryName.tag)")
                //cell.itemName?.attributedText = makeAttributedString(title: cellTitle, subtitle: "")
            } else {
                cell.categoryName?.attributedText = makeAttributedString(title: "", subtitle: "")
            }
            
            // catCountLabel
            let category = list.categoryForItemAtIndex(indexPath)
            if let category = category {
                cell.catCountLabel.attributedText = categoryCountString(category)
                cell.catCountLabel.textAlignment = NSTextAlignment.Right
            }
            
            // cell separator
            cell.preservesSuperviewLayoutMargins = false
            cell.separatorInset = UIEdgeInsetsZero
            cell.layoutMargins = UIEdgeInsetsZero
            
            cell.backgroundColor = UIColor.lightGrayColor()
            cell.delegate = self
            
            return cell
         } else if cellType == ItemViewCellType.AddItem {
            // set up Add row
            // let cell = tableView.dequeueReusableCellWithIdentifier(addItemCellId, forIndexPath: indexPath)
            let cell = tableView.dequeueReusableCellWithIdentifier(addItemCellId) as! AddItemCell
            
            // cell separator
            cell.preservesSuperviewLayoutMargins = false
            cell.separatorInset = UIEdgeInsetsZero
            cell.layoutMargins = UIEdgeInsetsZero
            
            // set up cell tag for later id
            cell.addItemButton.tag = indexPath.row
            
            return cell
        } else if cellType == nil {
            print("ERROR: cell type is nil...")
        }
        
        return UITableViewCell()
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if let list = list {
            if list.cellIsItem(indexPath) {
                return kItemViewCellHeight
            } else {
                return kItemViewCellHeight
            }
        }
        return kItemViewCellHeight
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
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let title = list.cellTitle(indexPath)
        //print("selection: cat \(indexPath.section)  item \(indexPath.row)  title \(title)")
        let indices = list.indicesForObjectAtIndexPath(indexPath)
        
        print("selection: cat \(indices.categoryIndex)  item \(indices.itemIndex)  \(title)")
    }
    
    // override to support conditional editing of the table view
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return list.cellTypeAtIndex(indexPath.row) != ItemViewCellType.AddItem
    }
    
    // override to support editing the table view
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath)
    {
        if editingStyle == .Delete {
            deleteItemIndexPath = indexPath
            let deletedItem = list?.objectAtIndexPath(indexPath)
            
            if list.objectIsItem(deletedItem) {
                confirmDelete((deletedItem as! Item).name, isItem: true)
            } else {
                confirmDelete((deletedItem as! Category).name, isItem: false)
            }
        }
        else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
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
                list.updateCellTypeArray()
            }
            editingNewItemName = false
        } else if editingNewCategoryName
        {
            if textField.text!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()) == ""
            {
                // remove last category from list
                list.categories.removeLast()
                self.tableView.reloadData()
                list.updateCellTypeArray()
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
        let i = textField.tag
        let newName = textField.text!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        let indexPath = NSIndexPath(forRow: i, inSection: 0)
        
        list?.updateObjectNameAtIndexPath(indexPath, withName: newName)
        //navigationController?.navigationBar.hidden = true
        //print(textField.text)
    }
    
    @IBAction func addItemButtonTapped(sender: UIButton)
    {
        // create a new item and append to the category of the add button
        //let newItem = Item(name: "new item: \(sender.tag)")
        let newItem = Item(name: "", completed: false)
        let category  = list.categoryForAddItemButtonAtRowIndex(sender.tag)
        
        category.items.append(newItem)
        list.updateCellTypeArray()
        self.tableView.reloadData()
        self.resetCellViewTags()
        
        let newItemIndexPath = list.indexPathForItem(newItem)
        
        if let indexPath = newItemIndexPath {
            //print("newIndexPath: \(indexPath.row)  sender.tag \(sender.tag)")
            
            // set up editing mode for item name
            let cell = tableView.cellForRowAtIndexPath(indexPath) as! ItemCell
            
            cell.itemName.userInteractionEnabled = true
            cell.itemName.becomeFirstResponder()
            editingNewItemName = true
        } else {
            print("ERROR: addItemButtonTapped - indexPathForItem returned a nil index path.")
        }
    }
    
    
    @IBAction func addCategoryButtonTapped(sender: UIButton)
    {
        var newCategory: Category
        
        if list.categories[0].displayHeader == false {
            newCategory = list.categories[0]
            newCategory.displayHeader = true
            newCatIndexPath = NSIndexPath(forRow: 0, inSection: 0)
        } else  {
            newCategory = Category(name: "", displayHeader: true)
            list.categories.append(newCategory)
            newCatIndexPath = list.indexPathForCategory(newCategory)
        }
        
        list.updateCellTypeArray()
        self.tableView.reloadData()
        
        if let indexPath = newCatIndexPath {
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
        let i = sender.view?.tag
        let indexPath = NSIndexPath(forRow: i!, inSection: 0)
        
        if list.cellIsCategory(indexPath)
        {
            if !inEditMode {
                let i = sender.view?.tag
                let category = list.categoryForItemAtIndex(NSIndexPath(forRow: i!, inSection: 0))
                
                if let cat = category
                {
                    var indexPaths = [NSIndexPath]()
                    
                    cat.expanded = !cat.expanded
                    print("cellSingleTapAction was hit for category \(i) with name: \(cat.name)")
                    
                    self.tableView.beginUpdates()
                    
                    if cat.expanded {
                        // we are expanding a category
                        var insertPos = indexPath.row
                        
                        for item in cat.items
                        {
                            if showCompletedItems || !item.completed {
                                indexPaths.append(NSIndexPath(forRow: ++insertPos, inSection: 0))
                            }
                        }
                        
                        // one more for the addItem cell
                        indexPaths.append(NSIndexPath(forRow: ++insertPos, inSection: 0))
                        
                        // now insert the expanded rows into the table view
                        self.tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: UITableViewRowAnimation.Fade)
                    } else {
                        // we are collapsing a category
                        var indexPaths = [NSIndexPath]()
                        var index = indexPath.row
                        
                        for item in cat.items
                        {
                            if showCompletedItems || !item.completed || arrayContainsItem(itemsCompletedInHideCompletedItemsMode, item: item) {
                                indexPaths.append(NSIndexPath(forRow: ++index, inSection: 0))
                                
                                // need to remove the item from itemsCompletedInHideCompletedItemsMode (if it was in the array)
                                let i = indexOfItemInArray(itemsCompletedInHideCompletedItemsMode, item: item)
                                if i > -1 {
                                    itemsCompletedInHideCompletedItemsMode.removeAtIndex(i)
                                }
                            }
                        }
                        
                        // one more for the addItem cell
                        indexPaths.append(NSIndexPath(forRow: ++index, inSection: 0))
                        
                        // now delete the collapsed rows from the table view
                        self.tableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: UITableViewRowAnimation.Fade)
                    }
                    
                    //need to update the cellTypeArray after collapse/expand event
                    list.updateCellTypeArray()
                    
                    // this is needed so that operations that rely on view.tag (like this one!) will function correctly
                    self.resetCellViewTags()
                    
                    self.tableView.endUpdates()
                    
                    if cat.expanded {
                        // scroll the newly expanded header to the top so items can be seen
                        self.tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition.Top, animated: true)
                    }
                }
            } else {
                print("no toggle - inEditMode!")
            }
        }
    }
    
    /// Respond to a double tap (cell name edit).
    func cellDoubleTapAction(sender: UITapGestureRecognizer)
    {
        if sender.view != nil {
            let indexPath = NSIndexPath(forRow: (sender.view?.tag)!, inSection: 0)
            
            if list.cellIsItem(indexPath) {
                let cell = tableView.cellForRowAtIndexPath(indexPath) as! ItemCell
                
                cell.itemName.userInteractionEnabled = true
                cell.itemName.becomeFirstResponder()
            } else if list.cellIsCategory(indexPath) {
                let cell = tableView.cellForRowAtIndexPath(indexPath) as! CategoryCell
                
                cell.categoryName.userInteractionEnabled = true
                cell.categoryName.becomeFirstResponder()
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
        
        let obj = list.objectAtIndexPath(sourceIndexPath!)
        
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
        
        // finalize list data with new location for sourceIndexObj
        if sourceIndexPath != nil
        {
            var center: CGPoint = snapshot!.center
            center.y = location.y
            snapshot?.center = center
            
            // check if destination is different from source and valid
            if indexPath != sourceIndexPath && indexPath != nil && list != nil
            {
                let moveDirection = sourceIndexPath!.row >  indexPath!.row ? MoveDirection.Up : MoveDirection.Down
                var altIndexPath = indexPath!.row > 0 ? NSIndexPath(forRow: indexPath!.row - 1, inSection: 0) : indexPath!
                let sourceDataObj = list.objectAtIndexPath(sourceIndexPath!)
                var destDataObj  = moveDirection == .Up ? list.objectAtIndexPath(altIndexPath) : list.objectAtIndexPath(indexPath!)
                let destCellType = moveDirection == .Up ? list.cellTypeAtIndex(altIndexPath.row) : list.cellTypeAtIndex(indexPath!.row)
                
                // move cells, update the list data source, move items and categories differently
                if sourceDataObj is Item
                {
                    // we are moving an item
                    tableView.beginUpdates()
                    
                    // remove the item from its original location
                    list.removeItemAtIndexPath(sourceIndexPath!, preserveCategories: true)
                    
                    // insert the item at its new location
                    if destCellType == ItemViewCellType.Item
                    {
                        list.insertItemAtIndexPath(sourceDataObj as! Item, indexPath: indexPath!, atPosition: .Middle)
                    }
                    else if destCellType == ItemViewCellType.Category || destCellType == ItemViewCellType.AddItem
                    {
                        // use dirModifier to jump over a dest category when moving up (down is handled by landing on the new category)
                        var position = (moveDirection == .Down) ? InsertPosition.Beginning : InsertPosition.End
                        
                        // are we are moving above top row (then reset dest position to beginning)
                        if indexPath!.row == 0 {
                            position = .Beginning
                        }
                        
                        // fix for moving down to an AddItem cell (should get pushed to the next category)
                        if destCellType == .AddItem {
                            destDataObj = list.objectAtIndexPath(NSIndexPath(forRow: indexPath!.row, inSection: 0))
                            altIndexPath = indexPath!
                        }
                        
                        // check if dest cat is collapsed
                        if destDataObj is Category {
                            let destCat = destDataObj as! Category
                            
                            if destCat.expanded == false {
                                // need to alter path to land on the collapsed category
                                list.insertItemAtIndexPath(sourceDataObj as! Item, indexPath: altIndexPath, atPosition: .End)
                                
                                // also need to remove the row from the table as it will no longer be displayed
                                tableView.deleteRowsAtIndexPaths([altIndexPath], withRowAnimation: UITableViewRowAnimation.Fade)
                            } else {
                                if destCat.expanded {
                                    list.insertItemAtIndexPath(sourceDataObj as! Item, indexPath: altIndexPath, atPosition: .Beginning)
                                } else {
                                    list.insertItemAtIndexPath(sourceDataObj as! Item, indexPath: altIndexPath, atPosition: .End)
                                }
                            }
                        } else {
                            list.insertItemAtIndexPath(sourceDataObj as! Item, indexPath: altIndexPath, atPosition: position)
                        }
                    }
                    
                    print("moving row from \(sourceIndexPath?.row) to \(indexPath!.row)")
                    
                    tableView.endUpdates()
                }
                else if sourceDataObj is Category
                {
                    // we are moving a category
                    let sourceCatIndex = list.indicesForObjectAtIndexPath(sourceIndexPath!).categoryIndex
                    var destCatIndex = list.indicesForObjectAtIndexPath(indexPath!).categoryIndex
                    
                    // this is so dropping a category on an item will only move the category if the item is above the dest category when moving up
                    let moveDirection = sourceIndexPath!.row >  indexPath!.row ? MoveDirection.Up : MoveDirection.Down

                    if moveDirection == .Up && destDataObj is Item && destCatIndex != nil {
                        ++destCatIndex!
                    }
                    
                    print("sourceCatIndex: \(sourceCatIndex)  destCatIndex: \(destCatIndex)")
                    
                    if sourceCatIndex != nil && destCatIndex != nil {
                        tableView.beginUpdates()
                        
                        // remove the category from its original location
                        list.removeCatetoryAtIndex(sourceCatIndex!)
                        
                        list.insertCategory(sourceDataObj as! Category, atIndex: destCatIndex!)
                        
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
            
            if list.objectAtIndexPath(indexPath) is Category {
                preserveCat = false
            }
            
            removedPaths = currentList.removeItemAtIndexPath(indexPath, preserveCategories: preserveCat)
            tableView.deleteRowsAtIndexPaths(removedPaths, withRowAnimation: .Fade)
            deleteItemIndexPath = nil
            tableView.endUpdates()
            
            tableView.reloadData()
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
            list.showCompletedItems = self.showCompletedItems
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
                if cell is ItemCell {
                    (cell as! ItemCell).itemName!.tag = indexPath.row
                } else if cell is CategoryCell {
                    (cell as! CategoryCell).categoryName!.tag = indexPath.row
                } else if cell is AddItemCell {
                    (cell as! AddItemCell).addItemButton.tag = indexPath.row
                }
                
                cell!.contentView.tag = indexPath.row
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
        var indexPaths = [NSIndexPath]()
        
        if showCompletedItems == false
        {
            // we are hiding the completed rows
            var deletePos = -1
            
            for category in list.categories
            {
                if category.displayHeader {
                    ++deletePos
                }
                
                if category.expanded
                {
                    for item in category.items
                    {
                        if item.completed {
                            indexPaths.append(NSIndexPath(forRow: ++deletePos, inSection: 0))
                        } else {
                            ++deletePos
                        }
                    }
                    ++deletePos     // for the AddItem cell
                }
            }
            
            // remove the complete rows
            self.tableView.beginUpdates()
            self.tableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: UITableViewRowAnimation.Fade)
            self.tableView.endUpdates()
        }
        else
        {
            // we are showing the completed rows
            var insertPos = -1
            
            for category in list.categories
            {
                if category.displayHeader {
                    ++insertPos
                }
                
                if category.expanded
                {
                    for item in category.items
                    {
                        // only add previously completed items (not newly completed as those are already being displayed)
                        if item.completed && arrayContainsItem(itemsCompletedInHideCompletedItemsMode, item: item) == false {
                            indexPaths.append(NSIndexPath(forRow: ++insertPos, inSection: 0))
                        } else {
                            ++insertPos
                        }
                    }
                    ++insertPos     // for the AddItem cell
                }
            }
            
            itemsCompletedInHideCompletedItemsMode.removeAll()
            
            // insert the complete rows
            self.tableView.beginUpdates()
            self.tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: UITableViewRowAnimation.Fade)
            self.tableView.endUpdates()
        }
   
        // need to update the cellTypeArray after show/hide event
        list.updateCellTypeArray()
        
        // this is needed so that operations that rely on view.tag will function correctly
        self.resetCellViewTags()
        
        self.tableView.reloadData()
    }
    
    // called when check switch is toggled
    @IBAction func checkSwitchTapped(sender: UISwitch)
    {
        let i = sender.tag
        let senderItem = list.objectAtIndexPath(NSIndexPath(forRow: i, inSection: 0))
        
        if senderItem is Item {
            let item = senderItem as! Item
            item.completed = sender.on
            print("item: \(item.name) is set to \(sender.on)")
            
            // If we are currently hiding completed items and our item is changed to completed
            // then add to itemsCompletedInHideCompletedItemsMode array so the item doesn't get re-added
            // when later switching back to show completed mode.
            if showCompletedItems == false
            {
                // get index of item in itemsCompletedInHideCompletedItemsMode array
                let i = indexOfItemInArray(itemsCompletedInHideCompletedItemsMode, item: item)
                
                if item.completed && i == -1 {
                    // add to array
                    itemsCompletedInHideCompletedItemsMode.append(item)
                }
                else if !item.completed && i > -1 {
                    // remove from array
                    itemsCompletedInHideCompletedItemsMode.removeAtIndex(i)
                }
            }
            
            // need to update the counts in the cat cell
            if let category = list.categoryForItem(item) {
                if let catIndexPath = list.indexPathForCategory(category) {
                    if self.tableView.indexPathsForVisibleRows?.contains(catIndexPath) == true {
                        let catCell = tableView.cellForRowAtIndexPath(catIndexPath) as! CategoryCell
                        catCell.catCountLabel.attributedText = self.categoryCountString(category)
                    }
                }
            }
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
