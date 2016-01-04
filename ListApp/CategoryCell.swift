//
//  CategoryCell.swift
//  ListApp
//
//  Created by Steven Gentry on 1/2/16.
//  Copyright © 2016 Steven Gentry. All rights reserved.
//

import UIKit

// A protocol that the TableViewCell uses to inform its delegate of state change
protocol CategoryCellDelegate: class
{
    // indicates that the cell has been long pressed for editing
    func catNameTappedForEditing(textField: UITextField)
}

class CategoryCell: UITableViewCell
{
    @IBOutlet weak var categoryName: UITextField!
    @IBOutlet weak var catCountLabel: UILabel!
    weak var delegate: CategoryCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String!) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

    override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool
    {
        if let _ = gestureRecognizer as? UILongPressGestureRecognizer
        {
            self.delegate?.catNameTappedForEditing(categoryName)
            return true
        }
        return false
    }
    
}
