//
//  ListData.swift
//  EnList
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

// key strings for record access
let key_name                = "name"
let key_showCompletedItems  = "showCompletedItems"
let key_showInactiveItems   = "showInactiveItems"
let key_listColorName       = "listColorName"
let key_categories          = "categories"
let key_modificationDate    = "modificationDate"
let key_listReference       = "listReference"
let key_listRecord          = "listRecord"
let key_order               = "order"
let key_expanded            = "expanded"
let key_displayHeader       = "displayHeader"
let key_owningList          = "owningList"
let key_categoryReference   = "categoryReference"
let key_categoryRecord      = "categoryRecord"
let key_items               = "items"
let key_note                = "note"
let key_createdBy           = "createdBy"
let key_createdDate         = "createdDate"
let key_modifiedBy          = "modifiedBy"
let key_modifiedDate        = "modifiedDate"
let key_owningCategory      = "owningCategory"
let key_itemRecord          = "itemRecord"
let key_state               = "state"
let key_tutorial            = "tutorial"
let key_image               = "image"

let alpha: Float = 1.0

// blue
var color1_1 = UIColor(colorLiteralRed: 0.00, green: 0.478, blue: 1.00, alpha: 0.85 )         // system blue (default)
let color1_2 = UIColor(colorLiteralRed: 0.47, green: 0.62,  blue: 0.75, alpha: alpha)         // icon blue
let color1_3 = UIColor(colorLiteralRed: 0.50, green: 0.75,  blue: 1.00, alpha: alpha)         // lt blue

// green
let color2_1 = UIColor(colorLiteralRed: 0.25, green: 0.95,  blue: 0.25, alpha: alpha)         // green
let color2_2 = UIColor(colorLiteralRed: 0.50, green: 0.80,  blue: 0.50, alpha: alpha)         // dusty green
let color2_3 = UIColor(colorLiteralRed: 0.70, green: 0.55,  blue: 0.40, alpha: alpha)         // brown

// red
let color3_1 = UIColor(colorLiteralRed: 1.00, green: 0.30,  blue: 0.30, alpha: alpha)         // red
let color3_2 = UIColor(colorLiteralRed: 0.60, green: 0.40,  blue: 1.00, alpha: alpha)         // purple
let color3_3 = UIColor(colorLiteralRed: 1.00, green: 0.50,  blue: 0.25, alpha: alpha)         // orange

// other
let color4_1 = UIColor(colorLiteralRed: 0.90, green: 0.90,  blue: 0.10, alpha: alpha)         // yellow
let color4_2 = UIColor(colorLiteralRed: 0.75, green: 0.75,  blue: 0.50, alpha: alpha)         // tan
let color4_3 = UIColor(colorLiteralRed: 0.70, green: 0.70,  blue: 0.70, alpha: alpha)         // lt gray

let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate

enum ItemState: Int {
    case Inactive = 0
    case Incomplete = 1
    case Complete = 2
    
    // this function will bump the button to the next state
    mutating func next() {
        switch self {
        case Inactive:      self = Incomplete
        case Incomplete:    self = Complete
        case Complete:      self = Inactive
        }
    }
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
    var listColor: UIColor?
    var listColorName: String = "r1_1" {
        didSet {
            needToSave = true
            setListColor()
        }
    }
    var needToSave: Bool = false
    var needToDelete: Bool = false
    var modificationDate: NSDate?
    var listRecord: CKRecord?
    var listReference: CKReference?
    var order: Int = 0 { didSet { if order != oldValue { needToSave = true } } }
    var showCompletedItems:  Bool = true { didSet { self.updateIndices(); needToSave = true } }
    var showInactiveItems:   Bool = true { didSet { self.updateIndices(); needToSave = true } }
    var isTutorialList = false
    
    var expandAllCategories: Bool = true {
        didSet {
            for category in categories {
                category.expanded = expandAllCategories
            }
            self.updateIndices()
            needToSave = true
        }
    }
    
    // new list initializer
    init(name: String, createRecord: Bool, tutorial: Bool = false)
    {
        self.name = name
        self.isTutorialList = tutorial
        
        if createRecord {
            // new list needs a new record and reference
            self.listRecord = CKRecord.init(recordType: ListsRecordType)
            self.listReference = CKReference.init(record: listRecord!, action: CKReferenceAction.DeleteSelf)
        }
        
        self.modificationDate = NSDate.init()
    }
    
///////////////////////////////////////////////////////
//
//  MARK: List data I/O methods
//
///////////////////////////////////////////////////////
    
    // Memberwise initializer - called when restoring from local storage on launch
    init(name: String?, showCompletedItems: Bool?, showInactiveItems: Bool?, listColorName: String?, modificationDate: NSDate?, listReference: CKReference?, listRecord: CKRecord?, categories: [Category]?)
    {
        if let name               = name                 { self.name                = name               } else { self.name = "" }
        if let showCompletedItems = showCompletedItems   { self.showCompletedItems  = showCompletedItems } else { self.showCompletedItems = true }
        if let showInactiveItems  = showInactiveItems    { self.showInactiveItems   = showInactiveItems  } else { self.showInactiveItems  = true }
        if let modificationDate   = modificationDate     { self.modificationDate    = modificationDate   } else { self.modificationDate = NSDate.init() }
        if let listColorName      = listColorName        { self.listColorName       = listColorName      }
        if let listReference      = listReference        { self.listReference       = listReference      }
        if let listRecord         = listRecord           { self.listRecord          = listRecord         }
        if let categories         = categories           { self.categories          = categories         }
        
        super.init()
        
        self.updateIndices()
        self.setListColor()
    }
    
    required convenience init?(coder decoder: NSCoder)
    {
        let name               = decoder.decodeObjectForKey(key_name)               as? String
        let showCompletedItems = decoder.decodeObjectForKey(key_showCompletedItems) as? Bool
        let showInactiveItems  = decoder.decodeObjectForKey(key_showInactiveItems)  as? Bool
        let listColorName      = decoder.decodeObjectForKey(key_listColorName)      as? String
        let categories         = decoder.decodeObjectForKey(key_categories)         as? [Category]
        let listReference      = decoder.decodeObjectForKey(key_listReference)      as? CKReference
        let listRecord         = decoder.decodeObjectForKey(key_listRecord)         as? CKRecord
        let modificationDate   = decoder.decodeObjectForKey(key_modificationDate)   as? NSDate
        
        self.init(name: name, showCompletedItems: showCompletedItems, showInactiveItems: showInactiveItems, listColorName: listColorName, modificationDate: modificationDate, listReference: listReference, listRecord: listRecord, categories: categories)
    }
    
    // local storage
    func encodeWithCoder(coder: NSCoder)
    {
        self.modificationDate = NSDate.init()
        
        coder.encodeObject(self.name,               forKey: key_name)
        coder.encodeObject(self.showCompletedItems, forKey: key_showCompletedItems)
        coder.encodeObject(self.showInactiveItems,  forKey: key_showInactiveItems)
        coder.encodeObject(self.listColorName,      forKey: key_listColorName)
        coder.encodeObject(self.categories,         forKey: key_categories)
        coder.encodeObject(self.listReference,      forKey: key_listReference)
        coder.encodeObject(self.listRecord,         forKey: key_listRecord)
        coder.encodeObject(self.modificationDate,   forKey: key_modificationDate)
    }
    
    // commits this list and its categories to cloud storage
    func saveToCloud()
    {
        // don't save tutorial records to the cloud
        if self.isTutorialList {
            return
        }
        
        if let database = appDelegate.privateDatabase
        {
            if listRecord != nil
            {
                // commit change to cloud
                if needToDelete {
                    deleteRecord(listRecord!, database: database)
                } else if needToSave {
                    saveRecord(listRecord!)
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
    func saveRecord(listRecord: CKRecord)
    {
        print("saveRecord for List \(name)")
        
        // don't save tutorial records to the cloud
        if self.isTutorialList {
            return
        }
        
        listRecord.setObject(self.name,               forKey: key_name)
        listRecord.setObject(self.listColorName,      forKey: key_listColorName)
        listRecord.setObject(self.showCompletedItems, forKey: key_showCompletedItems)
        listRecord.setObject(self.showInactiveItems,  forKey: key_showInactiveItems)
        listRecord.setObject(self.order,              forKey: key_order)
        
        // add this record to the batch record array for updating
        appDelegate.addToUpdateRecords(listRecord, obj: self)
    }
    
    // update this list from cloud storage
    func updateFromRecord(record: CKRecord)
    {
        if let name               = record[key_name]               { self.name               = name as! String             }
        if let showCompletedItems = record[key_showCompletedItems] { self.showCompletedItems = showCompletedItems as! Bool }
        if let showInactiveItems  = record[key_showInactiveItems]  { self.showInactiveItems  = showInactiveItems as! Bool  }
        if let listColorName      = record[key_listColorName]      { self.listColorName      = listColorName as! String    }
        if let order              = record[key_order]              { self.order              = order  as! Int              }
        
        self.listRecord = record
        self.listReference = CKReference.init(record: record, action: CKReferenceAction.DeleteSelf)
        //print("updated list: \(list!.name)")
    }
    
    func deleteFromCloud() {
        self.needToDelete = true
        appDelegate.saveListData(true)
    }
    
    // deletes this list from the cloud
    func deleteRecord(listRecord: CKRecord, database: CKDatabase)
    {
        // don't save tutorial records to the cloud
        if self.isTutorialList {
            return
        }
        
        database.deleteRecordWithID(listRecord.recordID, completionHandler: { returnRecord, error in
            if let err = error {
                print("Delete List Error: \(err.localizedDescription)")
            } else {
                print("Success: List record deleted successfully")
            }
        })
    }
    
    func setListColor()
    {
        switch listColorName {
        case "r1_1": listColor = color1_1
        case "r1_2": listColor = color1_2
        case "r1_3": listColor = color1_3
        case "r2_1": listColor = color2_1
        case "r2_2": listColor = color2_2
        case "r2_3": listColor = color2_3
        case "r3_1": listColor = color3_1
        case "r3_2": listColor = color3_2
        case "r3_3": listColor = color3_3
        case "r4_1": listColor = color4_1
        case "r4_2": listColor = color4_2
        case "r4_3": listColor = color4_3
        default: listColor = color1_1
        }
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
                index += 1
                return index
            }
        }
        
        return -1
    }
    
    func addCategory(name: String, displayHeader: Bool, updateIndices: Bool, createRecord: Bool, tutorial: Bool = false) -> Category
    {
        let category = Category(name: name, displayHeader: displayHeader, createRecord: createRecord, tutorial: tutorial)
        categories.append(category)
        
        if updateIndices {
            self.updateIndices()
        }
        
        return category
    }
    
    func addItem(category: Category, name: String, state: ItemState, updateIndices: Bool, createRecord: Bool, tutorial: Bool = false) -> Item?
    {
        let indexForCat = indexForCategory(category)
        var item: Item? = nil
        
        if indexForCat > -1 {
            item = Item(name: name, state: state, createRecord: createRecord, tutorial: tutorial)
            category.items.append(item!)
        } else {
            print("ERROR: addItem given invalid category!")
        }
        
        if (updateIndices) {
            self.updateIndices()
        }
        
        return item
    }
    
    // sets all items to the active state
    func setAllItemsIncomplete() {
        for category in categories {
            for item in category.items {
                item.state = ItemState.Incomplete
            }
        }
    }
    
    // sets all items to the inactive state
    func setAllItemsInactive() {
        for category in categories {
            for item in category.items {
                item.state = ItemState.Inactive
            }
        }
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
            catIdx -= 1                                 // move to the previous category
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
                        
                        // add paths of category, add item row, and items
                        removedPaths = displayIndexPathsForCategoryFromIndexPath(indexPath, includeCategoryAndAddItemIndexPaths: true)
                        
                        // remove the category and its items from the list
                        self.categories.removeAtIndex(catIndex)
                    } else {
                        // we are deleting the only category which has become visible
                        // so instead only delete the items and set the category.displayHeader to false
                        // leaving the 'new item' row in place with a hidden category header
                        category.deleteCategoryItemsFromCloudStorage()
                        
                        // add paths of items
                        removedPaths = displayIndexPathsForCategoryFromIndexPath(indexPath, includeCategoryAndAddItemIndexPaths: false)
                        
                        // add path of category itself because we are going to hide it
                        removedPaths.append(indexPath)
                        category.displayHeader = false
                        
                        // remove the items from the category
                        category.deleteItems()
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
            i += 1
            cat.updateIndices(i)
            cat.order = i
        }
    }
    
    /// Returns the total number of rows to display in the ItemVC
    func totalDisplayCount() -> Int
    {
        var count = 0
        
        for category in categories {
            if category.displayHeader {
                count += 1
            }
            
            if category.expanded {
                for item in category.items {
                    if isDisplayedItem(item) {
                        count += 1
                    }
                }
                count += 1      // for AddItem cell
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
                index += 1
            }
            
            if index == row {
                return category
            }
            
            if category.expanded {
                for item in category.items {
                    if isDisplayedItem(item) {
                        index += 1
                        if index == row {
                            return item
                        }
                    }
                }
                index += 1
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
                index += 1
            }
            
            if category === obj {
                return (NSIndexPath(forRow: index, inSection: 0), false)
            }
            
            if category.expanded {
                for item in category.items {
                    if isDisplayedItem(item) {
                        index += 1
                        if item === obj {
                            return (NSIndexPath(forRow: index, inSection: 0), true)
                        }
                    }
                }
                // for AddItem cell
                index += 1
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
                    pos += 1
                    indexPaths.append(NSIndexPath(forRow: pos, inSection: 0))
                }
            }
            
            if includeAddItemIndexPath {
                // one more for the addItem cell
                pos += 1
                indexPaths.append(NSIndexPath(forRow: pos, inSection: 0))
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
                pos += 1
            }
            
            if category.expanded
            {
                for item in category.items
                {
                    if item.state == ItemState.Complete {
                        pos += 1
                        indexPaths.append(NSIndexPath(forRow: pos, inSection: 0))
                    } else if item.state != ItemState.Inactive || showInactiveItems {
                        pos += 1
                    }
                }
                pos += 1        // for the AddItem cell
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
                pos += 1
            }
            
            if category.expanded
            {
                for item in category.items
                {
                    if item.state == ItemState.Inactive {
                        pos += 1
                        indexPaths.append(NSIndexPath(forRow: pos, inSection: 0))
                    } else if item.state != ItemState.Complete || showCompletedItems {
                        pos += 1
                    }
                }
                pos += 1     // for the AddItem cell
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
            catIndex += 1
            
            if category.displayHeader {
                rowIndex += 1
                if rowIndex == row {
                    return Tag(catIdx: catIndex, itmIdx: itemIndex)     // categories are always itemIndex 0
                }
            }
            
            if category.expanded
            {
                for item in category.items
                {
                    if isDisplayedItem(item) {
                        itemIndex += 1
                        rowIndex += 1
                        if rowIndex == row {
                            return Tag(catIdx: catIndex, itmIdx: itemIndex)
                        }
                    }
                }
                // AddItem row
                itemIndex += 1
                rowIndex += 1
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
    
    // list
    func htmlForPrinting() -> String
    {
        //let listLabel = NSLocalizedString("List", comment: "label for 'List:'")
        
        // header
        var html: String = "<!DOCTYPE html>"
        html += "<html><head><style type='text/css'><!-- .tab { margin-left: 25px; } --> </style></head>"
        html += "<body><font face='arial'>"
        html += "<h1>\(self.name)</h1>"
        
        // categories
        for category in categories {
            html += "<p>"
            html += category.htmlForPrinting(self)
            html += "</p>"
        }
        
        html += "</font></body></html>"
        
        return html
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
    var needToSave: Bool
    var needToDelete: Bool
    var order: Int = 0 {
        didSet {
            if order != oldValue {
                needToSave = true
            }
        }
    }
    
    init(name: String?)
    {
        if let name = name { self.name = name } else { self.name = "" }
        
        self.categoryIndex = 0
        self.itemIndex = 0
        self.needToSave = true
        self.needToDelete = false
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
    var isTutorialCategory = false
    
    // new category initializer
    init(name: String, displayHeader: Bool, createRecord: Bool, tutorial: Bool = false)
    {
        self.displayHeader = displayHeader
        self.isTutorialCategory = tutorial
        self.modificationDate = NSDate.init()
        
        if createRecord {
            // new category needs a new record and reference
            categoryRecord = CKRecord.init(recordType: CategoriesRecordType)
            categoryReference = CKReference.init(record: categoryRecord!, action: CKReferenceAction.DeleteSelf)
        }
        
        modificationDate = NSDate.init()
        
        super.init(name: name)
    }
    
    // memberwise initializer
    init(name: String?, expanded: Bool?, displayHeader: Bool?, tutorial: Bool?, modificationDate: NSDate?, categoryReference: CKReference?, categoryRecord: CKRecord?, items: [Item]?)
    {
        if let expanded          = expanded          { self.expanded           = expanded          } else { self.expanded           = true }
        if let displayHeader     = displayHeader     { self.displayHeader      = displayHeader     } else { self.displayHeader      = true }
        if let modificationDate  = modificationDate  { self.modificationDate   = modificationDate  } else { self.modificationDate   = NSDate.init() }
        if let tutorial          = tutorial          { self.isTutorialCategory = tutorial          } else { self.isTutorialCategory = false }
        if let categoryReference = categoryReference { self.categoryReference  = categoryReference }
        if let categoryRecord    = categoryRecord    { self.categoryRecord     = categoryRecord    }
        if let items             = items             { self.items              = items             }
        
        super.init(name: name)
    }
    
    required convenience init?(coder decoder: NSCoder)
    {
        let name = decoder.decodeObjectForKey(key_name)                           as? String
        let expanded          = decoder.decodeObjectForKey(key_expanded)          as? Bool
        let displayHeader     = decoder.decodeObjectForKey(key_displayHeader)     as? Bool
        let tutorial          = decoder.decodeObjectForKey(key_tutorial)          as? Bool
        let modificationDate  = decoder.decodeObjectForKey(key_modificationDate)  as? NSDate
        let categoryReference = decoder.decodeObjectForKey(key_categoryReference) as? CKReference
        let categoryRecord    = decoder.decodeObjectForKey(key_categoryRecord)    as? CKRecord
        let items             = decoder.decodeObjectForKey(key_items)             as? [Item]
        
        self.init(name: name, expanded: expanded, displayHeader: displayHeader, tutorial: tutorial, modificationDate: modificationDate, categoryReference: categoryReference, categoryRecord: categoryRecord, items: items)
    }
    
    func encodeWithCoder(coder: NSCoder)
    {
        self.modificationDate = NSDate.init()
        
        coder.encodeObject(self.name,               forKey: key_name)
        coder.encodeObject(self.expanded,           forKey: key_expanded)
        coder.encodeObject(self.displayHeader,      forKey: key_displayHeader)
        coder.encodeObject(self.isTutorialCategory, forKey: key_tutorial)
        coder.encodeObject(self.modificationDate,   forKey: key_modificationDate)
        coder.encodeObject(self.categoryReference,  forKey: key_categoryReference)
        coder.encodeObject(self.categoryRecord,     forKey: key_categoryRecord)
        coder.encodeObject(self.items,              forKey: key_items)
    }
    
    // commits this category and its items to cloud storage
    func saveToCloud(listReference: CKReference)
    {
        // don't save the tutorial to the cloud
        if self.isTutorialCategory {
            return
        }
        
        if let database = appDelegate.privateDatabase
        {
            if categoryRecord != nil
            {
                // commit change to cloud
                if needToDelete {
                    deleteRecord(categoryRecord!, database: database)
                } else if needToSave {
                    saveRecord(categoryRecord!, listReference: listReference)
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
    func saveRecord(categoryRecord: CKRecord, listReference: CKReference)
    {
        // don't save the tutorial to the cloud
        if self.isTutorialCategory {
            return
        }
        
        categoryRecord.setObject(self.name,          forKey: key_name)
        categoryRecord.setObject(self.displayHeader, forKey: key_displayHeader)
        categoryRecord.setObject(self.expanded,      forKey: key_expanded)
        categoryRecord.setObject(listReference,      forKey: key_owningList)
        categoryRecord.setObject(self.order,         forKey: key_order)
        
        // add this record to the batch record array for updating
        appDelegate.addToUpdateRecords(categoryRecord, obj: self)
    }
    
    // update this category from cloud storage
    func updateFromRecord(record: CKRecord)
    {
        if let name          = record[key_name]          { self.name          = name as! String }
        if let expanded      = record[key_expanded]      { self.expanded      = expanded as! Bool }
        if let displayHeader = record[key_displayHeader] { self.displayHeader = displayHeader as! Bool }
        if let order         = record[key_order]         { self.order         = order as! Int }
        
        self.categoryRecord = record
        self.categoryReference = CKReference.init(record: record, action: CKReferenceAction.DeleteSelf)
        //print("updated category: \(category!.name)")
    }
    
    func deleteFromCloud()
    {
        self.needToDelete = true
        appDelegate.saveListData(true)
    }
    
    // deletes this category from the cloud
    func deleteRecord(categoryRecord: CKRecord, database: CKDatabase)
    {
        // don't save the tutorial to the cloud
        if self.isTutorialCategory {
            return
        }
        
        database.deleteRecordWithID(categoryRecord.recordID, completionHandler: { returnRecord, error in
            if let err = error {
                print("Delete Category Error: \(err.localizedDescription)")
            } else {
                print("Success: Category record deleted from cloud \(self.name)")
            }
        })
    }

    func deleteCategoryItemsFromCloudStorage()
    {
        for item in items {
            item.needToDelete = true
        }
        appDelegate.saveListData(true)
    }
    
    func deleteItems()
    {
        items.removeAll(keepCapacity: true)
    }
    
    // updates the indices for all items in this category
    func updateIndices(catIndex: Int)
    {
        self.categoryIndex = catIndex
        
        var i = 0
        for item in items {
            item.order = i
            i += 1
            item.itemIndex = i
            item.categoryIndex = catIndex
        }
        
        addItem.categoryIndex = catIndex
        i += 1
        addItem.itemIndex = i
    }
    
    // category
    func htmlForPrinting(list: List) -> String
    {
        // header
        var html: String = ""
        
        // category name
        if self.displayHeader {
            html += "<strong><span style='background-color: #F0F0F0'>&nbsp;&nbsp;\(self.name)&nbsp;&nbsp;</span></strong>"
        }
        
        // items
        html += "<table id='itemData' cellpadding='3'>"
        
        if self.expanded {
            for item in items {
                if list.isDisplayedItem(item) {
                    html += item.htmlForPrinting()
                }
            }
        }
        
        html += "</table>"
        
        return html
    }
    
    // returns the number of completed items in a category
    func itemsComplete() -> Int   { var i=0; for item in items { if item.state == ItemState.Complete   { i += 1 } }; return i }
    func itemsActive() -> Int     { var i=0; for item in items { if item.state != ItemState.Inactive   { i += 1 } }; return i }
    func itemsInactive() -> Int   { var i=0; for item in items { if item.state == ItemState.Inactive   { i += 1 } }; return i }
    func itemsIncomplete() -> Int { var i=0; for item in items { if item.state == ItemState.Incomplete { i += 1 } }; return i }
    
}

////////////////////////////////////////////////////////////////
//
//  MARK: - Item class
//
////////////////////////////////////////////////////////////////

class Item: ListObj, NSCoding
{
    override var name: String { didSet { if name  != oldValue { needToSave = true; modifiedBy = UIDevice.currentDevice().name; modifiedDate = NSDate.init() } } }
    var state: ItemState      { didSet { if state != oldValue { needToSave = true; modifiedBy = UIDevice.currentDevice().name; modifiedDate = NSDate.init() } } }
    var note: String          { didSet { if note  != oldValue { needToSave = true; modifiedBy = UIDevice.currentDevice().name; modifiedDate = NSDate.init() } } }
    var image: UIImage?       { didSet { needToSave = true; modifiedBy = UIDevice.currentDevice().name; modifiedDate = NSDate.init() } }
    var createdBy: String           // established locally - saved to cloud
    var createdDate: NSDate         // established locally - saved to cloud
    var modifiedBy: String          // established locally - saved to cloud
    var modifiedDate: NSDate  {     // established locally - saved to cloud
        didSet {
            // only update if new date is newer than the current date
            if oldValue.compare(modifiedDate) == NSComparisonResult.OrderedDescending {
                modifiedDate = oldValue
            }
        }
    }
    var itemRecord: CKRecord?
    var isTutorialItem = false
    
    // new item initializer
    init(name: String, state: ItemState, createRecord: Bool, tutorial: Bool = false)
    {
        self.state = state
        self.note = ""
        self.image = nil
        self.isTutorialItem = tutorial
        self.createdBy = UIDevice.currentDevice().name
        self.modifiedBy = UIDevice.currentDevice().name
        self.createdDate = NSDate.init()
        self.modifiedDate = NSDate.init()
        
        if createRecord {
            // a new item needs a new cloud record
            itemRecord = CKRecord.init(recordType: ItemsRecordType)
            createdBy = UIDevice.currentDevice().name
        }
        
        modifiedDate = NSDate.init()
        
        super.init(name: name)
    }

    // memberwise initializer
    init(name: String?, note: String?, image: UIImage?, state: ItemState, tutorial: Bool?, itemRecord: CKRecord?, createdBy: String?, createdDate: NSDate?, modifiedBy: String?, modifiedDate: NSDate?)
    {
        if let note         = note         { self.note           = note         } else { self.note           = ""                                                        }
        if let image        = image        { self.image          = image        } else { self.image          = nil                                                       }
        if let tutorial     = tutorial     { self.isTutorialItem = tutorial     } else { self.isTutorialItem = false                                                     }
        if let itemRecord   = itemRecord   { self.itemRecord     = itemRecord   } else { self.itemRecord     = nil                                                       }
        if let createdBy    = createdBy    { self.createdBy      = createdBy    } else { self.createdBy      = UIDevice.currentDevice().name                             }
        if let createdDate  = createdDate  { self.createdDate    = createdDate  } else { self.createdDate    = NSDate.init(timeIntervalSince1970: NSTimeInterval.init()) }
        if let modifiedBy   = modifiedBy   { self.modifiedBy     = modifiedBy   } else { self.modifiedBy     = UIDevice.currentDevice().name                             }
        if let modifiedDate = modifiedDate { self.modifiedDate   = modifiedDate } else { self.modifiedDate   = NSDate.init(timeIntervalSince1970: NSTimeInterval.init()) }
        
        self.state = state
        
        super.init(name: name)
    }
    
    required convenience init?(coder decoder: NSCoder)
    {
        let name         = decoder.decodeObjectForKey(key_name)         as? String
        let note         = decoder.decodeObjectForKey(key_note)         as? String
        let image        = decoder.decodeObjectForKey(key_image)        as? UIImage
        let tutorial     = decoder.decodeObjectForKey(key_tutorial)     as? Bool
        let createdBy    = decoder.decodeObjectForKey(key_createdBy)    as? String
        let createdDate  = decoder.decodeObjectForKey(key_createdDate)  as? NSDate
        let modifiedBy   = decoder.decodeObjectForKey(key_modifiedBy)   as? String
        let modifiedDate = decoder.decodeObjectForKey(key_modifiedDate) as? NSDate
        let itemRecord   = decoder.decodeObjectForKey(key_itemRecord)   as? CKRecord
        let state        = decoder.decodeIntForKey(key_state)
        let itemState    = state == 0 ? ItemState.Inactive : state == 1 ? ItemState.Incomplete : ItemState.Complete
        
        self.init(name: name, note: note, image: image, state: itemState, tutorial: tutorial, itemRecord: itemRecord, createdBy: createdBy, createdDate: createdDate, modifiedBy: modifiedBy, modifiedDate: modifiedDate)
    }
    
    func encodeWithCoder(coder: NSCoder)
    {
        //self.modifiedDate = NSDate.init()
        
        coder.encodeObject(self.name,            forKey: key_name)
        coder.encodeObject(self.note,            forKey: key_note)
        coder.encodeObject(self.image,           forKey: key_image)
        coder.encodeInteger(self.state.rawValue, forKey: key_state)
        coder.encodeObject(self.createdBy,       forKey: key_createdBy)
        coder.encodeObject(self.createdDate,     forKey: key_createdDate)
        coder.encodeObject(self.modifiedBy,      forKey: key_modifiedBy)
        coder.encodeObject(self.modifiedDate,    forKey: key_modifiedDate)
        coder.encodeObject(self.itemRecord,      forKey: key_itemRecord)
    }
    
    // commits this item change to cloud storage
    func saveToCloud(categoryReference: CKReference)
    {
        // don't save the tutorial to the cloud
        if self.isTutorialItem {
            return
        }
        
        if let database = appDelegate.privateDatabase {
            if needToDelete {
                deleteRecord(itemRecord!, database: database)
            } else if needToSave {
                saveRecord(itemRecord!, categoryReference: categoryReference)
            }
        }
    }
    
    // cloud storage method for this item
    func saveRecord(itemRecord: CKRecord, categoryReference: CKReference)
    {
        // don't save the tutorial to the cloud
        if self.isTutorialItem {
            return
        }
        
        // prepare image for archiving (CKAsset)
        itemRecord[key_image] = nil
        if self.image != nil {
            let imageFileURL = saveImageToFile(self.image!)
            if imageFileURL != nil {
                let asset = CKAsset(fileURL: imageFileURL!)
                itemRecord[key_image] = asset
            }
        }
        
        itemRecord[key_name] = self.name
        itemRecord[key_note] = self.note
        itemRecord[key_state] = self.state.rawValue
        itemRecord[key_owningCategory] = categoryReference
        itemRecord[key_order] = self.order
        itemRecord[key_createdBy] = self.createdBy
        itemRecord[key_createdDate] = self.createdDate
        itemRecord[key_modifiedBy] = self.modifiedBy
        itemRecord[key_modifiedDate] = self.modifiedDate
        
        // add this record to the batch record array for updating
        appDelegate.addToUpdateRecords(itemRecord, obj: self)
    }
    
    // update this item from cloud storage
    func updateFromRecord(record: CKRecord)
    {
        if let itemState = record["state"] as? Int {
            self.state = itemState == 0 ? ItemState.Inactive : itemState == 1 ? ItemState.Incomplete : ItemState.Complete
        } else {
            self.state = ItemState.Incomplete
        }
        
        if let name         = record[key_name]         { self.name         = name as! String         }
        if let note         = record[key_note]         { self.note         = note as! String         }
        if let order        = record[key_order]        { self.order        = order as! Int           }
        if let createdBy    = record[key_createdBy]    { self.createdBy    = createdBy as! String    }
        if let createdDate  = record[key_createdDate]  { self.createdDate  = createdDate as! NSDate  }
        if let modifiedBy   = record[key_modifiedBy]   { self.modifiedBy   = modifiedBy as! String   }
        if let modifiedDate = record[key_modifiedDate] { self.modifiedDate = modifiedDate as! NSDate }
        
        // retrieve the image as a CKAsset
        let asset = record[key_image] as? CKAsset
        if asset != nil {
            if let path = asset!.fileURL.path {
                let image = UIImage(contentsOfFile: path)
                self.image = image
                print("*** \(name) image set...")
            }
        }
        
        /*
        let imageFile: CKAsset? = record[key_image] as? CKAsset
        if let file = imageFile {
            if let data = NSData(contentsOfURL: file.fileURL) {
                self.image = UIImage(data: data)
            }
        }
        */
        
        // check date values after update from cloud record - reset if needed
        if self.modifiedDate.compare(NSDate.init(timeIntervalSince1970: NSTimeInterval.init())) == NSComparisonResult.OrderedSame {
            self.modifiedDate = NSDate.init()
        }
        
        if self.createdDate.compare(NSDate.init(timeIntervalSince1970: NSTimeInterval.init())) == NSComparisonResult.OrderedSame {
            self.createdDate = self.modifiedDate
        }
        
        // check if item has changed categories
        if let itemRecord = self.itemRecord {
            let currentCategory = getCategoryFromReference(itemRecord)
            let updateCategory = getCategoryFromReference(record)
            
            if currentCategory != updateCategory && updateCategory != nil {
                // item changed categories = delete item from old category
                if currentCategory != nil {
                    let index = currentCategory!.items.indexOf(self)
                    if index != nil {
                        currentCategory!.items.removeAtIndex(index!)
                        print("Item Move: deleted \(self.name) from \(currentCategory!.name)")
                    }
                }
                // add item to new category
                if self.order >= 0 {
                    if self.order < updateCategory!.items.count {
                        updateCategory!.items.insert(self, atIndex: self.order)
                    } else {
                        updateCategory!.items.append(self)
                    }
                    print("Item Move: inserted \(self.name) in \(updateCategory!.name) at pos \(self.order)")
                }
            }
        }
        
        self.itemRecord = record
        //print("updated item: \(item.name)")
    }
    
    // deletes this item from the cloud
    func deleteRecord(itemRecord: CKRecord, database: CKDatabase)
    {
        // don't save the tutorial to the cloud
        if self.isTutorialItem {
            return
        }
        
        database.deleteRecordWithID(itemRecord.recordID, completionHandler: { returnRecord, error in
            if let err = error {
                print("Delete Item Error for '\(self.name)': \(err.localizedDescription)")
            } else {
                print("Success: Item record deleted successfully '\(self.name)'")
            }
        })
    }

    func deleteFromCloud()
    {
        self.needToDelete = true
        appDelegate.saveListData(true)
    }
    
    // used by cloud save
    func saveImageToFile(image: UIImage) -> NSURL?
    {
        let dirPaths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let docsDir: AnyObject = dirPaths[0]
        let filePath = docsDir.stringByAppendingPathComponent("tempImage.png")
        
        do {
            try UIImagePNGRepresentation(image)?.writeToFile(filePath, options: NSDataWritingOptions.AtomicWrite)
        } catch {
            return nil
        }
        
        return NSURL.fileURLWithPath(filePath)
    }
    
    // item
    func htmlForPrinting() -> String
    {
        var html = ""
        
        // state
        var stateLabel = ""
        
        switch state {
        case .Complete:    stateLabel = "&nbsp;☑︎"
        case .Inactive:    stateLabel = "&nbsp;"
        case .Incomplete:  stateLabel = "&nbsp;☐"
        }
        
        // name
        if self.state == .Inactive {
            html += "<tr><td>\(stateLabel)</td><td><font size='3'; color='gray'>\(self.name)</font></td></tr>"
        } else {
            html += "<tr><td>\(stateLabel)</td><td><font size='3'>\(self.name)</td></tr>"
        }
        
        // note
        if appDelegate.printNotes && self.note.characters.count > 0 {
            html += "<tr><td></td><td><div class='tab'><font size='2'; color='gray'>\(self.note)</font></div></td></tr>"
        }
        
        return html
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

/*
extension UIColor
{
    func rgb() -> Int? {
        var fRed   : CGFloat = 0
        var fGreen : CGFloat = 0
        var fBlue  : CGFloat = 0
        var fAlpha : CGFloat = 0
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
    
    static func colorFromRGB(rgb: Int) -> UIColor?
    {
        if rgb == 0 {
            return nil
        }
        
        let RGB: Int64 = Int64.init(rgb)
        
        // let rgb = (iAlpha << 24) + (iRed << 16) + (iGreen << 8) + iBlue
        
        let blue  = Float(RGB & 0xFF)       / 0xFF
        let green = Float(RGB & 0xFF00)     / 0xFF00
        let red   = Float(RGB & 0xFF0000)   / 0xFF0000
        let alpha = Float(RGB & 0xFF000000) / 0xFF000000
        
        return UIColor(colorLiteralRed: red, green: green, blue: blue, alpha: alpha)
    }
}
*/

////////////////////////////////////////////////////////////////
//
//  MARK: - Utility methods
//
////////////////////////////////////////////////////////////////


func getListFromReference(categoryRecord: CKRecord) -> List?
{
    if let listReference = categoryRecord[key_owningList] as? CKReference {
        return appDelegate.getLocalList(listReference.recordID.recordName)
    }
    
    return nil
}

func getCategoryFromReference(itemRecord: CKRecord) -> Category?
{
    if let categoryReference = itemRecord[key_owningCategory] as? CKReference {
        return appDelegate.getLocalCategory(categoryReference.recordID.recordName)
    }
    
    return nil
}
