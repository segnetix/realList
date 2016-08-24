//
//  ListClassTests.swift
//  EnList
//
//  Created by Steven Gentry on 8/23/16.
//  Copyright © 2016 Steven Gentry. All rights reserved.
//

import XCTest
@testable import EnList

class ListClassTests: ModelClassTests
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
        list.insertItem(newItemBeginning, inCategory: cat, atPosition: .Beginning, updateIndices: false)
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
    /// Will insert the item at the indexPath.
    /// If the path is to a category, then will insert at beginning or end of category depending on move direction.
    func test_insertItemAtIndexPath()
    {
        let list = lists[1]
        let cat = list.categories[1]
        var indexPath = NSIndexPath.init(forRow: 7, inSection: 0)
        let newItem = Item.init(name: "Added Item", state: .Complete, createRecord: true)
        let newItemBeginning = Item.init(name: "Added Item Beginning", state: .Complete, createRecord: true)
        let newItemEnd = Item.init(name: "Added Item End", state: .Complete, createRecord: true)
        
        // given
        list.insertItemAtIndexPath(newItem, indexPath: indexPath, atPosition: .Middle, updateIndices: false)
        let testItem = cat.items[1]
        indexPath = NSIndexPath.init(forRow: 5, inSection: 0)
        list.insertItemAtIndexPath(newItemBeginning, indexPath: indexPath, atPosition: .Beginning, updateIndices: false)
        list.insertItemAtIndexPath(newItemEnd, indexPath: indexPath, atPosition: .End, updateIndices: true)
        
        // then
        let testItemBeginning = cat.items[0]
        let testItemEnd = cat.items[cat.items.count-1]
        XCTAssertTrue(testItem === newItem, "insertItemAtIndexPath item insert location check")
        XCTAssertTrue(testItemBeginning === newItemBeginning, "insertItemAtIndexPath beginning item location check")
        XCTAssertTrue(testItemEnd === newItemEnd, "insertItemAtIndexPath end item location check")
        XCTAssertTrue(cat.items.count == 6, "insertItemAtIndexPath items count")
    }
    
    // func insertCategory(category: Category, atIndex: Int)
    func test_insertCategory()
    {
        let list = lists[1]
        let cat = EnList.Category.init(name: "Added Category", displayHeader: true, createRecord: true)
        
        // given
        list.insertCategory(cat, atIndex: 1)
        let testCat = list.categories[1]
        
        // then
        XCTAssertTrue(cat === testCat, "insertCategory category compare")
        XCTAssertTrue(list.categories.count == 4, "insertCategory category count")
    }
    
    // func updateIndices()
    func test_updateIndices()
    {
        // clear all indices
        for list in lists {
            for cat in list.categories {
                cat.categoryIndex = 0
                cat.itemIndex = 0
                for item in cat.items {
                    item.categoryIndex = 0
                    item.itemIndex = 0
                }
                cat.addItem.categoryIndex = 0
                cat.addItem.itemIndex = 0
            }
        }
        
        // given
        for list in lists {
            list.updateIndices()
        }
        
        // then
        for list in lists {
            var catIdx = 0
            
            for cat in list.categories {
                var itmIdx = 0
                
                //NSLog("catIdx \(catIdx) cat.catIndex \(cat.categoryIndex)")
                XCTAssertTrue(cat.categoryIndex == catIdx, "updateIndices category.categoryIndex")
                XCTAssertTrue(cat.itemIndex == itmIdx, "updateIndices category.itemIndex")
                
                itmIdx += 1
                for item in cat.items {
                    XCTAssertTrue(item.categoryIndex == catIdx, "updateIndices item.categoryIndex")
                    XCTAssertTrue(item.itemIndex == itmIdx, "updateIndices item.itemIndex")
                    itmIdx += 1
                }
                catIdx += 1
            }
        }
    }
    
    // func resetCategoryOrderByPosition()
    func test_resetCategoryOrderByPosition()
    {
        // clear order
        for list in lists {
            for cat in list.categories {
                cat.order = 0
            }
        }
        
        // given
        for list in lists {
            list.resetCategoryOrderByPosition()
        }
        
        // then
        for list in lists {
            var catOrder = 0
            for cat in list.categories {
                XCTAssertTrue(cat.order == catOrder, "resetCategoryOrderByPosition category.order")
                catOrder += 1
            }
        }
    }
    
    // func resetCategoryAndItemOrderByPosition()
    func test_resetCategoryAndItemOrderByPosition()
    {
        // clear order
        for list in lists {
            for cat in list.categories {
                cat.order = 0
                for item in cat.items {
                    item.order = 0
                }
            }
        }
        
        // given
        for list in lists {
            list.resetCategoryAndItemOrderByPosition()
        }
        
        // then
        for list in lists {
            var catOrder = 0
            for cat in list.categories {
                XCTAssertTrue(cat.order == catOrder, "resetCategoryAndItemOrderByPosition category.order")
                
                var itemOrder = 0
                for item in cat.items {
                    NSLog("itemOrder \(itemOrder)  item.order \(item.order)")
                    XCTAssertTrue(item.order == itemOrder, "resetCategoryAndItemOrderByPosition item.order")
                    itemOrder += 1
                }
                catOrder += 1
            }
        }
    }
    
    // func totalDisplayCount() -> Int
    func test_totalDisplayCount_expanded()
    {
        // all expanded
        for list in lists {
            // given
            var count = 0
            
            for cat in list.categories {
                if cat.displayHeader {
                    count += 1
                }
                if cat.expanded {
                    count += cat.items.count + 1
                }
            }
            
            // then
            let dispCount = list.totalDisplayCount()
            XCTAssertTrue(count == dispCount, "totalDisplayCount_expanded compare all expanded")
            NSLog("displayCount \(dispCount) - \(count)")
        }
    
    }
    
    func test_totalDisplayCount_some_collapsed()
    {
        // some collapsed categories
        lists[0].categories[0].expanded = false
        lists[0].categories[2].expanded = false
        lists[1].categories[1].expanded = false
        
        for list in lists {
            // given
            var count = 0
            
            for cat in list.categories {
                if cat.displayHeader {
                    count += 1
                }
                if cat.expanded {
                    count += cat.items.count + 1
                }
            }
            
            // then
            let dispCount = list.totalDisplayCount()
            XCTAssertTrue(count == dispCount, "totalDisplayCount_some_collapsed compare")
            NSLog("displayCount \(dispCount) - \(count)")
        }

    }
    
    func test_totalDisplayCount_all_collapsed()
    {
        // some collapsed categories
        for list in lists {
            for cat in list.categories {
                cat.expanded = false
            }
        }
        
        for list in lists {
            // given
            var count = 0
            
            for cat in list.categories {
                if cat.displayHeader {
                    count += 1
                }
                if cat.expanded {
                    count += cat.items.count + 1
                }
            }
            
            // then
            let dispCount = list.totalDisplayCount()
            XCTAssertTrue(count == dispCount, "totalDisplayCount_all_collapsed compare")
            NSLog("displayCount \(dispCount) - \(count)")
        }
        
    }
    
    // func categoryForTag(tag: Int) -> Category?
    func test_categoryForTag()
    {
        let list = lists[0]
        let tag = kItemIndexMax + 2
        
        // given
        let cat = list.categoryForTag(tag)
        let testCat = list.categories[1]
        
        // then
        XCTAssertTrue(cat === testCat, "categoryForTag category compare")
        
    }
    
    // func itemForTag(tag: Int) -> Item?
    func test_itemForTag()
    {
        let list = lists[0]
        let tag = kItemIndexMax + 2
        
        // given
        let item = list.itemForTag(tag)
        let testItem = list.categories[1].items[1]
        
        // then
        XCTAssertTrue(item === testItem, "itemForTag item compare")
    }
    
    // func objectForTag(tag: Int) -> ListObj?
    func test_objectForTag()
    {
        let list = lists[0]
        let tag1 = kItemIndexMax * 2
        let tag2 = (kItemIndexMax * 2) + 1
        
        // given
        let obj1 = list.objectForTag(tag1)
        let obj2 = list.objectForTag(tag2)
        let testObj1 = list.categories[2]
        let testObj2 = list.categories[2].items[0]
        
        // then
        XCTAssertTrue(obj1 === testObj1, "objectForTag obj1 compare")
        XCTAssertTrue(obj2 === testObj2, "objectForTag obj2 compare")
    }
    
    // func categoryForObj(item: ListObj) -> Category?
    func test_categoryForObj()
    {
        let list = lists[0]
        let obj1 = list.categories[2]
        let obj2 = list.categories[2].items[2]
        let testCat = list.categories[2]
        
        // given
        let testObj1 = list.categoryForObj(obj1)
        let testObj2 = list.categoryForObj(obj2)
        
        // then
        XCTAssertTrue(testObj1 === testCat, "categoryForObj testObj1 compare")
        XCTAssertTrue(testObj2 === testCat, "categoryForObj testObj2 compare")
    }
    
    // func categoryForIndexPath(indexPath: NSIndexPath) -> Category?
    func test_categoryForIndexPath()
    {
        let list = lists[0]
        var indexPath = NSIndexPath.init(forRow: 7, inSection: 0)
        let testCat = list.categories[1]
        
        // given
        var cat = list.categoryForIndexPath(indexPath)
        XCTAssertNil(cat, "categoryForIndexPath item path is nil")
        
        indexPath = NSIndexPath.init(forRow: 5, inSection: 0)
        cat = list.categoryForIndexPath(indexPath)
        XCTAssertTrue(cat === testCat, "categoryForIndexPath compare category")
    }
    
    // func itemForIndexPath(indexPath: NSIndexPath) -> Item?
    func test_itemForIndexPath()
    {
        let list = lists[0]
        var indexPath = NSIndexPath.init(forRow: 7, inSection: 0)
        let testItem = list.categories[1].items[1]
        
        // given
        var item = list.itemForIndexPath(indexPath)
        XCTAssertTrue(item === testItem, "itemForIndexPath compare item")
        
        indexPath = NSIndexPath.init(forRow: 5, inSection: 0)
        item = list.itemForIndexPath(indexPath)
        XCTAssertNil(item, "itemForIndexPath item path is nil")
    }
    
    // func objectForIndexPath(indexPath: NSIndexPath) -> ListObj?
    func test_objectForIndexPath()
    {
        // given
        let list = lists[0]
        var indexPath: NSIndexPath?
        let testItem = list.categories[1].items[1]
        let testCat = list.categories[1]
        let testAddItem = list.categories[1].addItem
        
        // then
        indexPath = NSIndexPath.init(forRow: 7, inSection: 0)
        var obj = list.objectForIndexPath(indexPath!)
        XCTAssertTrue(obj is Item, "objectForIndexPath obj is Item")
        XCTAssertTrue(obj === testItem, "objectForIndexPath compare item")
        
        indexPath = NSIndexPath.init(forRow: 5, inSection: 0)
        obj = list.objectForIndexPath(indexPath!)
        XCTAssertTrue(obj is EnList.Category, "objectForIndexPath obj is Category")
        XCTAssertTrue(obj === testCat, "objectForIndexPath compare category")
        
        indexPath = NSIndexPath.init(forRow: 9, inSection: 0)
        obj = list.objectForIndexPath(indexPath!)
        XCTAssertTrue(obj is AddItem, "objectForIndexPath obj is AddItem")
        XCTAssertTrue(obj === testAddItem, "objectForIndexPath compare addItem")
    }
    
    // func displayIndexPathForTag(tag: Int) -> NSIndexPath?
    func test_displayIndexPathForTag()
    {
        let list = lists[0]
        let tag = kItemIndexMax + 2
        
        // given
        let indexPath = list.displayIndexPathForTag(tag)
        XCTAssertTrue(indexPath!.row == 7, "displayIndexPathForTag compare indexPath")
    }
    
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
