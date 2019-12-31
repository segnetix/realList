//
//  ItemCell.swift
//  EnList
//
//  Created by Steven Gentry on 12/31/15.
//  Copyright © 2015 Steven Gentry. All rights reserved.
//

import UIKit

class ItemCell: UITableViewCell {
    @IBOutlet weak var checkBox: CheckBox!
    @IBOutlet weak var itemName: UITextField!
    @IBOutlet weak var itemNote: UILabel!
    @IBOutlet weak var tapView: UIView!
    @IBOutlet weak var pictureIndicator: UIImageView!
        
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        //gradientLayer.frame = bounds
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
}
