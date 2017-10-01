//
//  CheckBox.swift
//  EnList
//
//  Created by Steven Gentry on 2/10/16.
//  Copyright © 2016 Steven Gentry. All rights reserved.
//

import UIKit

class CheckBox: UIButton
{
    // images
    let completeImage = UIImage(named: "checkBox_complete")
    let incompleteImage = UIImage(named: "checkBox_incomplete")
    let inactiveImage = UIImage(named: "checkBox_inactive")
    
    // image colors
    let inactiveColor = UIColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1.0)
    let defaultColor = UIColor(red: 0.0, green: 0.478, blue: 1.0, alpha: 1.0)
    
    // external links
    var item: Item?
    var list: List?
    static var itemVC: ItemViewController?      // type property
    
    func checkBoxInit(_ item: Item, list: List, tag: Int) {
        self.item = item
        self.list = list
        self.tag = tag
        
        // intercept button tap events
        self.addTarget(self, action: #selector(CheckBox.buttonTapped(_:)), for: UIControlEvents.touchUpInside)
        
        // set the initial check box image
        setImage()
    }
    
    // cycle the button image on tap
    func buttonTapped(_ sender: UIButton) {
        if sender == self && CheckBox.itemVC != nil {
            CheckBox.itemVC!.checkButtonTapped(self)
            self.setImage()
        }
    }
    
    // set the checkbox image based on current item state
    func setImage() {
        var origImage: UIImage?
        
        if item!.state == ItemState.incomplete {
            origImage = incompleteImage
        } else if item!.state == ItemState.complete {
            origImage = completeImage
        } else if item!.state == ItemState.inactive {
            origImage = inactiveImage
        }
        
        // set check box color from list color
        let tintedImage = origImage?.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
        self.setImage(tintedImage, for: UIControlState())
        
        if item!.state != ItemState.inactive && list!.listColor != nil {
            self.tintColor = list!.listColor
        } else if item!.state == ItemState.inactive {
            self.tintColor = inactiveColor
        } else {
            self.tintColor = defaultColor
        }
        
        // special handling for yellow (color4_1)
        if item!.state != ItemState.inactive && list!.listColorName == r4_1 {
            self.tintColor = color4_1_alt
        }
    }
    
}



