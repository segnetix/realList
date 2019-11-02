//
//  AddItemCell.swift
//  EnList
//
//  Created by Steven Gentry on 1/16/16.
//  Copyright © 2016 Steven Gentry. All rights reserved.
//

import UIKit

class AddItemCell: UITableViewCell {
    @IBOutlet weak var addItemButton: AddButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String!) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
}
