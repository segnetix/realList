//
//  ItemViewController.swift
//  ListApp
//
//  Created by Steven Gentry on 12/30/15.
//  Copyright © 2015 Steven Gentry. All rights reserved.
//

import UIKit

class ItemViewController: UITableViewController, UITextFieldDelegate
{
    let maxItemsPerCategory = 1000000
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
        let categoryNr: Int = i / maxItemsPerCategory
        let itemNr: Int = i - (categoryNr * maxItemsPerCategory)
        list.categories[categoryNr].items[itemNr].name = textField.text!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        
        print(textField.text)
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        // return the number of categories
        let count = list?.categories.count
        
        if count != nil {
            return count!
        }
        else {
            return 0
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        // return the number of items in this category
        return list.categories[section].items.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier("ItemCell", forIndexPath: indexPath) as! ItemCell
        
        // Configure the cell...
        //cell.textLabel?.text = list?.categories[indexPath.section].items[indexPath.row].name
        cell.itemName.userInteractionEnabled = inEditMode
        cell.itemName.delegate = self
        cell.itemName.addTarget(self, action: "itemNameDidChange:", forControlEvents: UIControlEvents.EditingChanged)
        cell.itemName!.tag = (indexPath.section * maxItemsPerCategory) + indexPath.row
        
        let title = list?.categories[indexPath.section].items[indexPath.row].name
        
        if let cellTitle = title {
            cell.itemName?.attributedText = makeAttributedString(title: cellTitle, subtitle: "\(cell.itemName.tag)")
            //cell.itemName?.attributedText = makeAttributedString(title: cellTitle, subtitle: "")
        }
        else {
            cell.itemName?.attributedText = makeAttributedString(title: "", subtitle: "")
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        // empty category names will not get a section header
        return list.categories[section].name
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //selectedCategory = indexPath.section
        print("selection: cat \(indexPath.section)  item \(indexPath.row)")
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
            self.title = list.name
            self.tableView.reloadData()
        } else {
            self.title = "<empty>"
            self.tableView.reloadData()
        }
    }
    
    /*
    // not called
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        print("commitEditingStyle: \(editingStyle)  section: \(indexPath.section)  row: \(indexPath.row)")
    }
    
    override func tableView(tableView: UITableView, willBeginEditingRowAtIndexPath indexPath: NSIndexPath) {
        print("willBeginEditingRowAtIndexPath section: \(indexPath.section)  row: \(indexPath.row)")
    }
    */
    
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath)
    {
        if editingStyle == .Delete
        {
            deleteItemIndexPath = indexPath
            let deletedItem = list.categories[indexPath.section].items[indexPath.row]
            confirmDelete(deletedItem.name)
        }
        else if editingStyle == .Insert
        {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath)
    {
        let item = list?.categories[fromIndexPath.section].items[fromIndexPath.row]
        list?.categories[fromIndexPath.section].items.removeAtIndex(fromIndexPath.row)
        list?.categories[toIndexPath.section].items.insert(item!, atIndex: toIndexPath.row)
        
        self.tableView.reloadData()
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
        if let indexPath = deleteItemIndexPath
        {
            tableView.beginUpdates()
            
            // Delete the row from the data source
            list.categories[indexPath.section].items.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            self.tableView.reloadData()
            deleteItemIndexPath = nil
            
            tableView.endUpdates()
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
