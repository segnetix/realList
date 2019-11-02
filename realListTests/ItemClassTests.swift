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
    
    // func clearNeedToSave()
    func test_clearNeedToSave()
    {
        let item = lists[0].categories[0].items[0]
        item.needToSave = true
        
        // given
        item.clearNeedToSave()
        
        // then
        XCTAssertTrue(item.needToSave == false, "clearNeedToSave")
    }
    
    // func htmlForPrinting(includePics: Bool) -> String
    func test_htmlFoPrinting()
    {
        let item = lists[0].categories[0].items[0]
        
        // given
        let html = item.htmlForPrinting(false)
        
        // then
        NSLog("html length = \(html.count)")
        XCTAssertTrue(html.count > 0, "htmlForPrinting character count check")
    }
    
    // func setImage(image: UIImage?)
    func test_setImage()
    {
        let item = lists[0].categories[0].items[0]
        let image = UIImage(named: "Cloud_check")
        
        // given
        let imageModDate = Date.init()
        item.setImage(image)
        
        // then
        XCTAssertNotNil(item.imageAsset, "setImage")
        XCTAssertTrue(item.imageAsset!.itemName == "First Item", "setImage")
        XCTAssertTrue(item.needToSave == true, "setImage")
        XCTAssertTrue(item.imageModifiedDate > imageModDate, "setImage")
    }
    
    // func getImage() -> UIImage?
    func test_getImage()
    {
        let item = lists[0].categories[0].items[0]
        item.setImage(UIImage(named: "Cloud_check"))
        
        // given
        let image = item.getImage()
        
        // then
        XCTAssertNotNil(image)
    }
    
    // func addImageAsset() -> ImageAsset?
    func test_addImage()
    {
        let item = lists[0].categories[0].items[0]
        
        // given
        item.imageAsset = nil
        
        // then
        _ = item.addImageAsset()
        XCTAssertNotNil(item.imageAsset, "addImage assert not nil image asset")
    }
    
    func DISABLE_testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
