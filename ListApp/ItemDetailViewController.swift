//
//  ItemDetailViewController.swift
//  ListApp
//
//  Created by Steven Gentry on 2/6/16.
//  Copyright © 2016 Steven Gentry. All rights reserved.
//

import UIKit

class ItemDetailViewController: UIViewController, UITextViewDelegate
{
    var containerView: UIView = UIView()
    var titleLabel: UILabel = UILabel()
    var noteTextView = UITextView()
    var closeButton: UIButton = UIButton()
    weak var itemVC: ItemViewController?
    weak var item: Item?
    weak var list: List?
    
    init(item: Item, list: List) {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = UIModalPresentationStyle.Custom
        self.item = item
        self.list = list
        createUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createUI()
    {
        titleLabel.text = item?.name
        noteTextView.text = item?.note
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = UIColor(white: 1.0, alpha: 1.0)
        view.addSubview(containerView)
        
        // Set some constants to use when creating constraints
        //let titleFontSize: CGFloat = view.bounds.size.width > 667.0 ? 40.0 : 22.0
        //let bodyFontSize: CGFloat = view.bounds.size.width > 667.0 ? 40.0 : 22.0
        //let noteFontSize: CGFloat = 15.0
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleTitle1)
        if item?.state != ItemState.Inactive {
            titleLabel.textColor = UIColor.blackColor()
        } else {
            titleLabel.textColor = UIColor.lightGrayColor()
        }
        
        titleLabel.textAlignment = NSTextAlignment.Left
        containerView.addSubview(titleLabel)
        
        noteTextView.translatesAutoresizingMaskIntoConstraints = false
        noteTextView.textColor = UIColor.blackColor()
        noteTextView.layer.borderColor = containerView.tintColor.CGColor
        if list != nil && list!.listColor != nil {
            noteTextView.layer.borderColor = list!.listColor!.CGColor
        } else {
            noteTextView.layer.borderColor = containerView.tintColor.CGColor
        }
        noteTextView.layer.borderWidth = 2.0
        noteTextView.layer.cornerRadius = 5.0
        noteTextView.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        noteTextView.textAlignment = NSTextAlignment.Left
        noteTextView.returnKeyType = UIReturnKeyType.Done
        noteTextView.delegate = self
        containerView.addSubview(noteTextView)
        
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setTitle("Close", forState: UIControlState.Normal)
        closeButton.setTitleColor(containerView.tintColor, forState: UIControlState.Normal)
        closeButton.titleLabel!.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        closeButton.addTarget(self, action: "close:", forControlEvents: UIControlEvents.TouchUpInside)
        containerView.addSubview(closeButton)
        
        let views: [String : AnyObject] = [
            "containerView": containerView,
            "titleLabel": titleLabel,
            "noteTextView": noteTextView,
            "closeButton": closeButton]
        
        view.addConstraints(
            NSLayoutConstraint.constraintsWithVisualFormat(
                "H:|[containerView]|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: nil,
                views: views))
        
        view.addConstraints(
            NSLayoutConstraint.constraintsWithVisualFormat(
                "V:|[containerView]|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: nil,
                views: views))
        
        containerView.addConstraints(
            NSLayoutConstraint.constraintsWithVisualFormat(
                "H:|-20-[titleLabel]-20-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: nil,
                views: views))
        
        containerView.addConstraints(
            NSLayoutConstraint.constraintsWithVisualFormat(
                "H:|-20-[noteTextView]-20-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: nil,
                views: views))

        containerView.addConstraints(
            NSLayoutConstraint.constraintsWithVisualFormat(
                "H:|[closeButton]|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: nil,
                views: views))
        
        containerView.addConstraints(
            NSLayoutConstraint.constraintsWithVisualFormat(
                "V:|-24-[titleLabel]-[noteTextView(180)]-(>=20)-[closeButton]-24-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: nil,
                views: views))
        
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if (text == "\n") {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    func close(sender: UIButton) {
        item?.note = noteTextView.text
        itemVC?.tableView.reloadData()
        itemVC?.appDelegate.saveAll()
        presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
    }

}
