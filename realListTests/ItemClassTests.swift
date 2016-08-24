//
//  ItemClassTests.swift
//  EnList
//
//  Created by Steven Gentry on 8/23/16.
//  Copyright © 2016 Steven Gentry. All rights reserved.
//

import XCTest
@testable import EnList

class ItemClassTests: ModelClassTests
{
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    //func indexForCategory(category: Category) -> Int
    func test_indexForCategory()
    {
        // given
        //  indices should already be set
        
        // then
        for list in lists {
            var expectedIndex = 0
            for cat in list.categories {
                let index = list.indexForCategory(cat)
                NSLog("index \(index)  expectedIndex \(expectedIndex)")
                XCTAssertTrue(expectedIndex == index, "indexForCategory")
                expectedIndex += 1
            }
        }
    }
    
    // func addCategory(name: String, displayHeader: Bool, updateIndices: Bool, createRecord: Bool, tutorial: Bool = false) -> Category
    func test_addCategory()
    {
        // given
        let list = lists[0]
        let cat = list.addCategory("Added Category", displayHeader: true, updateIndices: true, createRecord: true)
        
        // then
        XCTAssertTrue(list.categories.count == 4, "addCategory count")
        XCTAssertTrue(cat.name == "Added Category", "addCategory name")
        XCTAssertTrue(cat.categoryIndex == 3, "addCategory index")
    }
    
    // func addItem(category: Category, name: String, state: ItemState, updateIndices: Bool, createRecord: Bool, tutorial: Bool = false) -> Item?
    func test_addItem()
    {
        // given
        let list = lists[0]
        let cat = list.categories[0]
        let item = list.addItem(cat, name: "Added Item", state: .Complete, updateIndices: true, createRecord: true)
        
        // then
        XCTAssertNotNil(item, "")
        XCTAssertTrue(item!.name == "Added Item", "addItem name")
        XCTAssertTrue(cat.items.count == 4, "addItem category count")
    }
    
    // func setAllItemsIncomplete()
    func test_setAllItemsIncomplete()
    {
        let list = lists[0]
        
        // given
        list.setAllItemsIncomplete()
        
        // then
        for cat in list.categories {
            for item in cat.items {
                XCTAssertTrue(item.state == .Incomplete, "setAllItemsIncomplete state")
            }
        }
    }
    
    // func setAllItemsInactive()
    func test_setAllItemsInactive()
    {
        let list = lists[0]
        
        // given
        list.setAllItemsInactive()
        
        // then
        for cat in list.categories {
            for item in cat.items {
                XCTAssertTrue(item.state == .Inactive, "setAllItemsInactive state")
            }
        }
    }
    
    // func clearNeedToSave()
    func test_clearNeedToSave()
    {
        // given
        for list in lists {
            list.clearNeedToSave()
        }
        
        // then
        for list in lists {
            XCTAssertTrue(list.needToSave == false, "clearNeedToSave list")
            
            for cat in list.categories {
                XCTAssertTrue(cat.needToSave == false, "clearNeedToSave category")
                
                for item in cat.items {
                    XCTAssertTrue(item.needToSave == false, "clearNeedToSave item")
                    XCTAssertTrue(item.imageAsset?.needToSave == false, "clearNeedToSave image asset")
                }
            }
        }
    }
    
    // func removeItem(item: Item, updateIndices: Bool) -> [NSIndexPath]
    func test_removeItem()
    {
        let list = lists[1]
        let cat = list.categories[1]
        let removedItem = cat.items[1]
        
        // given
        let indexPath = list.removeItem(removedItem, updateIndices: true)
        
        // then
        XCTAssertTrue(indexPath[0].row == 7, "removeItem indexPath check")
        
        for list in lists {
            for cat in list.categories {
                for item in cat.items {
                    XCTAssertTrue(item != removedItem, "removeItem item compare")
                }
            }
        }
        
        XCTAssertTrue(cat.items.count == 2, "removeItem items count")
    }
    
    // func removeCategory(category: Category, updateIndices: Bool) -> [NSIndexPath]
    func test_removeCategory()
    {
        let list = lists[1]
        let removedCat = list.categories[1]
        
        // given
        let indexPath = list.removeCategory(removedCat, updateIndices: true)
        
        // then
        XCTAssertTrue(indexPath[0].row == 5, "removeCategory indexPath check")
        
        for list in lists {
            for cat in list.categories {
                XCTAssertTrue(cat != removedCat, "removeCategory category compare")
            }
        }
        
        XCTAssertTrue(list.categories.count == 2, "removeCategory items count")
    }
    
    // func insertItem(item: Item, afterObj: ListObj, updateIndices: Bool)
    func test_insertItem_afterItem()
    {
        let list = lists[1]
        let cat = list.categories[1]
        let targetItem = cat.items[1]
        let newItem = Item.init(name: "Added Item", state: .Complete, createRecord: true)
        
        // given
        list.insertItem(newItem, afterObj: targetItem, updateIndices: true)
        
        // then
        let testItem = cat.items[2]
        XCTAssertTrue(testItem === newItem, "insertItem_afterItem location check")
        XCTAssertTrue(cat.items.count == 4, "insertItem_afterItem items count")
    }
    
    // func insertItem(item: Item, beforeObj: ListObj, updateIndices: Bool) -> Category
    func test_insertItem_beforeItem()
    {
        let list = lists[1]
        let cat = list.categories[1]
        let targetItem = cat.items[1]
        let newItem = Item.init(name: "Added Item", state: .Complete, createRecord: true)
        
        // given
        list.insertItem(newItem, beforeObj: targetItem, updateIndices: true)
        
        // then
        let testItem1 = cat.items[1]
        let testItem2 = cat.items[2]
        XCTAssertTrue(testItem1 === newItem, "insertItem_beforeItem testItem1 location check")
        XCTAssertTrue(testItem2 === targetItem, "insertItem_beforeItem testItem2 location check")
        XCTAssertTrue(cat.items.count == 4, "insertItem items count")
    }
    
    // func insertItem(item: Item, inCategory: Category, atPosition: InsertPosition, updateIndices: Bool)
    func test_insertItem_inCategory()
    {
        let list = lists[1]
        let cat = list.categories[1]
        let newItemBeginning = Item.init(name: "Added Item Beginning", state: .Complete, createRecord: true)
        let newItemEnd = Item.init(name: "Added Item End", state: .Complete, createRecord: true)
        
        // given
        list.insertItem(newItemBeginning, inCategory: cat, atPosition: .Beginning, updateIndices: true)
        list.insertItem(newItemEnd, inCategory: cat, atPosition: .End, updateIndices: true)
        
        // then
        let testItemBeginning = cat.items[0]
        let testItemEnd = cat.items[cat.items.count-1]
        XCTAssertTrue(testItemBeginning === newItemBeginning, "insertItem_inCategory beginning item location check")
        XCTAssertTrue(testItemEnd === newItemEnd, "insertItem_inCategory end item location check")
        XCTAssertTrue(cat.items.count == 5, "insertItem items count")
    }
    
    // func removeListObjAtIndexPath(indexPath: NSIndexPath, preserveCategories: Bool, updateIndices: Bool) -> [NSIndexPath]
    func test_removeListObjAtIndexPath_item()
    {
        let list = lists[1]
        let indexPath = NSIndexPath.init(forRow: 2, inSection: 0)
        
        // given
        let targetItem = list.itemForIndexPath(indexPath)
        let returnIndexPath = list.removeListObjAtIndexPath(indexPath, preserveCategories: true, updateIndices: true)
        
        // then
        for list in lists {
            for cat in list.categories {
                for item in cat.items {
                    XCTAssertTrue(item != targetItem, "removeListObjAtIndexPath_item item compare")
                }
            }
        }
        
        XCTAssertNotNil(targetItem, "removeListObjAtIndexPath_item target not nil")
        XCTAssertTrue(returnIndexPath.count == 1, "removeListObjAtIndexPath_item indexPath count")
        XCTAssertTrue(indexPath.row == returnIndexPath[0].row, "removeListObjAtIndexPath_item indexPath compare")
    }
    
    func test_removeListObjAtIndexPath_category()
    {
        let list = lists[1]
        let indexPath = NSIndexPath.init(forRow: 5, inSection: 0)
        
        // given
        let targetCategory = list.categoryForIndexPath(indexPath)
        let returnIndexPath = list.removeListObjAtIndexPath(indexPath, preserveCategories: false, updateIndices: true)
        
        // then
        for list in lists {
            for cat in list.categories {
                XCTAssertTrue(cat != targetCategory, "removeListObjAtIndexPath_category category compare")
            }
        }
        
        XCTAssertNotNil(targetCategory, "removeListObjAtIndexPath_category targetCategory not nil")
        XCTAssertTrue(returnIndexPath.count == 5, "removeListObjAtIndexPath_category indexPath count")
        XCTAssertTrue(returnIndexPath.contains(NSIndexPath.init(forRow: 5, inSection: 0)), "removeListObjAtIndexPath_category indexPath compare")
        XCTAssertTrue(returnIndexPath.contains(NSIndexPath.init(forRow: 6, inSection: 0)), "removeListObjAtIndexPath_category indexPath compare")
        XCTAssertTrue(returnIndexPath.contains(NSIndexPath.init(forRow: 7, inSection: 0)), "removeListObjAtIndexPath_category indexPath compare")
        XCTAssertTrue(returnIndexPath.contains(NSIndexPath.init(forRow: 8, inSection: 0)), "removeListObjAtIndexPath_category indexPath compare")
        XCTAssertTrue(returnIndexPath.contains(NSIndexPath.init(forRow: 9, inSection: 0)), "removeListObjAtIndexPath_category indexPath compare")
    }
    
    // func insertItemAtIndexPath(item: Item, indexPath: NSIndexPath, atPosition: InsertPosition, updateIndices: Bool)
    // func insertCategory(category: Category, atIndex: Int)
    // func updateIndices()
    // func resetCategoryAndItemOrderByPosition()
    // func resetCategoryOrderByPosition()
    // func totalDisplayCount() -> Int
    // func categoryForTag(tag: Int) -> Category?
    // func itemForTag(tag: Int) -> Item?
    // func objectForTag(tag: Int) -> ListObj?
    // func categoryForObj(item: ListObj) -> Category?
    // func categoryForIndexPath(indexPath: NSIndexPath) -> Category?
    // func itemForIndexPath(indexPath: NSIndexPath) -> Item?
    // func objectForIndexPath(indexPath: NSIndexPath) -> ListObj?
    // func displayIndexPathForTag(tag: Int) -> NSIndexPath?
    // func displayIndexPathForObj(obj: ListObj) -> (indexPath: NSIndexPath?, isItem: Bool)
    // func displayIndexPathForCategory(category: Category) -> NSIndexPath?
    // func displayIndexPathForItem(item: Item) -> NSIndexPath?
    // func displayIndexPathForAddItemInCategory(category: Category) -> NSIndexPath?
    // func displayIndexPathsForCategoryFromIndexPath(indexPath: NSIndexPath, includeCategoryAndAddItemIndexPaths: Bool) -> [NSIndexPath]
    // func displayIndexPathsForCategory(category: Category, includeAddItemIndexPath: Bool) -> [NSIndexPath]
    // func indexPathsForCompletedRows() -> [NSIndexPath]
    // func indexPathsForInactiveRows() -> [NSIndexPath]
    // func titleForObjectAtIndexPath(indexPath: NSIndexPath) -> String?
    // func updateObjNameAtTag(tag: Int, name: String)
    // func isDisplayedItem(item: Item) -> Bool
    // func indexPathIsLastRowDisplayed(indexPath: NSIndexPath) -> Bool
    // func tagForIndexPath(indexPath: NSIndexPath) -> Tag
    // func tagValueForIndexPath(indexPath: NSIndexPath) -> Int
    // func htmlForPrinting(includePics: Bool) -> String
    // func itemCount() -> Int
    
    func DISABLE_testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
