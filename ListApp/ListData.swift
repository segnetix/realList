//
//  ListData.swift
//  ListApp
//
//  Created by Steven Gentry on 12/31/15.
//  Copyright © 2015 Steven Gentry. All rights reserved.
//

import UIKit
import CloudKit

let kItemIndexMax = 100000
let ListsRecordType = "Lists"
let CategoriesRecordType = "Categories"
let ItemsRecordType = "Items"

enum ItemState: Int {
    case Inactive = 0
    case Incomplete = 1
    case Complete = 2
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

class List: NSObject, NSCoding
{
    var name: String { didSet { needToSave = true } }
    var categories = [Category]()
    var listColor: UIColor? { didSet { needToSave = true } }
    var needToSave: Bool = false
    var needToDelete: Bool = false
    var modificationDate: NSDate?
    var listRecord: CKRecord?
    var listReference: CKReference?
    var order: Int = 0 { didSet { needToSave = true } }
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var showCompletedItems: Bool = true { didSet { self.updateIndices(); needToSave = true } }
    var showInactiveItems:  Bool = true { didSet { self.updateIndices(); needToSave = true } }
    
    // new list initializer
    init(name: String)
    {
        self.name = name
        
        // new list needs a new record and reference
        listRecord = CKRecord.init(recordType: ListsRecordType)
        listReference = CKReference.init(record: listRecord!, action: CKReferenceAction.DeleteSelf)
        modificationDate = NSDate.init()
    }
    
///////////////////////////////////////////////////////
//
//  MARK: List data I/O methods
//
///////////////////////////////////////////////////////
    
    // Memberwise initializer - called when restoring from local storage on launch
    init(name: String?, showCompletedItems: Bool?, showInactiveItems: Bool?, listColor: UIColor?, modificationDate: NSDate?, listReference: CKReference?, listRecord: CKRecord?, categories: [Category]?)
    {
        if let name               = name                 { self.name                = name               } else { self.name = "" }
        if let showCompletedItems = showCompletedItems   { self.showCompletedItems  = showCompletedItems } else { self.showCompletedItems = true }
        if let showInactiveItems  = showInactiveItems    { self.showInactiveItems   = showInactiveItems  } else { self.showInactiveItems  = true }
        if let modificationDate   = modificationDate     { self.modificationDate    = modificationDate   } else { self.modificationDate = NSDate.init() }
        if let listColor          = listColor            { self.listColor           = listColor          }
        if let listReference      = listReference        { self.listReference       = listReference      }
        if let listRecord         = listRecord           { self.listRecord          = listRecord         }
        if let categories         = categories           { self.categories          = categories         }
        
        super.init()
        
        self.updateIndices()
    }
    
    required convenience init?(coder decoder: NSCoder)
    {
        let name               = decoder.decodeObjectForKey("name")               as? String
        let showCompletedItems = decoder.decodeObjectForKey("showCompletedItems") as? Bool
        let showInactiveItems  = decoder.decodeObjectForKey("showInactiveItems")  as? Bool
        let listColor          = decoder.decodeObjectForKey("listColor")          as? UIColor
        let categories         = decoder.decodeObjectForKey("categories")         as? [Category]
        let listReference      = decoder.decodeObjectForKey("listReference")      as? CKReference
        let listRecord         = decoder.decodeObjectForKey("listRecord")         as? CKRecord
        let modificationDate   = decoder.decodeObjectForKey("modificationDate")   as? NSDate
        
        self.init(name: name, showCompletedItems: showCompletedItems, showInactiveItems: showInactiveItems, listColor: listColor, modificationDate: modificationDate, listReference: listReference, listRecord: listRecord, categories: categories)
    }
    
    // local storage
    func encodeWithCoder(coder: NSCoder)
    {
        coder.encodeObject(self.name, forKey: "name")
        coder.encodeObject(self.showCompletedItems, forKey: "showCompletedItems")
        coder.encodeObject(self.showInactiveItems, forKey: "showInactiveItems")
        coder.encodeObject(self.listColor, forKey: "listColor")
        coder.encodeObject(self.categories, forKey: "categories")
        coder.encodeObject(self.listReference, forKey: "listReference")
        coder.encodeObject(self.listRecord, forKey: "listRecord")
        coder.encodeObject(self.modificationDate, forKey: "modificationDate")
    }
    
    // commits this list and its categories to cloud storage
    func saveToCloud()
    {
        if let database = appDelegate.privateDatabase
        {
            if listRecord != nil
            {
                // commit change to cloud
                if needToDelete {
                    deleteRecord(listRecord!, database: database)
                } else if needToSave {
                    saveRecord(listRecord!, database: database)
                }
            } else {
                print("Can't save list '\(name)' - listRecord is nil...")
            }
        }
        
        // pass on to the categories
        if listReference != nil {
            for category in categories {
                category.saveToCloud(listReference!)
            }
        }
    }
    
    // saves this list record to the cloud
    func saveRecord(listRecord: CKRecord, database: CKDatabase)
    {
        print("saveRecord for Lists called... \(name)")
        var rgbColor = NSNumber(integer: 0)
        
        if listColor != nil {
            let rgb = listColor!.rgb()
            if rgb != nil {
                rgbColor = rgb!
            }
        }
        
        listRecord.setObject(self.name, forKey: "name")
        listRecord.setObject(rgbColor, forKey: "listColor")
        listRecord.setObject(self.showCompletedItems, forKey: "showCompletedItems")
        listRecord.setObject(self.showInactiveItems, forKey: "showInactiveItems")
        listRecord.setObject(self.order, forKey: "order")
        
        // add this record to the batch record array for updating
        appDelegate.addToUpdateRecords(listRecord, obj: self)
    }
    
    func deleteFromCloud() {
        self.needToDelete = true
        appDelegate.saveListData(true)
    }
    
    // deletes this list from the cloud
    func deleteRecord(listRecord: CKRecord, database: CKDatabase)
    {
        database.deleteRecordWithID(listRecord.recordID, completionHandler: { returnRecord, error in
            if let err = error {
                print("Delete List Error: \(err.localizedDescription)")
            } else {
                print("Success: List record deleted successfully")
            }
        })
    }
    
///////////////////////////////////////////////////////
//
//  MARK: Initializers for Category and Item objects
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
                // delete item from cloud storage
                let item = obj as! Item
                item.deleteFromCloud()
                
                // remove the item from the category
                self.categories[catIndex].items.removeAtIndex(itemIndex)
                removedPaths.append(indexPath)
            } else {
                if preserveCategories {
                    // remove the first item in this category
                    self.categories[catIndex].items.removeAtIndex(0)
                    removedPaths.append(indexPath)
                } else {
                    let category = obj as! Category
                    
                    if categories.count > 1 {
                        // delete the category and its items from cloud storage
                        category.deleteFromCloud()
                        
                        // remove the category and its items from the list
                        removedPaths = displayIndexPathsForCategoryFromIndexPath(indexPath, includeCategoryAndAddItemIndexPaths: true)
                        self.categories.removeAtIndex(catIndex)
                    } else {
                        // we are deleting the only category which has become visible
                        // so instead delete just the items and set the category.displayHeader to false
                        category.displayHeader = false
                        category.deleteCategoryItems()
                        
                        removedPaths = displayIndexPathsForCategoryFromIndexPath(indexPath, includeCategoryAndAddItemIndexPaths: false)
                        self.categories.removeAtIndex(catIndex)
                    }
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
            cat.order = i
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
    /// If includeCategoryIndexPath is true, then the returned paths will also include the index path to category itself.
    /// Otherwise, the returned paths will consist of only the items and the AddItem row.
    func displayIndexPathsForCategoryFromIndexPath(indexPath: NSIndexPath, includeCategoryAndAddItemIndexPaths: Bool) -> [NSIndexPath]
    {
        let category = categoryForIndexPath(indexPath)
        
        if category != nil {
            var indexPaths = displayIndexPathsForCategory(category!, includeAddItemIndexPath: includeCategoryAndAddItemIndexPaths)
            
            if includeCategoryAndAddItemIndexPaths {
                indexPaths.append(indexPath)
            }
            return indexPaths
        }
        
        return [NSIndexPath]()
    }
    
    /// Returns an array of display index paths for a category that is being expanded or collapsed.
    func displayIndexPathsForCategory(category: Category, includeAddItemIndexPath: Bool) -> [NSIndexPath]
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
            
            if includeAddItemIndexPath {
                // one more for the addItem cell
                indexPaths.append(NSIndexPath(forRow: ++pos, inSection: 0))
            }
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
            obj!.needToSave = true
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
//  MARK: - ListObj class
//
////////////////////////////////////////////////////////////////

class ListObj: NSObject
{
    var name: String { didSet { needToSave = true } }
    var categoryIndex: Int
    var itemIndex: Int
    var needToSave: Bool = true
    var needToDelete: Bool = false
    var order: Int = 0 { didSet { needToSave = true } }
    
    init(name: String?)
    {
        if let name = name { self.name = name } else { self.name = "" }
        
        self.categoryIndex = 0
        self.itemIndex = 0
        self.needToSave = true
    }
    
    func updateIndicesFromTag(tag: Int)
    {
        let tag = Tag.indicesFromTag(tag)
        categoryIndex = tag.catIdx
        itemIndex = tag.itmIdx
    }
    
    func tag() -> Int
    {
        return Tag.tagFromIndices(categoryIndex, itmIdx: itemIndex)
    }
}

////////////////////////////////////////////////////////////////
//
//  MARK: - Category class
//
////////////////////////////////////////////////////////////////

class Category: ListObj, NSCoding
{
    var items = [Item]()
    var addItem = AddItem()
    var displayHeader: Bool = true { didSet { needToSave = true } }
    var expanded: Bool = true { didSet { needToSave = true } }
    var modificationDate: NSDate?
    var categoryReference: CKReference?
    var categoryRecord: CKRecord?
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    // new category initializer
    init(name: String, displayHeader: Bool)
    {
        self.displayHeader = displayHeader
        self.modificationDate = NSDate.init()
        
        // new category needs a new record and reference
        categoryRecord = CKRecord.init(recordType: CategoriesRecordType)
        categoryReference = CKReference.init(record: categoryRecord!, action: CKReferenceAction.DeleteSelf)
        modificationDate = NSDate.init()
        
        super.init(name: name)
    }
    
    // memberwise initializer
    init(name: String?, expanded: Bool?, displayHeader: Bool?, modificationDate: NSDate?, categoryReference: CKReference?, categoryRecord: CKRecord?, items: [Item]?)
    {
        if let expanded          = expanded          { self.expanded          = expanded          } else { self.expanded          = true }
        if let displayHeader     = displayHeader     { self.displayHeader     = displayHeader     } else { self.displayHeader     = true }
        if let modificationDate  = modificationDate  { self.modificationDate  = modificationDate  } else { self.modificationDate  = NSDate.init() }
        if let categoryReference = categoryReference { self.categoryReference = categoryReference }
        if let categoryRecord    = categoryRecord    { self.categoryRecord    = categoryRecord    }
        if let items             = items             { self.items             = items             }
        
        super.init(name: name)
    }
    
    required convenience init?(coder decoder: NSCoder)
    {
        let name = decoder.decodeObjectForKey("name")                           as? String
        let expanded          = decoder.decodeObjectForKey("expanded")          as? Bool
        let displayHeader     = decoder.decodeObjectForKey("displayHeader")     as? Bool
        let modificationDate  = decoder.decodeObjectForKey("modificationDate")  as? NSDate
        let categoryReference = decoder.decodeObjectForKey("categoryReference") as? CKReference
        let categoryRecord    = decoder.decodeObjectForKey("categoryRecord")    as? CKRecord
        let items             = decoder.decodeObjectForKey("items")             as? [Item]
        
        self.init(name: name, expanded: expanded, displayHeader: displayHeader, modificationDate: modificationDate, categoryReference: categoryReference, categoryRecord: categoryRecord, items: items)
    }
    
    func encodeWithCoder(coder: NSCoder)
    {
        coder.encodeObject(self.name, forKey: "name")
        coder.encodeObject(self.expanded, forKey: "expanded")
        coder.encodeObject(self.displayHeader, forKey: "displayHeader")
        coder.encodeObject(self.modificationDate, forKey: "modificationDate")
        coder.encodeObject(self.categoryReference, forKey: "categoryReference")
        coder.encodeObject(self.categoryRecord, forKey: "categoryRecord")
        coder.encodeObject(self.items, forKey: "items")
    }
    
    // commits this category and its items to cloud storage
    func saveToCloud(listReference: CKReference)
    {
        if let database = appDelegate.privateDatabase
        {
            if categoryRecord != nil
            {
                // commit change to cloud
                if needToDelete {
                    deleteRecord(categoryRecord!, database: database)
                } else if needToSave {
                    saveRecord(categoryRecord!, listReference: listReference, database: database)
                }

            } else {
                print("Can't save category '\(name)' - listRecord is nil...")
            }
        }
        
        // pass on to the items
        if categoryReference != nil {
            for item in items {
                item.saveToCloud(categoryReference!)
            }
        }
    }
    
    // commits just this category to cloud storage
    func saveRecord(categoryRecord: CKRecord, listReference: CKReference, database: CKDatabase)
    {
        categoryRecord.setObject(self.name, forKey: "name")
        categoryRecord.setObject(self.displayHeader, forKey: "displayHeader")
        categoryRecord.setObject(self.expanded, forKey: "expanded")
        categoryRecord.setObject(listReference, forKey: "owningList")
        categoryRecord.setObject(self.order, forKey: "order")
        
        // add this record to the batch record array for updating
        appDelegate.addToUpdateRecords(categoryRecord, obj: self)
    }
    
    func deleteFromCloud() {
        self.needToDelete = true
        appDelegate.saveListData(true)
    }
    
    // deletes this category from the cloud
    func deleteRecord(categoryRecord: CKRecord, database: CKDatabase)
    {
        database.deleteRecordWithID(categoryRecord.recordID, completionHandler: { returnRecord, error in
            if let err = error {
                print("Delete Category Error: \(err.localizedDescription)")
            } else {
                print("Success: Category record deleted from cloud \(self.name)")
            }
        })
    }

    func deleteCategoryItems() {
        for item in items {
            item.needToDelete = true
        }
        appDelegate.saveListData(true)
    }
    
    // updates the indices for all items in this category
    func updateIndices(catIndex: Int)
    {
        self.categoryIndex = catIndex
        
        var i = 0
        for item in items {
            item.order = i
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

class Item: ListObj, NSCoding
{
    var state: ItemState { didSet { needToSave = true } }
    var note: String { didSet { needToSave = true } }
    var modificationDate: NSDate?
    var itemRecord: CKRecord?
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    // new item initializer
    init(name: String, state: ItemState)
    {
        self.state = state
        self.note = ""
        self.modificationDate = NSDate.init()
        
        // new item needs a new record
        itemRecord = CKRecord.init(recordType: ItemsRecordType)
        modificationDate = NSDate.init()
        
        super.init(name: name)
    }

    // memberwise initializer
    init(name: String?, note: String?, state: ItemState, itemRecord: CKRecord?, modificationDate: NSDate?)
    {
        if let note             = note             { self.note             = note             } else { self.note = "" }
        if let itemRecord       = itemRecord       { self.itemRecord       = itemRecord       } else { self.itemRecord  = nil }
        if let modificationDate = modificationDate { self.modificationDate = modificationDate } else { self.modificationDate = NSDate.init() }
        
        self.state = state
        
        super.init(name: name)
    }
    
    required convenience init?(coder decoder: NSCoder)
    {
        let name           = decoder.decodeObjectForKey("name")           as? String
        let note           = decoder.decodeObjectForKey("note")           as? String
        let state          = decoder.decodeIntForKey("state")
        let modificationDate = decoder.decodeObjectForKey("modificationDate") as? NSDate
        let itemRecord     = decoder.decodeObjectForKey("itemRecord")     as? CKRecord
        let itemState      = state == 0 ? ItemState.Inactive : state == 1 ? ItemState.Incomplete : ItemState.Complete
        
        self.init(name: name, note: note, state: itemState, /*itemRecordID: itemRecordID,*/ itemRecord: itemRecord, modificationDate: modificationDate)
    }
    
    func encodeWithCoder(coder: NSCoder)
    {
        coder.encodeObject(self.name, forKey: "name")
        coder.encodeObject(self.note, forKey: "note")
        coder.encodeInteger(state.rawValue, forKey: "state")
        coder.encodeObject(self.modificationDate, forKey: "modificationDate")
        coder.encodeObject(self.itemRecord, forKey: "itemRecord")
    }
    
    // commits this item change to cloud storage
    func saveToCloud(categoryReference: CKReference)
    {
        if let database = appDelegate.privateDatabase {
            if needToDelete {
                deleteRecord(itemRecord!, database: database)
            } else if needToSave {
                saveRecord(itemRecord!, categoryReference: categoryReference, database: database)
            }
        }
    }
    
    // cloud storage method for this item
    func saveRecord(itemRecord: CKRecord, categoryReference: CKReference, database: CKDatabase)
    {
        itemRecord.setObject(self.name, forKey: "name")
        itemRecord.setObject(self.note, forKey: "note")
        itemRecord.setObject(self.state.rawValue, forKey: "state")
        itemRecord.setObject(categoryReference, forKey: "owningCategory")
        itemRecord.setObject(self.order, forKey: "order")
        
        // add this record to the batch record array for updating
        appDelegate.addToUpdateRecords(itemRecord, obj: self)
    }
    
    // deletes this item from the cloud
    func deleteRecord(itemRecord: CKRecord, database: CKDatabase)
    {
        database.deleteRecordWithID(itemRecord.recordID, completionHandler: { returnRecord, error in
            if let err = error {
                print("Delete Item Error for '\(self.name)': \(err.localizedDescription)")
            } else {
                print("Success: Item record deleted successfully '\(self.name)'")
                //self.appDelegate.updateTimestamps(true)
            }
        })
    }

    func deleteFromCloud() {
        self.needToDelete = true
        appDelegate.saveListData(true)
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

////////////////////////////////////////////////////////////////
//
//  MARK: - UIColor extension
//
////////////////////////////////////////////////////////////////

extension UIColor
{
    func rgb() -> Int? {
        var fRed : CGFloat = 0
        var fGreen : CGFloat = 0
        var fBlue : CGFloat = 0
        var fAlpha: CGFloat = 0
        if self.getRed(&fRed, green: &fGreen, blue: &fBlue, alpha: &fAlpha) {
            let iRed = Int(fRed * 255.0)
            let iGreen = Int(fGreen * 255.0)
            let iBlue = Int(fBlue * 255.0)
            let iAlpha = Int(fAlpha * 255.0)
            
            //  (Bits 24-31 are alpha, 16-23 are red, 8-15 are green, 0-7 are blue).
            let rgb = (iAlpha << 24) + (iRed << 16) + (iGreen << 8) + iBlue
            return rgb
        } else {
            // Could not extract RGBA components:
            return nil
        }
    }
}
