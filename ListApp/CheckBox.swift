//
//  CheckBox.swift
//  ListApp
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
    let inactiveColor = UIColor(colorLiteralRed: 0.7, green: 0.7, blue: 0.7, alpha: 1.0)
    let defaultColor = UIColor(colorLiteralRed: 0.0, green: 0.478, blue: 1.0, alpha: 1.0)
    
    // external links
    var item: Item?
    var list: List?
    var itemVC: ItemViewController?
    
    func checkBoxInit(item: Item, list: List, itemVC: ItemViewController, tag: Int) {
        self.item = item
        self.list = list
        self.itemVC = itemVC
        self.tag = tag
        
        self.addTarget(self, action: "buttonTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        
        // set the initial check box image
        setImage()
    }
    
    // cycle the button image on tap
    func buttonTapped(sender: UIButton) {
        if sender == self && itemVC != nil {
            itemVC!.checkButtonTapped(self)
            self.setImage()
        }
    }
    
    // set the checkbox image based on current item state
    func setImage() {
        var origImage: UIImage?
        
        if item!.state == ItemState.Incomplete {
            origImage = incompleteImage
        } else if item!.state == ItemState.Complete {
            origImage = completeImage
        } else if item!.state == ItemState.Inactive {
            origImage = inactiveImage
        }
        
        // set check box color from list color
        let tintedImage = origImage?.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        self.setImage(tintedImage, forState: .Normal)
        
        if item!.state != ItemState.Inactive && list!.listColor != nil {
            self.tintColor = list!.listColor
        } else if item!.state == ItemState.Inactive {
            self.tintColor = inactiveColor
        } else {
            self.tintColor = defaultColor
        }
    }
    
}



