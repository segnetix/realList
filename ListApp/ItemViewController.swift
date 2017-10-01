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
    case beginning
    case middle
    case end
}

enum MoveDirection {
    case up
    case down
}

enum ItemViewCellType {
    case item
    case category
    case addItem
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
    var deleteItemIndexPath: IndexPath?
    var editModeIndexPath: IndexPath?
    var longPressGestureRecognizer: UILongPressGestureRecognizer?
    var sourceIndexPath: IndexPath?
    var sourceObject: ListObj?
    var movingFromIndexPath: IndexPath?
    var newCatIndexPath: IndexPath?
    var prevLocation: CGPoint?
    var snapshot: UIView?
    var displayLink: CADisplayLink?
    var longPressActive = false
    var editingNewItemName = false
    var editingNewCategoryName = false
    var tempCollapsedCategoryIsMoving = false
    var inAddNewItemLoop = false
    var longPressHandedToList = false
    var longPressCellType: ItemViewCellType = .item
    let settingsTransitionDelegate = SettingsTransitioningDelegate()
    let itemDetailTransitionDelegate = ItemDetailTransitioningDelegate()
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
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
        let settingsButton: UIButton = UIButton(type: UIButtonType.custom)
        let settingsImage = UIImage(named: "Settings")
        settingsButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        if let settingsImage = settingsImage {
            let tintedImage = settingsImage.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
            settingsButton.setImage(tintedImage, for: UIControlState())
            settingsButton.tintColor = color1_1
        }
        settingsButton.addTarget(self, action: #selector(ItemViewController.settingsButtonTapped), for: .touchUpInside)
        let rightBarButton = UIBarButtonItem()
        rightBarButton.customView = settingsButton
        self.navigationItem.rightBarButtonItem = rightBarButton
        
        // settingsVC
        modalPresentationStyle = UIModalPresentationStyle.custom
        
        // this is to suppress the extra cell separators in the table view
        self.tableView.tableFooterView = UIView()
        
        // refresh control
        refreshControl = UIRefreshControl()
        refreshControl!.backgroundColor = UIColor.clear
        refreshControl!.tintColor = UIColor.clear
        refreshControl!.addTarget(self, action: #selector(self.updateListData(_:)), for: UIControlEvents.valueChanged)
        self.tableView.addSubview(refreshControl!)
        
        loadCustomRefreshContents()
        
        // set up keyboard show/hide notifications
        NotificationCenter.default.addObserver(self, selector: #selector(ItemViewController.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ItemViewController.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ItemViewController.keyboardDidShow(_:)), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ItemViewController.keyboardDidHide(_:)), name: NSNotification.Name.UIKeyboardDidHide, object: nil)
        
        refreshItems()
    }
    
    func loadCustomRefreshContents()
    {
        let refreshContents = Bundle.main.loadNibNamed("RefreshContents", owner: self, options: nil)
        
        // refresh view
        refreshView = refreshContents?[0] as! UIView
        refreshView.frame = refreshControl!.bounds
        
        // refresh activity indicator
        refreshAnimation = refreshView.viewWithTag(1) as! UIActivityIndicatorView
        refreshAnimation.alpha = 0.0
        
        // refresh label
        refreshLabel = refreshView.viewWithTag(2) as! UILabel
        refreshLabel.text = ""
        
        // refresh cancel button
        refreshCancelButton = refreshView.viewWithTag(3) as! UIButton
        refreshCancelButton.backgroundColor = UIColor.clear
        refreshCancelButton.layer.cornerRadius = 16
        refreshCancelButton.layer.borderWidth = 1
        refreshCancelButton.layer.borderColor = UIColor.black.cgColor
        refreshCancelButton.addTarget(self, action: #selector(self.cancelFetch(_:)), for: UIControlEvents.touchUpInside)
        refreshCancelButton.isEnabled = false
        refreshCancelButton.alpha = 0.3
        
        refreshControl!.addSubview(refreshView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //layoutAnimated(false)
        //refreshView.frame = CGRectMake(0, 0, self.tableView.bounds.width, refreshView.frame.height)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        //print("viewWillTransitionToSize... \(size)")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
    }
    
    override func viewDidLayoutSubviews() {
        //print("viewDidLayoutSubviews with width: \(self.view.frame.width)")
        super.viewDidLayoutSubviews()
        
        refreshView.frame = CGRect(x: 0, y: 0, width: self.tableView.bounds.width, height: refreshView.frame.height)
        
        layoutAnimated(true)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    func updateListData(_ refreshControl: UIRefreshControl)
    {
        refreshAnimation.startAnimating()
        refreshCancelButton.isEnabled = true
        refreshCancelButton.alpha = 1.0
        refreshAnimation.alpha = 1.0
        appDelegate.fetchCloudData(refreshLabel, refreshEnd: refreshEnd)
    }
    
    func cancelFetch(_ button: UIButton) {
        refreshLabel.text = "Canceled"
        appDelegate.cancelCloudDataFetch()
    }
    
    func refreshEnd() {
        refreshLabel.text = ""
        refreshCancelButton.isEnabled = false
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        // return the total number of rows in our item table view (categories + items)
        if let list = list {
            let displayCount = list.totalDisplayCount()
            
            return displayCount
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let obj = list.objectForIndexPath(indexPath)
        let tag = obj != nil ? obj!.tag() : -1
        
        // separator color
        if list!.listColorName == r4_1 {
            self.tableView.separatorColor = color4_1_alt
        } else if list.listColor != nil {
            self.tableView.separatorColor = list.listColor
        } else {
            self.tableView.separatorColor = UIColor.darkGray
        }
        
        if obj is Item {
            // item cell
            let cell = tableView.dequeueReusableCell(withIdentifier: itemCellID, for: indexPath) as! ItemCell
            let item = obj as! Item
            let tag = item.tag()
            
            // Configure the cell...
            //cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            cell.itemName.isUserInteractionEnabled = false
            cell.itemName.delegate = self
            cell.itemName.addTarget(self, action: #selector(ItemViewController.itemNameDidChange(_:)), for: UIControlEvents.editingChanged)
            cell.itemName.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)
            cell.itemName.autocapitalizationType = appDelegate.namesCapitalize     ? .words : .none
            cell.itemName.spellCheckingType      = appDelegate.namesSpellCheck     ? .yes   : .no
            cell.itemName.autocorrectionType     = appDelegate.namesAutocorrection ? .yes   : .no
            cell.itemName!.tag = tag
            cell.contentView.tag = tag
            cell.tapView.tag = tag
            
            // set up picture indicator
            if item.imageAsset?.image != nil {
                cell.pictureIndicator.isHidden = false
                let origImage = cell.pictureIndicator.image
                
                if let origImage = origImage {
                    // set picture indicator color from list color
                    let tintedImage = origImage.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
                    cell.pictureIndicator.image = tintedImage
                    
                    if list!.listColorName == r4_1 {
                        cell.pictureIndicator.tintColor = color4_1_alt
                    } else if list!.listColor != nil {
                        cell.pictureIndicator.tintColor = list!.listColor
                    } else {
                        cell.pictureIndicator.tintColor = UIColor.darkGray
                    }
                }
            } else {
                cell.pictureIndicator.isHidden = true
            }
            
            // set up single tap gesture recognizer in cat cell to enable expand/collapse
            let singleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ItemViewController.cellSingleTapAction(_:)))
            singleTapGestureRecognizer.numberOfTapsRequired = 1
            cell.tapView.addGestureRecognizer(singleTapGestureRecognizer)
            
            // set up double tap gesture recognizer in item cell to enable cell moving
            let doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ItemViewController.cellDoubleTapAction(_:)))
            doubleTapGestureRecognizer.numberOfTapsRequired = 2
            singleTapGestureRecognizer.require(toFail: doubleTapGestureRecognizer)
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
            if item.state == ItemState.inactive {
                cell.itemName.textColor = UIColor.lightGray
            } else {
                cell.itemName.textColor = UIColor.black
            }
            
            // set item note
            cell.itemNote.text = item.note
            cell.itemNote.textColor = UIColor.lightGray
            
            cell.backgroundColor = UIColor.white
            cell.delegate = self
            
            // cell separator
            cell.preservesSuperviewLayoutMargins = false
            cell.separatorInset = UIEdgeInsets.zero
            cell.layoutMargins = UIEdgeInsets.zero
            
            return cell
        } else if obj is Category  {
            // category cell
            let cell = tableView.dequeueReusableCell(withIdentifier: categoryCellID, for: indexPath) as! CategoryCell
            let category = obj as! Category
            let tag = category.tag()
            
            // Configure the cell...
            cell.categoryName.isUserInteractionEnabled = false
            cell.categoryName.delegate = self
            cell.categoryName.addTarget(self, action: #selector(ItemViewController.itemNameDidChange(_:)), for: UIControlEvents.editingChanged)
            cell.categoryName.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)
            cell.categoryName.autocapitalizationType = appDelegate.namesCapitalize ? .words : .none
            cell.categoryName.spellCheckingType = appDelegate.namesSpellCheck ? .yes : .no
            cell.categoryName.autocorrectionType = appDelegate.namesAutocorrection ? .yes : .no
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
            singleTapGestureRecognizer.require(toFail: doubleTapGestureRecognizer)
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
            cell.catCountLabel.textAlignment = NSTextAlignment.right
            
            // cell separator
            cell.preservesSuperviewLayoutMargins = false
            cell.separatorInset = UIEdgeInsets.zero
            cell.layoutMargins = UIEdgeInsets.zero
            
            // cat cell background color
            if list.listColor != nil {
                cell.backgroundColor = list.listColor
            } else {
                cell.backgroundColor = UIColor.lightGray
            }
            
            // change colors based on background color
            if [r2_3, r4_1].contains(list.listColorName) {
                cell.categoryName.textColor = UIColor.black
                cell.catCountLabel.textColor = UIColor.black
            } else {
                cell.categoryName.textColor = UIColor.white
                cell.catCountLabel.textColor = UIColor.white
            }
            
            // cell separator
            cell.preservesSuperviewLayoutMargins = false
            cell.separatorInset = UIEdgeInsets.zero
            cell.layoutMargins = UIEdgeInsets.zero
            
            return cell
         } else {
            // set up AddItem row
            let cell = tableView.dequeueReusableCell(withIdentifier: addItemCellId) as! AddItemCell
            
            // cell separator
            cell.preservesSuperviewLayoutMargins = false
            cell.separatorInset = UIEdgeInsets.zero
            cell.layoutMargins = UIEdgeInsets.zero
            
            // set up add item button
            cell.addItemButton.addButtonInit(list, itemVC: self, tag: tag)
            
            // cell separator
            cell.preservesSuperviewLayoutMargins = false
            cell.separatorInset = UIEdgeInsets.zero
            cell.layoutMargins = UIEdgeInsets.zero
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let obj = list.objectForIndexPath(indexPath)
        if obj is Item {
            return kItemCellHeight
        } else if obj is Category {
            return kCategoryCellHeight
        } else {
            return kAddItemCellHeight
        }
    }
    
    // override to support conditional editing of the table view
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        let obj = list.objectForIndexPath(indexPath)
        
        return obj is Item || obj is Category
    }
    
    // override to support editing the table view
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath)
    {
        if editingStyle == .delete {
            deleteItemIndexPath = indexPath
            let deletedItem = list.objectForIndexPath(indexPath)
            
            if deletedItem is Item {
                confirmDelete((deletedItem as! Item).name, isItem: true)
            } else if deletedItem is Category {
                confirmDelete((deletedItem as! Category).name, isItem: false)
            }
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView)
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
    
    
    func keyboardWillShow(_ notification: Notification)
    {
        //print("keyboardWillShow")
        inEditMode = true
        
        var info = (notification as NSNotification).userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
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
                tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
            }
        }
    }
    
    func hasHardwareKeyboard(_ notification: Notification) -> Bool {
        var info = (notification as NSNotification).userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let keyboard = self.view.convert(keyboardFrame, to: self.view.window)
        let height = self.view.frame.size.height
        
        if (keyboard.origin.y + keyboard.size.height) > height {
            return true
        }
        
        return false
    }
    
    func keyboardWillHide(_ notification: Notification)
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
    
    func keyboardDidShow(_ notification: Notification) {
        //print("keyboardDidShow")
    }
    
    func keyboardDidHide(_ notification: Notification) {
        //print("keyboardDidHide")
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool
    {
        //print("textFieldShouldBeginEditing")
        // this clears an initial space in a new cell name
        if textField.text == " " {
            textField.text = ""
        }
        
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        //print("textFieldDidEndEditing")
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        //print("textFieldShouldReturn")
        textField.isUserInteractionEnabled = false
        textField.resignFirstResponder()
        self.tableView.setEditing(false, animated: true)

        // delete the newly added item if user didn't create a name
        if editingNewItemName
        {
            if textField.text!.trimmingCharacters(in: CharacterSet.whitespaces).isEmpty
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
            if textField.text!.trimmingCharacters(in: CharacterSet.whitespaces).isEmpty
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
        
        appDelegate.saveListData(async: true)
        
        return true
    }
    
    func itemNameDidChange(_ textField: UITextField)
    {
        // update item name data with new value
        let newName = textField.text!.trimmingCharacters(in: CharacterSet.whitespaces)
        list.updateObjNameAtTag(textField.tag, name: newName)
    }

    func addNewItem(_ sender: UIButton)
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
                preferredStyle: .alert)
            let okAction = UIAlertAction(title: okTitle, style: .default, handler: nil)
            alertVC.addAction(okAction)
            
            present(alertVC, animated: true, completion: nil)
            
            return
        }
        
        var newItem: Item? = nil
        
        newItem = list.addItem(category, name: "", state: ItemState.incomplete, updateIndices: true, createRecord: true)
        
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
                if let cell = tableView.cellForRow(at: indexPath) as? ItemCell {
                    cell.itemName.isUserInteractionEnabled = true
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
                self.tableView.scrollToRow(at: indexPath!, at: UITableViewScrollPosition.bottom, animated: true)
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
            newCatIndexPath = IndexPath(row: 0, section: 0)
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
                self.tableView.scrollToRow(at: IndexPath(row: (indexPath as NSIndexPath).row, section: 0), at: UITableViewScrollPosition.bottom, animated: false)
                self.resetCellViewTags()
                
                // set up a selector event to fire when the new cell has scrolled into place
                NSObject.cancelPreviousPerformRequests(withTarget: self)
                self.perform(#selector(ItemViewController.scrollToCategoryEnded(_:)), with: nil, afterDelay: 0.5)
            } else {
                // new cell is already visible
                //print("new cell is already visible")
                let cell = tableView.cellForRow(at: indexPath) as! CategoryCell
                
                cell.categoryName.isUserInteractionEnabled = true
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
    
    func scrollToCategoryEnded(_ scrollView: UIScrollView)
    {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        
        if let cell = tableView.cellForRow(at: newCatIndexPath!) as? CategoryCell {
            cell.categoryName.isUserInteractionEnabled = true
            cell.categoryName.becomeFirstResponder()
            editingNewCategoryName = true
            editingNewItemName = false
            newCatIndexPath = nil
        } else {
            print("ERROR: scrollToCategoryEnded - no row at newCatIndexPath: \(String(describing: newCatIndexPath))")
        }
    }
    
    func categoryCountString(_ category: Category) -> String
    {
        return "\(category.itemsComplete())/\(category.itemsActive())"
    }

    func handleCategoryCollapseExpand(_ category: Category)
    {
        // get display index paths for this category
        let indexPaths = list.displayIndexPathsForCategory(category, includeAddItemIndexPath: true)    // includes AddItem cell path
        
        self.tableView.beginUpdates()
        if category.expanded {
            // insert the expanded rows into the table view
            self.tableView.insertRows(at: indexPaths, with: UITableViewRowAnimation.automatic)
        } else {
            // remove the collapsed rows from the table view
            self.tableView.deleteRows(at: indexPaths, with: UITableViewRowAnimation.automatic)
        }
        self.tableView.endUpdates()
    }
    
////////////////////////////////////////////////////////////////
//
//  MARK: - Gesture Recognizer methods
//
////////////////////////////////////////////////////////////////
    
    /// Respond to a single tap (toggle expand/collapse state of category).
    func cellSingleTapAction(_ sender: UITapGestureRecognizer)
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
                        self.tableView.reloadRows(at: [indexPath!], with: .none)
                        
                        if category.expanded {
                            // scroll the newly expanded header to the top so items can be seen
                            self.tableView.scrollToRow(at: indexPath!, at: UITableViewScrollPosition.top, animated: true)
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
                appDelegate.saveListData(async: true)
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
    func cellDoubleTapAction(_ sender: UITapGestureRecognizer)
    {
        if sender.view != nil {
            let obj = list.objectForTag(sender.view!.tag)
            let pathResult = list.displayIndexPathForObj(obj!)
            editModeIndexPath = pathResult.indexPath
            
            if let indexPath = editModeIndexPath {
                if obj is Item {
                    let cell = tableView.cellForRow(at: indexPath) as! ItemCell
                    cell.itemName.isUserInteractionEnabled = true
                    cell.itemName.becomeFirstResponder()
                } else if obj is Category {
                    let cell = tableView.cellForRow(at: indexPath) as! CategoryCell
                    cell.categoryName.isUserInteractionEnabled = true
                    cell.categoryName.becomeFirstResponder()
                }
            }
        }
    }

    /// Handle long press gesture (cell move).
    func longPressAction(_ gesture: UILongPressGestureRecognizer)
    {
        let state: UIGestureRecognizerState = gesture.state
        let location: CGPoint = gesture.location(in: tableView)
        let topBarHeight = getTopBarHeight()
        var indexPath: IndexPath? = tableView.indexPathForRow(at: location)
        
        // prevent long press action on an AddItem cell
        if indexPath != nil {
            let cell = tableView.cellForRow(at: indexPath!)
            
            if cell is AddItemCell && !longPressHandedToList {
                // we got a long press action on the AddItem cell...
                
                // if it is the last AddItem cell, then we are moving down past the bottom of the tableView, so end the long press
                if list.indexPathIsLastRowDisplayed(indexPath!) && longPressActive {
                    longPressEnded(movingFromIndexPath, location: location)
                    // the following is needed to reset the gesture
                    gesture.isEnabled = false
                    gesture.isEnabled = true
                    return
                }
            }
        }
        
        // check if we need to end scrolling
        let touchLocationInWindow = tableView.convert(location, to: tableView.window)
        
        // we need to end the long press if we move above the top cell and into the top bar
        if touchLocationInWindow.y <= topBarHeight && location.y <= 0
        {
            // if we moved above the table view then set the destination to the top cell and end the long press
            if longPressActive {
                indexPath = IndexPath(row: 0, section: 0)
                longPressEnded(indexPath, location: location)
            }
            return
        }
        
        // check if we need to scroll tableView
        let touchLocation = gesture.location(in: gesture.view!.window)
        
        if touchLocation.y > (tableView.bounds.height - kScrollZoneHeight) {
            // need to scroll down
            if displayLink == nil {
                displayLink = CADisplayLink(target: self, selector: #selector(ItemViewController.scrollDownLoop))
                if let displayLink = displayLink {
                    displayLink.preferredFramesPerSecond = kFramesPerSecond
                    displayLink.add(to: RunLoop.main, forMode: RunLoopMode.defaultRunLoopMode)
                }
            }
        } else if touchLocation.y < (topBarHeight + kScrollZoneHeight) {
            // need to scroll up
            if displayLink == nil {
                displayLink = CADisplayLink(target: self, selector: #selector(ItemViewController.scrollUpLoop))
                if let displayLink = displayLink {
                    displayLink.preferredFramesPerSecond = kFramesPerSecond
                    displayLink.add(to: RunLoop.main, forMode: RunLoopMode.defaultRunLoopMode)
                }
            }
        } else if displayLink != nil {
            // check if we need to cancel a current scroll update because the touch moved out of scroll area
            if touchLocation.y < (tableView.bounds.height - kScrollZoneHeight) {
                if let displayLink = displayLink {
                    displayLink.invalidate()
                }
                displayLink = nil
            } else if touchLocation.y > (topBarHeight + kScrollZoneHeight) {
                if let displayLink = displayLink {
                    displayLink.invalidate()
                }
                displayLink = nil
            }
        }

        // if indexPath is null then we took our dragged cell to the list view
        // need to transfer control of the long press gesture to the list view
        if indexPath == nil {
            longPressHandedToList = true
            appDelegate.passGestureToListVC(gesture, obj: sourceObject)
            
            if gesture.state == .ended {
                gesture.isEnabled = false
                gesture.isEnabled = true
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
        case UIGestureRecognizerState.began:
            self.longPressBegan(indexPath!, location: location)
            prevLocation = location
            
        case UIGestureRecognizerState.changed:
            // long press has moved - call move method
            self.longPressMoved(indexPath!, location: location)
            prevLocation = location
            
        default:
            // long press has ended - call clean up method
            self.longPressEnded(indexPath!, location: location)
            prevLocation = nil
            
        }   // end switch
        
    }
    
    func longPressBegan(_ indexPath: IndexPath, location: CGPoint)
    {
        longPressActive = true
        sourceIndexPath = indexPath
        movingFromIndexPath = indexPath
        let cell = tableView.cellForRow(at: indexPath)!
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
            longPressCellType = .category
        } else if sourceObject is Item {
            longPressCellType = .item
        } else {
            longPressCellType = .addItem
            return
        }
        
        // create snapshot for long press cell moving
        if sourceObject is Item || sourceObject is Category {
            var center = cell.center
            snapshot?.center = center
            snapshot?.alpha = 0.0
            tableView.addSubview(snapshot!)
            
            UIView.animate(withDuration: 0.25, animations: { () -> Void in
                center.y = location.y
                self.snapshot?.center = center
                self.snapshot?.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
                self.snapshot?.alpha = 0.7
                cell.alpha = 0.0
                }, completion: { (finished: Bool) -> Void in
                    cell.isHidden = true      // hides the real cell while moving
            })
        }
    }
    
    func longPressMoved(_ idxPath: IndexPath?, location: CGPoint)
    {
        guard var indexPath = idxPath else { return }
        guard prevLocation != nil else { return }
        guard longPressCellType != .addItem else { return }
        
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
                if longPressCellType == .item && cellAtIndexPathIsAddCellCategoryPair(indexPath) {
                    // an item is moving over an AddCell/Category pair
                    let moveDirection = location.y < prevLocation!.y ? MoveDirection.up : MoveDirection.down
                    
                    if moveDirection == .down {
                        let rowCount = list.totalDisplayCount()
                        // this is to prevent dragging past the last row
                        if (indexPath as NSIndexPath).row >= rowCount-1 {
                            indexPath = IndexPath(row: (indexPath as NSIndexPath).row, section: 0)
                        } else {
                            indexPath = IndexPath(row: (indexPath as NSIndexPath).row + 1, section: 0)
                        }
                    } else {
                        indexPath = IndexPath(row: (indexPath as NSIndexPath).row - 1, section: 0)
                    }
                } else if longPressCellType == .category {
                    // a category is moving over another category
                }
                
                // ... move the rows
                tableView.moveRow(at: movingFromIndexPath!, to: indexPath)

                // ... and update movingFromIndexPath so it is in sync with UI changes
                movingFromIndexPath = indexPath
            }
        }
    }
    
    /// Clean up after a long press gesture.
    func longPressEnded(_ indexPath: IndexPath?, location: CGPoint)
    {
        longPressActive = false
        
        // cancel any scroll loop
        displayLink?.invalidate()
        displayLink = nil
        sourceObject = nil
        longPressHandedToList = false
        
        if longPressCellType == .addItem {
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
                let moveDirection = (sourceIndexPath! as NSIndexPath).row >  (indexPath! as NSIndexPath).row ? MoveDirection.up : MoveDirection.down
                let srcDataObj = list.objectForIndexPath(sourceIndexPath!)
                let destDataObj = list.objectForIndexPath(indexPath!)
                
                // move cells, update the list data source, move items and categories differently
                if srcDataObj is Item {
                    let srcItem = srcDataObj as! Item
                    
                    // we are moving an item
                    tableView.beginUpdates()
                    
                    // remove the item from its original location
                    _ = list.removeItem(srcItem, updateIndices: true)
                    //print("removeItem... \(srcItem.name)")
                    
                    // insert the item at its new location
                    if destDataObj is Item {
                        let destItem = destDataObj as! Item
                        if moveDirection == .down {
                            list.insertItem(srcItem, afterObj: destItem, updateIndices: true)
                        } else {
                            _ = list.insertItem(srcItem, beforeObj: destItem, updateIndices: true)
                        }
                        //print("insertItem... \(destItem.name)")
                    } else if destDataObj is Category {
                        var destCat = destDataObj as! Category
                        
                        if moveDirection == .down {
                            list.insertItem(srcItem, afterObj: destCat, updateIndices: true)
                        } else {
                            destCat = list.insertItem(srcItem, beforeObj: destCat, updateIndices: true)
                        }
                        
                        // if moving to a collapsed category, then need to remove the row from the table as it will no longer be displayed
                        if destCat.expanded == false {
                            tableView.deleteRows(at: [indexPath!], with: UITableViewRowAnimation.automatic)
                        }
                    } else if destDataObj is AddItem {
                        let addItem = destDataObj as! AddItem
                        
                        // moving to AddItem cell, so drop just above the AddItem cell
                        let destCat = list.categoryForObj(addItem)
                        
                        if destCat != nil {
                            list.insertItem(srcItem, inCategory: destCat!, atPosition: .end, updateIndices: true)
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
                    let moveDirection = (sourceIndexPath! as NSIndexPath).row >  (indexPath! as NSIndexPath).row ? MoveDirection.up : MoveDirection.down
                    
                    if moveDirection == .up && destDataObj is Item && dstCategoryIndex >= 0 {
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
            cell = tableView.cellForRow(at: indexPath!)
        }
        
        cell?.alpha = 0.0
        UIView.animate(withDuration: 0.25, animations: { () -> Void in
            if cell != nil {
                self.snapshot?.center = cell!.center
            }
            self.snapshot?.transform = CGAffineTransform.identity
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
        
        appDelegate.saveListData(async: true)
    }
    
    func scrollUpLoop()
    {
        let currentOffset = tableView.contentOffset
        let topBarHeight = getTopBarHeight()
        let newOffsetY = max(currentOffset.y - kItemViewScrollRate, -topBarHeight)
        let location: CGPoint = longPressGestureRecognizer!.location(in: tableView)
        let indexPath: IndexPath? = tableView.indexPathForRow(at: location)
        
        self.tableView.setContentOffset(CGPoint(x: currentOffset.x, y: newOffsetY), animated: false)
        
        if let path = indexPath {
            longPressMoved(path, location: location)
            prevLocation = location
        }
    }
    
    func scrollDownLoop()
    {
        let currentOffset = tableView.contentOffset
        let lastCellIndex = IndexPath(row: list.totalDisplayCount() - 1, section: 0)
        let lastCell = tableView.cellForRow(at: lastCellIndex)
        
        if lastCell == nil {
            self.tableView.setContentOffset(CGPoint(x: currentOffset.x, y: currentOffset.y + kItemViewScrollRate), animated: false)
            
            let location: CGPoint = longPressGestureRecognizer!.location(in: tableView)
            let indexPath: IndexPath? = tableView.indexPathForRow(at: location)
            
            if let path = indexPath {
                longPressMoved(path, location: location)
                prevLocation = location
            }
        } else {
            self.tableView.scrollToRow(at: lastCellIndex, at: .bottom, animated: true)
        }
    }
    
////////////////////////////////////////////////////////////////
//
//  MARK: - Delete methods
//
////////////////////////////////////////////////////////////////
    
    func confirmDelete(_ objName: String, isItem: Bool)
    {
        let DeleteItemTitle = NSLocalizedString("Delete_Item_Title", comment: "A title in an alert asking if the user wants to delete an item.")
        let DeleteItemMessage = String(format: NSLocalizedString("Delete_Item_Message", comment: "Are you sure you want to permanently delete the item %@?"), objName)
        let DeleteCategoryTitle = NSLocalizedString("Delete_Category_Title", comment: "A title in an alert asking if the user wants to delete a category.")
        let DeleteCategoryMessage = String(format: NSLocalizedString("Delete_Category_Message", comment: "Are you sure you want to permanently delete the category %@ and all of the items in it?"), objName)
        
        let alert = UIAlertController(title: isItem ? DeleteItemTitle : DeleteCategoryTitle, message: isItem ? DeleteItemMessage : DeleteCategoryMessage, preferredStyle: .alert)
        let deleteAction = UIAlertAction(title: NSLocalizedString("Delete", comment: "The Delete button title"), style: .destructive, handler: handleDeleteItem)
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "The Cancel button title"), style: .cancel, handler: cancelDeleteItem)
        
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        
        // Support display in iPad
        alert.popoverPresentationController?.sourceView = self.view
        alert.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.size.width / 2.0, y: self.view.bounds.size.height / 2.0, width: 1.0, height: 1.0)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    // deletes an item or a category and all of the items in it
    func handleDeleteItem(_ alertAction: UIAlertAction!) -> Void
    {
        if let indexPath = deleteItemIndexPath, let currentList = list {
            tableView.beginUpdates()
            
            // Delete the row(s) from the data source and return display paths of the removed rows
            var removedPaths: [IndexPath]
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
            tableView.deleteRows(at: removedPaths, with: .fade)
            
            // handle if we added a new category above
            if catAdded {
                let insertIndexPath = IndexPath.init(row: 0, section: 0)
                tableView.insertRows(at: [insertIndexPath], with: .automatic)
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
    
    func cancelDeleteItem(_ alertAction: UIAlertAction!) 
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
    
    func colorForIndex(_ index: Int) -> UIColor
    {
        return UIColor.white
        /*
        // gradient
        let itemCount = list.totalDisplayCount() - 1
        let val = (CGFloat(index) / CGFloat(itemCount)) * 0.99
        return UIColor(red: 0.0, green: val, blue: 1.0, alpha: 0.5)
        */
    }

    func snapshotFromView(_ inputView: UIView) -> UIView
    {
        // Make an image from the input view.
        UIGraphicsBeginImageContextWithOptions(inputView.bounds.size, false, 0)
        if let context = UIGraphicsGetCurrentContext()
        {
            inputView.layer.render(in: context)
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
                let indexPath = IndexPath(row: index, section: 0)
                cell = tableView.cellForRow(at: indexPath)
                    
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
    
    func rowAtIndexPathIsVisible(_ indexPath: IndexPath) -> Bool
    {
        let indicies = self.tableView.indexPathsForVisibleRows
        
        if indicies != nil {
            return indicies!.contains(indexPath)
        }
        
        return false
    }
    
    func adjustIndexPathIfItemMovingAboveTopRow(_ idxPath: IndexPath) -> IndexPath
    {
        var indexPath = idxPath
        
        if sourceIndexPath != nil {
            let srcObj = tableView.cellForRow(at: sourceIndexPath!)
        
            if srcObj is ItemCell && (indexPath as NSIndexPath).row == 0 {
                let obj = tableView.cellForRow(at: indexPath)
                
                if obj is CategoryCell {
                    indexPath = IndexPath(row: 1, section: 0)
                }
            }
        }
        
        return indexPath
    }
    
    /// Returns true if the cell at the given index path is part of an AddCell/Category pair.
    func cellAtIndexPathIsAddCellCategoryPair(_ indexPath: IndexPath) -> Bool
    {
        let row = (indexPath as NSIndexPath).row
        let nextRow = row + 1
        let prevRow = row - 1
        var isPair = false
        
        let cell = tableView.cellForRow(at: indexPath)
        let nextCell = tableView.cellForRow(at: IndexPath(row: nextRow, section: 0))
        let prevCell = tableView.cellForRow(at: IndexPath(row: prevRow, section: 0))
        
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
    func categoryTotalRowCount(_ indexPath: IndexPath) -> Int
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
        let statusBarHeight = UIApplication.shared.statusBarFrame.size.height
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
            present(vc, animated: true, completion: nil)
        }
    }
    
    func loadItemDetailView(_ item: Item)
    {
        transitioningDelegate = itemDetailTransitionDelegate
        
        let vc = ItemDetailViewController(item: item, list: list, itemVC: self)      // pass item by reference to
        vc.transitioningDelegate = itemDetailTransitionDelegate
        
        present(vc, animated: true, completion: nil)
    }
    
    // called from the dismissing settings view controller
    func presentPrintDialog()
    {
        let html = self.getHTMLforPrinting(appDelegate.picsInPrintAndEmail)
        let printController = UIPrintInteractionController.shared
        let printFormatter = UIMarkupTextPrintFormatter(markupText: html)
        
        printFormatter.perPageContentInsets = UIEdgeInsets(top: 0, left: 72, bottom: 72, right: 60)    // page margins (72 = 1") - bottom is ignored, top only used on first page
        printController.printFormatter = printFormatter
        printController.delegate = self
        printController.showsNumberOfCopies = true
        
        printController.present(animated: true, completionHandler: nil)
    }
    
    func scheduleEmailDialog() {
        DispatchQueue.main.async {
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
            mailViewController.navigationBar.barStyle = UIBarStyle.default
            
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
            
            self.present(mailViewController, animated: true, completion: nil)
        }
        else
        {
            let alertController = UIAlertController(title: "Can't Send Email", message: "Your device could not send e-mail.  Please check e-mail configuration and try again.", preferredStyle: .alert)
            let OKAction = UIAlertAction(title: "OK", style: .default) { (action) in
                print("email not configued... alert controller OKAction...")
            }
            alertController.addAction(OKAction)
            
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    // Dismisses the email composition interface when users tap Cancel or Send. Proceeds to update the message field with the result of the operation.
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?)
    {
        var message = ""
        
        switch result {
        case MFMailComposeResult.cancelled:
            message = "Email Cancelled"
        case MFMailComposeResult.saved:
            message = "Email Saved"
        case MFMailComposeResult.sent:
            message = "Email Sent"
        case MFMailComposeResult.failed:
            if let err = error {
                message = "Email Failure: \(err.localizedDescription)"
            }
        }
        
        if (result != MFMailComposeResult.cancelled) {
            let alertController = UIAlertController(title: message, message: nil, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default) { [unowned self] (action) in
                self.dismiss(animated: false, completion: nil)
            }
            alertController.addAction(okAction)
            
            controller.present(alertController, animated: true, completion: nil)
        } else {
            self.dismiss(animated: false, completion: nil)
        }
    }
    
    func getHTMLforPrinting(_ includePics: Bool) -> String
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
            preferredStyle: .alert)
        let okAction = UIAlertAction(title: okTitle, style: .default, handler: nil)
        alertVC.addAction(okAction)
        
        present(alertVC, animated: true, completion: nil)
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
            self.tableView.deleteRows(at: indexPaths as [IndexPath], with: UITableViewRowAnimation.automatic)
            self.tableView.endUpdates()
        }
        else
        {
            // insert the complete rows
            self.tableView.beginUpdates()
            self.tableView.insertRows(at: indexPaths as [IndexPath], with: UITableViewRowAnimation.automatic)
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
            self.tableView.deleteRows(at: indexPaths as [IndexPath], with: UITableViewRowAnimation.automatic)
            self.tableView.endUpdates()
        }
        else
        {
            // insert the inactive rows
            self.tableView.beginUpdates()
            self.tableView.insertRows(at: indexPaths as [IndexPath], with: UITableViewRowAnimation.automatic)
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
    func checkButtonTapped(_ checkBox: CheckBox) {
        print("checkButtonTapped: \(checkBox.tag)")
        let senderItem = list.objectForTag(checkBox.tag)
        var indexPath: IndexPath? = nil
        
        if senderItem is Item {
            let item = senderItem as! Item
            indexPath = list.displayIndexPathForItem(item)
            
            // cycle item state
            item.state.next()
            
            // call saveListData - cloudOnly mode
            appDelegate.saveListData(async: true)
            
            // set item name text color
            if indexPath != nil {
                let cell = tableView.cellForRow(at: indexPath!) as! ItemCell
                if item.state == ItemState.inactive {
                    cell.itemName.textColor = UIColor.lightGray
                } else {
                    cell.itemName.textColor = UIColor.black
                }
            }
            
            // remove a newly completed row if we are hiding completed items
            if list.showCompletedItems == false && item.state == ItemState.complete {
                if indexPath != nil {
                    self.tableView.deleteRows(at: [indexPath!], with: UITableViewRowAnimation.automatic)
                }
            }
            
            // remove a newly inactive row if we are hiding inactive items
            if list.showInactiveItems == false && item.state == ItemState.inactive {
                if indexPath != nil {
                    self.tableView.deleteRows(at: [indexPath!], with: UITableViewRowAnimation.automatic)
                }
            }
            
            // need to update the counts in the cat cell count label
            if let category = list.categoryForObj(item) {
                if let catIndexPath = list.displayIndexPathForCategory(category) {
                    if self.tableView.indexPathsForVisibleRows?.contains(catIndexPath) == true {
                        let catCell = tableView.cellForRow(at: catIndexPath) as! CategoryCell
                        catCell.catCountLabel.text = self.categoryCountString(category)
                    }
                }
            }
        } else {
            print("ERROR: checkButtonTapped received an index path that points to a non-item object!")
        }

    }
    
    // called after the item state has changed
    func checkButtonTapped_postStateChange(_ checkBox: CheckBox)
    {
        print("checkButtonTapped: \(checkBox.tag)")
        let senderItem = list.objectForTag(checkBox.tag)
        var indexPath: IndexPath? = nil
        
        if senderItem is Item {
            let item = senderItem as! Item
            indexPath = list.displayIndexPathForItem(item)
            
            // set item name text color
            if indexPath != nil {
                let cell = tableView.cellForRow(at: indexPath!) as! ItemCell
                if item.state == ItemState.inactive {
                    cell.itemName.textColor = UIColor.lightGray
                } else {
                    cell.itemName.textColor = UIColor.black
                }
            }
            
            // remove a newly completed row if we are hiding completed items
            if list.showCompletedItems == false && item.state == ItemState.complete {
                if indexPath != nil {
                    self.tableView.deleteRows(at: [indexPath!], with: UITableViewRowAnimation.automatic)
                }
            }
            
            // remove a newly inactive row if we are hiding inactive items
            if list.showInactiveItems == false && item.state == ItemState.inactive {
                if indexPath != nil {
                    self.tableView.deleteRows(at: [indexPath!], with: UITableViewRowAnimation.automatic)
                }
            }
            
            // need to update the counts in the cat cell count label
            if let category = list.categoryForObj(item) {
                if let catIndexPath = list.displayIndexPathForCategory(category) {
                    if self.tableView.indexPathsForVisibleRows?.contains(catIndexPath) == true {
                        let catCell = tableView.cellForRow(at: catIndexPath) as! CategoryCell
                        catCell.catCountLabel.text = self.categoryCountString(category)
                    }
                }
            }
        } else {
            print("ERROR: checkButtonTapped received an index path that points to a non-item object!")
        }
    }
    
    // item array helper methods
    func arrayContainsItem(_ itemArray: [Item], item: Item) -> Bool
    {
        return indexOfItemInArray(itemArray, item: item) > -1
    }
    
    func indexOfItemInArray(_ itemArray: [Item], item: Item) -> Int
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
    func layoutAnimated(_ animated: Bool)
    {
        tableView.frame.size.height = self.view.frame.height
        
        //print("layoutAnimated - frame height - old: \(oldFrameHeight) new: \(tableView.frame.size.height)")
        UIView.animate(withDuration: animated ? 0.5 : 0.0, animations: {
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
    func listSelected(_ newList: List) {
        list = newList
    }
    
    // called when the ListController changes the name of the list
    func listNameChanged(_ newName: String) {
        if list != nil {
            self.title = list!.name
        }
    }
    
    // called when the ListController deletes a list
    func listDeleted(_ deletedList: List) {
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
