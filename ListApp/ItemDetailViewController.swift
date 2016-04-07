//
//  ItemDetailViewController.swift
//  EnList
//
//  Created by Steven Gentry on 2/6/16.
//  Copyright © 2016 Steven Gentry. All rights reserved.
//

import UIKit

class ItemDetailViewController: UIViewController, UITextViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate
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
    var addPhotoButton = UIButton()
    var imageView = UIImageView()
    var spacerLabel = UILabel()
    var infoVertStackView = UIStackView()
    var closeButton: UIButton = UIButton()
    var itemVC: ItemViewController!
    var item: Item!
    var list: List!
    let imagePicker = UIImagePickerController()
    
////////////////////////////////////////////////////////////////
//
//  MARK: - Init methods
//
////////////////////////////////////////////////////////////////
    
    init(item: Item, list: List, itemVC: ItemViewController)
    {
        super.init(nibName: nil, bundle: nil)
        
        modalPresentationStyle = UIModalPresentationStyle.Custom
        self.item = item
        self.list = list
        self.itemVC = itemVC
        
        createUI()
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        imagePicker.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func createUI()
    {
        let wideDisplay = view.frame.width >= 768
        let shortDisplay = view.frame.height < 568
        let formatter = NSDateFormatter()
        formatter.dateStyle = NSDateFormatterStyle.MediumStyle
        formatter.timeStyle = .MediumStyle
        let padding = "    "
        var dateString = ""
        
        titleLabel.text = item.name
        noteTextView.text = item.note
        
        // overall container view
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = UIColor(white: 1.0, alpha: 1.0)
        view.addSubview(containerView)

        // title label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
        if item.state != ItemState.Inactive {
            titleLabel.textColor = UIColor.blackColor()
        } else {
            titleLabel.textColor = UIColor.lightGrayColor()
        }
        
        titleLabel.textAlignment = NSTextAlignment.Left
        containerView.addSubview(titleLabel)
        
        // note text view
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
        
        // image view
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.borderColor = containerView.tintColor.CGColor
        if list.listColor != nil {
            imageView.layer.borderColor = list.listColor!.CGColor
        } else {
            imageView.layer.borderColor = containerView.tintColor.CGColor
        }
        imageView.layer.borderWidth = 2.0
        imageView.layer.cornerRadius = 5.0
        if item.imageAsset?.image != nil {
            imageView.image = item.getImage()
        } else {
            imageView.image = nil
        }
        imageView.image = item.imageAsset?.image
        imageView.contentMode = .ScaleAspectFit
        containerView.addSubview(imageView)
        
        // info text
        var infoTextFont: UIFont = UIFont.preferredFontForTextStyle(UIFontTextStyleFootnote)
        
        if wideDisplay {
            infoTextFont = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        }
        
        createdLabel.translatesAutoresizingMaskIntoConstraints = false
        createdLabel.font = infoTextFont
        createdLabel.text = NSLocalizedString("Created", comment: "label for the 'Created:' text field.")
        
        createdByText.translatesAutoresizingMaskIntoConstraints = false
        createdByText.font = infoTextFont
        createdByText.text = padding + item.createdBy
        
        createdDateText.translatesAutoresizingMaskIntoConstraints = false
        createdDateText.font = infoTextFont
        dateString = formatter.stringFromDate(item.createdDate)
        createdDateText.text = padding + dateString
        
        spacerLabel.translatesAutoresizingMaskIntoConstraints = false
        spacerLabel.font = infoTextFont
        spacerLabel.text = padding
        
        modifiedLabel.translatesAutoresizingMaskIntoConstraints = false
        modifiedLabel.font = infoTextFont
        modifiedLabel.text = NSLocalizedString("Modified", comment: "label for the 'Modified:' text field.")
        
        modifiedByText.translatesAutoresizingMaskIntoConstraints = false
        modifiedByText.font = infoTextFont
        modifiedByText.text = padding + item.modifiedBy
        
        modifiedDateText.translatesAutoresizingMaskIntoConstraints = false
        modifiedDateText.font = infoTextFont
        dateString = formatter.stringFromDate(item.modifiedDate)
        modifiedDateText.text = padding + dateString
        
        // info text stack
        infoVertStackView.axis = .Vertical
        infoVertStackView.distribution = .EqualSpacing
        infoVertStackView.alignment = .Leading
        infoVertStackView.spacing = 0
        infoVertStackView.translatesAutoresizingMaskIntoConstraints = false
        
        infoVertStackView.addArrangedSubview(createdLabel)
        infoVertStackView.addArrangedSubview(createdByText)
        infoVertStackView.addArrangedSubview(createdDateText)
        infoVertStackView.addArrangedSubview(spacerLabel)
        infoVertStackView.addArrangedSubview(modifiedLabel)
        infoVertStackView.addArrangedSubview(modifiedByText)
        infoVertStackView.addArrangedSubview(modifiedDateText)
        containerView.addSubview(infoVertStackView)
        
        // photo button
        addPhotoButton.translatesAutoresizingMaskIntoConstraints = false
        addPhotoButton.addTarget(self, action: #selector(ItemDetailViewController.addPhoto(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        if item.imageAsset?.image == nil {
            setPhotoButton(true)
        } else {
            setPhotoButton(false)
        }
        containerView.addSubview(addPhotoButton)
        
        // close button
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setImage(UIImage(named: "Close Window_blue"), forState: .Normal)
        closeButton.addTarget(self, action: #selector(ItemDetailViewController.close(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        containerView.addSubview(closeButton)
        
        let views: [String : AnyObject] = [
            "containerView": containerView,
            "titleLabel": titleLabel,
            "noteTextView": noteTextView,
            "infoVertStackView": infoVertStackView,
            "photoButton": addPhotoButton,
            "imageView": imageView,
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
        /*
        containerView.addConstraints(
            NSLayoutConstraint.constraintsWithVisualFormat(
                "H:|-20-[midHorizStackView]-20-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: nil,
                views: views))
        */
        
        if wideDisplay {
            containerView.addConstraints(
                NSLayoutConstraint.constraintsWithVisualFormat(
                    "H:|-20-[infoVertStackView]-(>=24)-[photoButton]-24-[imageView(360)]-20-|",
                    options: [.AlignAllTop],
                    metrics: nil,
                    views: views))
        } else if !shortDisplay {
            containerView.addConstraints(
                NSLayoutConstraint.constraintsWithVisualFormat(
                    "H:|-20-[photoButton]-(>=24)-[imageView(200)]-20-|",
                    options: [.AlignAllTop],
                    metrics: nil,
                    views: views))
            
            containerView.addConstraints(
                NSLayoutConstraint.constraintsWithVisualFormat(
                    "H:|-20-[infoVertStackView]",
                    options: NSLayoutFormatOptions(rawValue: 0),
                    metrics: nil,
                    views: views))
        } else {
            containerView.addConstraints(
                NSLayoutConstraint.constraintsWithVisualFormat(
                    "H:|-20-[photoButton]-(>=24)-[imageView(180)]-20-|",
                    options: [.AlignAllTop],
                    metrics: nil,
                    views: views))
            
            containerView.addConstraints(
                NSLayoutConstraint.constraintsWithVisualFormat(
                    "H:|-20-[infoVertStackView]",
                    options: NSLayoutFormatOptions(rawValue: 0),
                    metrics: nil,
                    views: views))
        }
        
        /*
        containerView.addConstraints(
            NSLayoutConstraint.constraintsWithVisualFormat(
                "H:|-18-[createdLabel]|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: nil,
                views: views))
        
        infoVertStackView.addConstraints(
            NSLayoutConstraint.constraintsWithVisualFormat(
                "H:|-40-[createdByText]|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: nil,
                views: views))
        
        infoVertStackView.addConstraints(
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
        */
        
        containerView.addConstraints(
            NSLayoutConstraint.constraintsWithVisualFormat(
                "H:|[closeButton]|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: nil,
                views: views))
        
        if wideDisplay {
            containerView.addConstraints(
                NSLayoutConstraint.constraintsWithVisualFormat(
                    "V:|-32-[titleLabel]-[noteTextView(250)]-24-[imageView(270)]-(>=8)-[closeButton]-24-|",
                    options: NSLayoutFormatOptions(rawValue: 0),
                    metrics: nil,
                    views: views))
        } else if !shortDisplay {
            containerView.addConstraints(
                NSLayoutConstraint.constraintsWithVisualFormat(
                    "V:|-20-[titleLabel]-2-[noteTextView(150)]-[imageView(150)]-(>=8)-[infoVertStackView]-(>=12)-[closeButton]-16-|",
                    options: NSLayoutFormatOptions(rawValue: 0),
                    metrics: nil,
                    views: views))
        } else {
            containerView.addConstraints(
                NSLayoutConstraint.constraintsWithVisualFormat(
                    "V:|-16-[titleLabel]-2-[noteTextView(120)]-[imageView(135)]-(>=0)-[infoVertStackView]-(>=8)-[closeButton]-8-|",
                    options: NSLayoutFormatOptions(rawValue: 0),
                    metrics: nil,
                    views: views))
        }
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool
    {
        if (text == "\n") {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
////////////////////////////////////////////////////////////////
//
//  MARK: - Photo methods
//
////////////////////////////////////////////////////////////////
    
    func addPhoto(sender: UIButton)
    {
        var photoAction: UIAlertAction?
        
        if UIImagePickerController.availableCaptureModesForCameraDevice(.Rear) != nil {
            photoAction = UIAlertAction(title: "Take Photo", style: .Default, handler: { (alert: UIAlertAction!) in
                dispatch_async(dispatch_get_main_queue()) {
                    self.imagePicker.allowsEditing = false
                    self.imagePicker.sourceType = .Camera
                    self.presentViewController(self.imagePicker, animated: true, completion: nil)
                }
            } )
        }
        
        let alertVC = UIAlertController(
            title: "Add Photo",
            message: "",
            preferredStyle: .Alert)
        let libraryAction = UIAlertAction(title: "Photo Library", style: .Default, handler: { (alert: UIAlertAction!) in
            dispatch_async(dispatch_get_main_queue()) {
                self.imagePicker.allowsEditing = false
                self.imagePicker.sourceType = .PhotoLibrary
                self.presentViewController(self.imagePicker, animated: true, completion: nil)
            }
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil )
        alertVC.addAction(libraryAction)
        alertVC.addAction(cancelAction)
        if photoAction != nil {
            alertVC.addAction(photoAction!)
        }
        presentViewController(alertVC, animated: true, completion: nil)
    }
    
    func deletePhoto(sender: UIButton)
    {
        let alertVC = UIAlertController(
            title: "Delete Photo?",
            message: "Are you sure want to delete this photo?",
            preferredStyle: .Alert)
        let deleteAction = UIAlertAction(title: "Delete", style: .Destructive, handler: { (alert: UIAlertAction!) in
            dispatch_async(dispatch_get_main_queue()) {
                self.imageView.image = nil
                self.setPhotoButton(true)
            }
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil )
        alertVC.addAction(deleteAction)
        alertVC.addAction(cancelAction)
        presentViewController(alertVC, animated: true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject])
    {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            imageView.image = resizeImage(pickedImage, newWidth: 360)       // set to iPad width
            setPhotoButton(false)
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage
    {
        let scale = newWidth / image.size.width
        let newHeight = image.size.height * scale
        UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight))
        image.drawInRect(CGRectMake(0, 0, newWidth, newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController)
    {
        dismissViewControllerAnimated(true, completion: nil)
        setPhotoButton(true)
    }
    
    func setPhotoButton(add: Bool)
    {
        var cameraImage: UIImage?
        var tintedImage: UIImage?
        
        addPhotoButton.removeTarget(nil, action: nil, forControlEvents: .AllEvents)
        
        if add {
            cameraImage = UIImage(named: "Camera")
            tintedImage = UIImage(named: "Camera")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
            addPhotoButton.addTarget(self, action: #selector(ItemDetailViewController.addPhoto(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        } else {
            cameraImage = UIImage(named: "Camera_delete")
            tintedImage = UIImage(named: "Camera_delete")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
            addPhotoButton.addTarget(self, action: #selector(ItemDetailViewController.deletePhoto(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        }
        
        if list.listColor != nil {
            addPhotoButton.setImage(tintedImage, forState: .Normal)
            addPhotoButton.tintColor = list.listColor!
        } else {
            addPhotoButton.setImage(cameraImage, forState: .Normal)
        }
    }
    
////////////////////////////////////////////////////////////////
//
//  MARK: - Close method
//
////////////////////////////////////////////////////////////////
    
    func close(sender: UIButton)
    {
        self.item.note = noteTextView.text
        self.item.setImage(imageView.image)
        self.item.needToSave = true
        self.itemVC.tableView.reloadData()
        self.itemVC.appDelegate.saveAll()
        
        presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
    }
    
}
