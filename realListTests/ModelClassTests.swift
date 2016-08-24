//
//  ModelClassTests.swift
//  EnList
//
//  Created by Steven Gentry on 8/23/16.
//  Copyright © 2016 Steven Gentry. All rights reserved.
//

import XCTest
@testable import EnList

class ModelClassTests: XCTestCase
{
    var lists = [List]()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // list data setup
        var list = List(name: "List One", createRecord: true, tutorial: true)
        var cat: EnList.Category?
        var item: Item?
        
        list.listColorName = r1_2
        lists.append(list)
        
        list.needToSave = true
        
        // cat 1
        cat = list.addCategory("First Category", displayHeader: true, updateIndices: false, createRecord: true)
        cat!.needToSave = true
        
        item = list.addItem(cat!, name: "First Item", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        item!.note = "First Item note..."
        item!.needToSave = true
        
        item = list.addItem(cat!, name: "Second Item", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        item!.note = "Second Item note..."
        
        item = list.addItem(cat!, name: "Third Item", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        item!.note = "Third Item note..."
        item!.needToSave = true
        
        // cat 2
        cat = list.addCategory("Second Category", displayHeader: true, updateIndices: false, createRecord: true)
        
        item = list.addItem(cat!, name: "Fourth Item", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        item!.note = "Fourth Item note..."
        
        item = list.addItem(cat!, name: "Fifth Item", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        item!.note = "Fifth Item note..."
        item!.needToSave = true
        
        item = list.addItem(cat!, name: "Sixth Item", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        item!.note = "Sixth Item note..."
        
        // cat 3
        cat = list.addCategory("Third Category", displayHeader: true, updateIndices: false, createRecord: true)
        cat!.needToSave = true
        
        item = list.addItem(cat!, name: "Seventh Item", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        item!.note = "Seventh Item note..."
        item!.needToSave = true
        
        item = list.addItem(cat!, name: "Eight Item", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        item!.note = "Eight Item note..."
        
        item = list.addItem(cat!, name: "Ninth Item", state: ItemState.Incomplete, updateIndices: true, createRecord: true)
        item!.note = "Ninth Item note..."
        item!.needToSave = true
        
        //list.updateIndices()
        
        // list 2
        list = List(name: "List Two", createRecord: true, tutorial: true)
        list.listColorName = r1_2
        lists.append(list)
        
        // cat 4
        cat = list.addCategory("Fourth Category", displayHeader: true, updateIndices: false, createRecord: true)
        
        item = list.addItem(cat!, name: "Item 10", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        item!.note = "Item 10 note..."
        item!.needToSave = true
        
        item = list.addItem(cat!, name: "Item 11", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        item!.note = "Item 11 note..."
        
        item = list.addItem(cat!, name: "Item 12", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        item!.note = "Item 12 note..."
        
        // cat 5
        cat = list.addCategory("Fifth Category", displayHeader: true, updateIndices: false, createRecord: true)
        
        item = list.addItem(cat!, name: "Item 13", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        item!.note = "Item 13 note..."
        
        item = list.addItem(cat!, name: "Item 14", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        item!.note = "Item 14 note..."
        item!.needToSave = true
        
        item = list.addItem(cat!, name: "Item 15", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        item!.note = "Item 15 note..."
        
        // cat 6
        cat = list.addCategory("Sixth Category", displayHeader: true, updateIndices: false, createRecord: true)
        cat!.needToSave = true
        
        item = list.addItem(cat!, name: "Item 16", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        item!.note = "Item 16 note..."
        item!.needToSave = true
        
        item = list.addItem(cat!, name: "Item 17", state: ItemState.Incomplete, updateIndices: false, createRecord: true)
        item!.note = "Item 17 note..."
        
        item = list.addItem(cat!, name: "Item 18", state: ItemState.Incomplete, updateIndices: true, createRecord: true)
        item!.note = "Item 18 note..."
        item!.needToSave = true
        
        //list.updateIndices()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        
        // list data clean up
        lists.removeAll()
    }
    
}
