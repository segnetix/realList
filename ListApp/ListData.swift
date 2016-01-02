//
//  ListData.swift
//  ListApp
//
//  Created by Steven Gentry on 12/31/15.
//  Copyright © 2015 Steven Gentry. All rights reserved.
//

/*
class ListData
{
    var lists = [List]()

    func addList(listName: String)
    {
        let list = List(name: listName)
        
        lists.append(list)
    }
    
}
*/

class List
{
    var name: String
    var categories = [Category]()
    
    // designated initializer for a List
    init(name: String) {
        self.name = name
    }
    
    /*
    func addCategory(category: Category)
    {
        categories.append(category)
    }
    */
}

class Category
{
    var name: String
    var items = [Item]()
    
    // designated initializer for a Category
    init(name: String) {
        self.name = name
    }
    
    /*
    func addItem(item: Item)
    {
        items.append(item)
    }
    */
}

class Item
{
    var name: String
    
    // designated initializer for an Item
    init(name: String) {
        self.name = name
    }
    
}
