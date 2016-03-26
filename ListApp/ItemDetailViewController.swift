//
//  ItemDetailViewController.swift
//  EnList
//
//  Created by Steven Gentry on 2/6/16.
//  Copyright © 2016 Steven Gentry. All rights reserved.
//

import UIKit

class ItemDetailViewController: UIViewController, UITextViewDelegate
{
    var containerView: UIView = UIView()
    var titleLabel: UILabel = UILabel()
    var createdLabel: UILabel = UILabel()
    var createdByText: UILabel = UILabel()
    var createdDateText: UILabel = UILabel()
    var modifiedLabel: UILabel = UILabel()
    var modifiedByText: UILabel = UILabel()
    var modifiedDateText: UILabel = UILabel()
    var noteTextView = UITextView()
    var closeButton: UIButton = UIButton()
    var itemVC: ItemViewController!
    var item: Item!
    var list: List!
    
    init(item: Item, list: List, itemVC: ItemViewController)
    {
        super.init(nibName: nil, bundle: nil)
        
        modalPresentationStyle = UIModalPresentationStyle.Custom
        self.item = item
        self.list = list
        self.itemVC = itemVC
        
        createUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func createUI()
    {
        let formatter = NSDateFormatter()
        formatter.dateStyle = NSDateFormatterStyle.MediumStyle
        formatter.timeStyle = .MediumStyle
        var dateString = ""
        
        titleLabel.text = item.name
        noteTextView.text = item.note
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = UIColor(white: 1.0, alpha: 1.0)
        view.addSubview(containerView)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
        if item.state != ItemState.Inactive {
            titleLabel.textColor = UIColor.blackColor()
        } else {
            titleLabel.textColor = UIColor.lightGrayColor()
        }
        
        titleLabel.textAlignment = NSTextAlignment.Left
        containerView.addSubview(titleLabel)
        
        noteTextView.translatesAutoresizingMaskIntoConstraints = false
        noteTextView.textColor = UIColor.blackColor()
        noteTextView.layer.borderColor = containerView.tintColor.CGColor
        if list.listColor != nil {
            noteTextView.layer.borderColor = list.listColor!.CGColor
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
        
        createdLabel.translatesAutoresizingMaskIntoConstraints = false
        createdLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleFootnote)
        createdLabel.text = NSLocalizedString("Created", comment: "label for the 'Created:' text field.")
        containerView.addSubview(createdLabel)
        
        createdByText.translatesAutoresizingMaskIntoConstraints = false
        createdByText.font = UIFont.preferredFontForTextStyle(UIFontTextStyleFootnote)
        createdByText.text = item.createdBy
        containerView.addSubview(createdByText)
    
        createdDateText.translatesAutoresizingMaskIntoConstraints = false
        createdDateText.font = UIFont.preferredFontForTextStyle(UIFontTextStyleFootnote)
        dateString = formatter.stringFromDate(item.createdDate)
        createdDateText.text = dateString
        containerView.addSubview(createdDateText)
        
        modifiedLabel.translatesAutoresizingMaskIntoConstraints = false
        modifiedLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleFootnote)
        modifiedLabel.text = NSLocalizedString("Modified", comment: "label for the 'Modified:' text field.")
        containerView.addSubview(modifiedLabel)
        
        modifiedByText.translatesAutoresizingMaskIntoConstraints = false
        modifiedByText.font = UIFont.preferredFontForTextStyle(UIFontTextStyleFootnote)
        modifiedByText.text = item.modifiedBy
        containerView.addSubview(modifiedByText)
        
        modifiedDateText.translatesAutoresizingMaskIntoConstraints = false
        modifiedDateText.font = UIFont.preferredFontForTextStyle(UIFontTextStyleFootnote)
        dateString = formatter.stringFromDate(item.modifiedDate)
        modifiedDateText.text = dateString
        containerView.addSubview(modifiedDateText)
        
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setImage(UIImage(named: "Close Window_blue"), forState: .Normal)
        closeButton.addTarget(self, action: #selector(ItemDetailViewController.close(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        containerView.addSubview(closeButton)
        
        let views: [String : AnyObject] = [
            "containerView": containerView,
            "titleLabel": titleLabel,
            "noteTextView": noteTextView,
            "createdLabel": createdLabel,
            "createdByText": createdByText,
            "createdDateText": createdDateText,
            "modifiedLabel": modifiedLabel,
            "modifiedByText": modifiedByText,
            "modifiedDateText": modifiedDateText,
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
                "H:|-18-[createdLabel]|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: nil,
                views: views))
        
        containerView.addConstraints(
            NSLayoutConstraint.constraintsWithVisualFormat(
                "H:|-40-[createdByText]|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: nil,
                views: views))
        
        containerView.addConstraints(
            NSLayoutConstraint.constraintsWithVisualFormat(
                "H:|-40-[createdDateText]|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: nil,
                views: views))
        
        containerView.addConstraints(
            NSLayoutConstraint.constraintsWithVisualFormat(
                "H:|-18-[modifiedLabel]|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: nil,
                views: views))
        
        containerView.addConstraints(
            NSLayoutConstraint.constraintsWithVisualFormat(
                "H:|-40-[modifiedByText]|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: nil,
                views: views))
        
        containerView.addConstraints(
            NSLayoutConstraint.constraintsWithVisualFormat(
                "H:|-40-[modifiedDateText]|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: nil,
                views: views))
        
        containerView.addConstraints(
            NSLayoutConstraint.constraintsWithVisualFormat(
                "V:|-24-[titleLabel]-[noteTextView(150)]-24-[createdLabel]-[createdByText]-[createdDateText]-24-[modifiedLabel]-[modifiedByText]-[modifiedDateText]-(>=20)-[closeButton]-24-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: nil,
                views: views))
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool
    {
        if (text == "\n") {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    func close(sender: UIButton)
    {
        self.item.note = noteTextView.text
        self.item.needToSave = true
        self.itemVC.tableView.reloadData()
        self.itemVC.appDelegate.saveAll()
        
        presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
    }
    
}
