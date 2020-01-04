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
let ImagesRecordType = "Images"
let DeletesRecordType = "Deletes"

// key strings for record access
let key_name                = "name"
let key_showCompletedItems  = "showCompletedItems"
let key_showInactiveItems   = "showInactiveItems"
let key_isTutorialList      = "isTutorialList"
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
let key_deletedDate         = "deletedDate"
let key_imageModifiedDate   = "imageModifiedDate"
let key_owningCategory      = "owningCategory"
let key_itemRecord          = "itemRecord"
let key_itemReference       = "itemReference"
let key_state               = "state"
let key_tutorial            = "tutorial"
let key_itemAddCount        = "itemAddCount"
let key_owningItem          = "owningItem"
let key_imageData           = "imageData"
let key_imageGUID           = "imageGUID"
let key_imageAsset          = "imageAsset"
let key_imageRecord         = "imageRecord"
let key_objectRecordID      = "objectRecordID"
let key_objectName          = "objectName"
let key_objectType          = "objectType"
let key_itemName            = "itemName"

// color row and column constants
let r1_1                    = "r1_1"
let r1_2                    = "r1_2"
let r1_3                    = "r1_3"
let r2_1                    = "r2_1"
let r2_2                    = "r2_2"
let r2_3                    = "r2_3"
let r3_1                    = "r3_1"
let r3_2                    = "r3_2"
let r3_3                    = "r3_3"
let r4_1                    = "r4_1"
let r4_2                    = "r4_2"
let r4_3                    = "r4_3"

let jpegCompressionQuality  = CGFloat(0.6)      // JPEG quality range is 0.0 (low) to 1.0 (high)

let alpha: CGFloat = 1.0

// SUSAN'S COLORS
// row 1
var color1_1 = UIColor(red: 0.000, green: 0.478, blue: 1.000, alpha: 0.850)     // system blue
let color1_2 = UIColor(red: 0.470, green: 0.620, blue: 0.750, alpha: alpha)     // icon blue (default)
let color1_3 = UIColor(red: 0.337, green: 0.753, blue: 0.996, alpha: alpha)     // lt blue

// row 2
let color2_1 = UIColor(red: 0.059, green: 0.439, blue: 0.004, alpha: alpha)     // green
let color2_2 = UIColor(red: 0.055, green: 0.431, blue: 0.425, alpha: alpha)     // teal
let color2_3 = UIColor(red: 0.137, green: 1.000, blue: 0.020, alpha: alpha)     // bright green

// row 3
let color3_1 = UIColor(red: 0.984, green: 0.000, blue: 0.059, alpha: alpha)     // red
let color3_2 = UIColor(red: 0.463, green: 0.000, blue: 0.118, alpha: alpha)     // burgandy
let color3_3 = UIColor(red: 0.988, green: 0.314, blue: 0.773, alpha: alpha)     // pink

// row 4
let color4_1 = UIColor(red: 0.996, green: 1.000, blue: 0.337, alpha: alpha)     // yellow
let color4_2 = UIColor(red: 0.984, green: 0.420, blue: 0.043, alpha: alpha)     // orange
let color4_3 = UIColor(red: 0.420, green: 0.000, blue: 1.000, alpha: alpha)     // purple
//let color4_3 = UIColor(red: 0.259, green: 0.000, blue: 0.365, alpha: alpha)   // rockies purple

// alt yellow (for checkbox and button contrast)
let color4_1_alt = UIColor.darkGray

let appDelegate = UIApplication.shared.delegate as! AppDelegate

enum ItemState: Int {
    case inactive = 0
    case incomplete = 1
    case complete = 2
    
    // this function will bump the button to the next state
    mutating func next() {
        switch self {
        case .inactive:      self = .incomplete
        case .incomplete:    self = .complete
        case .complete:      self = .inactive
        }
    }
}

////////////////////////////////////////////////////////////////
//
//  MARK: - ListData (singleton)
//
////////////////////////////////////////////////////////////////

class ListData {
    private init() {}   // prevent use of default initializer
    static var lists = [List]()
    
    // computed values
    static var listCount: Int {
        get {
            return lists.count
        }
    }
    
    static var listObjCount: Int {
        get {
            var count = lists.count
            for list in lists {
                count += list.categories.count
                for category in list.categories {
                    count += category.items.count
                    for item in category.items {
                        if item.imageAsset?.image != nil {
                            count += 1
                        }
                    }
                }
            }
            return count
        }
    }
    
    static var nonTutorialListCount: Int {
        get {
            var tempListCount = 0
            for list in lists {
                if list.isTutorialList == false {
                    tempListCount += 1
                }
            }
            return tempListCount
        }
    }

    static var tutorialListIndex: Int? {
        get {
            var i = 0
            for list in lists {
                if list.isTutorialList {
                    return i
                }
                i += 1
            }
            return nil
        }
    }
    
    //MARK:- Class Functions
    class func loadLocal(filePath: String) -> Bool {
        if let archivedListData = NSKeyedUnarchiver.unarchiveObject(withFile: filePath) as? [List] {
            lists = archivedListData
            return true
        }
        return false
    }
    
    class func saveLocal(filePath: String) -> Bool {
        return NSKeyedArchiver.archiveRootObject(ListData.lists, toFile: filePath)
    }
    
    class func listForRow(at indexPath: IndexPath) -> List? {
        if indexPath.row >= 0 && indexPath.row < lists.count {
            return lists[indexPath.row]
        }
        return nil
    }
    
    class func list(_ index: Int) -> List? {
        if index >= 0 && index < lists.count {
            return lists[index]
        }
        return nil
    }
    
    class func listIndex(of list: List) -> Int? {
        if let index = lists.firstIndex(of: list) {
            return index
        }
        return nil
    }
    
    class func removeList(_ list: List) {
        lists.removeObject(list)
    }
    
    class func removeListAt(_ indexPath: IndexPath) -> List? {
        return self.removeListAt(indexPath.row)
    }
    
    class func removeListAt(_ index: Int) -> List? {
        if index >= 0 && index < lists.count {
            let list = lists[index]
            lists.remove(at: index)
            return list
        }
        return nil
    }
    
    class func removeLastList() {
        lists.removeLast()
    }
    
    class func appendList(_ list: List) {
        lists.append(list)
    }
    
    class func insertList(_ list: List, at indexPath: IndexPath) {
        lists.insert(list, at: indexPath.row)
    }
    
    class func saveToCloud() {
        for list in lists {
            list.saveToCloud()
        }
    }
    
    class func updateIndices() {
        for list in lists {
            list.updateIndices()
        }
    }
    
    class func clearNeedToSave() {
        for list in lists {
            list.clearNeedToSave()
        }
    }
    
    class func resetListOrderValues() {
        var i = 0
        for list in lists {
            list.order = i
            i += 1
        }
    }
    
    class func lastCategoryInList(_ list: List) -> Category? {
        return list.categories.last
    }
    
    class func deleteObjects(listDeleteRecordIDs: [String], categoryDeleteRecordIDs: [String], itemDeleteRecordIDs: [String]) {
        var listsToDelete = [List]()
        
        for list in lists {
            let listRecordName = list.listRecord?.recordID.recordName
            if let listRecordName = listRecordName {
                if listDeleteRecordIDs.contains(listRecordName) {
                    listsToDelete.append(list)
                }
            }
            
            var categoriesToDelete = [Category]()
            for category in list.categories {
                let categoryRecordName = category.categoryRecord?.recordID.recordName
                if let categoryRecordName = categoryRecordName {
                    if categoryDeleteRecordIDs.contains(categoryRecordName) {
                        categoriesToDelete.append(category)
                    }
                }
                
                var itemsToDelete = [Item]()
                for item in category.items {
                    let itemRecordName = item.itemRecord?.recordID.recordName
                    if let itemRecordName = itemRecordName {
                        if itemDeleteRecordIDs.contains(itemRecordName) {
                            itemsToDelete.append(item)
                        }
                    }
                }
                
                // remove the deleted items in this category
                category.items.removeObjectsInArray(itemsToDelete)
                //print("*** processDeleteObjects - deleted \(itemsToDelete.count) items in \(list.name): \(category.name)")
            }
            
            // remove the deleted categories in this list
            list.categories.removeObjectsInArray(categoriesToDelete)
            //print("*** processDeleteObjects - deleted \(categoriesToDelete.count) categories in \(list.name)")
        }
        
        // remove the deleted lists
        lists.removeObjectsInArray(listsToDelete)
        //print("*** processDeleteObjects - deleted \(listsToDelete.count) lists")
    }
    
    class func countNeedToSave() -> Int {
        var count = 0
        
        for list in lists {
            if list.needToSave {
                count += 1
            }
            
            for category in list.categories {
                if category.needToSave {
                    count += 1
                }
                
                for item in category.items {
                    if item.needToSave {
                        count += 1
                    }
                }
            }
        }
        
        return count
    }
    
    // reorder lists, categories and items according to order number
    class func reorderListObjects() {
        // sort lists
        lists.sort { $0.order < $1.order }
        
        for list in lists {
            list.categories.sort { $0.order < $1.order }
            
            //print("sort list \(list.name))")
            
            for category in list.categories {
                category.items.sort { $0.order < $1.order }
            }
            
            list.updateIndices()
        }
    }
    
    // reset the order field for each list based on current position in the list array
    class func resetListOrderByPosition() {
        var pos = 0
        for list in lists {
            list.order = pos
            pos += 1
        }
    }
    
    // reset the order field for each list
    class func resetListCategoryAndItemOrderByPosition() {
        var listPos = 0
        for list in lists {
            list.order = listPos
            listPos += 1
            
            list.resetCategoryAndItemOrderByPosition()
        }
    }
    
    // returns a ListData object from the given recordName
    class func getLocalObject(_ recordIDName: String) -> AnyObject? {
        for list in lists {
            if list.listRecord != nil {
                if list.listRecord!.recordID.recordName == recordIDName {
                    return list
                }
                
                for category in list.categories {
                    if category.categoryRecord != nil {
                        if category.categoryRecord!.recordID.recordName == recordIDName {
                            return category
                        }
                        
                        for item in category.items {
                            if item.itemRecord != nil {
                                if item.itemRecord!.recordID.recordName == recordIDName {
                                    return item
                                }
                            } else if item.imageAsset?.imageRecord.recordID.recordName == recordIDName {
                                return item.imageAsset
                            }
                        }
                    }
                }
            }
        }
        
        return nil
    }
    
    // returns a List object matching the given CKRecordID
    class func getLocalList(_ recordIDName: String) -> List? {
        for list in lists {
            if list.listRecord != nil {
                if list.listRecord!.recordID.recordName == recordIDName {
                    return list
                }
            }
        }
        
        return nil
    }
    
    // returns a Category object matching the given CKRecordID
    class func getLocalCategory(_ recordIDName: String) -> Category? {
        for list in lists {
            for category in list.categories {
                if category.categoryRecord?.recordID.recordName == recordIDName {
                    return category
                }
            }
        }
        
        return nil
    }
    
    // returns an Item object matching the given CKRecordID
    class func getLocalItem(_ recordIDName: String) -> Item? {
        for list in lists {
            for category in list.categories {
                for item in category.items {
                    if item.itemRecord?.recordID.recordName == recordIDName {
                        return item
                    }
                }
            }
        }
        
        return nil
    }
    
    // returns the list that contains the given category
    class func getListForCategory(_ searchCategory: Category) -> List? {
        for list in lists {
            for category in list.categories {
                if category === searchCategory {
                    return list
                }
            }
        }
        
        return nil
    }
    
    // returns the list that contains the given item
    class func getListForItem(_ searchItem: Item) -> List? {
        for list in lists {
            for category in list.categories {
                for item in category.items {
                    if item === searchItem {
                        return list
                    }
                }
            }
        }
        
        return nil
    }
    
    // returns the list that contains the given list object
    class func getListForListObj(_ searchObj: ListObj) -> List? {
        for list in lists {
            for category in list.categories {
                if category == searchObj {
                    return list
                }
                for item in category.items {
                    if item === searchObj {
                        return list
                    }
                }
            }
        }
        
        return nil
    }
    
    // returns the category that contains the given item
    class func getCategoryForItem(_ searchItem: Item) -> Category? {
        for list in lists {
            for category in list.categories {
                for item in category.items {
                    if item === searchItem {
                        return category
                    }
                }
            }
        }
        
        return nil
    }
    
    // returns the category that contains the given item in the given list
    class func getCategoryForItem(_ searchItem: Item, inList: List) -> Category? {
        for category in inList.categories {
            for item in category.items {
                if item === searchItem {
                    return category
                }
            }
        }
        
        return nil
    }
}

////////////////////////////////////////////////////////////////
//
//  MARK: - List Utility methods
//
////////////////////////////////////////////////////////////////

func getListFromReference(_ categoryRecord: CKRecord) -> List? {
    if let listReference = categoryRecord[key_owningList] as? CKRecord.Reference {
        return ListData.getLocalList(listReference.recordID.recordName)
    }
    
    return nil
}

func getCategoryFromReference(_ itemRecord: CKRecord) -> Category? {
    if let categoryReference = itemRecord[key_owningCategory] as? CKRecord.Reference {
        return ListData.getLocalCategory(categoryReference.recordID.recordName)
    }
    
    return nil
}

func getItemFromReference(_ imageRecord: CKRecord) -> Item? {
    if let itemReference = imageRecord[key_owningItem] as? CKRecord.Reference {
        return ListData.getLocalItem(itemReference.recordID.recordName)
    }
    
    return nil
}

// create a Delete record for this list delete and save to cloud
func createDeleteRecord(_ database: CKDatabase, recordName: String, objectType: String, objectName: String) {
    let deleteRecord = CKRecord(recordType: DeletesRecordType, recordID: CKRecord.ID(zoneID: CloudCoordinator.sharedZoneID))
    deleteRecord[key_objectRecordID] = recordName as CKRecordValue?
    deleteRecord[key_objectType] = objectType as CKRecordValue?
    deleteRecord[key_objectName] = objectName as CKRecordValue?
    deleteRecord[key_deletedDate] = Date.init() as CKRecordValue?
    
    database.save(deleteRecord, completionHandler: { returnRecord, error in
        if let err = error {
            print("Save deleteRecord Error for '\(objectName)': \(err.localizedDescription)")
        } else {
            print("Success: delete record saved successfully for '\(objectName)' recordID: \(recordName)")
        }
    })
}

////////////////////////////////////////////////////////////////
//
//  MARK:- List class
//
////////////////////////////////////////////////////////////////

// 1. lists have one or more categories that hold items
// 2. if the list has only one category and the category is empty then the list behaves as though it has no categories (actually the one category is hidden)
// 3. if the user adds a category with an empty name then the data model will set the name to a single space char
// 4. if the user deletes the last category then the last category is not deleted but the name is set to a single space char

class List: NSObject, NSCoding {
    var name: String { didSet { needToSave = true } }
    var categories = [Category]()
    var listColor: UIColor?
    var listColorName: String = r1_2 {
        didSet {
            needToSave = true
            setListColor()
        }
    }
    var needToSave: Bool = false
    var needToDelete: Bool = false
    var modificationDate: Date?
    var listRecord: CKRecord?
    var listReference: CKRecord.Reference?
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
    
    // Designated initializer - new list initializer
    init(name: String, createRecord: Bool, tutorial: Bool = false) {
        self.name = name
        self.isTutorialList = tutorial
        super.init()
        
        if createRecord {
            // new list needs a new record and reference
            listRecord = CKRecord(recordType: ListsRecordType, recordID: CKRecord.ID(zoneID: CloudCoordinator.sharedZoneID))
            listReference = CKRecord.Reference.init(record: listRecord!, action: CKRecord.Reference.Action.deleteSelf)
        }
        
        self.modificationDate = Date.init()
    }

///////////////////////////////////////////////////////
//
//  MARK:- List data I/O methods
//
///////////////////////////////////////////////////////
    
    // Designated memberwise initializer - called when restoring from local storage on launch
    init(name: String?, showCompletedItems: Bool?, showInactiveItems: Bool?, tutorial: Bool?, listColorName: String?, modificationDate: Date?, listReference: CKRecord.Reference?, listRecord: CKRecord?, categories: [Category]?) {
        if let name               = name                 { self.name                = name               } else { self.name = ""                        }
        if let showCompletedItems = showCompletedItems   { self.showCompletedItems  = showCompletedItems } else { self.showCompletedItems = true        }
        if let showInactiveItems  = showInactiveItems    { self.showInactiveItems   = showInactiveItems  } else { self.showInactiveItems  = true        }
        if let tutorial           = tutorial             { self.isTutorialList      = tutorial           } else { self.isTutorialList = false           }
        if let modificationDate   = modificationDate     { self.modificationDate    = modificationDate   } else { self.modificationDate = Date.init()   }
        if let listColorName      = listColorName        { self.listColorName       = listColorName      }
        if let listReference      = listReference        { self.listReference       = listReference      }
        if let listRecord         = listRecord           { self.listRecord          = listRecord         }
        if let categories         = categories           { self.categories          = categories         }
        
        super.init()
        
        self.updateIndices()
        self.setListColor()
    }
    
    // Secondary initializer - for unarchiving a list object
    convenience required init?(coder decoder: NSCoder) {
        let name               = decoder.decodeObject(forKey: key_name)               as? String
        let showCompletedItems = decoder.decodeBool(forKey: key_showCompletedItems)
        let showInactiveItems  = decoder.decodeBool(forKey: key_showInactiveItems)
        let tutorial           = decoder.decodeBool(forKey: key_isTutorialList)
        let listColorName      = decoder.decodeObject(forKey: key_listColorName)      as? String
        let categories         = decoder.decodeObject(forKey: key_categories)         as? [Category]
        let listReference      = decoder.decodeObject(forKey: key_listReference)      as? CKRecord.Reference
        let listRecord         = decoder.decodeObject(forKey: key_listRecord)         as? CKRecord
        let modificationDate   = decoder.decodeObject(forKey: key_modificationDate)   as? Date
        
        self.init(name: name,
                  showCompletedItems: showCompletedItems,
                  showInactiveItems: showInactiveItems,
                  tutorial: tutorial,
                  listColorName: listColorName,
                  modificationDate: modificationDate,
                  listReference: listReference,
                  listRecord: listRecord,
                  categories: categories)
    }
    
    // to local storage
    func encode(with coder: NSCoder) {
        self.modificationDate = Date.init()
        
        coder.encode(self.name,               forKey: key_name)
        coder.encode(self.showCompletedItems, forKey: key_showCompletedItems)
        coder.encode(self.showInactiveItems,  forKey: key_showInactiveItems)
        coder.encode(self.isTutorialList,     forKey: key_isTutorialList)
        coder.encode(self.listColorName,      forKey: key_listColorName)
        coder.encode(self.categories,         forKey: key_categories)
        coder.encode(self.listReference,      forKey: key_listReference)
        coder.encode(self.listRecord,         forKey: key_listRecord)
        coder.encode(self.modificationDate,   forKey: key_modificationDate)
    }
    
    // to cloud storage
    func saveToCloud() {
        // don't save tutorial records to the cloud
        if self.isTutorialList {
            return
        }
                
        if listRecord != nil {
            // commit change to cloud
            if needToDelete {
                deleteRecord(listRecord!, database: CloudCoordinator.privateDatabase)
            } else if needToSave || appDelegate.needsDataSaveOnMigration {
                saveRecord(listRecord!)
            }
        } else {
            print("ERROR: list saveToCloud - Can't save list '\(name)' to cloud - listRecord is nil...")
            }
        
        // pass on to the categories
        if listReference != nil {
            for category in categories {
                category.saveToCloud(listReference: listReference!)
            }
        }
    }
    
    // saves this list record to the cloud
    func saveRecord(_ listRecord: CKRecord) {
        // don't save tutorial records to the cloud
        if self.isTutorialList {
            return
        }
        
        var record = listRecord
        
        if listRecord.recordID.zoneID.zoneName.contains("default") {
            let recordID = CKRecord.ID(recordName: record.recordID.recordName, zoneID: CloudCoordinator.sharedZoneID)
            let sharedZoneRecord = CKRecord(recordType: ListsRecordType, recordID: recordID)
            listReference = CKRecord.Reference.init(record: sharedZoneRecord, action: CKRecord.Reference.Action.deleteSelf)
            record = sharedZoneRecord
            self.listRecord = sharedZoneRecord
        }
        
        record.setObject(self.name as CKRecordValue?,               forKey: key_name)
        record.setObject(self.listColorName as CKRecordValue?,      forKey: key_listColorName)
        record.setObject(self.showCompletedItems as CKRecordValue?, forKey: key_showCompletedItems)
        record.setObject(self.showInactiveItems as CKRecordValue?,  forKey: key_showInactiveItems)
        record.setObject(self.order as CKRecordValue?,              forKey: key_order)
        
        // add this record to the batch record array for updating
        CloudCoordinator.addToUpdateRecords(record, obj: self)
    }
    
    // update this list from cloud storage
    func updateFromRecord(_ record: CKRecord) {
        if let name               = record[key_name]               { self.name               = name as! String             }
        if let showCompletedItems = record[key_showCompletedItems] { self.showCompletedItems = showCompletedItems as! Bool }
        if let showInactiveItems  = record[key_showInactiveItems]  { self.showInactiveItems  = showInactiveItems as! Bool  }
        if let listColorName      = record[key_listColorName]      { self.listColorName      = listColorName as! String    }
        if let order              = record[key_order]              { self.order              = order  as! Int              }
        
        self.listRecord = record
        self.listReference = CKRecord.Reference.init(record: record, action: CKRecord.Reference.Action.deleteSelf)
        
        // list record is now updated
        needToSave = false
        
        //print("updated list: \(list!.name)")
    }
    
    func deleteFromCloud() {
        self.needToDelete = true
        DataPersistenceCoordinator.saveListData(async: true)
    }
    
    // deletes this list from the cloud
    func deleteRecord(_ listRecord: CKRecord, database: CKDatabase) {
        // don't save tutorial records to the cloud
        if self.isTutorialList {
            return
        }
        
        database.delete(withRecordID: listRecord.recordID, completionHandler: { returnRecord, error in
            if let err = error {
                print("Delete List Error: \(err.localizedDescription)")
            } else {
                print("Success: List record deleted successfully '\(self.name)' recordID: \(listRecord.recordID.recordName)")
            }
        })
        
        // create a Delete record for this list delete and save to cloud
        createDeleteRecord(database, recordName: listRecord.recordID.recordName, objectType: ListsRecordType, objectName: self.name)
    }
    
    func setListColor() {
        switch listColorName {
        case r1_1: listColor = color1_1
        case r1_2: listColor = color1_2
        case r1_3: listColor = color1_3
        case r2_1: listColor = color2_1
        case r2_2: listColor = color2_2
        case r2_3: listColor = color2_3
        case r3_1: listColor = color3_1
        case r3_2: listColor = color3_2
        case r3_3: listColor = color3_3
        case r4_1: listColor = color4_1
        case r4_2: listColor = color4_2
        case r4_3: listColor = color4_3
        default: listColor = color1_2
        }
    }
    
///////////////////////////////////////////////////////
//
//  MARK:- Methods for Category and Item objects
//
///////////////////////////////////////////////////////
    
    func indexForCategory(_ category: Category) -> Int {
        var index = -1
        
        for cat in categories {
            if cat === category {
                index += 1
                return index
            }
            index += 1
        }
        
        return -1
    }
    
    func addCategory(_ name: String, displayHeader: Bool, updateIndices: Bool, createRecord: Bool, tutorial: Bool = false) -> Category {
        let category = Category(name: name, displayHeader: displayHeader, createRecord: createRecord, tutorial: tutorial)
        categories.append(category)
        
        if updateIndices {
            self.updateIndices()
        }
        
        return category
    }
    
    func addItem(_ category: Category, name: String, state: ItemState, updateIndices: Bool, createRecord: Bool, tutorial: Bool = false) -> Item? {
        let indexForCat = indexForCategory(category)
        var item: Item? = nil
        
        if indexForCat > -1 {
            item = Item(name: name, state: state, createRecord: createRecord)
            category.items.append(item!)
        } else {
            print("ERROR: addItem given invalid category!")
        }
        
        if updateIndices {
            self.updateIndices()
        }
        
        return item
    }
    
    // sets all items to the active state
    func setAllItemsIncomplete() {
        for category in categories {
            for item in category.items {
                item.state = ItemState.incomplete
            }
        }
    }
    
    // sets all items to the inactive state
    func setAllItemsInactive() {
        for category in categories {
            for item in category.items {
                item.state = ItemState.inactive
            }
        }
    }
    
    // sets all items needToSave to false
    func clearNeedToSave() {
        self.needToSave = false
        
        for category in categories {
            category.clearNeedToSave()
        }
    }
    
///////////////////////////////////////////////////////
//
//  MARK:- Remove and insert methods for List objects
//
///////////////////////////////////////////////////////
    
    /// Will remove the given item from the list data.
    func removeItem(_ item: Item, updateIndices: Bool) -> [IndexPath] {
        var removedPaths = [IndexPath]()
        let indexPath = displayIndexPathForItem(item)
        
        if indexPath != nil {
            //let catIdx = item.categoryIndex
            //let itmIdx = item.itemIndex - 1         // we have to subtract 1 to convert from itemIndex to items index (cat is 0, 1st item is 1, etc.)
            
            //self.categories[catIdx].items.removeAtIndex(itmIdx)
            
            // locate this item in list data and delete it
            if let cat = ListData.getCategoryForItem(item, inList: self) {
                cat.items.removeObject(item)
                cat.resetItemOrderByPosition()
                removedPaths.append(indexPath!)
            }
        }
        
        if updateIndices {
            self.updateIndices()
        }
        
        return removedPaths
    }
    
    /// Will remove the given category from the list data.
    func removeCategory(_ category: Category, updateIndices: Bool) -> [IndexPath] {
        var removedPaths = [IndexPath]()
        let indexPath = displayIndexPathForCategory(category)
        
        if indexPath != nil {
            //self.categories.removeAtIndex(category.categoryIndex)
            self.categories.removeObject(category)
            self.resetCategoryOrderByPosition()
            removedPaths.append(indexPath!)
        }
        
        if updateIndices {
            self.updateIndices()
        }
        
        return removedPaths
    }

    
    /// Will insert item after afterObj.
    func insertItem(_ item: Item, afterObj: ListObj, updateIndices: Bool) {
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
        
        category.items.insert(item, at: itmIdx + 1)
        category.resetItemOrderByPosition()
        
        if updateIndices {
            self.updateIndices()
        }
    }
    
    /// Will insert item before beforeObj.
    func insertItem(_ item: Item, beforeObj: ListObj, updateIndices: Bool) -> Category {
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
        
        categories[catIdx].items.insert(item, at: itmIdx)
        categories[catIdx].resetItemOrderByPosition()
        
        if updateIndices {
            self.updateIndices()
        }
        
        return categories[catIdx]
    }
    
    /// Will insert item at either the beginning or the end of the category.
    func insertItem(_ item: Item, inCategory: Category, atPosition: InsertPosition, updateIndices: Bool) {
        switch atPosition {
        case .beginning:
            inCategory.items.insert(item, at: 0)
        case .end:
            let itemCount = inCategory.items.count
            inCategory.items.insert(item, at: itemCount)
        default:
            break
        }
        
        inCategory.resetItemOrderByPosition()
        
        if updateIndices {
            self.updateIndices()
        }
    }
    
    /// Will remove the item at indexPath.
    /// If the path is to a category, will remove the entire category with items.
    /// Returns an array with the display index paths of any removed rows.
    func removeListObjAtIndexPath(_ indexPath: IndexPath, preserveCategories: Bool, updateIndices: Bool) -> [IndexPath] {
        var removedPaths = [IndexPath]()
        let obj = objectForIndexPath(indexPath)
        
        if let obj = obj {
            let catIndex = obj.categoryIndex
            let itemIndex = obj.itemIndex - 1       // we have to subtract 1 to convert from itemIndex to items index (cat is 0, 1st item is 1, etc.)
            
            print("remove: indicesForObjectAtIndexPath cat \(catIndex) item \(itemIndex) name: \(obj.name)")
            
            //if itemIndex >= 0 {
            if obj is Item {
                // delete item from cloud storage
                //let item = obj as! Item
                //item.deleteFromCloud()
                
                // remove the item from the category
                //self.categories[catIndex].items.removeAtIndex(itemIndex)
                
                // locate this item in list data and delete it
                let item = obj as! Item
                
                if let cat = ListData.getCategoryForItem(item, inList: self) {
                    cat.items.removeObject(item)
                    cat.resetItemOrderByPosition()
                    removedPaths.append(indexPath)
                }
            } else if obj is Category {
                let cat = obj as! Category
                
                if preserveCategories {
                    // remove the first item in this category
                    cat.items.removeFirst()
                    self.categories[catIndex].resetItemOrderByPosition()
                    removedPaths.append(indexPath)
                } else {
                    if categories.count > 1 {
                        if cat.expanded {
                            // add paths of category, add item row, and items
                            removedPaths = displayIndexPathsForCategoryFromIndexPath(indexPath, includeCategoryAndAddItemIndexPaths: true)
                        } else {
                            removedPaths = [indexPath]
                        }
                        
                        // remove the category and its items from the list
                        self.categories.removeObject(cat)
                    } else {
                        // we are deleting the only category which has become visible
                        // so instead only delete the items and set the category.displayHeader to false
                        // leaving the 'new item' row in place with a hidden category header
                        cat.deleteCategoryItemsFromCloudStorage()
                        
                        // add paths of items
                        removedPaths = displayIndexPathsForCategoryFromIndexPath(indexPath, includeCategoryAndAddItemIndexPaths: false)
                        
                        // add path of category itself because we are going to hide it
                        removedPaths.append(indexPath)
                        cat.displayHeader = false
                        
                        // remove the items from the category
                        cat.deleteItems()
                    }
                    self.resetCategoryOrderByPosition()
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
    func insertItemAtIndexPath(_ item: Item, indexPath: IndexPath, atPosition: InsertPosition, updateIndices: Bool) {
        let tag = tagForIndexPath(indexPath)
        let catIndex = tag.catIdx
        let itemIndex = tag.itmIdx - 1          // we have to subtract 1 to convert from itemIndex to items index (cat is 0, 1st item is 1, etc.)
    
        switch atPosition {
        case .beginning:
            categories[catIndex].items.insert(item, at: 0)
        case .middle:
            if itemIndex >= 0 {
                categories[catIndex].items.insert(item, at: itemIndex)
            } else {
                // if itemIndex is 0 then we are moving down past the last item in the category, so just decrement the category and append
                if catIndex > 0 {
                    categories[catIndex - 1].items.append(item)
                } else {
                    // special case for moving past end of the list, append to the end of the last category
                    categories[categories.count-1].items.append(item)
                }
            }
        case .end:
            if catIndex >= 0 {
                categories[catIndex].items.append(item)
            } else {
                print("ALERT! - insertItemAtIndexPath - .End with nil categoryIndex...")
            }
        }
        
        categories[catIndex].resetItemOrderByPosition()
        
        if updateIndices {
            self.updateIndices()
        }
    }
    
    /// Remove the category (and associated items) at the given index.
    /*
    func removeCatetoryAtIndex(sourceCatIndex: Int) {
        if sourceCatIndex < self.categories.count {
            categories.removeAtIndex(sourceCatIndex)
        }
        
        updateIndices()
    }
    */
    
    /// Inserts the given category at the given index.
    func insertCategory(_ category: Category, atIndex: Int) {
        if atIndex >= self.categories.count {
            // append this category to the end
            self.categories.append(category)
        } else {
            self.categories.insert(category, at: atIndex)
        }
        
        self.resetCategoryOrderByPosition()
        
        updateIndices()
    }
    

///////////////////////////////////////////////////////
//
//  MARK: New reference methods for List objects
//
///////////////////////////////////////////////////////
    
    /// Updates the indices for all objects in the list.
    func updateIndices() {
        var i = -1
        for cat in categories {
            i += 1
            cat.updateIndices(i)
            cat.order = i
        }
    }
    
    func resetCategoryAndItemOrderByPosition() {
        var catPos = 0
        for category in categories {
            category.order = catPos
            catPos += 1
            
            category.resetItemOrderByPosition()
        }
    }
    
    func resetCategoryOrderByPosition() {
        var pos = 0
        for category in categories {
            category.order = pos
            pos += 1
        }
    }
    
    /// Returns the total number of rows to display in the ItemVC
    func totalDisplayCount() -> Int {
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
    func categoryForTag(_ tag: Int) -> Category? {
        let tag = Tag.indicesFromTag(tag)
        
        if tag.catIdx >= 0 && tag.catIdx < categories.count {
            return categories[tag.catIdx]
        }
        
        print("ERROR: categoryForTag given invalid tag! \(tag)")
        return nil
    }
    
    /// Returns the Item with the given tag.
    func itemForTag(_ tag: Int) -> Item? {
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
    func objectForTag(_ tag: Int) -> ListObj? {
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
    func categoryForObj(_ item: ListObj) -> Category? {
        if item.categoryIndex >= 0 && item.categoryIndex < categories.count {
            return categories[item.categoryIndex]
        }
        
        print("ERROR: categoryForItem - Item has an invalid category index!")
        return nil
    }
    
    /// Returns a Category for the object at the given index path.
    func categoryForIndexPath(_ indexPath: IndexPath) -> Category? {
        let obj = objectForIndexPath(indexPath)
        
        if obj is Category {
            return (obj as! Category)
        }
        
        return nil
    }
    
    /// Returns an Item for the object at the given index path.
    func itemForIndexPath(_ indexPath: IndexPath) -> Item? {
        let obj = objectForIndexPath(indexPath)
        
        if obj is Item {
            return (obj as! Item)
        }
        
        return nil
    }
    
    /// Returns the object for the given indexPath.
    func objectForIndexPath(_ indexPath: IndexPath) -> ListObj? {
        let row = (indexPath as NSIndexPath).row
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
    func displayIndexPathForTag(_ tag: Int) -> IndexPath? {
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
    func displayIndexPathForObj(_ obj: ListObj) -> (indexPath: IndexPath?, isItem: Bool) {
        var index = -1
        
        for category in categories {
            if category.displayHeader {
                index += 1
            }
            
            if category === obj {
                return (IndexPath(row: index, section: 0), false)
            }
            
            if category.expanded {
                for item in category.items {
                    if isDisplayedItem(item) {
                        index += 1
                        if item === obj {
                            return (IndexPath(row: index, section: 0), true)
                        }
                    }
                }
                // for AddItem cell
                index += 1
                if category.addItem === obj {
                    return (IndexPath(row: index, section: 0), true)
                }
            }
        }
        
        print("ERROR: displayIndexPathForObj given an invalid object!")
        return (nil, false)
    }
    
    /// Returns a display indexPath to the given Category.
    func displayIndexPathForCategory(_ category: Category) -> IndexPath? {
        let result = displayIndexPathForObj(category)
        
        if result.isItem == false {
            return result.indexPath
        }
        
        print("ERROR: displayIndexPathForCategory given an invalid object as a Category!")
        return nil
    }
    
    /// Returns a display indexPath to the given Item.
    func displayIndexPathForItem(_ item: Item) -> IndexPath? {
        let result = displayIndexPathForObj(item)
        
        if result.isItem {
            return result.indexPath
        }
        
        print("ERROR: displayIndexPathForCategory given an invalid object as an Item!")
        return nil
    }
    
    /// Returns a display indexPath for the AddItem cell in this category.
    func displayIndexPathForAddItemInCategory(_ category: Category) -> IndexPath? {
        var lastItemInCat: ListObj? = nil
        
        if category.items.count > 0 {
            lastItemInCat = category.items[category.items.count-1]
        } else {
            lastItemInCat = category
        }
        
        if let lastItem = lastItemInCat
        {
            let lastItemIndexPath: IndexPath? = displayIndexPathForObj(lastItem).indexPath
            
            if let lastItemIndexPath = lastItemIndexPath {
                return IndexPath(row: (lastItemIndexPath as NSIndexPath).row + 1, section: 0)
            }
        } else {
           print("ERROR: displayIndexPathForAddItemInCategory given an invalid category!")
        }
        
        return nil
    }
    
    /// Returns the index paths for a Category at given index path, all of its Items and the AddItem row.
    /// If includeCategoryIndexPath is true, then the returned paths will also include the index path to category itself.
    /// Otherwise, the returned paths will consist of only the items and the AddItem row.
    func displayIndexPathsForCategoryFromIndexPath(_ indexPath: IndexPath, includeCategoryAndAddItemIndexPaths: Bool) -> [IndexPath] {
        let category = categoryForIndexPath(indexPath)
        
        if category != nil {
            var indexPaths = displayIndexPathsForCategory(category!, includeAddItemIndexPath: includeCategoryAndAddItemIndexPaths)
            
            if includeCategoryAndAddItemIndexPaths {
                indexPaths.append(indexPath)
            }
            return indexPaths
        }
        
        return [IndexPath]()
    }
    
    /// Returns an array of display index paths for a category that is being expanded or collapsed.
    func displayIndexPathsForCategory(_ category: Category, includeAddItemIndexPath: Bool) -> [IndexPath] {
        var indexPaths = [IndexPath]()
        let catIndexPath = displayIndexPathForCategory(category)
        
        if let indexPath = catIndexPath
        {
            var pos = (indexPath as NSIndexPath).row
            
            for item in category.items {
                if isDisplayedItem(item) {
                    pos += 1
                    indexPaths.append(IndexPath(row: pos, section: 0))
                }
            }
            
            if includeAddItemIndexPath {
                // one more for the addItem cell
                pos += 1
                indexPaths.append(IndexPath(row: pos, section: 0))
            }
        } else {
            print("ERROR: displayIndexPathsForCategory was given an invalid index path!")
        }
        
        return indexPaths
    }
    
    /// Returns index paths for completed rows.
    func indexPathsForCompletedRows() -> [IndexPath] {
        var indexPaths = [IndexPath]()
        var pos = -1
        
        for category in categories {
            if category.displayHeader {
                pos += 1
            }
            
            if category.expanded {
                for item in category.items {
                    if item.state == ItemState.complete {
                        pos += 1
                        indexPaths.append(IndexPath(row: pos, section: 0))
                    } else if item.state != ItemState.inactive || showInactiveItems {
                        pos += 1
                    }
                }
                pos += 1        // for the AddItem cell
            }
        }
        
        return indexPaths
    }
    
    /// Returns index paths for inactive rows.
    func indexPathsForInactiveRows() -> [IndexPath] {
        var indexPaths = [IndexPath]()
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
                    if item.state == ItemState.inactive {
                        pos += 1
                        indexPaths.append(IndexPath(row: pos, section: 0))
                    } else if item.state != ItemState.complete || showCompletedItems {
                        pos += 1
                    }
                }
                pos += 1     // for the AddItem cell
            }
        }
        
        return indexPaths
    }
    
    /// Returns the title of the object at the given index path.
    func titleForObjectAtIndexPath(_ indexPath: IndexPath) -> String? {
        let obj = objectForIndexPath(indexPath)
        
        if obj != nil {
            return obj!.name
        }
        
        print("ERROR: titleForObjectAtIndexPath given an invalid index path!")
        return ""
    }
    
    /// Updates the category or item object's name.
    func updateObjNameAtTag(_ tag: Int, name: String) {
        let obj = objectForTag(tag)
        
        if obj != nil {
            obj!.name = name
            obj!.needToSave = true
        }
    }
    
    /// Determines if an Item should be displayed
    func isDisplayedItem(_ item: Item) -> Bool {
        return (item.state == .incomplete) ||
               (item.state == .complete && showCompletedItems) ||
               (item.state == .inactive && showInactiveItems)
    }
    
    /// Returns true if the given path is the last row displayed.
    func indexPathIsLastRowDisplayed(_ indexPath: IndexPath) -> Bool {
        var lastObjRow: Int? = nil
        let lastCategory = categories[categories.count-1]
        
        if lastCategory.expanded == false {
            // category is collapsed, compare with category row
            lastObjRow = (displayIndexPathForCategory(lastCategory) as NSIndexPath?)?.row
        } else {
            // category is expanded, get indexPath to AddItem row
            let addItemIndexPath = displayIndexPathForObj(lastCategory.addItem)
            if addItemIndexPath.indexPath != nil {
                lastObjRow = (addItemIndexPath.indexPath! as NSIndexPath).row
            }
        }
        
        return lastObjRow == (indexPath as NSIndexPath).row
    }
    
    /// Returns the catagory and item indices for the given path.
    func tagForIndexPath(_ indexPath: IndexPath) -> Tag {
        let row = (indexPath as NSIndexPath).row
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
    func tagValueForIndexPath(_ indexPath: IndexPath) -> Int {
        let obj = objectForIndexPath(indexPath)
        
        if obj != nil {
            return obj!.tag()
        }
        
        return -1
    }
    
    // list
    func htmlForPrinting(_ includePics: Bool) -> String {
        //let listLabel = NSLocalizedString("List", comment: "label for 'List:'")
        
        // header
        var html: String = "<!DOCTYPE html>"
        html += "<html><head><style type='text/css'><!-- .tab { margin-left: 25px; } --> </style></head>"
        html += "<body><font face='arial'>"
        html += "<h1>\(self.name)</h1>"
        
        // categories
        for category in categories {
            html += "<p>"
            html += category.htmlForPrinting(self, includePics: includePics)
            html += "</p>"
        }
        
        html += "</font></body></html>"
        
        return html
    }

    // item count for this list
    func itemCount() -> Int {
        var count = 0
        
        for category in categories {
            count += category.items.count
        }
        
        return count
    }
}

////////////////////////////////////////////////////////////////
//
//  MARK: - ListObj class
//
////////////////////////////////////////////////////////////////

class ListObj: NSObject {
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
    
    // Designated initializer
    init(name: String?) {
        if let name = name { self.name = name } else { self.name = "" }
        
        self.categoryIndex = 0
        self.itemIndex = 0
        self.needToSave = true
        self.needToDelete = false
        
        super.init()
    }
    
    func tag() -> Int {
        return Tag.tagFromIndices(categoryIndex, itmIdx: itemIndex)
    }
}

////////////////////////////////////////////////////////////////
//
//  MARK: - Category class
//
////////////////////////////////////////////////////////////////

class Category: ListObj, NSCoding {
    var items = [Item]()
    var addItem = AddItem()
    var displayHeader: Bool = true { didSet { needToSave = true } }
    var expanded: Bool = true { didSet { needToSave = true } }
    var modificationDate: Date?
    var categoryRecord: CKRecord?
    var categoryReference: CKRecord.Reference?
    var isTutorialCategory = false
    var itemAddCount: Int32 = 0
    
    // Designated initializer - new category initializer
    init(name: String, displayHeader: Bool, createRecord: Bool, tutorial: Bool = false) {
        self.displayHeader = displayHeader
        self.isTutorialCategory = tutorial
        
        if createRecord {
            // new category needs a new record and reference
            categoryRecord = CKRecord(recordType: CategoriesRecordType, recordID: CKRecord.ID(zoneID: CloudCoordinator.sharedZoneID))
            categoryReference = CKRecord.Reference.init(record: categoryRecord!, action: CKRecord.Reference.Action.deleteSelf)
        }
        
        self.modificationDate = Date.init()
        
        super.init(name: name)
    }
    
    // Designated initializer - memberwise initializer
    init(name: String?, expanded: Bool?, displayHeader: Bool?, tutorial: Bool?, itemAddCount: Int32?, modificationDate: Date?, categoryReference: CKRecord.Reference?, categoryRecord: CKRecord?, items: [Item]?) {
        if let expanded          = expanded          { self.expanded           = expanded          } else { self.expanded           = true          }
        if let displayHeader     = displayHeader     { self.displayHeader      = displayHeader     } else { self.displayHeader      = true          }
        if let modificationDate  = modificationDate  { self.modificationDate   = modificationDate  } else { self.modificationDate   = Date.init()   }
        if let tutorial          = tutorial          { self.isTutorialCategory = tutorial          } else { self.isTutorialCategory = false         }
        if let itemAddCount      = itemAddCount      { self.itemAddCount       = itemAddCount      } else { self.itemAddCount       = 0             }
        if let categoryReference = categoryReference { self.categoryReference  = categoryReference }
        if let categoryRecord    = categoryRecord    { self.categoryRecord     = categoryRecord    }
        if let items             = items             { self.items              = items             }
        
        super.init(name: name)
    }
    
    // Secondary initializer - for unarchiving a category object
    convenience required init?(coder decoder: NSCoder) {
        let name = decoder.decodeObject(forKey: key_name)                           as? String
        let expanded          = decoder.decodeBool(forKey: key_expanded)
        let displayHeader     = decoder.decodeBool(forKey: key_displayHeader)
        let tutorial          = decoder.decodeBool(forKey: key_tutorial)
        let itemAddCount      = decoder.decodeCInt(forKey: key_itemAddCount)        as  Int32
        let modificationDate  = decoder.decodeObject(forKey: key_modificationDate)  as? Date
        let categoryReference = decoder.decodeObject(forKey: key_categoryReference) as? CKRecord.Reference
        let categoryRecord    = decoder.decodeObject(forKey: key_categoryRecord)    as? CKRecord
        let items             = decoder.decodeObject(forKey: key_items)             as? [Item]
        
        self.init(name: name,
                  expanded: expanded,
                  displayHeader: displayHeader,
                  tutorial: tutorial,
                  itemAddCount: itemAddCount,
                  modificationDate: modificationDate,
                  categoryReference: categoryReference,
                  categoryRecord: categoryRecord,
                  items: items)
    }
    
    func encode(with coder: NSCoder) {
        self.modificationDate = Date.init()
        
        coder.encode(self.name,               forKey: key_name)
        coder.encode(self.expanded,           forKey: key_expanded)
        coder.encode(self.displayHeader,      forKey: key_displayHeader)
        coder.encode(self.isTutorialCategory, forKey: key_tutorial)
        coder.encodeCInt(self.itemAddCount,   forKey: key_itemAddCount)
        coder.encode(self.modificationDate,   forKey: key_modificationDate)
        coder.encode(self.categoryReference,  forKey: key_categoryReference)
        coder.encode(self.categoryRecord,     forKey: key_categoryRecord)
        coder.encode(self.items,              forKey: key_items)
    }
    
    // commits this category and its items to cloud storage
    func saveToCloud(listReference: CKRecord.Reference) {
        // don't save the tutorial to the cloud
        if self.isTutorialCategory {
            return
        }
                
        if categoryRecord != nil {
            // commit change to cloud
            if needToDelete {
                deleteRecord(categoryRecord!, database: CloudCoordinator.privateDatabase)
            } else if needToSave || appDelegate.needsDataSaveOnMigration {
                saveRecord(categoryRecord!, listReference: listReference)
            }

        } else {
            print("Can't save category '\(name)' - listRecord is nil...")
        }
        
        // pass on to the items
        if categoryReference != nil {
            for item in items {
                item.saveToCloud(categoryReference: categoryReference!)
            }
        }
    }
    
    // commits just this category to cloud storage
    func saveRecord(_ categoryRecord: CKRecord, listReference: CKRecord.Reference) {
        // don't save the tutorial to the cloud
        if self.isTutorialCategory {
            return
        }
        
        var record = categoryRecord
        
        if categoryRecord.recordID.zoneID.zoneName.contains("default") {
            let recordID = CKRecord.ID(recordName: record.recordID.recordName, zoneID: CloudCoordinator.sharedZoneID)
            let sharedZoneRecord = CKRecord(recordType: CategoriesRecordType, recordID: recordID)
            categoryReference = CKRecord.Reference.init(record: sharedZoneRecord, action: CKRecord.Reference.Action.deleteSelf)
            record = sharedZoneRecord
            self.categoryRecord = sharedZoneRecord
        }
        
        record.setObject(self.name as CKRecordValue?,           forKey: key_name)
        record.setObject(self.displayHeader as CKRecordValue?,  forKey: key_displayHeader)
        record.setObject(self.expanded as CKRecordValue?,       forKey: key_expanded)
        record.setObject(listReference,                         forKey: key_owningList)
        record.setObject(self.order as CKRecordValue?,          forKey: key_order)
        
        // add this record to the batch record array for updating
        CloudCoordinator.addToUpdateRecords(record, obj: self)
    }
    
    // update this category from cloud storage
    func updateFromRecord(_ record: CKRecord) {
        if let name          = record[key_name]          { self.name          = name as! String        }
        if let expanded      = record[key_expanded]      { self.expanded      = expanded as! Bool      }
        if let displayHeader = record[key_displayHeader] { self.displayHeader = displayHeader as! Bool }
        if let order         = record[key_order]         { self.order         = order as! Int          }
        
        if self.categoryRecord != nil {
            let currentOwningListRef = categoryRecord!.object(forKey: key_owningList) as! CKRecord.Reference
            let newOwningListRef = record.object(forKey: key_owningList) as! CKRecord.Reference
            
            if currentOwningListRef.recordID.recordName != newOwningListRef.recordID.recordName {
                // category has moved to another list, need to move the category in local list data
                print("category needs to change lists...!!!")
                
                // get references to source and destination list objects
                let srcList = ListData.getLocalList(currentOwningListRef.recordID.recordName)
                let destList = ListData.getLocalList(newOwningListRef.recordID.recordName)
                
                if let srcList = srcList, let destList = destList {
                    // remove this category from the old list
                    _ = srcList.removeCategory(self, updateIndices: false)
                    
                    // add to the new list
                    // check if we've moved the only category from the old list, if so create a new default category for the old list
                    if srcList.categories.count == 0 {
                        _ = srcList.addCategory("", displayHeader: false, updateIndices: false, createRecord: true)
                    }
                    
                    // check if moving to a list with only a hidden category
                    // if so, then delete if no items, otherwise
                    // make the hidden category unhidden (it will likely have no name)
                    if (destList.categories.count == 1) && (destList.categories[0].displayHeader == false) {
                        let hiddenCategory = destList.categories[0]
                        
                        if hiddenCategory.items.count == 0 {
                            // only existing category is hidden and empty, so delete it (may already
                            // be deleted in cloud from initiating device, but not a problem)
                            hiddenCategory.deleteFromCloud()
                            _ = destList.removeCategory(hiddenCategory, updateIndices: false)
                        } else {
                            hiddenCategory.displayHeader = true
                        }
                    }
                    
                    // append the moving category to the destination list
                    destList.categories.append(self)
                    
                    print("moving category \(self.name) from \(srcList.name) to \(destList.name)")
                }
            }
        }
        
        self.categoryRecord = record
        
        if self.categoryReference == nil {
            self.categoryReference = CKRecord.Reference.init(record: record, action: CKRecord.Reference.Action.deleteSelf)
        }
        
        // category record is now updated
        needToSave = false
    
        //print("updated category: \(category!.name)")
    }
    
    func deleteFromCloud() {
        self.needToDelete = true
        DataPersistenceCoordinator.saveListData(async: true)
    }
    
    // deletes this category from the cloud
    func deleteRecord(_ categoryRecord: CKRecord, database: CKDatabase) {
        // don't save the tutorial to the cloud
        if self.isTutorialCategory {
            return
        }
        
        database.delete(withRecordID: categoryRecord.recordID, completionHandler: { returnRecord, error in
            if let err = error {
                print("Delete Category Error: \(err.localizedDescription)")
            } else {
                print("Success: Category record deleted from cloud '\(self.name)' recordID: \(categoryRecord.recordID.recordName)")
            }
        })
        
        // create a Delete record for this category delete and save to cloud
        createDeleteRecord(database, recordName: categoryRecord.recordID.recordName, objectType: CategoriesRecordType, objectName: self.name)
    }

    func deleteCategoryItemsFromCloudStorage() {
        for item in items {
            item.needToDelete = true
        }
        DataPersistenceCoordinator.saveListData(async: true)
    }
    
    func deleteItems() {
        items.removeAll(keepingCapacity: true)
    }
    
    func clearNeedToSave() {
        self.needToSave = false
        
        for item in items {
            item.clearNeedToSave()
        }
    }
    
    // updates the indices for all items in this category
    func updateIndices(_ catIndex: Int) {
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
    
    func resetItemOrderByPosition() {
        var pos = 0
        for item in items {
            item.order = pos
            pos += 1
        }
    }
    
    // category
    func htmlForPrinting(_ list: List, includePics: Bool) -> String {
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
                    html += item.htmlForPrinting(includePics)
                }
            }
        }
        
        html += "</table>"
        
        return html
    }
    
    // returns the number of completed items in a category
    func itemsComplete() -> Int   { var i=0; for item in items { if item.state == ItemState.complete   { i += 1 } }; return i }
    func itemsActive() -> Int     { var i=0; for item in items { if item.state != ItemState.inactive   { i += 1 } }; return i }
    func itemsInactive() -> Int   { var i=0; for item in items { if item.state == ItemState.inactive   { i += 1 } }; return i }
    func itemsIncomplete() -> Int { var i=0; for item in items { if item.state == ItemState.incomplete { i += 1 } }; return i }
    
}

////////////////////////////////////////////////////////////////
//
//  MARK: - Item class
//
////////////////////////////////////////////////////////////////

class Item: ListObj, NSCoding {
    override var name: String {
        didSet {
            if name  != oldValue {
                needToSave = true
                modifiedBy = UIDevice.current.name
                modifiedDate = Date.init()
                imageAsset?.itemName = self.name
            }
        }
    }
    
    var state: ItemState        { didSet { if state != oldValue { needToSave = true; modifiedBy = UIDevice.current.name; modifiedDate = Date.init() } } }
    var note: String            { didSet { if note  != oldValue { needToSave = true; modifiedBy = UIDevice.current.name; modifiedDate = Date.init() } } }
    var itemRecord: CKRecord?
    var itemReference: CKRecord.Reference?
    var imageAsset: ImageAsset?
    //var isTutorialItem = false
    var createdBy: String           // established locally - saved to cloud
    var createdDate: Date           // established locally - saved to cloud
    var modifiedBy: String          // established locally - saved to cloud
    var modifiedDate: Date   {      // established locally - saved to cloud
        didSet {
            // also set modified by
            modifiedBy = UIDevice.current.name
        }
    }
    var imageModifiedDate: Date {
        didSet {
            // also set modified date
            if imageModifiedDate > modifiedDate {
                modifiedDate = imageModifiedDate
            }
        }
    }
    
    // Designated initializer - new item initializer
    init(name: String, state: ItemState, createRecord: Bool) {
        self.state = state
        self.note = ""
        self.imageAsset = nil
        //self.isTutorialItem = tutorial
        createdBy = UIDevice.current.name
        modifiedBy = UIDevice.current.name
        createdDate = Date.init(timeIntervalSince1970: 0)
        modifiedDate = Date.init(timeIntervalSince1970: 0)
        self.imageModifiedDate = Date.init(timeIntervalSince1970: 0)
        
        if createRecord {
            // a new item needs a new cloud record
            itemRecord = CKRecord(recordType: ItemsRecordType, recordID: CKRecord.ID(zoneID: CloudCoordinator.sharedZoneID))
            itemReference = CKRecord.Reference.init(record: itemRecord!, action: CKRecord.Reference.Action.deleteSelf)
            
            imageAsset = ImageAsset(itemName: name, itemReference: itemReference!)
            createdBy = UIDevice.current.name
            modifiedBy = UIDevice.current.name
            createdDate = Date.init()
            modifiedDate = Date.init()
        }
        
        if imageAsset != nil {
            imageAsset!.itemName = name
        }
        
        super.init(name: name)
    }

    // Designated memberwise initializer
    init(name: String?, note: String?, imageAsset: ImageAsset?, state: ItemState, itemRecord: CKRecord?, itemReference: CKRecord.Reference?, createdBy: String?, createdDate: Date?, modifiedBy: String?, modifiedDate: Date?, imageModifiedDate: Date?) {
        if let note               = note              { self.note              = note              } else { self.note              = ""                                                                          }
        if let itemRecord         = itemRecord        { self.itemRecord        = itemRecord        } else { self.itemRecord        = nil                                                                         }
        if let createdBy          = createdBy         { self.createdBy         = createdBy         } else { self.createdBy         = UIDevice.current.name                                                       }
        if let createdDate        = createdDate       { self.createdDate       = createdDate       } else { self.createdDate       = Date.init(timeIntervalSince1970: 0)                                         }
        if let modifiedBy         = modifiedBy        { self.modifiedBy        = modifiedBy        } else { self.modifiedBy        = UIDevice.current.name                                                       }
        if let modifiedDate       = modifiedDate      { self.modifiedDate      = modifiedDate      } else { self.modifiedDate      = Date.init(timeIntervalSince1970: 0)                                         }
        if let imageModifiedDate  = imageModifiedDate { self.imageModifiedDate = imageModifiedDate } else { self.imageModifiedDate = Date.init(timeIntervalSince1970: 0)                                         }
        if let itemReference      = itemReference     { self.itemReference     = itemReference     } else { self.itemReference     = CKRecord.Reference.init(record: itemRecord!, action: CKRecord.Reference.Action.deleteSelf) }
        if let imageAsset         = imageAsset {
            self.imageAsset = imageAsset
            self.imageAsset!.itemName = name
            //print("*** Item memberwise initializer set imageAsset.itemName to \(name)")
        } else {
            self.imageAsset = ImageAsset(itemName: name, itemReference: self.itemReference!)
            //print("*** Item memberwise initializer is initializing the ImageAsset...")
        }
        
        self.state = state
        
        super.init(name: name)
    }
    
    // Secondary initializer - for unarchiving an item object
    convenience required init?(coder decoder: NSCoder) {
        let name              = decoder.decodeObject(forKey: key_name)              as? String
        let note              = decoder.decodeObject(forKey: key_note)              as? String
        let imageAsset        = decoder.decodeObject(forKey: key_imageAsset)        as? ImageAsset
        let createdBy         = decoder.decodeObject(forKey: key_createdBy)         as? String
        let createdDate       = decoder.decodeObject(forKey: key_createdDate)       as? Date
        let modifiedBy        = decoder.decodeObject(forKey: key_modifiedBy)        as? String
        let modifiedDate      = decoder.decodeObject(forKey: key_modifiedDate)      as? Date
        let imageModifiedDate = decoder.decodeObject(forKey: key_imageModifiedDate) as? Date
        let itemRecord        = decoder.decodeObject(forKey: key_itemRecord)        as? CKRecord
        let itemReference     = decoder.decodeObject(forKey: key_itemReference)     as? CKRecord.Reference
        let state             = decoder.decodeCInt(forKey: key_state)
        let itemState         = state == 0 ? ItemState.inactive : state == 1 ? ItemState.incomplete : ItemState.complete
        
        self.init(name: name,
                  note: note,
                  imageAsset: imageAsset,
                  state: itemState,
                  //tutorial: tutorial,
                  itemRecord: itemRecord,
                  itemReference: itemReference,
                  createdBy: createdBy,
                  createdDate: createdDate,
                  modifiedBy: modifiedBy,
                  modifiedDate: modifiedDate,
                  imageModifiedDate: imageModifiedDate)
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.name,              forKey: key_name)
        coder.encode(self.note,              forKey: key_note)
        coder.encode(self.imageAsset,        forKey: key_imageAsset)
        coder.encode(self.createdBy,         forKey: key_createdBy)
        coder.encode(self.createdDate,       forKey: key_createdDate)
        coder.encode(self.modifiedBy,        forKey: key_modifiedBy)
        coder.encode(self.modifiedDate,      forKey: key_modifiedDate)
        coder.encode(self.imageModifiedDate, forKey: key_imageModifiedDate)
        coder.encode(self.itemRecord,        forKey: key_itemRecord)
        coder.encode(self.itemReference,     forKey: key_itemReference)
        coder.encode(self.state.rawValue,    forKey: key_state)
    }
    
    // commits this item change to cloud storage
    func saveToCloud(categoryReference: CKRecord.Reference) {
        if needToDelete {
            deleteRecord(itemRecord!, database: CloudCoordinator.privateDatabase)
        } else if needToSave || appDelegate.needsDataSaveOnMigration {
            saveRecord(itemRecord!, categoryReference: categoryReference)
        }
        
        // pass save on to the imageAsset
        if imageAsset != nil && itemReference != nil  {
            imageAsset!.itemName = self.name
            imageAsset!.saveToCloud(itemReference!)
        } else {
            print("******* ERROR in item - saveToCloud: imageAsset or itemReference is nil...")
        }
    }
    
    // cloud storage method for this item
    func saveRecord(_ itemRecord: CKRecord, categoryReference: CKRecord.Reference) {
        var record = itemRecord
        
        if itemRecord.recordID.zoneID.zoneName.contains("default") {
            let recordID = CKRecord.ID(recordName: record.recordID.recordName, zoneID: CloudCoordinator.sharedZoneID)
            let sharedZoneRecord = CKRecord(recordType: ItemsRecordType, recordID: recordID)
            itemReference = CKRecord.Reference.init(record: sharedZoneRecord, action: CKRecord.Reference.Action.deleteSelf)
            record = sharedZoneRecord
            self.itemRecord = sharedZoneRecord
        }
        
        record[key_name] = self.name as CKRecordValue?
        record[key_note] = self.note as CKRecordValue?
        record[key_state] = self.state.rawValue as CKRecordValue?
        record[key_owningCategory] = categoryReference
        record[key_order] = self.order as CKRecordValue?
        record[key_createdBy] = self.createdBy as CKRecordValue?
        record[key_createdDate] = self.createdDate as CKRecordValue?
        record[key_modifiedBy] = self.modifiedBy as CKRecordValue?
        record[key_modifiedDate] = self.modifiedDate as CKRecordValue?
        record[key_imageModifiedDate] = self.imageModifiedDate as CKRecordValue?
        
        // add this record to the batch record array for updating
        CloudCoordinator.addToUpdateRecords(record, obj: self)
    }
    
    // update this item from cloud storage
    func updateFromRecord(_ record: CKRecord) {
        if let itemState = record[key_state] as? Int {
            self.state = itemState == 0 ? ItemState.inactive : itemState == 1 ? ItemState.incomplete : ItemState.complete
        } else {
            self.state = ItemState.incomplete
        }
        
        if let name              = record[key_name]              { self.name              = name as! String            }
        if let note              = record[key_note]              { self.note              = note as! String            }
        if let order             = record[key_order]             { self.order             = order as! Int              }
        if let createdBy         = record[key_createdBy]         { self.createdBy         = createdBy as! String       }
        if let createdDate       = record[key_createdDate]       { self.createdDate       = createdDate as! Date       }
        if let modifiedDate      = record[key_modifiedDate]      { self.modifiedDate      = modifiedDate as! Date      }
        // modifiedBy is handled later
        
        // update item record, reference, and image asset (if needed)
        self.itemRecord = record
        self.itemReference = CKRecord.Reference.init(record: record, action: CKRecord.Reference.Action.deleteSelf)
        
        if self.imageAsset == nil {
            self.imageAsset = ImageAsset(itemName: self.name, itemReference: itemReference!)
        }
        
        // if the cloud imageModifiedDate is newer than local then we need to schedule the imageAsset for this item to be pulled
        if let recordImageModifiedDate = record[key_imageModifiedDate] as? Date {
            if recordImageModifiedDate > self.imageModifiedDate || (recordImageModifiedDate == self.imageModifiedDate &&
                                                                    recordImageModifiedDate != Date.init(timeIntervalSince1970: 0) &&
                                                                    self.imageAsset?.image == nil) {
                // a newer image for this item exists
                // add this imageAsset to the array needing fetching
                if imageAsset != nil {
                    //print("ImageAsset.updateFromRecord - itemRecordID for \(self.name) was added to the itemReferences for image update...")
                    DataPersistenceCoordinator.addToItemReferences(self.itemReference!)
                } else {
                    print("******* ERROR in item updateFromRecord - the imageAsset for this item is nil...!!!")
                }
                
                // then set the local item imageModifiedDate to cloud value
                self.imageModifiedDate = recordImageModifiedDate
            }
        }
        
        // check date values after update from cloud record - reset if needed
        if self.modifiedDate == Date.init(timeIntervalSince1970: 0) {
            self.modifiedDate = Date.init()
        }
        
        if self.createdDate == Date.init(timeIntervalSince1970: 0) {
            self.createdDate = self.modifiedDate
        }
        
        // reset modifiedBy after changes
        if let modifiedBy = record[key_modifiedBy] { self.modifiedBy = modifiedBy as! String }
        
        let currentCategory = ListData.getCategoryForItem(self)     // current category by doing a category item search in the list data
        let updateCategory = getCategoryFromReference(record)       // destination category from the update record
        
        if currentCategory != updateCategory {
            // delete item from current category
            if currentCategory != nil {
                //currentCategory!.items.removeObject(self)
                let index = currentCategory!.items.firstIndex(of: self)
                if index != nil {
                    currentCategory!.items.remove(at: index!)
                    print("Item Move: deleted \(self.name) from \(currentCategory!.name)")
                }
            }
            
            // add item to new category
            if self.order >= 0 {
                if self.order < updateCategory!.items.count {
                    updateCategory!.items.insert(self, at: self.order)
                } else {
                    updateCategory!.items.append(self)
                }
                print("Item Move: inserted \(self.name) in \(updateCategory!.name) at pos \(self.order)")
            }
        }
        
        // item record is now updated
        needToSave = false
        //print("updated item: \(item.name)")
    }
    
    // deletes this item from the cloud (any attached imageAsset will also be deleted)
    func deleteRecord(_ itemRecord: CKRecord, database: CKDatabase) {
        // don't save the tutorial to the cloud
        // if self.isTutorialItem {
        //    return
        // }
        
        database.delete(withRecordID: itemRecord.recordID, completionHandler: { returnRecord, error in
            if let err = error {
                print("Delete Item Error for '\(self.name)': \(err.localizedDescription)")
            } else {
                print("Success: Item record deleted successfully '\(self.name)' recordID: \(String(describing: self.itemRecord?.recordID.recordName))")
            }
        })
        
        // create a Delete record for this item delete and save to cloud
        createDeleteRecord(database, recordName: itemRecord.recordID.recordName, objectType: ItemsRecordType, objectName: self.name)
    }
    
    func deleteFromCloud() {
        self.needToDelete = true
        DataPersistenceCoordinator.saveListData(async: true)
    }
    
    func clearNeedToSave() {
        self.needToSave = false
        self.imageAsset?.needToSave = false
    }
    
    // item
    func htmlForPrinting(_ includePics: Bool) -> String {
        var html = ""
        
        // state
        var stateLabel = ""
        
        switch state {
        case .complete:    stateLabel = "&nbsp;☑︎"
        case .inactive:    stateLabel = "&nbsp;"
        case .incomplete:  stateLabel = "&nbsp;☐"
        }
        
        // name
        if self.state == .inactive {
            html += "<tr><td>\(stateLabel)</td><td><font size='3'; color='gray'>\(self.name)</font></td></tr>"
        } else {
            html += "<tr><td>\(stateLabel)</td><td><font size='3'>\(self.name)</td></tr>"
        }
        
        // note
        if appDelegate.printNotes && self.note.count > 0 {
            html += "<tr><td></td><td><div class='tab'><font size='2'; color='gray'>\(self.note)</font></div></td></tr>"
        }
        
        // image
        if appDelegate.printNotes && includePics {
            if let image = imageAsset?.image {
                let resizedImage = resizeImage(image, newWidth: 120)
                let imageData = resizedImage.jpegData(compressionQuality: jpegCompressionQuality)
                if let imageData = imageData {
                    let base64String = imageData.base64EncodedString(options: .lineLength64Characters)
                    html += "<tr><td></td><td><b><img src='data:image/jpeg;base64,\(base64String)' width='120' height='90' align='left' border='0' alt='Item Image' ></b></td></tr>"
                }
            }
        }
        
        return html
    }
    
    func setImage(_ image: UIImage?) {
        if imageAsset == nil {
            print("******* ERROR: imageAsset for \(self.name) is nil!!! *******")
            return
        }
        
        if self.imageAsset!.setItemImage(image) {
            // image was updated
            self.imageAsset!.itemName = self.name
            self.imageModifiedDate = Date.init()
            self.needToSave = true
        }
    }
    
    func getImage() -> UIImage? {
        return imageAsset?.getItemImage()
    }
    
    func addImageAsset() -> ImageAsset? {
        var imageAsset: ImageAsset?
        
        if self.itemReference != nil {
            imageAsset = ImageAsset(itemName: self.name, itemReference: self.itemReference!)
            self.imageAsset = imageAsset
        }
        
        return imageAsset
    }
}

////////////////////////////////////////////////////////////////
//
//  MARK: - ImageAsset class
//
////////////////////////////////////////////////////////////////

class ImageAsset: NSObject, NSCoding {
    var itemName: String!
    var image: UIImage?
    var imageData: Data?
    var imageGUID: String
    var imageFileURL: URL?
    var itemReference: CKRecord.Reference?
    var imageAsset: CKAsset?
    var imageRecord: CKRecord
    var modifiedDate: Date   {    // established locally - saved to cloud
        didSet {
            // only update if new date is newer than the currently held date
            if oldValue > modifiedDate {
                modifiedDate = oldValue
            }
        }
    }
    var needToSave: Bool
    var needToDelete: Bool
    
    // Designated initializer - new item initializer
    init(itemName: String?, itemReference: CKRecord.Reference) {
        var name = ""
        if itemName != nil {
            name = itemName!
        }
        self.itemName = name
        self.image = nil
        self.imageData = nil
        self.imageGUID = UUID().uuidString
        self.imageFileURL = nil
        self.itemReference = itemReference
        self.needToSave = false
        self.needToDelete = false
        self.imageRecord = CKRecord(recordType: ImagesRecordType, recordID: CKRecord.ID(zoneID: CloudCoordinator.sharedZoneID))
        self.modifiedDate = Date.init()
        
        super.init()
    }
    
    // Designated memberwise initializer
    init(itemName: String?, imageData: Data?, imageGUID: String?, imageAsset: CKAsset?, itemReference: CKRecord.Reference?, imageRecord: CKRecord?, modifiedDate: Date?) {
        if let itemName      = itemName      { self.itemName      = itemName      } else { self.itemName      = ""                                          }
        if let imageData     = imageData     { self.imageData     = imageData     } else { self.imageData     = nil                                         }
        if let imageGUID     = imageGUID     { self.imageGUID     = imageGUID     } else { self.imageGUID     = UUID().uuidString                           }
        if let imageRecord   = imageRecord   { self.imageRecord   = imageRecord   } else { self.imageRecord   = CKRecord(recordType: ImagesRecordType, recordID: CKRecord.ID(zoneID: CloudCoordinator.sharedZoneID)) }
        if let modifiedDate  = modifiedDate  { self.modifiedDate  = modifiedDate  } else { self.modifiedDate  = Date.init(timeIntervalSince1970: 0)         }
        
        if itemReference != nil {
            self.itemReference = itemReference
        } else {
            print("*** ERROR: itemReference is nil in itemAsset initializer...")
        }
        
        // restore image from imageData
        if let imageData = self.imageData {
            self.image = UIImage(data: imageData)
        }

        self.needToSave = false
        self.needToDelete = false
        self.imageFileURL = nil
        
        super.init()
    }
    
    // encoder
    func encode(with coder: NSCoder) {
        coder.encode(self.itemName,      forKey: key_itemName)
        coder.encode(self.imageGUID,     forKey: key_imageGUID)
        coder.encode(self.itemReference, forKey: key_itemReference)
        coder.encode(self.imageAsset,    forKey: key_imageAsset)
        coder.encode(self.imageRecord,   forKey: key_imageRecord)
        coder.encode(self.modifiedDate,  forKey: key_modifiedDate)
        
        // encode the image data pulled from local storage
        if image != nil && imageData == nil {
            // if image came from cloud data then we have an image but no image data
            // so need a one-time conversion of image to JPEG NSData and encode
            imageData = image!.jpegData(compressionQuality: jpegCompressionQuality)
            //print("imageAsset - converted image to image data for encoding: \(String(describing: itemName))")
        }
        coder.encode(self.imageData,     forKey: key_imageData)
    }
    
    // decoder - Secondary initializer - for unarchiving an ImageAsset object
    convenience required init?(coder decoder: NSCoder) {
        let itemName      = decoder.decodeObject(forKey: key_name)          as? String
        let imageGUID     = decoder.decodeObject(forKey: key_imageGUID)     as? String
        let itemReference = decoder.decodeObject(forKey: key_itemReference) as? CKRecord.Reference
        let imageAsset    = decoder.decodeObject(forKey: key_imageAsset)    as? CKAsset
        let imageRecord   = decoder.decodeObject(forKey: key_imageRecord)   as? CKRecord
        let modifiedDate  = decoder.decodeObject(forKey: key_modifiedDate)  as? Date
        let imageData     = decoder.decodeObject(forKey: key_imageData)     as? Data
        
        self.init(itemName:      itemName,
                  imageData:     imageData,
                  imageGUID:     imageGUID,
                  imageAsset:    imageAsset,
                  itemReference: itemReference,
                  imageRecord:   imageRecord,
                  modifiedDate:  modifiedDate)
    }
    
    // commits the image to cloud storage (if needed)
    func saveToCloud(_ itemReference: CKRecord.Reference) {
        if needToSave || appDelegate.needsDataSaveOnMigration {
            saveRecord(imageRecord, itemReference: itemReference)
        } else if needToDelete {
            deleteRecord(imageRecord)
        }
    }
    
    // cloud storage method for this image
    func saveRecord(_ imageRecord: CKRecord, itemReference: CKRecord.Reference) {
        guard image != nil else { return }
        
        var record = imageRecord
        
        if imageRecord.recordID.zoneID.zoneName.contains("default") {
            let recordID = CKRecord.ID(recordName: record.recordID.recordName, zoneID: CloudCoordinator.sharedZoneID)
            let sharedZoneRecord = CKRecord(recordType: ImagesRecordType, recordID: recordID)
            record = sharedZoneRecord
            self.imageRecord = sharedZoneRecord
        }
        
        record[key_itemName]      = self.itemName as CKRecordValue?
        record[key_imageGUID]     = self.imageGUID as CKRecordValue?
        record[key_owningItem]    = itemReference
        record[key_modifiedDate]  = self.modifiedDate as CKRecordValue?
        record[key_imageAsset]    = self.imageAsset
        
        // add this record to the batch record array for updating
        CloudCoordinator.addToUpdateRecords(record, obj: self)
    }
    
    // deletes the image from the cloud by setting the
    // image asset to nil in the imageRecord and updating
    func deleteRecord(_ imageRecord: CKRecord) {
        imageRecord[key_modifiedDate]  = self.modifiedDate as CKRecordValue?
        imageRecord[key_imageAsset]    = nil
        
        // add this record to the batch record array for updating
        CloudCoordinator.addToUpdateRecords(imageRecord, obj: self)
    }

    // update this image from cloud storage
    func updateFromRecord(_ record: CKRecord) {
        // does the item need to be notified when the imageAsset is updated???
        if let item = getItemFromReference(record) {
            item.imageAsset = self
        } else {
            print("ERROR: imageAsset.updateFromRecord - owning item not found...")
        }
        
        if let itemName      = record[key_itemName]     { self.itemName      = (itemName     as! String)            }
        if let imageGUID     = record[key_imageGUID]    { self.imageGUID     = imageGUID     as! String             }
        if let itemReference = record[key_owningItem]   { self.itemReference = itemReference as? CKRecord.Reference }
        if let imageAsset    = record[key_imageAsset]   { self.imageAsset    = imageAsset    as? CKAsset            }
        if let modifiedDate  = record[key_modifiedDate] { self.modifiedDate  = modifiedDate  as! Date               }
        
        // check date values after update from cloud record - reset if needed
        if self.modifiedDate.compare(Date.init(timeIntervalSince1970: 0)) == ComparisonResult.orderedSame {
            self.modifiedDate = Date.init()
        }
        
        // unwrap the image from the asset
        if let path = imageAsset?.fileURL!.path {
            let image = UIImage(contentsOfFile: path)
            self.image = image
            //print("ImageAsset.updateFromRecord: got image update for \(imageGUID)...")
        }
        
        self.imageRecord = record
        
        // image record is now updated
        needToSave = false
    }
    
    func deleteFromCloud() {
        self.needToDelete = true
        DataPersistenceCoordinator.saveListData(async: true)
    }
    
    // writes the image to local file for uploading to cloud
    func setItemImage(_ image: UIImage?) -> Bool {
        var imageWasUpdated = false
        self.needToSave = false
        
        if self.image != image {
            print("setItemImage - new image is different than old: \(String(describing: itemName))")
            self.image = image
            imageWasUpdated = true
            
            if self.image != nil {
                do {
                    let dirPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
                    let docsDir: AnyObject = dirPaths[0] as AnyObject
                    self.imageFileURL = URL(fileURLWithPath: docsDir.appendingPathComponent(self.imageGUID + ".png"))
                    
                    //try UIImagePNGRepresentation(image!)!.writeToURL(imageFileURL!, options: .AtomicWrite)    // without compression
                    self.imageData = image!.jpegData(compressionQuality: jpegCompressionQuality)                // compress to JPG - imageData is used for local storage
                    try self.imageData!.write(to: imageFileURL!, options: .atomicWrite)                         // write compressed file
                    
                    self.imageAsset = CKAsset(fileURL: imageFileURL!)
                    self.needToSave = true
                } catch {
                    print("*** ERROR: setItemImage: \(error)")
                }
            } else {
                // delete current image from cloud
                self.deleteFromCloud()
                self.imageData = nil
            }
        } else {
            print("setItemImage - new image is the same as old image...")
        }
        
        return imageWasUpdated
    }
    
    func getItemImage() -> UIImage? {
        return self.image
    }
    
    // called after the image file is uploaded to cloud storage
    func deleteImageFile() {
        if self.imageFileURL != nil {
            let fileManager = FileManager.default
            
            do {
                try fileManager.removeItem(at: self.imageFileURL!)
                print("ItemAsset.deleteImageFile - delete was successful for \(self.imageGUID)!")
            }
            catch let error as NSError {
                print("*** ERROR in deleteImageFile: \(error)")
            }
        }
        
        self.imageFileURL = nil
    }
    
}

////////////////////////////////////////////////////////////////
//
//  MARK: - AddItem class
//
////////////////////////////////////////////////////////////////

class AddItem: ListObj {
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

struct Tag {
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
    
    static func tagFromIndices(_ catIdx: Int, itmIdx: Int) -> Int {
        return catIdx * kItemIndexMax + itmIdx
    }
    
    static func indicesFromTag(_ tag: Int) -> (catIdx: Int, itmIdx: Int) {
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

