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
        
        if object is Item {
            return true
        }
        
        return false
    }
    
    func cellIsCategory(indexPath: NSIndexPath) -> Bool
    {
        // returns true if path points to an item, false for categories
        let object = objectAtIndexPath(indexPath)
        
        if object is Category {
            return true
        }
        
        return false
    }
    
    func objectIsItem(object: AnyObject?) -> Bool
    {
        // returns true if object is an item, false for categories
        if object is Item {
            return true
        }
        
        return false
    }
    
    // returns an array of index paths of the category and displayed items for the category at the given path
    func getPathsForCategoryAtPath(indexPath: NSIndexPath) -> [NSIndexPath]
    {
        var catPaths = [NSIndexPath]()                          // holds array of display paths in category
        //let catDisplayPath = displayPathFor
        let category = self.categoryForItemAtIndex(indexPath)
        var row = indexPath.row
        
        // add the category path
        catPaths.append(indexPath)
        
        // add the paths of all items in the category
        if let cat = category {
            if cat.expanded {
                for _ in cat.items {
                    catPaths.append(NSIndexPath(forRow: ++row, inSection: 0))
                }
            }
        }
        
        return catPaths
    }
    
    // will remove the item at indexPath
    // if the path is to a category, will remove the entire category with items
    // returns the display index paths of any removed rows
    func removeItemAtIndexPath(indexPath: NSIndexPath, preserveCategories: Bool) -> [NSIndexPath]?
    {
        let itemIndices = indicesForObjectAtIndexPath(indexPath)
        print("remove: indicesForObjectAtIndexPath cat \(itemIndices.categoryIndex) item \(itemIndices.itemIndex)")
        
        if itemIndices.categoryIndex != nil && itemIndices.itemIndex != nil {
            // remove the item from the category
            self.categories[itemIndices.categoryIndex!].items.removeAtIndex(itemIndices.itemIndex!)
            return [indexPath]
        } else if itemIndices.categoryIndex != nil && itemIndices.itemIndex == nil {
            if preserveCategories {
                // remove the first item in this category
                self.categories[itemIndices.categoryIndex!].items.removeAtIndex(0)
                return [indexPath]
            } else {
                // remove an entire category and it's items
                let removedPaths = getPathsForCategoryAtPath(indexPath)
                self.categories.removeAtIndex(itemIndices.categoryIndex!)
                return removedPaths
            }
        } else {
            print("ERROR: List.removeItemAtIndexPath got a nil category or item index!")
            return nil
        }
    }
    
    // will insert the item at the indexPath
    // if the path is to a category, then will insert at beginning or end of category depending on move direction
    func insertItemAtIndexPath(item: Item, indexPath: NSIndexPath, atPosition: InsertPosition)
    {
        let itemIndices = indicesForObjectAtIndexPath(indexPath)
        print("insert: indicesForObjectAtIndexPath cat \(itemIndices.categoryIndex) item \(itemIndices.itemIndex)")
        
        switch atPosition {
        case .Beginning:
            self.categories[itemIndices.categoryIndex!].items.insert(item, atIndex: 0)
        case .Middle:
            if itemIndices.itemIndex != nil {
                self.categories[itemIndices.categoryIndex!].items.insert(item, atIndex: itemIndices.itemIndex!)
            } else {
                // if itemIndex is nil then we are moving down past the last item in the category, so just decrement the category and append
                if itemIndices.categoryIndex != nil {
                    self.categories[itemIndices.categoryIndex! - 1].items.append(item)
                } else {
                    // special case for moving past end of the list, append to the end of the last category
                    self.categories[categories.count-1].items.append(item)
                }
            }
        case .End:
            self.categories[itemIndices.categoryIndex!].items.append(item)
        }
    }
    
    // returns the data indices (cat and item) for the given display index path
    func indicesForObjectAtIndexPath(indexPath: NSIndexPath) -> (categoryIndex: Int?, itemIndex: Int?)
    {
        var index: Int = -1
        var catIndex: Int = -1
        
        for category in categories
        {
            ++index
            ++catIndex
            if category.name.characters.count > 0 {
                if index == indexPath.row {
                    // obj is a category, so item is nil
                    //print("indicesForObjectAtIndexPath cat \(catIndex) item (nil)")
                    return (catIndex, nil)
                }
            } else {
                // maps to a non-display category, so return indices to the first item in the category
                return (catIndex, indexPath.row)
            }
            
            // only count items in in expandeded categories
            if category.expanded {
                var itemIndex: Int = -1
                
                // expanded category
                for _ in category.items
                {
                    //print(item.name)
                    ++index
                    ++itemIndex
                    if index == indexPath.row {
                        // obj is an item
                        //print("indicesForObjectAtIndexPath cat \(catIndex) item \(itemIndex)")
                        return (catIndex, itemIndex)
                    }
                }
            } else {
                // collapsed category
                if index == indexPath.row {
                    // obj is a collapsed category
                    //print("indicesForObjectAtIndexPath cat \(catIndex) item (nil)")
                    return (catIndex, nil)
                }
            }
        }
        
        // points to a cell after end of last cell
        //print("indicesForObjectAtIndexPath cat (nil) item (nil)")
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
    
    // returns the path of the enclosing category for the given item
    func categoryPathForItemPath(itemPath: NSIndexPath) -> NSIndexPath?
    {
        let itemAtPath = self.objectAtIndexPath(itemPath)
        var index = -1
        var catPath: NSIndexPath? = nil
        
        for category in categories {
            catPath = NSIndexPath(forRow: ++index, inSection: 0)
            
            if category === itemAtPath {
                return catPath
            }
            
            for item in category.items {
                ++index
                if item === itemAtPath {
                    return catPath
                }
            }
        }
        
        return catPath
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
            if category.name.characters.count > 0 {
                ++index
                if index == indexPath.row {
                    if category.name.characters.count > 0 {
                        return category
                    } else {
                        --index // we will pick up the next object
                    }
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
    
    /*
    func getIndexPathsForAllRowsAfterCategoryAtIndexPath(indexPath: NSIndexPath) -> [NSIndexPath]
    {
        var indexPaths = [NSIndexPath]()
        
        for let category in categories
        {
            
        }
        
        
        return indexPaths
    }
    */
}

    // MARK: - Category class

class Category
{
    var name: String
    var items = [Item]()
    var expanded: Bool = true {
        didSet {
            //print("Category: \(name) expanded: \(expanded)")
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
