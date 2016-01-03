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

class List
{
    var name: String
    var categories = [Category]()
    
    // designated initializer for a List
    init(name: String) {
        self.name = name
    }
    
    func categoryCount() -> Int {
        return categories.count
    }
    
    func itemCount() -> Int {
        var count: Int = 0
        
        for category in categories {
            count += category.items.count
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
        let itemIndices = indeciesForObjectAtIndexPath(indexPath)
        
        if itemIndices.categoryIndex != nil && itemIndices.itemIndex != nil {
            self.categories[itemIndices.categoryIndex!].items.removeAtIndex(itemIndices.itemIndex!)
        } else {
            print("ERROR: List.removeItemAtIndexPath got a nil category or item index!")
        }
    }
    
    func insertItemAtIndexPath(item: Item, indexPath: NSIndexPath)
    {
        let itemIndices = indeciesForObjectAtIndexPath(indexPath)
        
        if itemIndices.categoryIndex != nil && itemIndices.itemIndex != nil {
            self.categories[itemIndices.categoryIndex!].items.insert(item, atIndex: itemIndices.itemIndex!)
        } else {
            print("ERROR: List.insertItemAtIndexPath got a nil category or item index!")
        }
    }
    
    func indeciesForObjectAtIndexPath(indexPath: NSIndexPath) -> (categoryIndex: Int?, itemIndex: Int?)
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
                print("indeciesForObjectAtIndexPath cat \(catIndex) item (nil)")
                return (catIndex, nil)
            }
            
            for _ in category.items
            {
                ++index
                ++itemIndex
                if index == indexPath.row {
                    // obj is an item
                    print("indeciesForObjectAtIndexPath cat \(catIndex) item \(itemIndex)")
                    return (catIndex, itemIndex)
                }
            }
        }
        
        // error condition
        print("ERROR: indeciesForObjectAtIndexPath exited with nil, nil!")
        return (nil, nil)
    }
    
    func categoryForItemAtIndex(indexPath: NSIndexPath) -> Category?
    {
        var index: Int = -1
        
        for category in categories
        {
            ++index
            if index == indexPath.row {
                return category
            }
            
            for _ in category.items
            {
                ++index
                if index == indexPath.row {
                    return category
                }
            }
        }

        return nil
    }
    
    func objectAtIndexPath(indexPath: NSIndexPath) -> AnyObject?
    {
        // returns the object (Category or Item) at the given index path
        var index: Int = -1
        
        for category in categories
        {
            ++index
            if index == indexPath.row {
                return category
            }
            
            for item in category.items
            {
                ++index
                if index == indexPath.row {
                    return item
                }
            }
        }
        
        return nil
    }
    
}

class Category
{
    var name: String
    var items = [Item]()
    
    // designated initializer for a Category
    init(name: String) {
        self.name = name
    }
    
    func itemCount() -> Int {
        return items.count
    }
}

class Item
{
    var name: String
    
    // designated initializer for an Item
    init(name: String)
    {
        self.name = name
    }
    
}
