//
//  ItemViewController.swift
//  ListApp
//
//  Created by Steven Gentry on 12/30/15.
//  Copyright © 2015 Steven Gentry. All rights reserved.
//

import UIKit

let itemCellID     = "ItemCell"
let categoryCellID = "CategoryCell"

class ItemViewController: UITableViewController, UITextFieldDelegate
{
    //let maxItemsPerCategory = 1000000
    var inEditMode = false
    var deleteItemIndexPath: NSIndexPath? = nil
    
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
        self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        refreshItems()
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
            let displayCount = currentList.totalDisplayCount()
            
            //print("displayCount: \(displayCount)")
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
        
            // set up short tap gesture recognizer in cat cell to enable expand/collapse
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "catCellTapped:")
            cell.contentView.addGestureRecognizer(tapGestureRecognizer)
            
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
            if let cat = category {
                cell.catCountLabel.text = String(cat.items.count)
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
            return 44
        } else {
            return 60
        }
        //return UITableViewAutomaticDimension
    }
    
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if list.cellIsItem(indexPath) {
            return 44
        } else {
            return 60
        }
        //return UITableViewAutomaticDimension
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let title = list.cellTitle(indexPath)
        //print("selection: cat \(indexPath.section)  item \(indexPath.row)  title \(title)")
        let indices = list.indicesForObjectAtIndexPath(indexPath)
        
        print("selection: cat \(indices.categoryIndex)  item \(indices.itemIndex)  \(title)")
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    // Override to support editing the table view.
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
    
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath)
    {
        if list != nil {
            let item = list!.objectAtIndexPath(fromIndexPath)
            
            if item != nil {
                tableView.beginUpdates()
                list!.removeItemAtIndexPath(fromIndexPath)
                list!.insertItemAtIndexPath(item as! Item, indexPath: toIndexPath)
                tableView.endUpdates()
                
                // also update the category rows so we get new item counts displayed
                /*
                let fromCatPath = list.categoryPathForItemPath(fromIndexPath)
                let toCatPath = list.categoryPathForItemPath(toIndexPath)
                if let fromPath = fromCatPath, toPath = toCatPath {
                    tableView.reloadRowsAtIndexPaths([fromPath, toPath], withRowAnimation: UITableViewRowAnimation.None)
                }*/
                tableView.reloadData()
            } else {
                print("ERROR: Attempt to move a null item!")
            }
        } else {
            print("ERROR: Attempt to move an item in a null list!")
        }
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
    
    func textFieldShouldReturn(textField: UITextField) -> Bool
    {
        inEditMode = false
        textField.userInteractionEnabled = false
        textField.resignFirstResponder()
        self.setEditing(false, animated: false)
        return true
    }
    
    func itemNameDidChange(textField: UITextField)
    {
        // update item name data with new value
        let i = textField.tag
        let newName = textField.text!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        let indexPath = NSIndexPath(forRow: i, inSection: 0)
        
        list?.updateObjectNameAtIndexPath(indexPath, withName: newName)
        
        //print(textField.text)
    }
    
    // toggle expand/collapse state of category
    func catCellTapped(sender: UITapGestureRecognizer)
    {
        if !inEditMode {
            let i = sender.view?.tag
            print("sender.view.tag \(i)")
            let category = list.categoryForItemAtIndex(NSIndexPath(forRow: i!, inSection: 0))
            
            if let cat = category {
                cat.expanded = !cat.expanded
                print("expandButton was hit for category \(i) with name: \(cat.name)")
                tableView.reloadData()
            }
        } else {
            print("no toggle - inEditMode!")
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
            // Delete the row(s) from the data source and return paths of the removed rows
            let removedPaths = currentList.removeItemAtIndexPath(indexPath)
            if let _ = removedPaths {
                tableView.deleteRowsAtIndexPaths(removedPaths!, withRowAnimation: .Fade)
            }
            deleteItemIndexPath = nil
            tableView.endUpdates()
        } else {
            print("ERROR: handleDeleteItem received a null indexPath or list!")
        }
    }
    
    func cancelDeleteItem(alertAction: UIAlertAction!)
    {
        deleteItemIndexPath = nil
        self.setEditing(false, animated: false)
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


    /*
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
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
    // called from the ItemCell when the itemName text field has been long pressed for editing
    func itemNameTappedForEditing(textField: UITextField)
    {
        print("item textField tapped: '\(textField.text)'")
        textField.userInteractionEnabled = true
        textField.becomeFirstResponder()
    }
}

// CategoryCellDelegate methods
extension ItemViewController: CategoryCellDelegate
{
    // called from the CagtegoryCell when the itemName text field has been long pressed for editing
    func catNameTappedForEditing(textField: UITextField)
    {
        print("cat textField tapped: '\(textField.text)'")
        inEditMode = true
        textField.userInteractionEnabled = true
        textField.becomeFirstResponder()
    }
}
