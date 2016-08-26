//
//  ItemViewController.swift
//  EnList
//
//  Created by Steven Gentry on 12/30/15.
//  Copyright © 2015 Steven Gentry. All rights reserved.
//

import UIKit
import QuartzCore
import MessageUI

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

let kItemViewScrollRate: CGFloat =  6.0
let kItemCellHeight:     CGFloat = 56.0
let kCategoryCellHeight: CGFloat = 44.0
let kAddItemCellHeight:  CGFloat = 44.0

class ItemViewController: UIAppViewController, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, /*ADBannerViewDelegate,*/ UIPrintInteractionControllerDelegate, MFMailComposeViewControllerDelegate
{
    @IBOutlet weak var tableView: UITableView!
    //@IBOutlet weak var adBanner: ADBannerView!
    
    var inEditMode = false
    var deleteItemIndexPath: NSIndexPath?
    var editModeIndexPath: NSIndexPath?
    var longPressGestureRecognizer: UILongPressGestureRecognizer?
    var sourceIndexPath: NSIndexPath?
    var sourceObject: ListObj?
    var movingFromIndexPath: NSIndexPath?
    var newCatIndexPath: NSIndexPath?
    var prevLocation: CGPoint?
    var snapshot: UIView?
    var displayLink: CADisplayLink?
    var longPressActive = false
    var editingNewItemName = false
    var editingNewCategoryName = false
    var tempCollapsedCategoryIsMoving = false
    var inAddNewItemLoop = false
    var longPressHandedToList = false
    var longPressCellType: ItemViewCellType = .Item
    let settingsTransitionDelegate = SettingsTransitioningDelegate()
    let itemDetailTransitionDelegate = ItemDetailTransitioningDelegate()
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var refreshControl : UIRefreshControl!
    
    // refresh view
    var refreshView: UIView!
    var refreshAnimation: UIActivityIndicatorView!
    var refreshLabel: UILabel!
    var refreshCancelButton: UIButton!
    
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
        manager.delegate = self
        
        CheckBox.itemVC = self      // assign CheckBox type property
        
        /*
        if appDelegate.appIsUpgraded {
            adBanner.delegate = nil
            adBanner.removeFromSuperview()
            adBanner.hidden = true
        } else {
            adBanner.delegate = self
        }
        */
        
        // Uncomment the following line to preserve selection between presentations
        //self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        //self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        // set up long press gesture recognizer for the cell move functionality
        longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(ItemViewController.longPressAction(_:)))
        self.tableView.addGestureRecognizer(longPressGestureRecognizer!)

        // settings button
        let settingsButton: UIButton = UIButton(type: UIButtonType.Custom)
        let settingsImage = UIImage(named: "Settings")
        settingsButton.frame = CGRectMake(0, 0, 30, 30)
        if let settingsImage = settingsImage {
            let tintedImage = settingsImage.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
            settingsButton.setImage(tintedImage, forState: .Normal)
            settingsButton.tintColor = color1_1
        }
        settingsButton.addTarget(self, action: #selector(ItemViewController.settingsButtonTapped), forControlEvents: .TouchUpInside)
        let rightBarButton = UIBarButtonItem()
        rightBarButton.customView = settingsButton
        self.navigationItem.rightBarButtonItem = rightBarButton
        
        // settingsVC
        modalPresentationStyle = UIModalPresentationStyle.Custom
        
        // this is to suppress the extra cell separators in the table view
        self.tableView.tableFooterView = UIView()
        
        // refresh control
        refreshControl = UIRefreshControl()
        refreshControl!.backgroundColor = UIColor.clearColor()
        refreshControl!.tintColor = UIColor.clearColor()
        refreshControl!.addTarget(self, action: #selector(self.updateListData(_:)), forControlEvents: UIControlEvents.ValueChanged)
        self.tableView.addSubview(refreshControl!)
        
        loadCustomRefreshContents()
        
        // set up keyboard show/hide notifications
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ItemViewController.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ItemViewController.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ItemViewController.keyboardDidShow(_:)), name: UIKeyboardDidShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ItemViewController.keyboardDidHide(_:)), name: UIKeyboardDidHideNotification, object: nil)
        
        refreshItems()
    }
    
    func loadCustomRefreshContents()
    {
        let refreshContents = NSBundle.mainBundle().loadNibNamed("RefreshContents", owner: self, options: nil)
        
        // refresh view
        refreshView = refreshContents[0] as! UIView
        refreshView.frame = refreshControl!.bounds
        
        // refresh activity indicator
        refreshAnimation = refreshView.viewWithTag(1) as! UIActivityIndicatorView
        refreshAnimation.alpha = 0.0
        
        // refresh label
        refreshLabel = refreshView.viewWithTag(2) as! UILabel
        refreshLabel.text = ""
        
        // refresh cancel button
        refreshCancelButton = refreshView.viewWithTag(3) as! UIButton
        refreshCancelButton.backgroundColor = UIColor.clearColor()
        refreshCancelButton.layer.cornerRadius = 16
        refreshCancelButton.layer.borderWidth = 1
        refreshCancelButton.layer.borderColor = UIColor.blackColor().CGColor
        refreshCancelButton.addTarget(self, action: #selector(self.cancelFetch(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        refreshCancelButton.enabled = false
        refreshCancelButton.alpha = 0.3
        
        refreshControl!.addSubview(refreshView)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        //layoutAnimated(false)
        //refreshView.frame = CGRectMake(0, 0, self.tableView.bounds.width, refreshView.frame.height)
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        //print("viewWillTransitionToSize... \(size)")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
    }
    
    override func viewDidLayoutSubviews() {
        //print("viewDidLayoutSubviews with width: \(self.view.frame.width)")
        super.viewDidLayoutSubviews()
        
        refreshView.frame = CGRectMake(0, 0, self.tableView.bounds.width, refreshView.frame.height)
        
        layoutAnimated(true)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    func updateListData(refreshControl: UIRefreshControl)
    {
        refreshAnimation.startAnimating()
        refreshCancelButton.enabled = true
        refreshCancelButton.alpha = 1.0
        refreshAnimation.alpha = 1.0
        appDelegate.fetchCloudData(refreshLabel, refreshEnd: refreshEnd)
    }
    
    func cancelFetch(button: UIButton) {
        refreshLabel.text = "Canceled"
        appDelegate.cancelCloudDataFetch()
    }
    
    func refreshEnd() {
        refreshLabel.text = ""
        refreshCancelButton.enabled = false
        refreshCancelButton.alpha = 0.3
        refreshAnimation.alpha = 0.0
        refreshAnimation.stopAnimating()
        refreshControl?.endRefreshing()
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
        
        // separator color
        if list!.listColorName == r4_1 {
            self.tableView.separatorColor = color4_1_alt
        } else if list.listColor != nil {
            self.tableView.separatorColor = list.listColor
        } else {
            self.tableView.separatorColor = UIColor.darkGrayColor()
        }
        
        if obj is Item {
            // item cell
            let cell = tableView.dequeueReusableCellWithIdentifier(itemCellID, forIndexPath: indexPath) as! ItemCell
            let item = obj as! Item
            let tag = item.tag()
            
            // Configure the cell...
            //cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            cell.itemName.userInteractionEnabled = false
            cell.itemName.delegate = self
            cell.itemName.addTarget(self, action: #selector(ItemViewController.itemNameDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
            cell.itemName.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
            cell.itemName.autocapitalizationType = appDelegate.namesCapitalize     ? .Words : .None
            cell.itemName.spellCheckingType      = appDelegate.namesSpellCheck     ? .Yes   : .No
            cell.itemName.autocorrectionType     = appDelegate.namesAutocorrection ? .Yes   : .No
            cell.itemName!.tag = tag
            cell.contentView.tag = tag
            cell.tapView.tag = tag
            
            // set up picture indicator
            if item.imageAsset?.image != nil {
                cell.pictureIndicator.hidden = false
                let origImage = cell.pictureIndicator.image
                
                if let origImage = origImage {
                    // set picture indicator color from list color
                    let tintedImage = origImage.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
                    cell.pictureIndicator.image = tintedImage
                    
                    if list!.listColorName == r4_1 {
                        cell.pictureIndicator.tintColor = color4_1_alt
                    } else if list!.listColor != nil {
                        cell.pictureIndicator.tintColor = list!.listColor
                    } else {
                        cell.pictureIndicator.tintColor = UIColor.darkGrayColor()
                    }
                }
            } else {
                cell.pictureIndicator.hidden = true
            }
            
            // set up single tap gesture recognizer in cat cell to enable expand/collapse
            let singleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ItemViewController.cellSingleTapAction(_:)))
            singleTapGestureRecognizer.numberOfTapsRequired = 1
            cell.tapView.addGestureRecognizer(singleTapGestureRecognizer)
            
            // set up double tap gesture recognizer in item cell to enable cell moving
            let doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ItemViewController.cellDoubleTapAction(_:)))
            doubleTapGestureRecognizer.numberOfTapsRequired = 2
            singleTapGestureRecognizer.requireGestureRecognizerToFail(doubleTapGestureRecognizer)
            cell.tapView.addGestureRecognizer(doubleTapGestureRecognizer)

            cell.checkBox.checkBoxInit(item, list: list, tag: tag)
            
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
            
            cell.backgroundColor = UIColor.whiteColor()
            cell.delegate = self
            
            // cell separator
            cell.preservesSuperviewLayoutMargins = false
            cell.separatorInset = UIEdgeInsetsZero
            cell.layoutMargins = UIEdgeInsetsZero
            
            return cell
        } else if obj is Category  {
            // category cell
            let cell = tableView.dequeueReusableCellWithIdentifier(categoryCellID, forIndexPath: indexPath) as! CategoryCell
            let category = obj as! Category
            let tag = category.tag()
            
            // Configure the cell...
            cell.categoryName.userInteractionEnabled = false
            cell.categoryName.delegate = self
            cell.categoryName.addTarget(self, action: #selector(ItemViewController.itemNameDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
            cell.categoryName.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
            cell.categoryName.autocapitalizationType = appDelegate.namesCapitalize ? .Words : .None
            cell.categoryName.spellCheckingType = appDelegate.namesSpellCheck ? .Yes : .No
            cell.categoryName.autocorrectionType = appDelegate.namesAutocorrection ? .Yes : .No
            cell.categoryName!.tag = tag
            cell.contentView.tag = tag
            
            // set up expand arrows
            if category.expanded {
                cell.expandArrows.image = UIImage(named: "Expand Arrows")
            } else {
                cell.expandArrows.image = UIImage(named: "Collapse Arrows")
            }
            
            // set up single tap gesture recognizer in cat cell to enable expand/collapse
            let singleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ItemViewController.cellSingleTapAction(_:)))
            singleTapGestureRecognizer.numberOfTapsRequired = 1
            cell.contentView.addGestureRecognizer(singleTapGestureRecognizer)
            
            // set up double tap gesture recognizer in cat cell to enable cell moving
            let doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ItemViewController.cellDoubleTapAction(_:)))
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
            
            // change colors based on background color
            if [r2_3, r4_1].contains(list.listColorName) {
                cell.categoryName.textColor = UIColor.blackColor()
                cell.catCountLabel.textColor = UIColor.blackColor()
            } else {
                cell.categoryName.textColor = UIColor.whiteColor()
                cell.catCountLabel.textColor = UIColor.whiteColor()
            }
            
            // cell separator
            cell.preservesSuperviewLayoutMargins = false
            cell.separatorInset = UIEdgeInsetsZero
            cell.layoutMargins = UIEdgeInsetsZero
            
            return cell
         } else {
            // set up AddItem row
            let cell = tableView.dequeueReusableCellWithIdentifier(addItemCellId) as! AddItemCell
            
            // cell separator
            cell.preservesSuperviewLayoutMargins = false
            cell.separatorInset = UIEdgeInsetsZero
            cell.layoutMargins = UIEdgeInsetsZero
            
            // set up add item button
            cell.addItemButton.addButtonInit(list, itemVC: self, tag: tag)
            
            // cell separator
            cell.preservesSuperviewLayoutMargins = false
            cell.separatorInset = UIEdgeInsetsZero
            cell.layoutMargins = UIEdgeInsetsZero
            
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
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView)
    {
        // this is needed
        if inEditMode {
            layoutAnimated(true)
        }
    }
    
////////////////////////////////////////////////////////////////
//
//  MARK: - TextField methods
//
////////////////////////////////////////////////////////////////
    
    
    func keyboardWillShow(notification: NSNotification)
    {
        //print("keyboardWillShow")
        inEditMode = true
        
        var info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        var keyboardHeight = keyboardFrame.height
        let toolbarHeight = self.view.frame.size.height - keyboardFrame.origin.y
        let bHasHardwareKeyboard = hasHardwareKeyboard(notification)
        
        if bHasHardwareKeyboard {
            keyboardHeight = toolbarHeight
        }
        
        // shrink the tableView height so it shows above the keyboard
        self.tableView.frame.size.height = self.view.frame.height - keyboardHeight
        
        // now make sure we have our edit cell in view
        if let indexPath = editModeIndexPath {
            if !bHasHardwareKeyboard {
                tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Bottom, animated: true)
            }
        }
    }
    
    func hasHardwareKeyboard(notification: NSNotification) -> Bool {
        var info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        let keyboard = self.view.convertRect(keyboardFrame, toView: self.view.window)
        let height = self.view.frame.size.height
        
        if (keyboard.origin.y + keyboard.size.height) > height {
            return true
        }
        
        return false
    }
    
    func keyboardWillHide(notification: NSNotification)
    {
        //print("keyboardWillHide")
        
        if !inAddNewItemLoop || !editingNewItemName {
            layoutAnimated(true)
        }
        
        inEditMode = false
        editingNewCategoryName = false
        editingNewItemName = false
        editModeIndexPath = nil
        
        resetCellViewTags()
    }
    
    func keyboardDidShow(notification: NSNotification) {
        //print("keyboardDidShow")
    }
    
    func keyboardDidHide(notification: NSNotification) {
        //print("keyboardDidHide")
    }
    
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool
    {
        //print("textFieldShouldBeginEditing")
        // this clears an initial space in a new cell name
        if textField.text == " " {
            textField.text = ""
        }
        
        return true
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        //print("textFieldDidEndEditing")
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool
    {
        //print("textFieldShouldReturn")
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
        }
        else if editingNewCategoryName
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
        
        // always run layout
        runAfterDelay(0.5) {
            self.layoutAnimated(true)
        }
        
        appDelegate.saveListData(true)
        
        return true
    }
    
    func itemNameDidChange(textField: UITextField)
    {
        // update item name data with new value
        let newName = textField.text!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        list.updateObjNameAtTag(textField.tag, name: newName)
    }

    func addNewItem(sender: UIButton)
    {
        // create a new item and append to the category of the add button
        guard let category = list.categoryForTag(sender.tag) else { return }
        
        inAddNewItemLoop = true
        
        if !inEditMode {
            layoutAnimated(true)
        }
        
        if (appDelegate.appIsUpgraded == false && category.isTutorialCategory == false && list.itemCount() >= kMaxItemCount) ||
           (appDelegate.appIsUpgraded == false && category.isTutorialCategory && category.itemAddCount > 0)
        {
            let itemLimitTitle = NSLocalizedString("Item_Limit", comment: "Item Limit dialog title.")
            let itemLimitMsg = String(format: NSLocalizedString("Item_Limit_Message", comment: "The free version of realList is limited to %i items per list.  Please upgrade or restore your purchase for unlimited items."), kMaxItemCount)
            let okTitle = NSLocalizedString("OK", comment: "OK - to commit the action or dismiss a dialog.")
            
            // max item count will be exceeded
            let alertVC = UIAlertController(
                title: itemLimitTitle,
                message: itemLimitMsg,
                preferredStyle: .Alert)
            let okAction = UIAlertAction(title: okTitle, style: .Default, handler: nil)
            alertVC.addAction(okAction)
            
            presentViewController(alertVC, animated: true, completion: nil)
            
            return
        }
        
        var newItem: Item? = nil
        
        newItem = list.addItem(category, name: "", state: ItemState.Incomplete, updateIndices: true, createRecord: true)
        
        // keep track of items added to this category for item limits in non-upgraded version
        if category.isTutorialCategory {
            category.itemAddCount += 1
        }
        
        list.updateIndices()
        tableView.reloadData()
        resetCellViewTags()
        
        if let item = newItem {
            let newItemIndexPath = list.displayIndexPathForItem(item)
            
            if let indexPath = newItemIndexPath {
                if let cell = tableView.cellForRowAtIndexPath(indexPath) as? ItemCell {
                    cell.itemName.userInteractionEnabled = true
                    cell.itemName.becomeFirstResponder()
                    editingNewItemName = true
                }
            }
        }
        
        // scroll the editing cell into view if necessary
        let indexPath = list.displayIndexPathForAddItemInCategory(category)
        
        if indexPath != nil {
            //print("*** addItem indexPath row is \(indexPath!.row)")
            if self.tableView.indexPathsForVisibleRows?.contains(indexPath!) == false {
                //print("*** addItem is not visible...")
                self.tableView.scrollToRowAtIndexPath(indexPath!, atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
            } else {
                //print("*** addItem is visible...")
            }
        }
        
        inAddNewItemLoop = false
    }
    
    func addNewCategory()
    {
        guard list.categories.count > 0 else { print("*** ERROR: addNewCategory - list \(list.name) has no categories"); return }
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
                self.performSelector(#selector(ItemViewController.scrollToCategoryEnded(_:)), withObject: nil, afterDelay: 0.5)
            } else {
                // new cell is already visible
                //print("new cell is already visible")
                let cell = tableView.cellForRowAtIndexPath(indexPath) as! CategoryCell
                
                cell.categoryName.userInteractionEnabled = true
                cell.categoryName.becomeFirstResponder()
                editingNewCategoryName = true
                editingNewItemName = false
                newCatIndexPath = nil
            }
        }
    }
    
    func collapseAllCategories() {
        guard let list = self.list else { return }
        print("collapseAllCategories")
        
        for category in list.categories {
            if category.expanded == true && category.displayHeader == true {
                category.expanded = false
                handleCategoryCollapseExpand(category)
            }
        }
        tableView.reloadData()
    }
    
    func expandAllCategories() {
        guard let list = self.list else { return }
        print("expandAllCategories")
        
        for category in list.categories {
            if category.expanded == false {
                category.expanded = true
                handleCategoryCollapseExpand(category)
            }
        }
        tableView.reloadData()
    }
    
    func scrollToCategoryEnded(scrollView: UIScrollView)
    {
        NSObject.cancelPreviousPerformRequestsWithTarget(self)
        
        if let cell = tableView.cellForRowAtIndexPath(newCatIndexPath!) as? CategoryCell {
            cell.categoryName.userInteractionEnabled = true
            cell.categoryName.becomeFirstResponder()
            editingNewCategoryName = true
            editingNewItemName = false
            newCatIndexPath = nil
        } else {
            print("ERROR: scrollToCategoryEnded - no row at newCatIndexPath: \(newCatIndexPath)")
        }
    }
    
    func categoryCountString(category: Category) -> String
    {
        return "\(category.itemsComplete())/\(category.itemsActive())"
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
                    let indexPath = list.displayIndexPathForCategory(category)
                    
                    // flip expanded state
                    category.expanded = !category.expanded
                    
                    handleCategoryCollapseExpand(category)
                    
                    // handle expand arrows
                    if indexPath != nil {
                        self.tableView.reloadRowsAtIndexPaths([indexPath!], withRowAnimation: .None)
                        
                        if category.expanded {
                            // scroll the newly expanded header to the top so items can be seen
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
                if !inEditMode {
                    // not in edit mode so can present item detail view
                    self.loadItemDetailView(obj as! Item)
                } else {
                    // in edit mode so dismiss keyboard (end editing) and re-layout the view
                    self.view.endEditing(true)
                    self.layoutAnimated(true)
                }
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
            editModeIndexPath = pathResult.indexPath
            
            if let indexPath = editModeIndexPath {
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
            
            if cell is AddItemCell && !longPressHandedToList {
                // we got a long press action on the AddItem cell...
                
                // if it is the last AddItem cell, then we are moving down past the bottom of the tableView, so end the long press
                if list.indexPathIsLastRowDisplayed(indexPath!) && longPressActive {
                    longPressEnded(movingFromIndexPath, location: location)
                    gesture.enabled = false
                    gesture.enabled = true
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
                displayLink = CADisplayLink(target: self, selector: #selector(ItemViewController.scrollDownLoop))
                displayLink!.frameInterval = 1
                displayLink!.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
            }
        } else if touchLocation.y < (topBarHeight + kScrollZoneHeight) {
            // need to scroll up
            if displayLink == nil {
                displayLink = CADisplayLink(target: self, selector: #selector(ItemViewController.scrollUpLoop))
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

        // if indexPath is null then we took our dragged cell to the list view
        // need to transfer control of the long press gesture to the list view
        if indexPath == nil {
            longPressHandedToList = true
            appDelegate.passGestureToListVC(gesture, obj: sourceObject)
            
            if gesture.state == .Ended {
                gesture.enabled = false
                gesture.enabled = true
                sourceIndexPath = nil
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
        
        sourceObject = list.objectForIndexPath(indexPath)
        
        // collapse the category before starting the long press
        if sourceObject is Category {
            let cat = sourceObject as! Category
            
            if cat.expanded {
                tempCollapsedCategoryIsMoving = true
                cat.expanded = false
                handleCategoryCollapseExpand(cat)
            }
            longPressCellType = .Category
        } else if sourceObject is Item {
            longPressCellType = .Item
        } else {
            longPressCellType = .AddItem
            return
        }
        
        // create snapshot for long press cell moving
        if sourceObject is Item || sourceObject is Category {
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
        }
    }
    
    func longPressMoved(idxPath: NSIndexPath?, location: CGPoint)
    {
        guard var indexPath = idxPath else { return }
        guard prevLocation != nil else { return }
        guard longPressCellType != .AddItem else { return }
        
        // if an item, then adjust indexPath if necessary so we don't move above top-most category
        indexPath = adjustIndexPathIfItemMovingAboveTopRow(indexPath)
        
        if snapshot != nil && location.y > 0 {
            var center: CGPoint = snapshot!.center
            center.y = location.y
            snapshot?.center = center
            
            // check if destination is valid then move the cell in the tableView
            if movingFromIndexPath != nil
            {
                // adjust dest index path for moves over groups being kept together
                if longPressCellType == .Item && cellAtIndexPathIsAddCellCategoryPair(indexPath) {
                    // an item is moving over an AddCell/Category pair
                    let moveDirection = location.y < prevLocation!.y ? MoveDirection.Up : MoveDirection.Down
                    
                    if moveDirection == .Down {
                        let rowCount = list.totalDisplayCount()
                        // this is to prevent dragging past the last row
                        if indexPath.row >= rowCount-1 {
                            indexPath = NSIndexPath(forRow: indexPath.row, inSection: 0)
                        } else {
                            indexPath = NSIndexPath(forRow: indexPath.row + 1, inSection: 0)
                        }
                    } else {
                        indexPath = NSIndexPath(forRow: indexPath.row - 1, inSection: 0)
                    }
                } else if longPressCellType == .Category {
                    /*
                    // a category is moving over another category
                    let moveDirection = location.y < prevLocation!.y ? MoveDirection.Up : MoveDirection.Down
                    let catRowCount = categoryTotalRowCount(indexPath)
                    
                    if moveDirection == .Down {
                        let rowCount = list.totalDisplayCount()
                        // this is to prevent dragging past the last row
                        if indexPath.row >= rowCount-1 {
                            indexPath = NSIndexPath(forRow: indexPath.row, inSection: 0)
                        } else {
                            indexPath = NSIndexPath(forRow: indexPath.row + catRowCount, inSection: 0)
                        }
                    } else {
                        indexPath = NSIndexPath(forRow: indexPath.row - catRowCount, inSection: 0)
                    }
                    */
                }
                
                // ... move the rows
                tableView.moveRowAtIndexPath(movingFromIndexPath!, toIndexPath: indexPath)

                // ... and update movingFromIndexPath so it is in sync with UI changes
                movingFromIndexPath = indexPath
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
        sourceObject = nil
        longPressHandedToList = false
        
        if longPressCellType == .AddItem {
            self.prevLocation = nil
            return
        }
        
        // finalize list data with new location for srcIndexObj
        if sourceIndexPath != nil {
            var center: CGPoint = snapshot!.center
            center.y = location.y
            snapshot?.center = center
            
            // check if destination is different from source and is valid
            if indexPath != nil && indexPath != sourceIndexPath {
                let moveDirection = sourceIndexPath!.row >  indexPath!.row ? MoveDirection.Up : MoveDirection.Down
                let srcDataObj = list.objectForIndexPath(sourceIndexPath!)
                let destDataObj = list.objectForIndexPath(indexPath!)
                
                // move cells, update the list data source, move items and categories differently
                if srcDataObj is Item {
                    let srcItem = srcDataObj as! Item
                    
                    // we are moving an item
                    tableView.beginUpdates()
                    
                    // remove the item from its original location
                    list.removeItem(srcItem, updateIndices: true)
                    //print("removeItem... \(srcItem.name)")
                    
                    // insert the item at its new location
                    if destDataObj is Item {
                        let destItem = destDataObj as! Item
                        if moveDirection == .Down {
                            list.insertItem(srcItem, afterObj: destItem, updateIndices: true)
                        } else {
                            list.insertItem(srcItem, beforeObj: destItem, updateIndices: true)
                        }
                        //print("insertItem... \(destItem.name)")
                    } else if destDataObj is Category {
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
                    } else if destDataObj is AddItem {
                        let addItem = destDataObj as! AddItem
                        
                        // moving to AddItem cell, so drop just above the AddItem cell
                        let destCat = list.categoryForObj(addItem)
                        
                        if destCat != nil {
                            list.insertItem(srcItem, inCategory: destCat!, atPosition: .End, updateIndices: true)
                        }
                    }
                    
                    //print("moving row from \(sourceIndexPath?.row) to \(indexPath!.row)")
                    
                    tableView.endUpdates()
                    
                    // save item changes to cloud
                    srcItem.needToSave = true
                    
                    tableView.endUpdates()
                } else if srcDataObj is Category {
                    // we are moving a category
                    let srcCategory = srcDataObj as! Category
                    let srcCategoryIndex = srcCategory.categoryIndex
                    var dstCategoryIndex = destDataObj!.categoryIndex
                    
                    // this is so dropping a category on an item will only move the category if the item is above the dest category when moving up
                    let moveDirection = sourceIndexPath!.row >  indexPath!.row ? MoveDirection.Up : MoveDirection.Down
                    
                    if moveDirection == .Up && destDataObj is Item && dstCategoryIndex >= 0 {
                        dstCategoryIndex += 1
                    }
                    
                    //print("srcCategoryIndex: \(srcCategoryIndex)  dstCategoryIndex: \(dstCategoryIndex)")
                    
                    if srcCategoryIndex >= 0 && dstCategoryIndex >= 0 {
                        tableView.beginUpdates()
                        
                        // remove the category from its original location
                        //list.removeCatetoryAtIndex(srcCategoryIndex)
                        list.categories.removeObject(srcCategory)
                        list.updateIndices()
                        
                        list.insertCategory(srcCategory, atIndex: dstCategoryIndex)
                        
                        tableView.endUpdates()
                        
                        // save all category order changes to cloud
                        for cat in list.categories {
                            cat.needToSave = true
                        }
                    }
                    
                    // restore a temp collapsed category
                    if tempCollapsedCategoryIsMoving {
                        srcCategory.expanded = true
                        handleCategoryCollapseExpand(srcCategory)
                        tempCollapsedCategoryIsMoving = false
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
        longPressHandedToList = false
        
        // clear any last long press hilight
        if let listVC = appDelegate.listViewController {
            listVC.highlightList(listVC.selectionIndex)
        }
        
        appDelegate.saveListData(true)
    }
    
    func scrollUpLoop()
    {
        let currentOffset = tableView.contentOffset
        let topBarHeight = getTopBarHeight()
        let newOffsetY = max(currentOffset.y - kItemViewScrollRate, -topBarHeight)
        let location: CGPoint = longPressGestureRecognizer!.locationInView(tableView)
        let indexPath: NSIndexPath? = tableView.indexPathForRowAtPoint(location)
        
        //if !appDelegate.appIsUpgraded && newOffsetY < 0 {
        //    newOffsetY = 0
        //}
        
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
    
    // deletes an item or a category and all of the items in it
    func handleDeleteItem(alertAction: UIAlertAction!) -> Void
    {
        if let indexPath = deleteItemIndexPath, currentList = list {
            tableView.beginUpdates()
            
            // Delete the row(s) from the data source and return display paths of the removed rows
            var removedPaths: [NSIndexPath]
            var preserveCat = true
            var catAdded = false
            
            let deleteObj = currentList.objectForIndexPath(indexPath)
            
            // cloud delete
            if deleteObj is Category {
                preserveCat = false
                let cat = deleteObj as! Category
                cat.deleteFromCloud()
                
                // handle if this is the only category in this list which is about to be deleted (add a new category)
                if list.categories.count == 1 {
                    let newCategory = list.addCategory("", displayHeader: false, updateIndices: false, createRecord: true)
                    if list.listReference != nil {
                        newCategory.saveToCloud(list.listReference!)
                    }
                    catAdded = true
                }
            } else if deleteObj is Item {
                let item = deleteObj as! Item
                item.deleteFromCloud()
                
                // tutorial category item delete
                if let itemCat = list.categoryForObj(item) {
                    
                    if itemCat.isTutorialCategory {
                        itemCat.itemAddCount -= 1
                    }
                }
            }
            
            // model delete
            removedPaths = currentList.removeListObjAtIndexPath(indexPath, preserveCategories: preserveCat, updateIndices: true)
            
            // table view delete
            tableView.deleteRowsAtIndexPaths(removedPaths, withRowAnimation: .Fade)
            
            // handle if we added a new category above
            if catAdded {
                let insertIndexPath = NSIndexPath.init(forRow: 0, inSection: 0)
                tableView.insertRowsAtIndexPaths([insertIndexPath], withRowAnimation: .Automatic)
            }
            
            deleteItemIndexPath = nil
            
            tableView.endUpdates()
            
            resetCellViewTags()
            
            // reload to update the category count
            self.tableView.reloadData()
        } else {
            print("ERROR: handleDeleteItem received a nil indexPath or list!")
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
        } else {
            self.title = NSLocalizedString("Items", comment: "Items - the view controller title for an empty list of items.")
        }
        
        tableView.reloadData()
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
        snapshot.layer.shadowOpacity = 0.3
        snapshot.layer.opacity = 0.6
        
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
                index += 1
                let indexPath = NSIndexPath(forRow: index, inSection: 0)
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
    
    func adjustIndexPathIfItemMovingAboveTopRow(idxPath: NSIndexPath) -> NSIndexPath
    {
        var indexPath = idxPath
        
        if sourceIndexPath != nil {
            let srcObj = tableView.cellForRowAtIndexPath(sourceIndexPath!)
        
            if srcObj is ItemCell && indexPath.row == 0 {
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

    // Returns the row count (cat header, items, add item row) of the category at the given index path.
    func categoryTotalRowCount(indexPath: NSIndexPath) -> Int
    {
        var rowCount = 0
        let category = list.categoryForIndexPath(indexPath)
        
        if let category = category {
            if category.displayHeader {
                rowCount += 1
            }
            
            if category.expanded {
                rowCount += category.items.count
                rowCount += 1
            }
        }
        
        return rowCount
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
        print("settings button tapped...")
        
        if let list = list {
            transitioningDelegate = settingsTransitionDelegate
            let vc = SettingsViewController(itemVC: self, showCompletedItems: list.showCompletedItems, showInactiveItems: list.showInactiveItems)
            vc.transitioningDelegate = settingsTransitionDelegate
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
    
    // called from the dismissing settings view controller
    func presentPrintDialog()
    {
        let html = self.getHTMLforPrinting(appDelegate.picsInPrintAndEmail)
        let printController = UIPrintInteractionController.sharedPrintController()
        let printFormatter = UIMarkupTextPrintFormatter(markupText: html)
        
        printFormatter.contentInsets = UIEdgeInsets(top: 0, left: 72, bottom: 72, right: 60)    // page margins (72 = 1") - bottom is ignored, top only used on first page
        printController.printFormatter = printFormatter
        printController.delegate = self
        printController.showsPageRange = true
        printController.showsNumberOfCopies = true
        
        printController.presentAnimated(true, completionHandler: nil)
    }
    
    func scheduleEmailDialog() {
        dispatch_async(dispatch_get_main_queue()) {
            self.presentEmailDialog()
        }
            
        //NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "presentEmailDialog", userInfo: nil, repeats: false)
    }
    
    // called from the dismissing settings view controller
    func presentEmailDialog()
    {
        if MFMailComposeViewController.canSendMail()
        {
            // init the mail view controller
            let mailViewController = MFMailComposeViewController.init()
            mailViewController.mailComposeDelegate = self
            mailViewController.navigationBar.barStyle = UIBarStyle.Default
            
            // test code for embedded images from attachments
            /*
            let image = list.categories[0].items[0].imageAsset?.image
            if image != nil {
                let imageData = UIImageJPEGRepresentation(image!, jpegCompressionQuality)
                mailViewController.addAttachmentData(imageData!, mimeType: "image/jpeg", fileName: "image01.jpg")
            }
            */
            
            // subject and title
            mailViewController.setSubject(list.name)
            
            var html = self.getHTMLforPrinting(false)
            
            html += "<div id='footer' style='margin-top:35px;'>"
            html += "Generated by <a href='http://www.segnetix.com/reallist.html'>realList</a></div>"
            
            mailViewController.setMessageBody(html, isHTML: true)
            
            self.presentViewController(mailViewController, animated: true, completion: nil)
        }
        else
        {
            let alertController = UIAlertController(title: "Can't Send Email", message: "Your device could not send e-mail.  Please check e-mail configuration and try again.", preferredStyle: .Alert)
            let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in
                print("email not configued... alert controller OKAction...")
            }
            alertController.addAction(OKAction)
            
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    // Dismisses the email composition interface when users tap Cancel or Send. Proceeds to update the message field with the result of the operation.
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?)
    {
        var message = ""
        
        switch result {
        case MFMailComposeResultCancelled:
            message = "Email Cancelled"
        case MFMailComposeResultSaved:
            message = "Email Saved"
        case MFMailComposeResultSent:
            message = "Email Sent"
        case MFMailComposeResultFailed:
            if let err = error {
                message = "Email Failure: \(err.localizedDescription)"
            }
        default:
            message = "Email Not Sent"
        }
        
        if (result != MFMailComposeResultCancelled) {
            let alertController = UIAlertController(title: message, message: nil, preferredStyle: .Alert)
            let okAction = UIAlertAction(title: "OK", style: .Default) { [unowned self] (action) in
                self.dismissViewControllerAnimated(false, completion: nil)
            }
            alertController.addAction(okAction)
            
            controller.presentViewController(alertController, animated: true, completion: nil)
        } else {
            self.dismissViewControllerAnimated(false, completion: nil)
        }
    }
    
    func getHTMLforPrinting(includePics: Bool) -> String
    {
        return list.htmlForPrinting(includePics)
    }
    
    func dataFetchCanceledAlert() {
        let canceledTitle = NSLocalizedString("Data_Fetch_Canceled", comment: "Data Fetch Canceled title")
        let canceledMsg = NSLocalizedString("Data_Fetch_Canceled_Message", comment: "The iCloud data fetch operation was canceled.")
        let okTitle = NSLocalizedString("OK", comment: "OK - to commit the action or dismiss a dialog.")
        
        // max list count (not including the tutorial) will be exceeded
        let alertVC = UIAlertController(
            title: canceledTitle,
            message: canceledMsg,
            preferredStyle: .Alert)
        let okAction = UIAlertAction(title: okTitle, style: .Default, handler: nil)
        alertVC.addAction(okAction)
        
        presentViewController(alertVC, animated: true, completion: nil)
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
            
            // call saveListData - cloudOnly mode
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
            i += 1
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
    
    /*
    func bannerViewActionShouldBegin(banner: ADBannerView!, willLeaveApplication willLeave: Bool) -> Bool
    {
        print("Banner view is beginning an ad action")
        let shouldExecuteAction = self.allowActionToRun()
        
        if !willLeave && shouldExecuteAction
        {
            // insert code here to suspend any services that might conflict with the advertisement
        }
        
        return shouldExecuteAction
    }
    
    func bannerViewActionDidFinish(banner: ADBannerView!)
    {
        // insert code here to resume any services paused by the ad banner action
        // must execute quickly
        print("bannerViewActionDidFinish")
    }
    
    func bannerViewDidLoadAd(banner: ADBannerView!)
    {
        if self.allowActionToRun() {
            self.adBanner.hidden = true
            if !inEditMode {
                self.layoutAnimated(false)
            }
        } else {
            self.adBanner.hidden = false
            if !inEditMode {
                self.layoutAnimated(true)
            }
        }
    }
    
    func bannerView(banner: ADBannerView!, didFailToReceiveAdWithError error: NSError!)
    {
        self.adBanner.hidden = true
        if !inEditMode {
            self.layoutAnimated(true)
        }
    }
    
    func allowActionToRun() -> Bool {
        // determine if we will allow an add action to take over the screen
        if appDelegate.appIsUpgraded {
            return false
        } else {
            return true
        }
    }
    */
    
    // resize the frame /* and move the adBanner on and off the screen */
    func layoutAnimated(animated: Bool)
    {
        //var topBarHeight = getTopBarHeight()
        //var bannerHeight: CGFloat = 0.0
        //var bannerLoaded = false
        //let bannerXpos   = self.view.frame.size.height
        //let showAdBanner = !appDelegate.appIsUpgraded
        //let oldFrameHeight = tableView.frame.size.height
        
        //if appDelegate.appIsUpgraded {
        //    topBarHeight = 0.0
        //}
        
        //tableView.frame.origin.y = 0//getTopBarHeight()
        //tableView.frame.size.height = self.view.frame.height - topBarHeight
        
        //if adBanner != nil {
        //    bannerHeight = adBanner!.frame.size.height
        //    bannerLoaded = adBanner!.bannerLoaded
        //}
        
        //if showAdBanner && bannerLoaded {
        //    // show the ad banner
        //    adBanner.hidden = false
        //    adBanner.frame.origin.y = bannerXpos - bannerHeight
        //    tableView.frame.size.height = self.view.frame.height - bannerHeight - topBarHeight
        //    tableView.frame.origin.y = topBarHeight
        //} else {
            // hide the ad banner
            //if adBanner != nil {
            //    adBanner.hidden = true
            //    adBanner.frame.origin.y = bannerXpos
            //}
            //tableView.frame.origin.y = topBarHeight
            //tableView.frame.size.height = self.view.frame.height - topBarHeight
        //}
        
        tableView.frame.size.height = self.view.frame.height// + topBarHeight
        //tableView.frame.origin.y = topBarHeight
        
        //print("layoutAnimated - frame height - old: \(oldFrameHeight) new: \(tableView.frame.size.height)")
        UIView.animateWithDuration(animated ? 0.5 : 0.0) {
            self.view.layoutIfNeeded()
        }
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
