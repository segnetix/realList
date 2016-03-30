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
    //let inactiveColor = UIColor(colorLiteralRed: 0.7, green: 0.7, blue: 0.7, alpha: 1.0)
    let defaultColor = UIColor(colorLiteralRed: 0.0, green: 0.478, blue: 1.0, alpha: 1.0)
    
    // external links
    var list: List?
    var itemVC: ItemViewController?
    
    func addButtonInit(list: List, itemVC: ItemViewController, tag: Int) {
        self.list = list
        self.itemVC = itemVC
        self.tag = tag
        
        self.addTarget(self, action: #selector(AddButton.buttonTapped(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        
        // set the initial add button image
        setImage()
    }
    
    func buttonTapped(sender: UIButton) {
        if sender == self && itemVC != nil {
            itemVC!.addItemButtonTapped(self)
        }
    }
    
    // set the image based on current list color
    func setImage() {
        // set add button color from list color
        let tintedImage = addButtonImage!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        self.setImage(tintedImage, forState: .Normal)
        
        if list!.listColor != nil {
            self.tintColor = list!.listColor
        } else {
            self.tintColor = defaultColor
        }
    }

}
