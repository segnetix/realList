//
//  ItemCell.swift
//  ListApp
//
//  Created by Steven Gentry on 12/31/15.
//  Copyright © 2015 Steven Gentry. All rights reserved.
//

import UIKit

// A protocol that the TableViewCell uses to inform its delegate of state change
protocol ItemCellDelegate: class
{
    // indicates that the cell has been long pressed for editing
    func itemNameTappedForEditing(textField: UITextField)
}

class ItemCell: UITableViewCell
{
    @IBOutlet weak var itemName: UITextField!
    weak var delegate: ItemCellDelegate?
    let gradientLayer = CAGradientLayer()
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        // Initialization code
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
    
    override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool
    {
        if let _ = gestureRecognizer as? UILongPressGestureRecognizer
        {
            self.delegate?.itemNameTappedForEditing(itemName)
            return true
        }
        return false
    }
    
}
