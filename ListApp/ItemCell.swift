//
//  ItemCell.swift
//  EnList
//
//  Created by Steven Gentry on 12/31/15.
//  Copyright © 2015 Steven Gentry. All rights reserved.
//

import UIKit

// A protocol that the TableViewCell uses to inform its delegate of state change
protocol ItemCellDelegate: class
{
    // gesture action methods for delegates
    //func itemSingleTapAction(sender: UIGestureRecognizer)
    //func itemDoubleTapAction(textField: UITextField)
    //func itemLongPressAction(sender: UILongPressGestureRecognizer)
}

class ItemCell: UITableViewCell
{
    @IBOutlet weak var checkBox: CheckBox!
    @IBOutlet weak var itemName: UITextField!
    @IBOutlet weak var itemNote: UILabel!
    
    weak var delegate: ItemCellDelegate?
    let gradientLayer = CAGradientLayer()
    
    override func awakeFromNib()
    {
        super.awakeFromNib()

        // Initialization code
        
        /*
        // set up single tap gesture recognizer in cat cell to enable expand/collapse
        let singleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: "cellSingleTappedAction:")
        singleTapGestureRecognizer.numberOfTapsRequired = 1
        self.addGestureRecognizer(singleTapGestureRecognizer)
        */
        
        /*
        // set up double tap gesture recognizer in item cell to enable cell moving
        let doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: "cellDoubleTappedAction:")
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        //singleTapGestureRecognizer.requireGestureRecognizerToFail(doubleTapGestureRecognizer)
        self.addGestureRecognizer(doubleTapGestureRecognizer)
        */
        
        // set up long press gesture recognizer
        // let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "longPressAction:")
        // doubleTapGestureRecognizer.requireGestureRecognizerToFail(longPressGestureRecognizer)
        // self.addGestureRecognizer(longPressGestureRecognizer)
        
    }
    
    override func layoutSubviews()
    {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?)
    {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        // gradient layer for cell
        gradientLayer.frame = bounds
        let color1 = UIColor(white: 1.0, alpha: 0.2).CGColor as CGColorRef
        let color2 = UIColor(white: 1.0, alpha: 0.1).CGColor as CGColorRef
        let color3 = UIColor.clearColor().CGColor as CGColorRef
        let color4 = UIColor(white: 0.0, alpha: 0.1).CGColor as CGColorRef
        gradientLayer.colors = [color1, color2, color3, color4]
        gradientLayer.locations = [0.0, 0.01, 0.95, 1.0]
        layer.insertSublayer(gradientLayer, atIndex: 0)
    }
    
    override func setSelected(selected: Bool, animated: Bool)
    {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

////////////////////////////////////////////////////////////////
//
//  MARK: - Gesture Recognizer Methods
//
////////////////////////////////////////////////////////////////
    
    /*
    func cellSingleTappedAction(sender: UIGestureRecognizer)
    {
        print("cellSingleTappedAction for \(itemName.text)")
        self.delegate?.itemSingleTapAction(sender)
    }
    */
    
    /*
    func cellDoubleTappedAction(sender: UITapGestureRecognizer)
    {
        print("cellDoubleTappedAction for \(itemName.text)")
        self.delegate?.itemDoubleTapAction(itemName)
    }
    */
    
    /*
    func longPressAction(sender: UILongPressGestureRecognizer)
    {
    print("longPressAction for \(categoryName.text)")
    self.delegate?.categoryLongPressAction(sender)
    }
    
    override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool
    {
    if let _ = gestureRecognizer as? UILongPressGestureRecognizer {
    return true
    }
    return false
    }
    */
    
}
