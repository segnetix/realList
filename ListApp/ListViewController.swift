//
//  ListViewController.swift
//  ListApp
//
//  Created by Steven Gentry on 12/30/15.
//  Copyright © 2015 Steven Gentry. All rights reserved.
//

import UIKit

// ListSelectionDelegate protocol
protocol ListSelectionDelegate: class
{
    func listSelected(newList: List)
    func listDeleted(deletedList: List)
}

class ListViewController: UITableViewController, UITextFieldDelegate
{
    var lists = [List]()
    var inEditMode = false
    var deleteListIndexPath: NSIndexPath? = nil
    
    weak var delegate: ListSelectionDelegate?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        //tableView.rowHeight = 80.0
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        //navigationController?.hidesBarsOnSwipe = false
        
        // in this case, it's good to combine hidesBarsOnTap with hidesBarsWhenKeyboardAppears
        // so the user can get back to the navigation bar to save
        //navigationController?.hidesBarsOnTap = true
        //navigationController?.hidesBarsWhenKeyboardAppears = true
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
    
    func listNameDidChange(textField: UITextField)
    {
        // update list name data with new value
        let i = textField.tag
        lists[i].name = textField.text!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        
        print(lists[i].name)
    }
    
    // MARK: - Table view data source
        
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        // return the number of rows
        return lists.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier("ListCell", forIndexPath: indexPath) as! ListCell
        
        // Configure the cell...
        let list = lists[indexPath.row]
        
        //cell.listName?.text = list.name
        cell.listName.delegate = self
        cell.listName.addTarget(self, action: "listNameDidChange:", forControlEvents: UIControlEvents.EditingChanged)
        cell.listName.tag = indexPath.row
        cell.listName.userInteractionEnabled = inEditMode
        //cell.listName.attributedText = makeAttributedString(title: list.name, subtitle: "\(cell.listName.tag)")
        cell.listName.attributedText = makeAttributedString(title: list.name, subtitle: "")
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        let selectedList = self.lists[indexPath.row]
        self.delegate?.listSelected(selectedList)
        
        if let itemViewController = self.delegate as? ItemViewController {
            splitViewController?.showDetailViewController(itemViewController.navigationController!, sender: nil)
        }
    }
    
    //override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    //    return UITableViewAutomaticDimension
    //}
    
    //override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    //    return UITableViewAutomaticDimension
    //}
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        self.setEditing(false, animated: true)
        return true
    }
    
    /**
     * Called when the user click on the view (outside the UITextField).

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
    }
    */
     
    /*
    // not called
    override func tableView(tableView: UITableView, didEndEditingRowAtIndexPath indexPath: NSIndexPath) {
        print("didEndEditingAtIndexPath: \(indexPath.section), \(indexPath.row)")
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
            deleteListIndexPath = indexPath
            let deletedList = lists[indexPath.row]
            confirmDelete(deletedList.name)
        }
        else if editingStyle == .Insert
        {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
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
    
    /*
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return self.inEditMode ? UITableViewCellEditingStyle.Delete: UITableViewCellEditingStyle.Delete
    }
    */
    
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
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    func makeAttributedString(title title: String, subtitle: String) -> NSAttributedString {
        let titleAttributes = [NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleBody), NSForegroundColorAttributeName: UIColor.blackColor()]
        let subtitleAttributes = [NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleSubheadline)]
        
        let titleString = NSMutableAttributedString(string: "\(title)\n", attributes: titleAttributes)
        let subtitleString = NSAttributedString(string: subtitle, attributes: subtitleAttributes)
        
        titleString.appendAttributedString(subtitleString)
        
        return titleString
    }
    
    func addTestItems()
    {
        // list1
        let list1 = List(name: "Costco")
        lists.append(list1)
        
        let cat1_1 = Category(name: "Fruits and Veggies")
        let cat1_2 = Category(name: "Meats")
        let cat1_3 = Category(name: "Other")
        
        list1.categories.append(cat1_2)
        list1.categories.append(cat1_1)
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
        
        cat1_3.items.append(Item(name: "Noodle Chicken Bag"))
        cat1_3.items.append(Item(name: "Soda"))
        cat1_3.items.append(Item(name: "Dinty Moore"))
        cat1_3.items.append(Item(name: "Tea Bags"))
        
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
        let list3 = List(name: "King Super")
        lists.append(list3)
        
        let cat3_1 = Category(name: "")
        let cat3_2 = Category(name: "General")
        
        list3.categories.append(cat3_1)
        list3.categories.append(cat3_2)
        
        cat3_1.items.append(Item(name: "Bread"))
        cat3_1.items.append(Item(name: "Tomatoes"))
        cat3_1.items.append(Item(name: "Coffee"))
        cat3_2.items.append(Item(name: "Syrup"))
        cat3_2.items.append(Item(name: "Dog toys"))
        cat3_2.items.append(Item(name: "Leggings"))
        
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
