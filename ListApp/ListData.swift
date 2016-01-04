//
//  ListData.swift
//  ListApp
//
//  Created by Steven Gentry on 12/31/15.
//  Copyright © 2015 Steven Gentry. All rights reserved.
//

import UIKit

/*
class ListData
{
    var lists = [List]()

    func addList(listName: String)
    {
        let list = List(name: listName)
        
        lists.append(list)
    }
    
}
*/

    // MARK: - List class

// 1. lists have one or more categories for items
// 2. if the list has only one category and the category name is empty then the list is treated as though it has no categories
// 3. if the user adds a category with an empty name then the data model will set the name to a single space char
// 4. if the user deletes the last category then the last category is not deleted but the name is set to a single space char
class List
{
    var name: String
    var categories = [Category]()
    
    // designated initializer for a List
    init(name: String) {
        self.name = name
    }
    
    // return the number of categories with non-empty names
    func categoryCount() -> Int
    {
        var count: Int = 0
        
        for category in categories {
            if category.name.characters.count > 0 {
                ++count
            }
        }
        
        return count
    }
    
    // return the number of expanded categories with non-empty names
    func categoryDisplayCount() -> Int
    {
        var count: Int = 0
        
        for category in categories {
            if category.name.characters.count > 0 {
                ++count
            }
        }
        
        return count
    }
    
    // returns total item count
    func itemCount() -> Int
    {
        var count: Int = 0
        
        for category in categories {
            count += category.items.count
        }
        
        return count
    }
    
    // returns total display item count
    func itemDisplayCount() -> Int
    {
        var count: Int = 0
        
        for category in categories {
            if category.expanded {
                count += category.items.count   // if expanded, add the count of items in this category
            }
        }
        
        return count
    }
    
    // returns total of all potential displayable rows
    func totalCount() -> Int
    {
        var count: Int = 0
        
        for category in categories {
            // add the category if displayed
            if category.name.characters.count > 0 {
                ++count
            }
            
            // add the items in this category
            count += category.items.count
        }
        
        return count
    }
    
    // returns the total of all rows to display
    func totalDisplayCount() -> Int
    {
        var count: Int = 0
        
        for category in categories {
            // add the category if displayed
            if category.name.characters.count > 0 {
                ++count
            }
            
            // add the items in this category if expanded
            if category.expanded {
                count += category.items.count
            }
        }
        
        return count
    }
    
    func cellTitle(indexPath: NSIndexPath) -> String?
    {
        let object = objectAtIndexPath(indexPath)
        
        if let obj = object {
            if objectIsItem(obj) {
                return (obj as! Item).name
            } else {
                return (obj as! Category).name
            }
        }
        
        return ""
    }
    
    func updateObjectNameAtIndexPath(indexPath: NSIndexPath, withName: String)
    {
        let obj = objectAtIndexPath(indexPath)
        
        if objectIsItem(obj) {
            (obj as! Item).name = withName
        } else {
            (obj as! Category).name = withName
        }
    }
    
    func cellIsItem(indexPath: NSIndexPath) -> Bool
    {
        // returns true if path points to an item, false for categories
        
        let object = objectAtIndexPath(indexPath)
        
        if let _ = object as? Item {
            return true
        }
        
        return false
    }
    
    func objectIsItem(object: AnyObject?) -> Bool
    {
        // returns true if object is an item, false for categories
        
        if let _ = object as? Item {
            return true
        }
        
        return false
    }
    
    func removeItemAtIndexPath(indexPath: NSIndexPath)
    {
        let itemIndices = indicesForObjectAtIndexPath(indexPath)
        
        if itemIndices.categoryIndex != nil && itemIndices.itemIndex != nil {
            self.categories[itemIndices.categoryIndex!].items.removeAtIndex(itemIndices.itemIndex!)
        } else {
            print("ERROR: List.removeItemAtIndexPath got a nil category or item index!")
        }
    }
    
    func insertItemAtIndexPath(item: Item, indexPath: NSIndexPath)
    {
        let itemIndices = indicesForObjectAtIndexPath(indexPath)
        
        if itemIndices.categoryIndex != nil && itemIndices.itemIndex != nil {
            self.categories[itemIndices.categoryIndex!].items.insert(item, atIndex: itemIndices.itemIndex!)
        } else {
            print("ERROR: List.insertItemAtIndexPath got a nil category or item index!")
        }
    }
    
    func indicesForObjectAtIndexPath(indexPath: NSIndexPath) -> (categoryIndex: Int?, itemIndex: Int?)
    {
        var index: Int = -1
        var catIndex: Int = -1
        
        for category in categories
        {
            var itemIndex: Int = -1
            
            ++index
            ++catIndex
            if index == indexPath.row {
                // obj is a category, so item is nil
                print("indicesForObjectAtIndexPath cat \(catIndex) item (nil)")
                return (catIndex, nil)
            }
            
            for _ in category.items
            {
                ++index
                ++itemIndex
                if index == indexPath.row {
                    // obj is an item
                    print("indicesForObjectAtIndexPath cat \(catIndex) item \(itemIndex)")
                    return (catIndex, itemIndex)
                }
            }
        }
        
        // error condition
        print("ERROR: indicesForObjectAtIndexPath exited with nil, nil!")
        return (nil, nil)
    }
    
    // returns the category (including the dummy category if only one category) for the given item
    func categoryForItem(givenItem: Item) -> Category?
    {
        for category in categories
        {
            for item in category.items {
                if item === givenItem {
                    return category
                }
            }
        }
        
        return nil
    }
    
    // returns the category (including the dummy category if only one category) for the item at the given index
    func categoryForItemAtIndex(indexPath: NSIndexPath) -> Category?
    {
        var index: Int = -1
        
        for category in categories
        {
            ++index
            if index == indexPath.row {
                return category
            }
            
            if category.expanded {
                for _ in category.items {
                    ++index
                    if index == indexPath.row {
                        return category
                    }
                }
            }
        }

        return nil
    }
    
    func objectAtIndexPath(indexPath: NSIndexPath) -> AnyObject?
    {
        // returns the object (Category or Item) at the given index path
        // also, will skip a category with an empty name
        // and will skip items in collapsed categories
        var index: Int = -1
        
        for category in categories
        {
            ++index
            if index == indexPath.row {
                if category.name.characters.count > 0 {
                    return category
                } else {
                    --index // we will pick up the next object
                }
            }
            
            // we only look at objects that are displayed
            if category.expanded {
                for item in category.items
                {
                    ++index
                    if index == indexPath.row {
                        return item
                    }
                }
            }
        }
        
        return nil
    }
    
}

    // MARK: - Category class

class Category
{
    var name: String
    var items = [Item]()
    var expanded: Bool = true {
        didSet {
            print("Category: \(name) expanded: \(expanded)")
        }
    }
    
    
    
    // designated initializer for a Category
    init(name: String) {
        self.name = name
    }
    
    func itemCount() -> Int {
        return items.count
    }
}

    // MARK: - Item class

class Item
{
    var name: String
    
    // designated initializer for an Item
    init(name: String)
    {
        self.name = name
    }
    
}
