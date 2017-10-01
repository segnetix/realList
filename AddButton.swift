//
//  AddButton.swift
//  EnList
//
//  Created by Steven Gentry on 3/29/16.
//  Copyright © 2016 Steven Gentry. All rights reserved.
//

import UIKit

class AddButton: UIButton
{
    // images
    let addButtonImage = UIImage(named: "Add")
    
    // image colors
    //let inactiveColor = UIColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1.0)
    let defaultColor = UIColor(red: 0.0, green: 0.478, blue: 1.0, alpha: 1.0)
    
    // external links
    var list: List?
    var itemVC: ItemViewController?
    
    func addButtonInit(_ list: List, itemVC: ItemViewController, tag: Int) {
        self.list = list
        self.itemVC = itemVC
        self.tag = tag
        
        self.addTarget(self, action: #selector(AddButton.buttonTapped(_:)), for: UIControlEvents.touchUpInside)
        
        // set the initial add button image
        setImage()
    }
    
    func buttonTapped(_ sender: UIButton) {
        if sender == self && itemVC != nil {
            itemVC!.addNewItem(self)
        }
    }
    
    // set the image based on current list color
    func setImage() {
        // set add button color from list color
        let tintedImage = addButtonImage!.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
        self.setImage(tintedImage, for: UIControlState())
        
        if list!.listColorName == r4_1 {
            self.tintColor = color4_1_alt
        } else if list!.listColor != nil {
            self.tintColor = list!.listColor
        } else {
            self.tintColor = defaultColor
        }
    }

}
