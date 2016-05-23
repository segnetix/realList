//
//  ListViewController.swift
//  EnList
//
//  Created by Steven Gentry on 12/30/15.
//  Copyright © 2015 Steven Gentry. All rights reserved.
//

import UIKit
import QuartzCore

let listCellID = "ListCell"
let addListCellId = "AddListCell"
let kScrollZoneHeight: CGFloat = 50.0
let selectedCellColor: UIColor = UIColor(colorLiteralRed: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)

// ListSelectionDelegate protocol
protocol ListSelectionDelegate: class
{
    func listSelected(newList: List)
    func listNameChanged(newName: String)
    func listDeleted(deletedList: List)
}

let kListViewScrollRate: CGFloat =  6.0
let kListViewCellHeight: CGFloat = 60.0

class ListViewController: UITableViewController, UITextFieldDelegate
{
    var lists = [List]()
    var inEditMode = false
    var deleteListIndexPath: NSIndexPath? = nil
    var editModeRow = -1
    var longPressGestureRecognizer: UILongPressGestureRecognizer? = nil
    var sourceIndexPath: NSIndexPath? = nil
    var movingFromIndexPath: NSIndexPath? = nil
    var prevLocation: CGPoint? = nil
    var snapshot: UIView? = nil
    var displayLink: CADisplayLink? = nil
    var longPressActive = false    
    var selectionIndex = 0
    var editingNewListName = false
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    weak var delegate: ListSelectionDelegate?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        //self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        // set up long press gesture recognizer for the cell move functionality
        longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(ListViewController.longPressAction(_:)))
        self.tableView.addGestureRecognizer(longPressGestureRecognizer!)
        
        /*
        // info button
        let infoButton: UIButton = UIButton(type: UIButtonType.Custom)
        infoButton.setImage(UIImage(named: "EnListIcon"), forState: .Normal)
        infoButton.addTarget(self, action: #selector(ListViewController.infoButtonTapped), forControlEvents: .TouchUpInside)
        let rightBarButton = UIBarButtonItem()
        rightBarButton.customView = infoButton
        self.navigationItem.rightBarButtonItem = rightBarButton
        */
        
        // about button
        let button: UIButton = UIButton(type: UIButtonType.Custom)
        button.setImage(UIImage(named: "EnListIcon"), forState: UIControlState.Normal)
        button.addTarget(self, action: #selector(ListViewController.infoButtonTapped), forControlEvents: UIControlEvents.TouchUpInside)
        button.frame = CGRectMake(0, 0, 32, 32)
        let barButton = UIBarButtonItem(customView: button)
        self.navigationItem.leftBarButtonItem = barButton
        
        // set up keyboard show/hide notifications
        /*
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ListViewController.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ListViewController.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
        */
        
        // this is to suppress the extra cell separators in the table view
        self.tableView.tableFooterView = UIView()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // selectionIndex can be set by the AppDelegate with an initial list selection on app start (from saved state)
        self.selectList(selectionIndex)
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
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    */
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        // return the number of rows (plus 1 for the Add row)
        return lists.count + 1
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
        //return kListViewCellHeight
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        if indexPath.row < lists.count {
            // set up a List row
            let cell = tableView.dequeueReusableCellWithIdentifier(listCellID, forIndexPath: indexPath) as! ListCell
            
            // Configure the cell...
            let list = lists[indexPath.row]
            
            cell.listName.userInteractionEnabled = false
            cell.listName.delegate = self
            cell.listName.addTarget(self, action: #selector(ListViewController.listNameDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
            cell.listName.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
            cell.listName.text = list.name
            cell.listName.autocapitalizationType = appDelegate.namesCapitalize ? .Words : .None
            cell.listName.spellCheckingType = appDelegate.namesSpellCheck ? .Yes : .No
            cell.listName.autocorrectionType = appDelegate.namesAutocorrection ? .Yes : .No
            cell.listName.tag = indexPath.row
            cell.contentView.tag = indexPath.row
            
            // list background color
            if cell.selected {
                cell.backgroundColor = selectedCellColor
            } else {
                cell.backgroundColor = UIColor.whiteColor()
            }
            
            // set up single tap gesture recognizer in cat cell to enable expand/collapse
            let singleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ListViewController.cellSingleTapAction(_:)))
            singleTapGestureRecognizer.numberOfTapsRequired = 1
            cell.contentView.addGestureRecognizer(singleTapGestureRecognizer)
            
            // set up double tap gesture recognizer in item cell to enable cell moving
            let doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ListViewController.cellDoubleTapAction(_:)))
            doubleTapGestureRecognizer.numberOfTapsRequired = 2
            singleTapGestureRecognizer.requireGestureRecognizerToFail(doubleTapGestureRecognizer)
            cell.contentView.addGestureRecognizer(doubleTapGestureRecognizer)
            
            // cell separator
            cell.preservesSuperviewLayoutMargins = false
            cell.separatorInset = UIEdgeInsetsZero
            cell.layoutMargins = UIEdgeInsetsZero
            
            return cell
        } else {
            // set up Add row
            let cell = tableView.dequeueReusableCellWithIdentifier(addListCellId)
            
            // cell separator
            cell!.preservesSuperviewLayoutMargins = false
            cell!.separatorInset = UIEdgeInsetsZero
            cell!.layoutMargins = UIEdgeInsetsZero
            
            return cell!
        }
    }
    
    /*
    override func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, didHighlightRowAtIndexPath indexPath: NSIndexPath) {
        print("need to highlight item \(indexPath.row)")
    }
    
    override func tableView(tableView: UITableView, didUnhighlightRowAtIndexPath indexPath: NSIndexPath) {
        print("need to unhighlight item \(indexPath.row)")
    }
    */
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        self.selectList(indexPath.row)
    }
    
    /*
    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        let deselectedCell = tableView.cellForRowAtIndexPath(indexPath)!
        deselectedCell.contentView.backgroundColor = UIColor.whiteColor()
    }

    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        print("will select item \(indexPath.row)")
        return indexPath
    }
    
    override func tableView(tableView: UITableView, willDeselectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        print("will deselect item \(indexPath.row)")
        return indexPath
    }
    */
    
    // override to support conditional editing of the table view
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return indexPath.row < lists.count
    }
    
    // override to support editing the table view
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath)
    {
        if editingStyle == .Delete {
            deleteListIndexPath = indexPath
            let deletedList = lists[indexPath.row]
            
            confirmDelete(deletedList.name)
        }
        else if editingStyle == .Insert {
            // Create a new list instance, insert it into the array of lists, and add a new row to the table view
        }
    }
    
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath)
    {
        let list = lists[fromIndexPath.row]
        lists.removeAtIndex(fromIndexPath.row)
        lists.insert(list, atIndex: toIndexPath.row)
        
        self.tableView.reloadData()
    }
    
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool
    {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    
////////////////////////////////////////////////////////////////
//
//  MARK: - TextField methods
//
////////////////////////////////////////////////////////////////
    
    /*
    func keyboardWillShow(notification: NSNotification)
    {
        var info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        let keyboardHeight = keyboardFrame.height
        //let topBarHeight = getTopBarHeight()
        
        // need to shrink the tableView height so it shows above the keyboard
        tableView.frame.size.height = self.view.frame.height - keyboardHeight// + topBarHeight
        
        // while the keyboard is visible
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
    }
    
    func keyboardWillHide(notification: NSNotification)
    {
        //let topBarHeight = getTopBarHeight()
        
        // need to expand the tableView height so it fills the screen
        tableView.frame.size.height = self.view.frame.height
        
        // while the keyboard is visible
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
    }
    */
    
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool
    {
        // scroll the editing cell into view if necessary
        let indexPath = NSIndexPath(forRow: textField.tag, inSection: 0)
        
        if self.tableView.indexPathsForVisibleRows?.contains(indexPath) == false
        {
            tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition.Bottom, animated: false)
        }
        
        // this clears an initial space in a new cell name
        if textField.text == " " {
            textField.text = ""
        }
        
        return true
    }

    
    func listNameDidChange(textField: UITextField)
    {
        // update list name data with new value
        let i = textField.tag
        lists[i].name = textField.text!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        
        // update ItemVC list name
        delegate?.listNameChanged(textField.text!)
    }

    
    func textFieldShouldReturn(textField: UITextField) -> Bool
    {
        inEditMode = false
        textField.userInteractionEnabled = false
        textField.resignFirstResponder()
        self.tableView.setEditing(false, animated: true)
        
        // delete the newly added list if user didn't create a name
        if editingNewListName
        {
            if textField.text!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()).isEmpty
            {
                // delete from lists array
                lists.removeLast()
                self.tableView.reloadData()
            }
        }
        
        editingNewListName = false
        
        appDelegate.saveListData(true)
        
        return true
    }
    
    @IBAction func addListButtonTapped(sender: UIButton)
    {
        var listCount = 0
        
        for list in lists {
            if list.isTutorialList == false {
                listCount += 1
            }
        }
        
        if appDelegate.appIsUpgraded == false && listCount >= kMaxListCount
        {
            let listLimitTitle = NSLocalizedString("List_Limit", comment: "List Limit title for the list limit exceeded dialog in the free version.")
            let listLimitMsg = String(format: NSLocalizedString("List_Limit_Message", comment: "The free version of realList is limited to %i lists.  Please upgrade or restore your purchase for unlimited lists."), kMaxListCount)
            let okTitle = NSLocalizedString("OK", comment: "OK - to commit the action or dismiss a dialog.")
            
            // max list count (not including the tutorial) will be exceeded
            let alertVC = UIAlertController(
                title: listLimitTitle,
                message: listLimitMsg,
                preferredStyle: .Alert)
            let okAction = UIAlertAction(title: okTitle, style: .Default, handler: nil)
            alertVC.addAction(okAction)
            
            presentViewController(alertVC, animated: true, completion: nil)
            
            return
        }
        
        // create a new list and append
        let newList = List(name: "", createRecord: true)
        newList.listColorName = r1_2
        lists.append(newList)
        
        newList.addCategory("", displayHeader: false, updateIndices: true, createRecord: true)
        
        self.tableView.reloadData()
        
        // set up editing mode for list name
        let indexPath = NSIndexPath(forRow: lists.count - 1, inSection: 0)
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! ListCell
        
        inEditMode = true
        editingNewListName = true
        cell.listName.userInteractionEnabled = true
        cell.listName.becomeFirstResponder()
        editingNewListName = true
    }
    
////////////////////////////////////////////////////////////////
//
//  MARK: - Gesture Recognizer methods
//
////////////////////////////////////////////////////////////////
    
    // respond to a single tap (display the selected list in the ItemListViewController)
    func cellSingleTapAction(sender: UITapGestureRecognizer)
    {
        let i = sender.view?.tag
        let indexPath = NSIndexPath(forRow: i!, inSection: 0)
        
        let selectedList = self.lists[indexPath.row]
        self.delegate?.listSelected(selectedList)
        
        if let itemViewController = self.delegate as? ItemViewController {
            splitViewController?.showDetailViewController(itemViewController.navigationController!, sender: nil)
        }
    }
    
    // respond to a double tap (list name edit)
    func cellDoubleTapAction(sender: UITapGestureRecognizer)
    {
        if sender.view != nil {
            let indexPath = NSIndexPath(forRow: (sender.view?.tag)!, inSection: 0)
            let cell = tableView.cellForRowAtIndexPath(indexPath) as! ListCell
            
            inEditMode = true
            cell.listName.userInteractionEnabled = true
            cell.listName.becomeFirstResponder()
        }
    }
    
    // handle cell move on long press (move)
    func longPressAction(gesture: UILongPressGestureRecognizer)
    {
        let state: UIGestureRecognizerState = gesture.state
        let location: CGPoint = gesture.locationInView(tableView)
        let topBarHeight = getTopBarHeight()
        var indexPath: NSIndexPath? = tableView.indexPathForRowAtPoint(location)
        
        // prevent long press action on an AddItem cell
        if indexPath != nil {
            let cell = tableView.cellForRowAtIndexPath(indexPath!)
            
            if cell is AddListCell
            {
                // we got a long press on the AddList cell... cancel the action
                if longPressActive {
                    indexPath = NSIndexPath(forRow: lists.count - 1, inSection: 0)
                    longPressEnded(indexPath, location: location)
                }
                return
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
                longPressEnded(indexPath, location: location)   // comment out this line to let the moving cell hang at the top until released -- may cause problems with snapshot not getting cleared
            }
            return
        }
        
        // check if we need to scroll tableView
        let touchLocation = gesture.locationInView(gesture.view!.window)
        
        if touchLocation.y > (tableView.bounds.height - kScrollZoneHeight) {
            // need to scroll down
            if displayLink == nil {
                displayLink = CADisplayLink(target: self, selector: #selector(ListViewController.scrollDownLoop))
                displayLink!.frameInterval = 1
                displayLink!.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
            }
        } else if touchLocation.y < (topBarHeight + kScrollZoneHeight) {
            // need to scroll up
            if displayLink == nil {
                displayLink = CADisplayLink(target: self, selector: #selector(ListViewController.scrollUpLoop))
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
        
        switch (state) {
        case UIGestureRecognizerState.Began:
            longPressActive = true
            sourceIndexPath = indexPath
            movingFromIndexPath = indexPath
            
            let cell = tableView.cellForRowAtIndexPath(indexPath!)!
            snapshot = snapshotFromView(cell)
            
            var center = cell.center
            snapshot?.center = center
            snapshot?.alpha = 0.0
            tableView.addSubview(snapshot!)
            
            UIView.animateWithDuration(0.25, animations: { () -> Void in
                center.y = location.y
                self.snapshot?.center = center
                self.snapshot?.transform = CGAffineTransformMakeScale(1.05, 1.05)
                self.snapshot?.alpha = 0.7
                cell.alpha = 0.0
                }, completion: { (finished: Bool) -> Void in
                    cell.hidden = true      // hides the real cell while moving
            })
            
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
    
    func longPressMoved(indexPath: NSIndexPath?, location: CGPoint)
    {
        if snapshot != nil {
            var center: CGPoint = snapshot!.center
            center.y = location.y
            snapshot?.center = center
            
            if indexPath != nil && location.y > 0 {
                // check if destination is different from source and valid then move the cell in the tableView
                if movingFromIndexPath != nil
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
    func longPressEnded(idxPath: NSIndexPath?, location: CGPoint)
    {
        longPressActive = false
        
        // cancel any scroll loop
        displayLink?.invalidate()
        displayLink = nil
        
        guard var indexPath = idxPath else { return }
        
        let destCell = self.tableView.cellForRowAtIndexPath(indexPath)
        
        // if we are dropping on the AddList cell then move dest to just above the AddList cell
        if destCell is AddListCell {
            indexPath = NSIndexPath(forRow: indexPath.row-1, inSection: 0)
        }
        
        // finalize list data with new location for sourceIndexObj
        if sourceIndexPath != nil {
            var center: CGPoint = snapshot!.center
            center.y = location.y
            snapshot?.center = center
            
            // check if destination is different from source and valid
            if indexPath != sourceIndexPath {
                // we are moving an item
                tableView.beginUpdates()
                
                // remove the item from its original location
                let removedList = lists.removeAtIndex(sourceIndexPath!.row)
                lists.insert(removedList, atIndex: indexPath.row)

                tableView.endUpdates()
            }
        } else {
            print("sourceIndexPath is nil...")
        }
        
        // clean up any snapshot views or displayLink scrolls
        let cell: UITableViewCell? = tableView.cellForRowAtIndexPath(indexPath)
        
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
        
        // need to reset the list order values
        var i = 0
        for list in lists {
            list.order = i
            i += 1
        }
        
        // and save data changes locally and to the cloud
        appDelegate.saveListData(true)
    }
    
    func scrollUpLoop()
    {
        let currentOffset = tableView.contentOffset
        let topBarHeight = getTopBarHeight()
        let newOffsetY = max(currentOffset.y - kListViewScrollRate, -topBarHeight)
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
        let lastCellIndex = NSIndexPath(forRow: lists.count - 1, inSection: 0)
        let lastCell = tableView.cellForRowAtIndexPath(lastCellIndex)
        
        if lastCell == nil {
            self.tableView.setContentOffset(CGPoint(x: currentOffset.x, y: currentOffset.y + kListViewScrollRate), animated: false)
            
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
    
    // presents the about window
    func infoButtonTapped()
    {
        let aboutVC = AboutViewController()
        aboutVC.listVC = self
        presentViewController(aboutVC, animated: true, completion: nil)
    }
    
    func confirmDelete(listName: String)
    {
        let DeleteListTitle = NSLocalizedString("Delete_List_Title", comment: "A title in an alert asking if the user wants to delete a list.")
        let DeleteListMessage = String(format: NSLocalizedString("Delete_List_Message", comment: "Are you sure you want to permanently delete the list %@?"), listName)
        
        let alert = UIAlertController(title: DeleteListTitle, message: DeleteListMessage, preferredStyle: .Alert)
        let deleteAction = UIAlertAction(title: NSLocalizedString("Delete", comment: "The Delete button title"), style: .Destructive, handler: handleDeleteList)
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "The Cancel button title"), style: .Cancel, handler: cancelDeleteList)
        
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        
        // Support display in iPad
        alert.popoverPresentationController?.sourceView = self.view
        alert.popoverPresentationController?.sourceRect = CGRectMake(self.view.bounds.size.width / 2.0, self.view.bounds.size.height / 2.0, 1.0, 1.0)
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func handleDeleteList(alertAction: UIAlertAction!) -> Void
    {
        if let indexPath = deleteListIndexPath
        {
            tableView.beginUpdates()
            
            // notify the ItemViewController that a list is being deleted
            let deletedList = lists[indexPath.row]
            self.delegate?.listDeleted(deletedList)
            
            // delete the list from cloud storage
            let list = lists[indexPath.row]
            list.deleteFromCloud()
            
            // delete the list from the data source
            lists.removeAtIndex(indexPath.row)
            
            // delete list index path from the table view
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            self.tableView.reloadData()
            deleteListIndexPath = nil
            
            tableView.endUpdates()
        }
    }
    
    func cancelDeleteList(alertAction: UIAlertAction!)
    {
        deleteListIndexPath = nil
        self.setEditing(false, animated: true)
    }
    
////////////////////////////////////////////////////////////////
//
//  MARK: - Helper methods
//
////////////////////////////////////////////////////////////////

    func selectList(index: Int)
    {
        selectionIndex = index
        
        if lists.count > selectionIndex && selectionIndex >= 0 {
            let selectedList = lists[selectionIndex]
            delegate?.listSelected(selectedList)
            
            // deselect all cells
            var i = 0
            for list in lists {
                list.order = i
                let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: i, inSection: 0))
                cell?.backgroundColor = UIColor.whiteColor()
                i += 1
            }
            
            // then select the current cell
            let selectedCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: selectionIndex, inSection: 0))
            selectedCell?.backgroundColor = selectedCellColor
            
            appDelegate.saveState(true)
        }
    }
    
    func getTopBarHeight() -> CGFloat {
        let statusBarHeight = UIApplication.sharedApplication().statusBarFrame.size.height
        let navBarHeight = self.navigationController!.navigationBar.frame.size.height
        
        return statusBarHeight + navBarHeight
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
    
    /*
    func clearNeedToSave() {
        for list in lists {
            list.needToSave = false
            
            for category in list.categories {
                category.needToSave = false
                
                for item in category.items {
                    item.needToSave = false
                }
            }
        }
    }
    */
    
    func countNeedToSave() -> Int {
        var count = 0
        
        for list in lists {
            if list.needToSave {
                count += 1
            }
            
            for category in list.categories {
                if category.needToSave {
                    count += 1
                }
                
                for item in category.items {
                    if item.needToSave {
                        count += 1
                    }
                }
            }
        }
        
        return count
    }
    
    // reorder lists, categories and items according to order number
    func reorderListObjects()
    {
        // sort lists
        lists.sortInPlace { $0.order < $1.order }
        
        for list in lists {
            list.categories.sortInPlace { $0.order < $1.order }
            
            for category in list.categories {
                category.items.sortInPlace { $0.order < $1.order }
            }
            
            list.updateIndices()
        }
    }
    
    func getListForCategory(category: Category) -> List?
    {
        for list in lists {
            for category in list.categories {
                if category === category {
                    return list
                }
            }
        }
        
        return nil
    }
    
    func getCategoryForItem(searchItem: Item) -> Category?
    {
        for list in lists {
            for category in list.categories {
                for item in category.items {
                    if item === searchItem {
                        return category
                    }
                }
            }
        }
        
        return nil
    }
    
////////////////////////////////////////////////////////////////
    
    func generateTutorial()
    {
        // do we already have a tutorial loaded?
        var i = 0
        for list in lists {
            if list.isTutorialList {
                self.selectionIndex = i
                return
            }
            i += 1
        }
        
        // list1
        let tutorial = List(name: "realList Tutorial", createRecord: true, tutorial: true)
        tutorial.listColorName = r1_2
        lists.append(tutorial)
        tutorial.order = lists.count-1
        
        var item: Item?
        
        // Getting started...
        let cat1 = tutorial.addCategory("Getting started...", displayHeader: true, updateIndices: false, createRecord: true, tutorial: true)
        
        item = tutorial.addItem(cat1, name: "Things to know about realList...", state: ItemState.Incomplete, updateIndices: false, createRecord: true, tutorial: true)
        item!.note = "...check them off as you learn them!"
        
        item = tutorial.addItem(cat1, name: "Make a new list item...", state: ItemState.Incomplete, updateIndices: false, createRecord: true, tutorial: true)
        item!.note = "...tap the item add button below."
        item!.imageAsset!.image = UIImage(named: "Tutorial_AddItem")
        
        // Item actions...
        let cat2 = tutorial.addCategory("Item actions...", displayHeader: true, updateIndices: false, createRecord: true, tutorial: true)
        item = tutorial.addItem(cat2, name: "Single tap an item...", state: ItemState.Incomplete, updateIndices: false, createRecord: true, tutorial: true)
        item!.note = "...to add a note like this."
        
        item = tutorial.addItem(cat2, name: "Add a picture to an item...", state: ItemState.Incomplete, updateIndices: false, createRecord: true, tutorial: true)
        item!.note = "...use the Camera icon to add a picture from your iOS camera or your photo library.  Tap the camera icon again to delete the picture from the item.  Try it!"
        
        item = tutorial.addItem(cat2, name: "Double tap an item...", state: ItemState.Incomplete, updateIndices: false, createRecord: true, tutorial: true)
        item!.note = "...to edit the item name."
        
        item = tutorial.addItem(cat2, name: "Swipe left...", state: ItemState.Incomplete, updateIndices: false, createRecord: true, tutorial: true)
        item!.note = "...to delete an item."
        item!.imageAsset!.image = UIImage(named: "Tutorial_Delete")
        
        item = tutorial.addItem(cat2, name: "Tap the check box...", state: ItemState.Incomplete, updateIndices: false, createRecord: true, tutorial: true)
        item!.note = "...to mark the item as completed."
        item!.imageAsset!.image = UIImage(named: "Tutorial_Checkbox_checked")
        
        item = tutorial.addItem(cat2, name: "Tap again...", state: ItemState.Incomplete, updateIndices: false, createRecord: true, tutorial: true)
        item!.note = "...to mark it as inactive."
        item!.imageAsset!.image = UIImage(named: "Tutorial_Checkbox_inactive")
        
        item = tutorial.addItem(cat2, name: "Tap again...", state: ItemState.Incomplete, updateIndices: false, createRecord: true, tutorial: true)
        item!.note = "...to mark it as active."
        item!.imageAsset!.image = UIImage(named: "Tutorial_Checkbox_active")
        
        item = tutorial.addItem(cat2, name: "Press, hold and drag...", state: ItemState.Incomplete, updateIndices: false, createRecord: true, tutorial: true)
        item!.note = "...to move an item."
        
        // Category actions...
        let cat3 = tutorial.addCategory("Category actions...", displayHeader: true, updateIndices: false, createRecord: true, tutorial: true)
        
        item = tutorial.addItem(cat3, name: "Create a new category...", state: ItemState.Incomplete, updateIndices: false, createRecord: true, tutorial: true)
        item!.note = "...tap the settings icon (upper right) and then tap the icon with the green plus to make a new category."
        item!.imageAsset!.image = UIImage(named: "Tutorial_AddCategory")
        
        item = tutorial.addItem(cat3, name: "Single tap a category...", state: ItemState.Incomplete, updateIndices: false, createRecord: true, tutorial: true)
        item!.note = "...to collapse all the items in that category."
        item!.imageAsset!.image = UIImage(named: "Tutorial_Category_collapsed")
        
        item = tutorial.addItem(cat3, name: "Single tap it again...", state: ItemState.Incomplete, updateIndices: false, createRecord: true, tutorial: true)
        item!.note = "...to expand it."
        item!.imageAsset!.image = UIImage(named: "Tutorial_Category_expanded")
        
        item = tutorial.addItem(cat3, name: "Double tap a category...", state: ItemState.Incomplete, updateIndices: false, createRecord: true, tutorial: true)
        item!.note = "...to edit its name."
        
        item = tutorial.addItem(cat3, name: "Swipe left...", state: ItemState.Incomplete, updateIndices: false, createRecord: true, tutorial: true)
        item!.note = "...to delete a category."
        item!.imageAsset!.image = UIImage(named: "Tutorial_Delete_category")
        
        item = tutorial.addItem(cat3, name: "Press, hold and drag a category...", state: ItemState.Incomplete, updateIndices: false, createRecord: true, tutorial: true)
        item!.note = "...to move it."
        
        // List actions...
        let cat4 = tutorial.addCategory("List actions...", displayHeader: true, updateIndices: false, createRecord: true, tutorial: true)
        item = tutorial.addItem(cat4, name: "Tap the 'Lists' button above...", state: ItemState.Incomplete, updateIndices: false, createRecord: true, tutorial: true)
        item!.note = "...to go back to the lists view.  (Note: on an iPad the Lists will always be on the left so there is no Lists button.)"
        item!.imageAsset!.image = UIImage(named: "Tutorial_Lists_button")
        
        item = tutorial.addItem(cat4, name: "Create a new list...", state: ItemState.Incomplete, updateIndices: false, createRecord: true, tutorial: true)
        item!.note = "...with the list add button."
        item!.imageAsset!.image = UIImage(named: "Tutorial_AddList")
        
        // Settings actions...
        let cat5 = tutorial.addCategory("Settings actions...", displayHeader: true, updateIndices: false, createRecord: true, tutorial: true)
        
        item = tutorial.addItem(cat5, name: "Tap the settings button...", state: ItemState.Incomplete, updateIndices: false, createRecord: true, tutorial: true)
        item!.note = "...for general list item actions."
        item!.imageAsset!.image = UIImage(named: "Tutorial_Settings")
        
        item = tutorial.addItem(cat5, name: "These buttons let you...", state: ItemState.Incomplete, updateIndices: false, createRecord: true, tutorial: true)
        item!.note = "...collapse all categories."
        item!.imageAsset!.image = UIImage(named: "Tutorial_collapse_all")
        
        item = tutorial.addItem(cat5, name: "and...", state: ItemState.Incomplete, updateIndices: false, createRecord: true, tutorial: true)
        item!.note = "...expand all categories."
        item!.imageAsset!.image = UIImage(named: "Tutorial_expand_all")
        
        item = tutorial.addItem(cat5, name: "and...", state: ItemState.Incomplete, updateIndices: false, createRecord: true, tutorial: true)
        item!.note = "...create new categories."
        item!.imageAsset!.image = UIImage(named: "Tutorial_AddCategory")
        
        item = tutorial.addItem(cat5, name: "and...", state: ItemState.Incomplete, updateIndices: false, createRecord: true, tutorial: true)
        item!.note = "...control what items are shown.  The left button will show/hide the completed items and the right button will show/hide inactive items."
        item!.imageAsset!.image = UIImage(named: "Tutorial_show_hide_items")
        
        item = tutorial.addItem(cat5, name: "and...", state: ItemState.Incomplete, updateIndices: false, createRecord: true, tutorial: true)
        item!.note = "...set all items to active or inactive."
        item!.imageAsset!.image = UIImage(named: "Tutorial_set_all_items")
        
        item = tutorial.addItem(cat5, name: "and...", state: ItemState.Incomplete, updateIndices: false, createRecord: true, tutorial: true)
        item!.note = "...change the color of your list."
        item!.imageAsset!.image = UIImage(named: "Tutorial_list_colors")
        
        item = tutorial.addItem(cat5, name: "and...", state: ItemState.Incomplete, updateIndices: false, createRecord: true, tutorial: true)
        item!.note = "...print your list with AirPrint."
        item!.imageAsset!.image = UIImage(named: "Tutorial_print")
        
        item = tutorial.addItem(cat5, name: "and...", state: ItemState.Incomplete, updateIndices: false, createRecord: true, tutorial: true)
        item!.note = "...email your list."
        item!.imageAsset!.image = UIImage(named: "Tutorial_email")
        
        item = tutorial.addItem(cat5, name: "and...", state: ItemState.Incomplete, updateIndices: false, createRecord: true, tutorial: true)
        item!.note = "...print and email your lists with or without notes."
        item!.imageAsset!.image = UIImage(named: "Tutorial_include_notes")
        
        // Synchronize devices...
        let cat6 = tutorial.addCategory("Synchronize devices...", displayHeader: true, updateIndices: false, createRecord: true, tutorial: true)
        
        item = tutorial.addItem(cat6, name: "realList can synchronize lists...", state: ItemState.Incomplete, updateIndices: false, createRecord: true, tutorial: true)
        item!.note = "...between all of your iOS devices.  Follow the next steps to set up iCloud synchronization for realList."
        item!.imageAsset!.image = UIImage(named: "Tutorial_iCloud_sync")
        
        item = tutorial.addItem(cat6, name: "1. Go to the About view...", state: ItemState.Incomplete, updateIndices: false, createRecord: true, tutorial: true)
        item!.note = "...access from the realList icon at the top of the List view."
        item!.imageAsset!.image = UIImage(named: "Tutorial_About_button")
        
        item = tutorial.addItem(cat6, name: "2. Check if iCloud is enabled...", state: ItemState.Incomplete, updateIndices: false, createRecord: true, tutorial: true)
        item!.note = "...if there is a green check mark in the cloud then realList is connected to iCloud.  If not, then go to the next steps to set up iCloud synchronization."
        item!.imageAsset!.image = UIImage(named: "Cloud_check")
        
        item = tutorial.addItem(cat6, name: "3. Set up your Apple iCloud account...", state: ItemState.Incomplete, updateIndices: false, createRecord: true, tutorial: true)
        item!.note = "...if you don't already have an iCloud account then set up now (it's free).  Tap the iCloud Settings button and enter your email address and a password for iCloud.  Apple gives you 5GB of data storage for free."
        item!.imageAsset!.image = UIImage(named: "Tutorial_iCloud_setup")
        
        item = tutorial.addItem(cat6, name: "4. Turn on iCloud Drive...", state: ItemState.Incomplete, updateIndices: false, createRecord: true, tutorial: true)
        item!.note = "...below the iCloud setup, tap on iCloud Drive and turn it On then scroll down to verify that iCloud drive is turned on for realList.  Once iCloud Drive is set up then realList will send/receive list changes to/from your iCloud drive and will automatically share lists between all of your iOS devices that are set up with iCloud.  Tap 'Back to realList' in the upper left corner."
        item!.imageAsset!.image = UIImage(named: "Tutorial_iCloudDrive_setup")
        
        item = tutorial.addItem(cat6, name: "5. Enable notifications...", state: ItemState.Incomplete, updateIndices: false, createRecord: true, tutorial: true)
        item!.note = "Notifications let realList synchronize between your iOS devices as you make changes to you lists.  Tap the Notification Settings button.  If you answered OK to notifications when realList first launched then this should already be set up.  If Notifications are off, then you can enable it here.  Tap Notifications and enable 'Allow Notifications' and realList is now set up for synchronization.  Be sure to do these steps on all of your iOS devices to share your list data between them."
        item!.imageAsset!.image = UIImage(named: "Tutorial_notifications")
        
        // About view...
        let cat7 = tutorial.addCategory("The About view...", displayHeader: true, updateIndices: false, createRecord: true, tutorial: true)
        
        item = tutorial.addItem(cat7, name: "The About view tells you...", state: ItemState.Incomplete, updateIndices: false, createRecord: true, tutorial: true)
        item!.note = "...about the status of your app and lets you choose preferences."
        item!.imageAsset!.image = UIImage(named: "Tutorial_About_view")
        
        item = tutorial.addItem(cat7, name: "You already saw...", state: ItemState.Incomplete, updateIndices: false, createRecord: true, tutorial: true)
        item!.note = "...the iCloud Settings and Notification Settings buttons."
        item!.imageAsset!.image = UIImage(named: "Tutorial_iCloud_Notification_Settings_buttons")
        
        item = tutorial.addItem(cat7, name: "App Settings...", state: ItemState.Incomplete, updateIndices: false, createRecord: true, tutorial: true)
        item!.note = "...the App Settings let you control auto capitalization and spell checking behaviors of names and notes.  Also you can control if pictures are included with item notes when you AirPrint your lists."
        item!.imageAsset!.image = UIImage(named: "Tutorial_AppSettings_button")
        
        item = tutorial.addItem(cat7, name: "Upgrade...", state: ItemState.Incomplete, updateIndices: false, createRecord: true, tutorial: true)
        item!.note = "...the Upgrade view lets you purchase an upgrade that removes limits on lists and items and removes the ad banner at the bottom of the item view.  Here you can also restore your purchase if you have already purchased the upgraded version.  After you have upgraded realList the white arrow in the Upgrade button turns to green."
        item!.imageAsset!.image = UIImage(named: "Tutorial_Upgrade_button")
        
        item = tutorial.addItem(cat7, name: "Tutorial...", state: ItemState.Incomplete, updateIndices: false, createRecord: true, tutorial: true)
        item!.note = "...the Tutorial button will either take you to the tutorial list or generate a new copy of the tutorial if you have deleted it."
        item!.imageAsset!.image = UIImage(named: "Tutorial_Tutorial_button")
        
        // All done...
        let cat8 = tutorial.addCategory("All done!!", displayHeader: true, updateIndices: false, createRecord: true, tutorial: true)
        item = tutorial.addItem(cat8, name: "You can delete this turorial...", state: ItemState.Incomplete, updateIndices: false, createRecord: true, tutorial: true)
        item!.note = "...from the Lists view at any time."
        
        item = tutorial.addItem(cat8, name: "You can add it again...", state: ItemState.Incomplete, updateIndices: false, createRecord: true, tutorial: true)
        item!.note = "...from the About view if you wish."
        item!.imageAsset!.image = UIImage(named: "Tutorial_Tutorial_button")
        
        item = tutorial.addItem(cat8, name: "Now you can...", state: ItemState.Incomplete, updateIndices: false, createRecord: true, tutorial: true)
        item!.note = "... start making your own lists!  If you have any questions please send them to the email contacts on the About view."
        item!.imageAsset!.image = UIImage(named: "Tutorial_contacts")
        
        // select the newly added tutorial
        self.selectionIndex = self.lists.count-1
        
        // housekeeping
        tutorial.updateIndices()
        self.tableView.reloadData()
    }
    
    /*
    func addTestItems()
    {
        // list1
        let list1 = List(name: "Costco", createRecord: true)
        lists.append(list1)
        
        let cat1_1 = list1.addCategory("Fruits and Veggies", displayHeader: true, updateIndices: false, createRecord: true)
        let cat1_2 = list1.addCategory("Meats", displayHeader: true, updateIndices: false, createRecord: true)
        let cat1_3 = list1.addCategory("Other", displayHeader: true, updateIndices: false, createRecord: true)
        
        list1.addItem(cat1_1, name: "Carrots", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        list1.addItem(cat1_1, name: "Squash", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        list1.addItem(cat1_1, name: "Tomatoes", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        list1.addItem(cat1_1, name: "Potatoes", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        list1.addItem(cat1_1, name: "Apples", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        list1.addItem(cat1_1, name: "Oranges", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        list1.addItem(cat1_1, name: "Lettuce", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        list1.addItem(cat1_1, name: "Onions", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        list1.addItem(cat1_1, name: "Bananas", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        list1.addItem(cat1_1, name: "Strawberries", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        list1.addItem(cat1_1, name: "Grapes", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        list1.addItem(cat1_1, name: "Peaches", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        
        list1.addItem(cat1_2, name: "Chicken", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        list1.addItem(cat1_2, name: "Sirloin", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        list1.addItem(cat1_2, name: "Salmon", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        list1.addItem(cat1_2, name: "Cod", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        list1.addItem(cat1_2, name: "Halibut", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        list1.addItem(cat1_2, name: "Ham", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        list1.addItem(cat1_2, name: "Bison", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        
        list1.addItem(cat1_3, name: "Water", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        list1.addItem(cat1_3, name: "Dinty Moore", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        list1.addItem(cat1_3, name: "Noodle Chicken Bag", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        list1.addItem(cat1_3, name: "Tea Bags", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        list1.addItem(cat1_3, name: "Vegtable Soup", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        list1.addItem(cat1_3, name: "Cookie Mix", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        list1.addItem(cat1_3, name: "Salad fixings", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        list1.addItem(cat1_3, name: "Salad dressing", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        
        // list2
        let list2 = List(name: "Safeway", createRecord: true)
        lists.append(list2)
        
        let cat2_1 = list2.addCategory("", displayHeader: false, updateIndices: false, createRecord: true)
        
        list2.addItem(cat2_1, name: "Juice", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        list2.addItem(cat2_1, name: "Cream Cheese", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        list2.addItem(cat2_1, name: "Deli Ham", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        list2.addItem(cat2_1, name: "Potatoes", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        list2.addItem(cat2_1, name: "Bananas", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        list2.addItem(cat2_1, name: "Oranges", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        
        // list3
        let list3 = List(name: "King Sooper", createRecord: true)
        lists.append(list3)
        
        let cat3_1 = list3.addCategory("", displayHeader: false, updateIndices: false, createRecord: true)
        
        list3.addItem(cat3_1, name: "Bread", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        list3.addItem(cat3_1, name: "Tomatoes", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        list3.addItem(cat3_1, name: "Coffee", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        list3.addItem(cat3_1, name: "Syrup", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        list3.addItem(cat3_1, name: "Dog toys", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        list3.addItem(cat3_1, name: "Leggings", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        
        // list4
        let list4 = List(name: "Trail Mannor", createRecord: true)
        lists.append(list4)
        
        let cat4_1 = list4.addCategory("", displayHeader: false, updateIndices: false, createRecord: true)
        
        list4.addItem(cat4_1, name: "Bread", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        list4.addItem(cat4_1, name: "Popcorn", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        list4.addItem(cat4_1, name: "Ramen noodles", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        list4.addItem(cat4_1, name: "Sleeping bags", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        list4.addItem(cat4_1, name: "Soap", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        list4.addItem(cat4_1, name: "Towels", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        list4.addItem(cat4_1, name: "Food", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        list4.addItem(cat4_1, name: "Bacon", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        list4.addItem(cat4_1, name: "Cereal", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        list4.addItem(cat4_1, name: "Coffee", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        list4.addItem(cat4_1, name: "Water", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        
        // list5
        let list5 = List(name: "Home Depot", createRecord: true)
        lists.append(list5)
        
        let cat5_1 = list5.addCategory("", displayHeader: false, updateIndices: false, createRecord: true)
        
        list5.addItem(cat5_1, name: "Paint", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        list5.addItem(cat5_1, name: "Nails", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        list5.addItem(cat5_1, name: "Extension cord", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        list5.addItem(cat5_1, name: "Toilet kit", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        list5.addItem(cat5_1, name: "Shower head", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        list5.addItem(cat5_1, name: "Garden hose", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        list5.addItem(cat5_1, name: "Lights", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        list5.addItem(cat5_1, name: "3/8' plywood", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        list5.addItem(cat5_1, name: "Power tools", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        list5.addItem(cat5_1, name: "Potting soil", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        list5.addItem(cat5_1, name: "Cat 6 cable", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        list5.addItem(cat5_1, name: "Wall plates", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        
        // list6
        let list6 = List(name: "Walmart", createRecord: true)
        lists.append(list6)
        
        let cat6_1 = list6.addCategory("", displayHeader: false, updateIndices: false, createRecord: true)
        
        list6.addItem(cat6_1, name: "Dog Shampoo", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        list6.addItem(cat6_1, name: "Chips", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        list6.addItem(cat6_1, name: "Movies", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        list6.addItem(cat6_1, name: "Subway sandwich", state: ItemState.Incomplete, updateIndices: true, createRecord: true)
        
        
        // update cell type array in temp lists
        /*
        list1.updateCellTypeArray()
        list2.updateCellTypeArray()
        list3.updateCellTypeArray()
        list4.updateCellTypeArray()
        list5.updateCellTypeArray()
        list6.updateCellTypeArray()
        */
    }
    */
}
