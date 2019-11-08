//
//  CategoryClassTests.swift
//  EnList
//
//  Created by Steven Gentry on 8/23/16.
//  Copyright © 2016 Steven Gentry. All rights reserved.
//

import XCTest
@testable import EnList

class CategoryClassTests: ModelClassTests
{
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    // func deleteItems()
    func test_deleteItems()
    {
        let cat = lists[0].categories[0]
        
        // given
        cat.deleteItems()
        
        // then
        XCTAssertTrue(cat.items.count == 0, "deleteItems")
    }
    
    // func clearNeedToSave()
    func test_clearNeedToSave()
    {
        let cat = lists[0].categories[0]
        cat.items[0].needToSave = true
        cat.items[1].needToSave = true
        cat.items[2].needToSave = true
        
        // given
        cat.clearNeedToSave()
        
        // then
        var count = 0
        for item in cat.items {
            if item.needToSave {
                count += 1
            }
        }
        XCTAssertTrue(count == 0, "clearNeedToSave")
    }
    
    // func updateIndices(catIndex: Int)
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
    
    // func resetItemOrderByPosition()
    func test_resetItemOrderByPosition()
    {
        let cat = lists[0].categories[0]
        
        for item in cat.items {
            item.order = 0
        }
        
        // given
        cat.resetItemOrderByPosition()
        
        // then
        var order = 0
        for item in cat.items {
            XCTAssertTrue(item.order == order, "resetItemOrderByPosition")
            order += 1
        }
    }
    
    // func htmlForPrinting(list: List, includePics: Bool) -> String
    func test_htmlForPrinting()
    {
        let list = lists[0]
        let cat = list.categories[0]
        
        // given
        let html = cat.htmlForPrinting(list, includePics: false)
        
        // then
        NSLog("html length = \(html.count)")
        XCTAssertTrue(html.count > 0, "htmlForPrinting character count check")
    }
    
    // func itemsComplete() -> Int
    func test_itemsComplete()
    {
        let cat = lists[0].categories[0]
        
        // given
        cat.items[0].state = .complete
        cat.items[1].state = .inactive
        cat.items[2].state = .incomplete
        
        // then
        XCTAssertTrue(cat.itemsComplete() == 1, "itemsComplete")
    }
    
    // func itemsActive() -> Int
    func test_itemsActive()
    {
        let cat = lists[0].categories[0]
        
        // given
        cat.items[0].state = .complete
        cat.items[1].state = .inactive
        cat.items[2].state = .incomplete
        
        // then
        XCTAssertTrue(cat.itemsActive() == 2, "itemsActive")
    }
    
    // func itemsInactive() -> Int
    func test_itemsInactive()
    {
        let cat = lists[0].categories[0]
        
        // given
        cat.items[0].state = .complete
        cat.items[1].state = .inactive
        cat.items[2].state = .incomplete
        
        // then
        XCTAssertTrue(cat.itemsInactive() == 1, "itemsInactive")
    }
    
    // func itemsIncomplete() -> Int
    func test_itemsIncomplete()
    {
        let cat = lists[0].categories[0]
        
        // given
        cat.items[0].state = .complete
        cat.items[1].state = .inactive
        cat.items[2].state = .incomplete
        
        // then
        XCTAssertTrue(cat.itemsIncomplete() == 1, "itemsIncomplete")
    }
    
    func DISABLE_testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
