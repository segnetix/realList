//
//  ListDataTests.swift
//  EnList
//
//  Created by Steven Gentry on 9/12/16.
//  Copyright © 2016 Steven Gentry. All rights reserved.
//

import XCTest
@testable import EnList

class ListDataTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    // computed values
    func test_listCount() {
        // given
        // 2 lists added in test setup
        
        // then
        XCTAssertTrue(ListData.listCount == 2, "listCount computed property")
    }
    
    func test_nonTutorialListCount() {
        // given
        // 1 tutorial lists added in test setup
        
        // then
        XCTAssertTrue(ListData.nonTutorialListCount == 1, "nonTutorialListCount computed property")
    }
    
    func test_tutorialListIndex() {
        // given
        // 1 tutorial list in test data at index 1
        
        // then
        XCTAssertTrue(ListData.tutorialListIndex == 1, "tutorialListIndex computed property")
    }
    
    // class functions
    // class func loadLocal(filePath: String) -> Bool
    func test_loadLocal() {
        // given
        
        // then
        XCTAssertTrue(ListData.tutorialListIndex == 1, "listCount")
    }
    
    // class func saveLocal(filePath: String) -> Bool
    func test_saveLocal() {
        // given
        
        // then
        XCTAssertTrue(ListData.tutorialListIndex == 1, "listCount")
    }
    
    // class func listForRow(at indexPath: IndexPath) -> List?
    func test_listForRow() {
        // given
        
        // then
        XCTAssertTrue(ListData.tutorialListIndex == 1, "listCount")
    }
    
    // class func list(_ index: Int) -> List?
    func test_list() {
        // given
        
        // then
        XCTAssertTrue(ListData.tutorialListIndex == 1, "listCount")
    }
    
    // class func listIndex(of list: List) -> Int?
    func test_listIndex() {
        // given
        
        // then
        XCTAssertTrue(ListData.tutorialListIndex == 1, "listCount")
    }
    
    // class func removeList(_ list: List)
    func test_removeList() {
        // given
        
        // then
        XCTAssertTrue(ListData.tutorialListIndex == 1, "listCount")
    }
    
    // class func removeListAt(_ indexPath: IndexPath) -> List?
    func test_removeListAt() {
        // given
        
        // then
        XCTAssertTrue(ListData.tutorialListIndex == 1, "listCount")
    }
    
    // class func removeListAt(_ index: Int) -> List?
    func test_removeListAt_1() {
        // given
        
        // then
        XCTAssertTrue(ListData.tutorialListIndex == 1, "listCount")
    }
    
    // class func removeLastList()
    func test_removeLastList_2() {
        // given
        
        // then
        XCTAssertTrue(ListData.tutorialListIndex == 1, "listCount")
    }
    
    // class func appendList(_ list: List)
    func test_appendList() {
        // given
        
        // then
        XCTAssertTrue(ListData.tutorialListIndex == 1, "listCount")
    }
    
    // class func insertList(_ list: List, at indexPath: IndexPath)
    func test_insertList() {
        // given
        
        // then
        XCTAssertTrue(ListData.tutorialListIndex == 1, "listCount")
    }
    
    // class func saveToCloud()
    func test_saveToCloud() {
        // given
        
        // then
        XCTAssertTrue(ListData.tutorialListIndex == 1, "listCount")
    }
    
    // class func updateIndices()
    func test_updateIndices() {
        // given
        
        // then
        XCTAssertTrue(ListData.tutorialListIndex == 1, "listCount")
    }
    
    // class func clearNeedToSave()
    func test_clearNeedToSave() {
        // given
        
        // then
        XCTAssertTrue(ListData.tutorialListIndex == 1, "listCount")
    }
    
    // class func resetListOrderValues()
    func test_resetListOrderValues() {
        // given
        
        // then
        XCTAssertTrue(ListData.tutorialListIndex == 1, "listCount")
    }
    
    // class func lastCategoryInList(_ list: List) -> Category?
    func test_lastCategoryInList() {
        // given
        
        // then
        XCTAssertTrue(ListData.tutorialListIndex == 1, "listCount")
    }
    
    // class func deleteObjects(listDeleteRecordIDs: [String], categoryDeleteRecordIDs: [String], itemDeleteRecordIDs: [String])
    func test_deleteObjects() {
        // given
        
        // then
        XCTAssertTrue(ListData.tutorialListIndex == 1, "listCount")
    }
    
    // class func countNeedToSave() -> Int
    func test_countNeedToSave() {
        // given
        
        // then
        XCTAssertTrue(ListData.tutorialListIndex == 1, "listCount")
    }
    
    // class func reorderListObjects()
    func test_reorderListObjects() {
        // given
        
        // then
        XCTAssertTrue(ListData.tutorialListIndex == 1, "listCount")
    }
    
    // class func resetListOrderByPosition()
    func test_resetListOrderByPosition() {
        // given
        
        // then
        XCTAssertTrue(ListData.tutorialListIndex == 1, "listCount")
    }
    
    // class func resetListCategoryAndItemOrderByPosition()
    func test_resetListCategoryAndItemOrderByPosition() {
        // given
        
        // then
        XCTAssertTrue(ListData.tutorialListIndex == 1, "listCount")
    }
    
    // class func getLocalObject(_ recordIDName: String) -> AnyObject?
    func test_getLocalObject() {
        // given
        
        // then
        XCTAssertTrue(ListData.tutorialListIndex == 1, "listCount")
    }
    
    // class func getLocalList(_ recordIDName: String) -> List?
    func test_getLocalList() {
        // given
        
        // then
        XCTAssertTrue(ListData.tutorialListIndex == 1, "listCount")
    }
    
    // class func getLocalCategory(_ recordIDName: String) -> Category?
    func test_getLocalCategory() {
        // given
        
        // then
        XCTAssertTrue(ListData.tutorialListIndex == 1, "listCount")
    }
    
    // class func getLocalItem(_ recordIDName: String) -> Item?
    func test_getLocalItem() {
        // given
        
        // then
        XCTAssertTrue(ListData.tutorialListIndex == 1, "listCount")
    }
    
    // class func getListForCategory(_ searchCategory: Category) -> List?
    func test_getListForCategory() {
        // given
        
        // then
        XCTAssertTrue(ListData.tutorialListIndex == 1, "listCount")
    }
    
    // class func getListForItem(_ searchItem: Item) -> List?
    func test_getListForItem() {
        // given
        
        // then
        XCTAssertTrue(ListData.tutorialListIndex == 1, "listCount")
    }
    
    // class func getListForListObj(_ searchObj: ListObj) -> List?
    func test_getListForListObj() {
        // given
        
        // then
        XCTAssertTrue(ListData.tutorialListIndex == 1, "listCount")
    }
    
    // class func getCategoryForItem(_ searchItem: Item) -> Category?
    func test_getCategoryForItem_1() {
        // given
        
        // then
        XCTAssertTrue(ListData.tutorialListIndex == 1, "listCount")
    }
    
    // class func getCategoryForItem(_ searchItem: Item, inList: List) -> Category?
    func test_getCategoryForItem_2() {
        // given
        
        // then
        XCTAssertTrue(ListData.tutorialListIndex == 1, "listCount")
    }
    
    func DISABLE_testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
}
