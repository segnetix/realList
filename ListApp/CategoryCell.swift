//
//  CategoryCell.swift
//  EnList
//
//  Created by Steven Gentry on 1/2/16.
//  Copyright © 2016 Steven Gentry. All rights reserved.
//

import UIKit

// A protocol that the TableViewCell uses to inform its delegate of state change
protocol CategoryCellDelegate: class
{
    // gesture action methods for delegates
    //func categorySingleTapAction(sender: UIGestureRecognizer)
    //func categoryDoubleTapAction(textField: UITextField)
    //func categoryLongPressAction(sender: UILongPressGestureRecognizer)
}

class CategoryCell: UITableViewCell
{
    @IBOutlet weak var categoryName: UITextField!
    @IBOutlet weak var catCountLabel: UILabel!
    //weak var delegate: CategoryCellDelegate?
    
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

////////////////////////////////////////////////////////////////
//
//  MARK: - Gesture Recognizer Methods
//
////////////////////////////////////////////////////////////////
    
    /*
    func cellSingleTappedAction(sender: UIGestureRecognizer)
    {
        print("cellSingleTappedAction for \(categoryName.text)")
        self.delegate?.categorySingleTapAction(sender)
    }
    */
    
    /*
    func cellDoubleTappedAction(sender: UITapGestureRecognizer)
    {
        print("cellDoubleTappedAction for \(categoryName.text)")
        self.delegate?.categoryDoubleTapAction(categoryName)
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
