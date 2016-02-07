//
//  ListData.swift
//  ListApp
//
//  Created by Steven Gentry on 12/31/15.
//  Copyright © 2015 Steven Gentry. All rights reserved.
//

import UIKit

let kItemIndexMax = 100000

enum ItemState {
    case Inactive
    case Incomplete
    case Complete
}

////////////////////////////////////////////////////////////////
//
//  MARK: - List class
//
////////////////////////////////////////////////////////////////

// 1. lists have one or more categories that hold items
// 2. if the list has only one category and the category name is empty then the list is treated as though it has no categories
// 3. if the user adds a category with an empty name then the data model will set the name to a single space char
// 4. if the user deletes the last category then the last category is not deleted but the name is set to a single space char

class List
{
    var name: String
    var categories = [Category]()
    
    var showCompletedItems: Bool = true {
        didSet(newShow) {
            self.updateIndices()
        }
    }
    
    var showInactiveItems: Bool = true {
        didSet(newShow) {
            self.updateIndices()
        }
    }
    
    // designated initializer for a List
    init(name: String) {
        self.name = name
    }
    
///////////////////////////////////////////////////////
//
//  MARK: New initializers for Category and Item objects
//
///////////////////////////////////////////////////////
    
    func indexForCategory(category: Category) -> Int
    {
        var index = -1
        
        for cat in categories {
            if cat === category {
                ++index
                return index
            }
        }
        
        return -1
    }
    
    func addCategory(name: String, displayHeader: Bool, updateIndices: Bool) -> Category
    {
        let category = Category(name: name, displayHeader: displayHeader)
        categories.append(category)
        
        if updateIndices {
            self.updateIndices()
        }
        
        return category
    }
    
    func addItem(category: Category, name: String, state: ItemState, updateIndices: Bool) -> Item?
    {
        let indexForCat = indexForCategory(category)
        var item: Item? = nil
        
        if indexForCat > -1 {
            item = Item(name: name, state: state)
            category.items.append(item!)
        } else {
            print("ERROR: addItem given invalid category!")
        }
        
        if (updateIndices) {
            self.updateIndices()
        }
        
        return item
    }
    
///////////////////////////////////////////////////////
//
//  MARK: New remove and insert methods for List objects
//
///////////////////////////////////////////////////////
    
    /// Will remove the given item from the list data.
    func removeItem(item: Item, updateIndices: Bool) -> [NSIndexPath]
    {
        var removedPaths = [NSIndexPath]()
        let indexPath = displayIndexPathForItem(item)
        
        if indexPath != nil {
            let catIdx = item.categoryIndex
            let itmIdx = item.itemIndex - 1         // we have to subtract 1 to convert from itemIndex to items index (cat is 0, 1st item is 1, etc.)
            self.categories[catIdx].items.removeAtIndex(itmIdx)
            removedPaths.append(indexPath!)
        }
        
        if updateIndices {
            self.updateIndices()
        }
        
        return removedPaths
    }
    
    /// Will insert item after afterObj.
    func insertItem(item: Item, afterObj: ListObj, updateIndices: Bool)
    {
        let catIdx = afterObj.categoryIndex
        var itmIdx = afterObj.itemIndex - 1         // we have to subtract 1 to convert from itemIndex to items index (cat is 0, 1st item is 1, etc.)
        let category = categories[catIdx]
        
        // check for insert after category, in that case drop at the beginning of the category if expanded, end if collapsed
        if itmIdx < 0 {
            if category.expanded == false {
                // collapsed
                itmIdx = category.items.count - 1
            } else {
                // expanded
                itmIdx = -1
            }
        }
        
        category.items.insert(item, atIndex: itmIdx + 1)
        
        if updateIndices {
            self.updateIndices()
        }
    }
    
    /// Will insert item before beforeObj.
    func insertItem(item: Item, beforeObj: ListObj, updateIndices: Bool) -> Category
    {
        var catIdx = beforeObj.categoryIndex
        var itmIdx = beforeObj.itemIndex - 1            // we have to subtract 1 to convert from itemIndex to items index (cat is 0, 1st item is 1, etc.)
        
        // check for insert before category, in that case switch to the end of the previous category
        if catIdx > 0 && itmIdx < 0 {
            --catIdx                                    // move to the previous category
            itmIdx = categories[catIdx].items.count     // end of the category
        } else if itmIdx < 0 {
            // moved above top row, set to top position in top category
            itmIdx = 0
        }
        
        categories[catIdx].items.insert(item, atIndex: itmIdx)
        
        if updateIndices {
            self.updateIndices()
        }
        
        return categories[catIdx]
    }
    
    /// Will insert item at either the beginning or the end of the category.
    func insertItem(item: Item, inCategory: Category, atPosition: InsertPosition, updateIndices: Bool)
    {
        switch atPosition {
        case .Beginning:
            inCategory.items.insert(item, atIndex: 0)
        case .End:
            let itemCount = inCategory.items.count
            inCategory.items.insert(item, atIndex: itemCount)
        default:
            break
        }
        
        if updateIndices {
            self.updateIndices()
        }
    }
    
    /// Will remove the item at indexPath.
    /// If the path is to a category, will remove the entire category with items.
    /// Returns an array with the display index paths of any removed rows.
    func removeItemAtIndexPath(indexPath: NSIndexPath, preserveCategories: Bool, updateIndices: Bool) -> [NSIndexPath]
    {
        var removedPaths = [NSIndexPath]()
        let obj = objectForIndexPath(indexPath)
        
        if let obj = obj
        {
            let catIndex = obj.categoryIndex
            let itemIndex = obj.itemIndex - 1       // we have to subtract 1 to convert from itemIndex to items index (cat is 0, 1st item is 1, etc.)
            
            print("remove: indicesForObjectAtIndexPath cat \(catIndex) item \(itemIndex) name: \(obj.name)")
            
            if itemIndex >= 0 {
                // remove the item from the category
                self.categories[catIndex].items.removeAtIndex(itemIndex)
                removedPaths.append(indexPath)
            } else {
                if preserveCategories {
                    // remove the first item in this category
                    self.categories[catIndex].items.removeAtIndex(0)
                    removedPaths.append(indexPath)
                } else {
                    // remove an entire category and it's items
                    removedPaths = displayIndexPathsForCategory(indexPath)
                    self.categories.removeAtIndex(catIndex)
                }
            }
        }
        
        if updateIndices {
            self.updateIndices()
        }
        
        return removedPaths
    }
    
    /// Will insert the item at the indexPath.
    /// If the path is to a category, then will insert at beginning or end of category depending on move direction.
    func insertItemAtIndexPath(item: Item, indexPath: NSIndexPath, atPosition: InsertPosition, updateIndices: Bool)
    {
        let tag = tagForIndexPath(indexPath)
        let catIndex = tag.catIdx
        let itemIndex = tag.itmIdx - 1          // we have to subtract 1 to convert from itemIndex to items index (cat is 0, 1st item is 1, etc.)
    
        switch atPosition {
        case .Beginning:
            categories[catIndex].items.insert(item, atIndex: 0)
        case .Middle:
            if itemIndex >= 0 {
                categories[catIndex].items.insert(item, atIndex: itemIndex)
            } else {
                // if itemIndex is 0 then we are moving down past the last item in the category, so just decrement the category and append
                if catIndex > 0 {
                    categories[catIndex - 1].items.append(item)
                } else {
                    // special case for moving past end of the list, append to the end of the last category
                    categories[categories.count-1].items.append(item)
                }
            }
        case .End:
            if catIndex >= 0 {
                categories[catIndex].items.append(item)
            } else {
                print("ALERT! - insertItemAtIndexPath - .End with nil categoryIndex...")
            }
        }
        
        if updateIndices {
            self.updateIndices()
        }
    }
    
    /// Removed the category (and associated items) at the given index.
    func removeCatetoryAtIndex(sourceCatIndex: Int)
    {
        if sourceCatIndex < self.categories.count
        {
            categories.removeAtIndex(sourceCatIndex)
        }
        
        updateIndices()
    }
    
    /// Inserts the given category at the given index.
    func insertCategory(category: Category, atIndex: Int)
    {
        if atIndex >= self.categories.count {
            // append this category to the end
            self.categories.append(category)
        } else {
            self.categories.insert(category, atIndex: atIndex)
        }
        
        updateIndices()
    }
    

///////////////////////////////////////////////////////
//
//  MARK: New reference methods for List objects
//
///////////////////////////////////////////////////////
    
    /// Updates the indices for all objects in the list.
    func updateIndices()
    {
        var i = -1
        for cat in categories {
            cat.updateIndices(++i)
        }
    }
    
    /// Returns the total number of rows to display in the ItemVC
    func totalDisplayCount() -> Int
    {
        var count = 0
        
        for category in categories {
            if category.displayHeader {
                ++count
            }
            
            if category.expanded {
                for item in category.items {
                    if isDisplayedItem(item) {
                        ++count
                    }
                }
                ++count     // for AddItem cell
            }
        }
        
        return count
    }
    
    /// Returns the Category with the given tag.
    func categoryForTag(tag: Int) -> Category?
    {
        let tag = Tag.indicesFromTag(tag)
        
        if tag.catIdx >= 0 && tag.catIdx < categories.count {
            return categories[tag.catIdx]
        }
        
        print("ERROR: categoryForTag given invalid tag! \(tag)")
        return nil
    }
    
    /// Returns the Item with the given tag.
    func itemForTag(tag: Int) -> Item?
    {
        let tag = Tag.indicesFromTag(tag)
        
        if tag.catIdx >= 0 && tag.catIdx < categories.count
        {
            let category = categories[tag.catIdx]
            if tag.itmIdx > 0 && tag.itmIdx <= category.items.count {
                return category.items[tag.itmIdx - 1]       // -1 converts from row tag to category item index
            }
        }
        
        print("ERROR: itemForTag given invalid tag!")
        return nil
    }
    
    /// Returns the object (Category or Item) with the given tag.
    func objectForTag(tag: Int) -> ListObj?
    {
        // get indices from tag
        let indices = Tag.indicesFromTag(tag)
        var obj: ListObj? = nil
        
        if indices.itmIdx == 0 {
            obj = categoryForTag(tag)
        } else {
            obj = itemForTag(tag)
        }
        
        if obj == nil {
            print("ERROR: objectForTag given invalid tag!")
        }
        
        return obj
    }
    
    /// Returns the Category for the given Item.
    func categoryForObj(item: ListObj) -> Category?
    {
        if item.categoryIndex >= 0 && item.categoryIndex < categories.count {
            return categories[item.categoryIndex]
        }
        
        print("ERROR: categoryForItem - Item has an invalid category index!")
        return nil
    }
    
    /// Returns a Category for the object at the given index path.
    func categoryForIndexPath(indexPath: NSIndexPath) -> Category?
    {
        let obj = objectForIndexPath(indexPath)
        
        if obj is Category {
            return (obj as! Category)
        }
        
        return nil
    }
    
    /// Returns an Item for the object at the given index path.
    func itemForIndexPath(indexPath: NSIndexPath) -> Item?
    {
        let obj = objectForIndexPath(indexPath)
        
        if obj is Item {
            return (obj as! Item)
        }
        
        return nil
    }
    
    /// Returns the object for the given indexPath.
    func objectForIndexPath(indexPath: NSIndexPath) -> ListObj?
    {
        let row = indexPath.row
        var index = -1
        
        for category in categories {
            if category.displayHeader {
                ++index
            }
            
            if index == row {
                return category
            }
            
            if category.expanded {
                for item in category.items {
                    if isDisplayedItem(item) {
                        ++index
                        if index == row {
                            return item
                        }
                    }
                }
                ++index
                if index == row {
                    return category.addItem
                }
            }
        }
        
        print("ERROR: objectForIndexPath given invalid indexPath!")
        return nil
    }
    
    /// Returns a display indexPath for a given tag.  The index path is calculated from the current category status plus ItemVC view status (show/hide status of completed/inactive items).
    func displayIndexPathForTag(tag: Int) -> NSIndexPath?
    {
        // get object from tag
        let obj = objectForTag(tag)
        
        // return indexPathForObj
        if let obj = obj {
            return displayIndexPathForObj(obj).indexPath
        }
        
        print("ERROR: displayIndexPathForTag given invalid tag!")
        return nil
    }
    
    /// Returns the current index path for the given object.  The index path is calculated from the current category status plus ItemVC view status (show/hide status of completed/inactive items).
    func displayIndexPathForObj(obj: ListObj) -> (indexPath: NSIndexPath?, isItem: Bool)
    {
        var index = -1
        
        for category in categories {
            if category.displayHeader {
                ++index
            }
            
            if category === obj {
                return (NSIndexPath(forRow: index, inSection: 0), false)
            }
            
            if category.expanded {
                for item in category.items {
                    if isDisplayedItem(item) {
                        ++index
                        if item === obj {
                            return (NSIndexPath(forRow: index, inSection: 0), true)
                        }
                    }
                }
                // for AddItem cell
                ++index
                if category.addItem === obj {
                    return (NSIndexPath(forRow: index, inSection: 0), true)
                }
            }
        }
        
        print("ERROR: displayIndexPathForObj given an invalid object!")
        return (nil, false)
    }
    
    /// Returns a display indexPath to the given Category.
    func displayIndexPathForCategory(category: Category) -> NSIndexPath?
    {
        let result = displayIndexPathForObj(category)
        
        if result.isItem == false {
            return result.indexPath
        }
        
        print("ERROR: displayIndexPathForCategory given an invalid object as a Category!")
        return nil
    }
    
    /// Returns a display indexPath to the given Item.
    func displayIndexPathForItem(item: Item) -> NSIndexPath?
    {
        let result = displayIndexPathForObj(item)
        
        if result.isItem {
            return result.indexPath
        }
        
        print("ERROR: displayIndexPathForCategory given an invalid object as an Item!")
        return nil
    }
    
    /// Returns a display indexPath for the AddItem cell in this category.
    func displayIndexPathForAddItemInCategory(category: Category) -> NSIndexPath?
    {
        var lastItemInCat: ListObj? = nil
        
        if category.items.count > 0 {
            lastItemInCat = category.items[category.items.count-1]
        } else {
            lastItemInCat = category
        }
        
        if let lastItem = lastItemInCat
        {
            let lastItemIndexPath: NSIndexPath? = displayIndexPathForObj(lastItem).indexPath
            
            if let lastItemIndexPath = lastItemIndexPath {
                return NSIndexPath(forRow: lastItemIndexPath.row + 1, inSection: 0)
            }
        } else {
           print("ERROR: displayIndexPathForAddItemInCategory given an invalid category!")
        }
        
        return nil
    }
    
    /// Returns the index paths for a Category at given index path, all of its Items and the AddItem row.
    func displayIndexPathsForCategory(indexPath: NSIndexPath) -> [NSIndexPath]
    {
        let category = categoryForIndexPath(indexPath)
        
        if category != nil {
            return displayIndexPathsForCategory(category!)
        }
        
        return [NSIndexPath]()
    }
    
    /// Returns an array of display index paths for a category that is being expanded or collapsed.
    func displayIndexPathsForCategory(category: Category) -> [NSIndexPath]
    {
        var indexPaths = [NSIndexPath]()
        let catIndexPath = displayIndexPathForCategory(category)
        
        if let indexPath = catIndexPath
        {
            var pos = indexPath.row
            
            for item in category.items {
                if isDisplayedItem(item) {
                    indexPaths.append(NSIndexPath(forRow: ++pos, inSection: 0))
                }
            }
            
            // one more for the addItem cell
            indexPaths.append(NSIndexPath(forRow: ++pos, inSection: 0))
        } else {
            print("ERROR: displayIndexPathsForCategory was given an invalid index path!")
        }
        
        return indexPaths
    }
    
    /// Returns index paths for completed rows.
    func indexPathsForCompletedRows() -> [NSIndexPath]
    {
        var indexPaths = [NSIndexPath]()
        var pos = -1
        
        for category in categories
        {
            if category.displayHeader {
                ++pos
            }
            
            if category.expanded
            {
                for item in category.items
                {
                    if item.state == ItemState.Complete {
                        indexPaths.append(NSIndexPath(forRow: ++pos, inSection: 0))
                    } else if item.state != ItemState.Inactive || showInactiveItems {
                        ++pos
                    }
                }
                ++pos     // for the AddItem cell
            }
        }
        
        return indexPaths
    }
    
    /// Returns index paths for inactive rows.
    func indexPathsForInactiveRows() -> [NSIndexPath]
    {
        var indexPaths = [NSIndexPath]()
        var pos = -1
        
        for category in categories
        {
            if category.displayHeader {
                ++pos
            }
            
            if category.expanded
            {
                for item in category.items
                {
                    if item.state == ItemState.Inactive {
                        indexPaths.append(NSIndexPath(forRow: ++pos, inSection: 0))
                    } else if item.state != ItemState.Complete || showCompletedItems {
                        ++pos
                    }
                }
                ++pos     // for the AddItem cell
            }
        }
        
        return indexPaths
    }
    
    /// Returns the title of the object at the given index path.
    func titleForObjectAtIndexPath(indexPath: NSIndexPath) -> String?
    {
        let obj = objectForIndexPath(indexPath)
        
        if obj != nil {
            return obj!.name
        }
        
        print("ERROR: titleForObjectAtIndexPath given an invalid index path!")
        return ""
    }
    
    /// Updates the category or item object's name.
    func updateObjNameAtTag(tag: Int, name: String)
    {
        let obj = objectForTag(tag)
        
        if obj != nil {
            obj!.name = name
        }
    }
    
    /// Determines if an Item should be displayed
    func isDisplayedItem(item: Item) -> Bool
    {
        return (item.state == .Incomplete) ||
               (item.state == .Complete && showCompletedItems) ||
               (item.state == .Inactive && showInactiveItems)
    }
    
    /// Returns true if the given path is the last row displayed.
    func indexPathIsLastRowDisplayed(indexPath: NSIndexPath) -> Bool
    {
        var lastObjRow: Int? = nil
        let lastCategory = categories[categories.count-1]
        
        if lastCategory.expanded == false {
            // category is collapsed, compare with category row
            lastObjRow = displayIndexPathForCategory(lastCategory)?.row
        } else {
            // category is expanded, get indexPath to AddItem row
            let addItemIndexPath = displayIndexPathForObj(lastCategory.addItem)
            if addItemIndexPath.indexPath != nil {
                lastObjRow = addItemIndexPath.indexPath!.row
            }
        }
        
        return lastObjRow == indexPath.row
    }
    
    /// Returns the catagory and item indices for the given path.
    func tagForIndexPath(indexPath: NSIndexPath) -> Tag
    {
        let row = indexPath.row
        var rowIndex = -1
        var catIndex = -1
        
        for category in categories
        {
            var itemIndex = 0
            ++catIndex
            
            if category.displayHeader {
                ++rowIndex
                if rowIndex == row {
                    return Tag(catIdx: catIndex, itmIdx: itemIndex)     // categories are always itemIndex 0
                }
            }
            
            if category.expanded
            {
                for item in category.items
                {
                    if isDisplayedItem(item) {
                        ++itemIndex
                        ++rowIndex
                        if rowIndex == row {
                            return Tag(catIdx: catIndex, itmIdx: itemIndex)
                        }
                    }
                }
                // AddItem row
                ++itemIndex
                ++rowIndex
                if rowIndex == row {
                    return Tag(catIdx: catIndex, itmIdx: itemIndex)
                }
            }
        }
        
        return Tag()
    }
    
    /// Return the int tag for the object at the given index path.
    func tagValueForIndexPath(indexPath: NSIndexPath) -> Int
    {
        let obj = objectForIndexPath(indexPath)
        
        if obj != nil {
            return obj!.tag()
        }
        
        return -1
    }
}

////////////////////////////////////////////////////////////////
//
//  MARK: - Category class
//
////////////////////////////////////////////////////////////////

class ListObj
{
    var name: String
    var categoryIndex: Int
    var itemIndex: Int
    
    init(name: String)
    {
        self.name = name
        self.categoryIndex = 0
        self.itemIndex = 0
    }
    
    func updateIndicesFromTag(tag: Int) {
        let tag = Tag.indicesFromTag(tag)
        categoryIndex = tag.catIdx
        itemIndex = tag.itmIdx
    }
    
    func tag() -> Int {
        return Tag.tagFromIndices(categoryIndex, itmIdx: itemIndex)
    }
}

class Category: ListObj
{
    var items = [Item]()
    var addItem = AddItem()
    var displayHeader: Bool
    var expanded: Bool = true {
        didSet {
            
        }
    }
    
    // designated initializer for a Category
    init(name: String, displayHeader: Bool) {
        self.displayHeader = displayHeader
        super.init(name: name)
    }
    
    // updates the indices for all items in this category
    func updateIndices(catIndex: Int)
    {
        self.categoryIndex = catIndex
        
        var i = 0
        for item in items {
            item.itemIndex = ++i
            item.categoryIndex = catIndex
        }
        
        addItem.categoryIndex = catIndex
        addItem.itemIndex = ++i
    }
    
    // returns the number of completed items in a category
    func itemsComplete() -> Int   {var i=0; for item in items {if item.state == ItemState.Complete   {++i}}; return i}
    func itemsActive() -> Int     {var i=0; for item in items {if item.state != ItemState.Inactive   {++i}}; return i}
    func itemsInactive() -> Int   {var i=0; for item in items {if item.state == ItemState.Inactive   {++i}}; return i}
    func itemsIncomplete() -> Int {var i=0; for item in items {if item.state == ItemState.Incomplete {++i}}; return i}
}

////////////////////////////////////////////////////////////////
//
//  MARK: - Item class
//
////////////////////////////////////////////////////////////////

class Item: ListObj
{
    var state: ItemState
    
    // designated initializer for an Item
    init(name: String, state: ItemState)
    {
        self.state = state
        super.init(name: name)
    }
}

////////////////////////////////////////////////////////////////
//
//  MARK: - AddItem class
//
////////////////////////////////////////////////////////////////

class AddItem: ListObj
{
    // designated initializer for an AddItem
    init()
    {
        super.init(name: "add item")
    }
}

////////////////////////////////////////////////////////////////
//
//  MARK: - Tag struct
//
////////////////////////////////////////////////////////////////

struct Tag
{
    var catIdx: Int
    var itmIdx: Int
    
    init() {
        self.catIdx = -1
        self.itmIdx = -1
    }
    
    init(catIdx: Int, itmIdx: Int) {
        self.catIdx = catIdx
        self.itmIdx = itmIdx
    }
    
    func value() -> Int {
        return Tag.tagFromIndices(self.catIdx, itmIdx: self.itmIdx)
    }
    
    static func tagFromIndices(catIdx: Int, itmIdx: Int) -> Int
    {
        return catIdx * kItemIndexMax + itmIdx
    }
    
    static func indicesFromTag(tag: Int) -> (catIdx: Int, itmIdx: Int)
    {
        let cIdx = tag / kItemIndexMax
        return (cIdx, tag - (cIdx * kItemIndexMax))
    }
}


