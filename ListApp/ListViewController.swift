//
//  ListViewController.swift
//  ListApp
//
//  Created by Steven Gentry on 12/30/15.
//  Copyright © 2015 Steven Gentry. All rights reserved.
//

import UIKit
import QuartzCore

let listCellID = "ListCell"
let addListCellId = "AddListCell"

// ListSelectionDelegate protocol
protocol ListSelectionDelegate: class
{
    func listSelected(newList: List)
    func listDeleted(deletedList: List)
}

let kListViewScrollRate: CGFloat = 6.0
let kListViewCellHeight: CGFloat = 44.0

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
    var scrollLoopCount = 0     // debugging var
    var longPressActive = false    
    var selectionIndex = -1
    var editingNewListName = false
    
    weak var delegate: ListSelectionDelegate?
    
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
        
        // this is to suppress the extra cell separators in the table view
        self.tableView.tableFooterView = UIView()
        
        // selectionIndex can be set by the AppDelegate with an initial list selection on app start (from saved state)
        self.selectList(selectionIndex)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        //navigationController?.hidesBarsOnSwipe = false
        
        // in this case, it's good to combine hidesBarsOnTap with hidesBarsWhenKeyboardAppears
        // so the user can get back to the navigation bar to save
        //navigationController?.hidesBarsOnTap = true
        //navigationController?.hidesBarsWhenKeyboardAppears = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    required init(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)!
        
        // adds temp test items
        addTestItems()
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
            cell.listName.addTarget(self, action: "listNameDidChange:", forControlEvents: UIControlEvents.EditingChanged)
            cell.listName.attributedText = makeAttributedString(title: list.name, subtitle: "")
            cell.listName.tag = indexPath.row
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
    override func prefersStatusBarHidden() -> Bool {
        return navigationController?.navigationBarHidden == true
    }
    
    override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        return UIStatusBarAnimation.Slide
    }
    */
    
    func listNameDidChange(textField: UITextField)
    {
        // update list name data with new value
        let i = textField.tag
        lists[i].name = textField.text!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        
        print(lists[i].name)
    }

    
    func textFieldShouldReturn(textField: UITextField) -> Bool
    {
        inEditMode = false
        textField.userInteractionEnabled = false
        textField.resignFirstResponder()
        self.tableView.setEditing(false, animated: true)
        
        // delete the newly added list if use didn't create a name
        if editingNewListName
        {
            if textField.text!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()) == ""
            {
                lists.removeLast()
                self.tableView.reloadData()
            }
        }
        
        // do we need this???
        UIView.animateWithDuration(0.25) {
            self.navigationController?.navigationBarHidden = false
        }
        
        editingNewListName = false
        
        return true
    }
    
    @IBAction func addListButtonTapped(sender: UIButton)
    {
        // create a new list and append
        let newList = List(name: "")
        newList.categories.append(Category(name: ""))
        lists.append(newList)
        self.tableView.reloadData()
        
        // set up editing mode for list name
        let indexPath = NSIndexPath(forRow: lists.count - 1, inSection: 0)
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! ListCell
        
        inEditMode = true
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
                return
            }
        }
        
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
        
        switch (state)
        {
        case UIGestureRecognizerState.Began:
            longPressActive = true
            sourceIndexPath = indexPath
            movingFromIndexPath = indexPath
            let cell = tableView.cellForRowAtIndexPath(indexPath!)!
            snapshot = snapshotFromView(cell)
            
            //let obj = list.objectAtIndexPath(sourceIndexPath!)
            
            //if obj is Item || obj is Category {
            
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
            
            //}
            
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
            if indexPath != sourceIndexPath && indexPath != nil
            {
                // we are moving an item
                tableView.beginUpdates()
                
                // remove the item from its original location
                let removedList = lists.removeAtIndex(sourceIndexPath!.row)
                lists.insert(removedList, atIndex: indexPath!.row)

                tableView.endUpdates()
            }
        } else {
            print("sourceIndexPath is nil...!!!")
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
        })
        
        self.tableView.reloadData()
        
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
        let lastCellIndex = NSIndexPath(forRow: lists.count - 1, inSection: 0)
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
    
    func confirmDelete(listName: String)
    {
        let alert = UIAlertController(title: "Delete List", message: "Are you sure you want to permanently delete the list \(listName)?", preferredStyle: .Alert)
        
        let DeleteAction = UIAlertAction(title: "Delete", style: .Destructive, handler: handleDeleteList)
        let CancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: cancelDeleteList)
        
        alert.addAction(DeleteAction)
        alert.addAction(CancelAction)
        
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
            
            /////////
            // TBD: *******  verify that underlying categories and items are also deleted!!!!!!!  *******
            /////////
            // delete the row from the data source
            lists.removeAtIndex(indexPath.row)
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
        if lists.count > index && index >= 0 {
            delegate?.listSelected(lists[index])
            
            // deselect all cells
            var i = 0
            for _ in lists {
                let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: i, inSection: 0))
                cell?.backgroundColor = UIColor.whiteColor()
                ++i
            }
            
            // then select the current cell
            let selectedCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: index, inSection: 0))
            selectedCell?.backgroundColor = UIColor(colorLiteralRed: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
        }
    }
    
    func makeAttributedString(title title: String, subtitle: String) -> NSAttributedString {
        let titleAttributes = [NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleBody), NSForegroundColorAttributeName: UIColor.blackColor()]
        let subtitleAttributes = [NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleSubheadline)]
        
        let titleString = NSMutableAttributedString(string: "\(title)\n", attributes: titleAttributes)
        let subtitleString = NSAttributedString(string: subtitle, attributes: subtitleAttributes)
        
        titleString.appendAttributedString(subtitleString)
        
        return titleString
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
    
////////////////////////////////////////////////////////////////
    
    func addTestItems()
    {
        // list1
        let list1 = List(name: "Costco")
        lists.append(list1)
        
        let cat1_1 = Category(name: "Fruits and Veggies")
        let cat1_2 = Category(name: "Meats")
        let cat1_3 = Category(name: "Other")
        
        list1.categories.append(cat1_1)
        list1.categories.append(cat1_2)
        list1.categories.append(cat1_3)
        
        cat1_1.items.append(Item(name: "Carrots"))
        cat1_1.items.append(Item(name: "Squash"))
        cat1_1.items.append(Item(name: "Tomatoes"))
        cat1_1.items.append(Item(name: "Potatoes"))
        cat1_1.items.append(Item(name: "Apples"))
        cat1_1.items.append(Item(name: "Oranges"))
        cat1_1.items.append(Item(name: "Lettuce"))
        cat1_1.items.append(Item(name: "Onions"))
        cat1_1.items.append(Item(name: "Bananas"))
        cat1_1.items.append(Item(name: "Strawberries"))
        
        cat1_2.items.append(Item(name: "Chicken"))
        cat1_2.items.append(Item(name: "Sirloin"))
        cat1_2.items.append(Item(name: "Salmon"))
        cat1_2.items.append(Item(name: "Cod"))
        cat1_2.items.append(Item(name: "Halibut"))
        cat1_2.items.append(Item(name: "Ham"))
        
        cat1_3.items.append(Item(name: "Noodle Chicken Bag"))
        cat1_3.items.append(Item(name: "Soda"))
        cat1_3.items.append(Item(name: "Dinty Moore"))
        cat1_3.items.append(Item(name: "Tea Bags"))
        cat1_3.items.append(Item(name: "Vegtable Soup"))
        cat1_3.items.append(Item(name: "Cookie Mix"))
        cat1_3.items.append(Item(name: "Salad fixings"))
        cat1_3.items.append(Item(name: "Dressing"))
        
        // list2
        let list2 = List(name: "Safeway")
        lists.append(list2)
        
        let cat2_1 = Category(name: "")
        list2.categories.append(cat2_1)
        
        cat2_1.items.append(Item(name: "Juice"))
        cat2_1.items.append(Item(name: "Cream Cheese"))
        cat2_1.items.append(Item(name: "Deli Ham"))
        cat2_1.items.append(Item(name: "Potatoes"))
        cat2_1.items.append(Item(name: "Bananas"))
        cat2_1.items.append(Item(name: "Oranges"))
        
        // list3
        let list3 = List(name: "King Sooper")
        lists.append(list3)
        
        let cat3_1 = Category(name: "")
        list3.categories.append(cat3_1)
        
        cat3_1.items.append(Item(name: "Bread"))
        cat3_1.items.append(Item(name: "Tomatoes"))
        cat3_1.items.append(Item(name: "Coffee"))
        cat3_1.items.append(Item(name: "Syrup"))
        cat3_1.items.append(Item(name: "Dog toys"))
        cat3_1.items.append(Item(name: "Leggings"))
        
        // list4
        let list4 = List(name: "Trail Mannor")
        lists.append(list4)
        
        let cat4_1 = Category(name: "")
        list4.categories.append(cat4_1)
        
        cat4_1.items.append(Item(name: "Popcorn"))
        cat4_1.items.append(Item(name: "Ramen noodles"))
        cat4_1.items.append(Item(name: "Sleeping bags"))
        cat4_1.items.append(Item(name: "Soap"))
        cat4_1.items.append(Item(name: "Towels"))
        cat4_1.items.append(Item(name: "Food"))
        cat4_1.items.append(Item(name: "Bacon"))
        cat4_1.items.append(Item(name: "Cereal"))
        cat4_1.items.append(Item(name: "Coffee"))
        cat4_1.items.append(Item(name: "Water"))
        
        // list5
        let list5 = List(name: "Home Depot")
        lists.append(list5)
        
        let cat5_1 = Category(name: "")
        
        list5.categories.append(cat5_1)
        
        cat5_1.items.append(Item(name: "Paint"))
        cat5_1.items.append(Item(name: "Nails"))
        cat5_1.items.append(Item(name: "Extension cord"))
        cat5_1.items.append(Item(name: "Toilet kit"))
        cat5_1.items.append(Item(name: "Shower head"))
        cat5_1.items.append(Item(name: "Garden hose"))
        cat5_1.items.append(Item(name: "Lights"))
        cat5_1.items.append(Item(name: "3/8' plywood"))
        cat5_1.items.append(Item(name: "Power tools"))
        cat5_1.items.append(Item(name: "Potting soil"))
        cat5_1.items.append(Item(name: "Cat 6 cable"))
        cat5_1.items.append(Item(name: "Wall plates"))
        
        // list6
        let list6 = List(name: "Walmart")
        lists.append(list6)
        
        let cat6_1 = Category(name: "")
        list6.categories.append(cat6_1)
        
        cat6_1.items.append(Item(name: "Dog Shampoo"))
        cat6_1.items.append(Item(name: "Chips"))
        cat6_1.items.append(Item(name: "Movies"))
        cat6_1.items.append(Item(name: "Subway sandwich"))
    }
}
