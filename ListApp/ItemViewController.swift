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
    
    // called when Edit/Done button is tapped in the navigation bar
    override func setEditing(editing: Bool, animated: Bool)
    {
        super.setEditing(editing, animated: animated)
        
        if editing {
            // enable the list cells for text editing
            inEditMode = true
        } else {
            // disable the list cells for text editing
            inEditMode = false
        }
        
        self.tableView.reloadData()
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
    
    func itemNameDidChange(textField: UITextField)
    {
        // update item name data with new value
        let i = textField.tag
        let newName = textField.text!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        let indexPath = NSIndexPath(forRow: i, inSection: 0)
        
        list?.updateObjectNameAtIndexPath(indexPath, withName: newName)
        
        print(textField.text)
    }
    
    func expandButtonHit(button: UIButton)
    {
        let i = button.tag
        let category = list.categoryForItemAtIndex(NSIndexPath(forRow: i, inSection: 0))
        
        if let cat = category {
            cat.expanded = !cat.expanded
            print("expandButton was hit for category \(i) with name: \(cat.name)")
            
            if cat.expanded {
                //self.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: i, inSection: 0)], withRowAnimation: .Top)
                self.tableView.reloadData()
            } else {
                self.tableView.reloadData()
            }
        }
        
    }
    
    // MARK: - Table view data source
    
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
            let catCount = currentList.categoryDisplayCount()
            let itemCount = currentList.itemDisplayCount()
            
            print("catDisplayCount: \(catCount)  itemDisplayCount: \(itemCount)")
            return catCount + itemCount
        } else {
            print("ERROR: numberOfRowsInSection - list is null!")
            return 0
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        if list.cellIsItem(indexPath) {
            // item cell
            let cell = tableView.dequeueReusableCellWithIdentifier(itemCellID, forIndexPath: indexPath) as! ItemCell
            
            // Configure the cell...
            cell.itemName.userInteractionEnabled = inEditMode
            cell.itemName.delegate = self
            cell.itemName.addTarget(self, action: "itemNameDidChange:", forControlEvents: UIControlEvents.EditingChanged)
            cell.itemName!.tag = indexPath.row
            
            let title = list?.cellTitle(indexPath)
            
            if let cellTitle = title {
                cell.itemName?.attributedText = makeAttributedString(title: cellTitle, subtitle: "\(cell.itemName.tag)")    // for debugging
                //cell.itemName?.attributedText = makeAttributedString(title: cellTitle, subtitle: "")                      // for production
            } else {
                cell.itemName?.attributedText = makeAttributedString(title: "", subtitle: "")
            }
            
            return cell
        } else {
            // category cell
            let cell = tableView.dequeueReusableCellWithIdentifier(categoryCellID, forIndexPath: indexPath) as! CategoryCell
            
            // Configure the cell...
            cell.categoryName.userInteractionEnabled = inEditMode
            cell.categoryName.delegate = self
            cell.categoryName.addTarget(self, action: "itemNameDidChange:", forControlEvents: UIControlEvents.EditingChanged)
            cell.categoryName!.tag = indexPath.row
            
            cell.expandButton.tag = indexPath.row
            cell.expandButton.addTarget(self, action: "expandButtonHit:", forControlEvents: UIControlEvents.TouchUpInside)
            
            let category = list.categoryForItemAtIndex(indexPath)
            
            if let cat = category {
                if cat.expanded {
                    cell.expandButton.setTitle("-", forState: .Normal)
                } else {
                    cell.expandButton.setTitle("+", forState: .Normal)
                }
            }
        
            let title = list?.cellTitle(indexPath)
            
            if let cellTitle = title {
                cell.categoryName?.attributedText = makeAttributedString(title: cellTitle, subtitle: "\(cell.categoryName.tag)")
                //cell.itemName?.attributedText = makeAttributedString(title: cellTitle, subtitle: "")
            } else {
                cell.categoryName?.attributedText = makeAttributedString(title: "", subtitle: "")
            }
            
            cell.backgroundColor = UIColor.lightGrayColor()
            
            return cell
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let title = list.cellTitle(indexPath)
        //print("selection: cat \(indexPath.section)  item \(indexPath.row)  title \(title)")
        let indices = list.indicesForObjectAtIndexPath(indexPath)
        
        print("selection: cat \(indices.categoryIndex)  item \(indices.itemIndex)  \(title)")
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        self.setEditing(false, animated: false)
        return true
    }
    
    /**
     * Called when the user click on the view (outside the UITextField).
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
    }
    */
    
    func refreshItems()
    {
        if list != nil {
            self.title = list!.name
            self.tableView.reloadData()
        } else {
            self.title = "<empty>"
            self.tableView.reloadData()
        }
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
            
            if let item = deletedItem {
                confirmDelete(item.name)
            } else {
                print("ERROR: Attempt to delete a null item!")
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
                
                // use tableView.reloadRowsAtIndexPaths???
                self.tableView.reloadData()
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
    
    func makeAttributedString(title title: String, subtitle: String) -> NSAttributedString {
        let titleAttributes = [NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleBody), NSForegroundColorAttributeName: UIColor.blackColor()]
        let subtitleAttributes = [NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleSubheadline)]
        
        let titleString = NSMutableAttributedString(string: "\(title)\n", attributes: titleAttributes)
        let subtitleString = NSAttributedString(string: subtitle, attributes: subtitleAttributes)
        
        titleString.appendAttributedString(subtitleString)
        
        return titleString
    }
    
    func confirmDelete(itemName: String)
    {
        let alert = UIAlertController(title: "Delete List", message: "Are you sure you want to permanently delete the item \(itemName)?", preferredStyle: .Alert)
        
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
            // Delete the row from the data source
            currentList.removeItemAtIndexPath(indexPath)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            deleteItemIndexPath = nil
            tableView.endUpdates()
            
             // use tableView.reloadRowsAtIndexPaths???
            self.tableView.reloadData()
        } else {
            print("ERROR: handleDeleteItem received a null indexPath or list!")
        }
    }
    
    func cancelDeleteItem(alertAction: UIAlertAction!)
    {
        deleteItemIndexPath = nil
        self.setEditing(false, animated: false)
    }

    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
    
}

// ListSelectionDelegate methods
extension ItemViewController: ListSelectionDelegate
{
    func listSelected(newList: List) {
        list = newList
    }
    
    func listDeleted(deletedList: List) {
        if deletedList === list {
            // our current list is being deleted
            list = nil
        }
    }
}
