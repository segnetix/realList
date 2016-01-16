//
//  ItemViewController.swift
//  ListApp
//
//  Created by Steven Gentry on 12/30/15.
//  Copyright © 2015 Steven Gentry. All rights reserved.
//

import UIKit
import QuartzCore

let itemCellID     = "ItemCell"
let categoryCellID = "CategoryCell"

enum InsertPosition {
    case Beginning
    case Middle
    case End
}

enum MoveDirection {
    case Up
    case Down
}

let kItemViewScrollRate: CGFloat = 6.0
let kItemViewCellHeight: CGFloat = 44.0

class ItemViewController: UITableViewController, UITextFieldDelegate
{
    var inEditMode = false
    var deleteItemIndexPath: NSIndexPath? = nil
    var editModeRow = -1
    var longPressGestureRecognizer: UILongPressGestureRecognizer? = nil
    var movedToCollapsedCategory = false
    var sourceIndexPath: NSIndexPath? = nil
    var movingFromIndexPath: NSIndexPath? = nil
    var prevLocation: CGPoint? = nil
    var snapshot: UIView? = nil
    var displayLink: CADisplayLink? = nil
    var scrollLoopCount = 0     // debugging var
    var longPressActive = false
    
    var list: List! {
        didSet (newList) {
            self.refreshItems()
        }
    }
    
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
    
    /*
    // we always will have one section only so just let it default
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return 1
    }
    */
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        // return the total number of rows in our item table view (categories + items)
        if let currentList = list {
            var displayCount = currentList.totalDisplayCount()
            
            // if moving a cell to a collapsed category then we need to account for the newly hidden cell by temporarily incrementing the displayCount
            if movedToCollapsedCategory {
                ++displayCount
                movedToCollapsedCategory = false
            }
            
            return displayCount
        } else {
            return 0
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        if list.cellIsItem(indexPath) {
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
        } else {
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
                cell.catCountLabel.attributedText = makeAttributedString(title: String(category.items.count), subtitle: "")
            }
            
            // cell separator
            cell.preservesSuperviewLayoutMargins = false
            cell.separatorInset = UIEdgeInsetsZero
            cell.layoutMargins = UIEdgeInsetsZero
            
            cell.backgroundColor = UIColor.lightGrayColor()
            cell.delegate = self
            
            return cell
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if list.cellIsItem(indexPath) {
            return kItemViewCellHeight
        } else {
            return kItemViewCellHeight
        }
        //return UITableViewAutomaticDimension
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
        return true
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
    
    override func prefersStatusBarHidden() -> Bool {
        return navigationController?.navigationBarHidden == true
    }
    
    override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        return UIStatusBarAnimation.Slide
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool
    {
        inEditMode = false
        textField.userInteractionEnabled = false
        textField.resignFirstResponder()
        self.tableView.setEditing(false, animated: true)

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
        navigationController?.navigationBar.hidden = true
        //print(textField.text)
    }
    
////////////////////////////////////////////////////////////////
//
//  MARK: - Gesture Recognizer methods
//
////////////////////////////////////////////////////////////////
    
    // respond to a single tap (toggle expand/collapse state of category)
    func cellSingleTapAction(sender: UITapGestureRecognizer)
    {
        let i = sender.view?.tag
        let indexPath = NSIndexPath(forRow: i!, inSection: 0)
       // let cellObj = list.objectAtIndexPath(indexPath)
        
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
                        
                        for (var i = 0; i < cat.items.count; ++i) {
                            indexPaths.append(NSIndexPath(forRow: ++insertPos, inSection: 0))
                        }
                        
                        self.tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: UITableViewRowAnimation.Fade)
                    } else {
                        // we are collapsing a category
                        var indexPaths = [NSIndexPath]()
                        let index = indexPath.row
                        
                        for (var i = index + 1; i <= index + cat.items.count; i++ ) {
                            indexPaths.append(NSIndexPath(forRow: i, inSection: 0))
                        }
                        
                        self.tableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: UITableViewRowAnimation.Fade)
                    }
                    
                    self.tableView.endUpdates()
                    
                    // this is needed so that operations that rely on view.tag (like this one!) will function correctly
                    self.resetCellViewTags()
                }
            } else {
                print("no toggle - inEditMode!")
            }

        }
    }
    
    // respond to a double tap (cell name edit)
    func cellDoubleTapAction(sender: UITapGestureRecognizer)
    {
        if sender.view != nil {
            let indexPath = NSIndexPath(forRow: (sender.view?.tag)!, inSection: 0)
            
            if list.cellIsItem(indexPath) {
                let cell = tableView.cellForRowAtIndexPath(indexPath) as! ItemCell
                
                inEditMode = true
                cell.itemName.userInteractionEnabled = true
                cell.itemName.becomeFirstResponder()
            } else if list.cellIsCategory(indexPath) {
                let cell = tableView.cellForRowAtIndexPath(indexPath) as! CategoryCell
                
                inEditMode = true
                cell.categoryName.userInteractionEnabled = true
                cell.categoryName.becomeFirstResponder()
            }
        }
    }

    // handle long press gesture (cell move)
    func longPressAction(gesture: UILongPressGestureRecognizer)
    {
        let state: UIGestureRecognizerState = gesture.state
        let location: CGPoint = gesture.locationInView(tableView)
        let topBarHeight = getTopBarHeight()
        var indexPath: NSIndexPath? = tableView.indexPathForRowAtPoint(location)
        
        let touchLocationInWindow = tableView.convertPoint(location, toView: tableView.window)
        //print("longPressAction: touchLocationInWindow.y", touchLocationInWindow.y)
        
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
        
        if touchLocation.y > tableView.bounds.height - 50 {
            // need to scroll down
            if displayLink == nil {
                displayLink = CADisplayLink(target: self, selector: Selector("scrollDownLoop"))
                displayLink!.frameInterval = 1
                displayLink!.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
            }
        } else if touchLocation.y < topBarHeight + 50 {
            // need to scroll up
            if displayLink == nil {
                displayLink = CADisplayLink(target: self, selector: Selector("scrollUpLoop"))
                displayLink!.frameInterval = 1
                displayLink!.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
            }
        } else if displayLink != nil {
            // check if we need to cancel a current scroll update because the touch moved out of scroll area
            if touchLocation.y < tableView.bounds.height - 50 {
                displayLink!.invalidate()
                displayLink = nil
                scrollLoopCount = 0
            } else if touchLocation.y > topBarHeight + 50 {
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
            longPressActive = true
            sourceIndexPath = indexPath
            movingFromIndexPath = indexPath
            let cell = tableView.cellForRowAtIndexPath(indexPath!)!
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
            
            prevLocation = location
            
        case UIGestureRecognizerState.Changed:
            // long press has moved - call move method
            self.longPressMoved(indexPath!, location: location)
            prevLocation = location
            
        default:
            // long press has ended - call clean up method
            self.longPressEnded(indexPath!, location: location)
            
        }   // end switch
        
    }
    
    func longPressMoved(var indexPath: NSIndexPath?, location: CGPoint)
    {
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
                    // ... move the rows
                    tableView.moveRowAtIndexPath(movingFromIndexPath!, toIndexPath: indexPath!)
                    
                    // ... and update movingFromIndexPath so it is in sync with UI changes
                    movingFromIndexPath = indexPath
                }
            }
        }
    }
    
    // clean up after a long press gesture
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
                let sourceDataObj = list.objectAtIndexPath(sourceIndexPath!)
                var destDataObj = list.objectAtIndexPath(indexPath!)
                
                // update the list data source, for now only move items (categories later)
                if sourceDataObj is Item
                {
                    // we are moving an item
                    tableView.beginUpdates()
                    
                    // remove the item from its original location
                    list.removeItemAtIndexPath(sourceIndexPath!, preserveCategories: true)
                    
                    // insert the item at its new location
                    if destDataObj is Item
                    {
                        list.insertItemAtIndexPath(sourceDataObj as! Item, indexPath: indexPath!, atPosition: .Middle)
                    }
                    else if destDataObj is Category
                    {
                        // use dirModifier to jump over a dest category when moving up (down is handled by landing on the new category)
                        let moveDirection = sourceIndexPath!.row >  indexPath!.row ? MoveDirection.Up : MoveDirection.Down
                        var position = (moveDirection == .Down) ? InsertPosition.Beginning : InsertPosition.End
                        var altIndexPath = indexPath!
                        
                        // alt path above category unles we are moving above top category
                        if indexPath!.row > 0 {
                            altIndexPath = NSIndexPath(forRow: indexPath!.row - 1, inSection: 0)
                        } else {
                            position = .Beginning
                        }
                        
                        // check if dest cat is collapsed
                        destDataObj = list.objectAtIndexPath(altIndexPath)
                        if destDataObj is Category {
                            let destCat = destDataObj as! Category
                            
                            if destCat.expanded == false {
                                // need to alter path to land on the collapsed category
                                list.insertItemAtIndexPath(sourceDataObj as! Item, indexPath: altIndexPath, atPosition: .End)
                                movedToCollapsedCategory = true
                            } else {
                                list.insertItemAtIndexPath(sourceDataObj as! Item, indexPath: altIndexPath, atPosition: position)
                            }
                        } else {
                            list.insertItemAtIndexPath(sourceDataObj as! Item, indexPath: altIndexPath, atPosition: position)
                        }
                    }
                    
                    print("moving row from \(sourceIndexPath?.row) to \(indexPath!.row)")
                    
                    // ... move the rows (do we need this???)
                    //tableView.moveRowAtIndexPath(sourceIndexPath!, toIndexPath: indexPath!)
                    
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
        
        //self.tableView.reloadData()
        
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
        
        //tableView.contentInset = UIEdgeInsetsMake(0, 0, -120, 0) //values passed are - top, left, bottom, right
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
            let removedPaths = currentList.removeItemAtIndexPath(indexPath, preserveCategories: true)
            if let _ = removedPaths {
                tableView.deleteRowsAtIndexPaths(removedPaths!, withRowAnimation: .Fade)
            }
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
    
    func makeAttributedString(title title: String, subtitle: String) -> NSAttributedString {
        let titleAttributes = [NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleBody), NSForegroundColorAttributeName: UIColor.blackColor()]
        let subtitleAttributes = [NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleSubheadline)]
        
        let titleString = NSMutableAttributedString(string: "\(title)\n", attributes: titleAttributes)
        let subtitleString = NSAttributedString(string: subtitle, attributes: subtitleAttributes)
        
        titleString.appendAttributedString(subtitleString)
        
        return titleString
    }
    
    func refreshItems()
    {
        if list != nil {
            self.title = list!.name
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
    func resetCellViewTags()
    {
        var cell: UITableViewCell? = nil
        var index = 0
        
        repeat {
            let indexPath = NSIndexPath(forRow: index++, inSection: 0)
            cell = tableView.cellForRowAtIndexPath(indexPath)
                
            if cell != nil {
                if cell is ItemCell {
                    (cell as! ItemCell).itemName!.tag = indexPath.row
                } else if cell is CategoryCell {
                    (cell as! CategoryCell).categoryName!.tag = indexPath.row
                }
                
                cell!.contentView.tag = indexPath.row
            }
            
        } while cell != nil
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
    
    func getTopBarHeight() -> CGFloat {
        let statusBarHeight = UIApplication.sharedApplication().statusBarFrame.size.height
        let navBarHeight = self.navigationController!.navigationBar.frame.size.height
        
        return statusBarHeight + navBarHeight
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
