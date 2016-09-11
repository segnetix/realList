//
//  ItemDetailViewController.swift
//  EnList
//
//  Created by Steven Gentry on 2/6/16.
//  Copyright © 2016 Steven Gentry. All rights reserved.
//

import UIKit

class ItemDetailViewController: UIAppViewController, UITextViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate
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
    var spacerView = UIView()
    var infoVertStackView = UIStackView()
    var closeButton: UIButton = UIButton()
    var itemVC: ItemViewController!
    var item: Item!
    var list: List!
    let imagePicker = UIImagePickerController()
    let formatter = DateFormatter()
    let padding = "   "
    var dateString = ""
    
////////////////////////////////////////////////////////////////
//
//  MARK: - Init methods
//
////////////////////////////////////////////////////////////////
    
    init(item: Item, list: List, itemVC: ItemViewController)
    {
        super.init(nibName: nil, bundle: nil)
        
        modalPresentationStyle = UIModalPresentationStyle.custom
        self.item = item
        self.list = list
        self.itemVC = itemVC
        
        formatter.dateStyle = DateFormatter.Style.medium
        formatter.timeStyle = .medium
        
        createUI()
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        imagePicker.delegate = self
        manager.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func createUI()
    {
        let wideDisplay = view.frame.width >= 768
        let shortDisplay = view.frame.height < 568
        
        titleLabel.text = item.name
        noteTextView.text = item.note
        
        // overall container view
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = UIColor(white: 1.0, alpha: 1.0)
        view.addSubview(containerView)

        // title label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)
        if item.state != ItemState.inactive {
            titleLabel.textColor = UIColor.black
        } else {
            titleLabel.textColor = UIColor.lightGray
        }
        
        titleLabel.textAlignment = NSTextAlignment.left
        containerView.addSubview(titleLabel)
        
        // note text view
        noteTextView.translatesAutoresizingMaskIntoConstraints = false
        noteTextView.textColor = UIColor.black
        noteTextView.layer.borderColor = containerView.tintColor.cgColor
        if list.listColor != nil {
            noteTextView.layer.borderColor = list.listColor!.cgColor
        } else {
            noteTextView.layer.borderColor = containerView.tintColor.cgColor
        }
        noteTextView.layer.borderWidth = 3.0
        noteTextView.layer.cornerRadius = 8.0
        noteTextView.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)
        noteTextView.textAlignment = NSTextAlignment.left
        noteTextView.returnKeyType = UIReturnKeyType.done
        noteTextView.autocapitalizationType = appDelegate.namesCapitalize     ? .sentences : .none
        noteTextView.spellCheckingType      = appDelegate.namesSpellCheck     ? .yes       : .no
        noteTextView.autocorrectionType     = appDelegate.namesAutocorrection ? .yes       : .no
        noteTextView.delegate = self
        containerView.addSubview(noteTextView)
        
        // image view
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.borderColor = containerView.tintColor.cgColor
        if list.listColor != nil {
            imageView.layer.borderColor = list.listColor!.cgColor
        } else {
            imageView.layer.borderColor = containerView.tintColor.cgColor
        }
        imageView.layer.borderWidth = 3.0
        imageView.layer.cornerRadius = 8.0
        imageView.clipsToBounds = true
        if item.imageAsset?.image != nil {
            imageView.image = item.getImage()
        } else {
            imageView.image = nil
        }
        imageView.image = item.imageAsset?.image
        imageView.contentMode = .scaleAspectFit
        containerView.addSubview(imageView)
        
        // info text
        let infoTextFont: UIFont = UIFont.preferredFont(forTextStyle: UIFontTextStyle.footnote)
        
        //if wideDisplay {
        //    infoTextFont = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        //}
        
        createdLabel.translatesAutoresizingMaskIntoConstraints = false
        createdLabel.font = infoTextFont
        createdLabel.text = NSLocalizedString("Created", comment: "label for the 'Created:' text field.")
        
        createdByText.translatesAutoresizingMaskIntoConstraints = false
        createdByText.font = infoTextFont
        createdByText.text = padding + item.createdBy
        
        createdDateText.translatesAutoresizingMaskIntoConstraints = false
        createdDateText.font = infoTextFont
        dateString = formatter.string(from: item.createdDate as Date)
        createdDateText.text = padding + dateString
        
        //spacerLabel.translatesAutoresizingMaskIntoConstraints = false
        //spacerLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleFootnote)
        //spacerLabel.text = padding
        
        spacerView.translatesAutoresizingMaskIntoConstraints = false  
        spacerView.sizeThatFits(CGSize(width: 60, height: 8))
        
        modifiedLabel.translatesAutoresizingMaskIntoConstraints = false
        modifiedLabel.font = infoTextFont
        modifiedLabel.text = NSLocalizedString("Modified", comment: "label for the 'Modified:' text field.")
        
        modifiedByText.translatesAutoresizingMaskIntoConstraints = false
        modifiedByText.font = infoTextFont
        modifiedByText.text = padding + item.modifiedBy
        
        modifiedDateText.translatesAutoresizingMaskIntoConstraints = false
        modifiedDateText.font = infoTextFont
        dateString = formatter.string(from: item.modifiedDate as Date)
        modifiedDateText.text = padding + dateString
        
        // info text stack
        infoVertStackView.axis = .vertical
        infoVertStackView.distribution = .equalCentering
        infoVertStackView.alignment = .leading
        infoVertStackView.spacing = 0
        infoVertStackView.translatesAutoresizingMaskIntoConstraints = false
        
        infoVertStackView.addArrangedSubview(createdLabel)
        infoVertStackView.addArrangedSubview(createdByText)
        infoVertStackView.addArrangedSubview(createdDateText)
        if !shortDisplay {
            infoVertStackView.addArrangedSubview(spacerView)
        }
        infoVertStackView.addArrangedSubview(modifiedLabel)
        infoVertStackView.addArrangedSubview(modifiedByText)
        infoVertStackView.addArrangedSubview(modifiedDateText)
        containerView.addSubview(infoVertStackView)
        
        // photo button
        addPhotoButton.translatesAutoresizingMaskIntoConstraints = false
        addPhotoButton.addTarget(self, action: #selector(ItemDetailViewController.addPhoto(_:)), for: UIControlEvents.touchUpInside)
        if item.imageAsset?.image == nil {
            setPhotoButton(true)
        } else {
            setPhotoButton(false)
        }
        containerView.addSubview(addPhotoButton)
        
        // close button
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        let origImage = UIImage(named: "Close Window_blue")
        if let origImage = origImage {
            // set close button color from list color
            let tintedImage = origImage.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
            closeButton.setImage(tintedImage, for: UIControlState())
            
            if list!.listColor != nil {
                closeButton.tintColor = list!.listColor
            }
        } else {
            closeButton.setImage(UIImage(named: "Close Window_blue"), for: UIControlState())
        }
        closeButton.addTarget(self, action: #selector(ItemDetailViewController.close(_:)), for: UIControlEvents.touchUpInside)
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
            NSLayoutConstraint.constraints(
                withVisualFormat: "H:|[containerView]|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: nil,
                views: views))
        
        view.addConstraints(
            NSLayoutConstraint.constraints(
                withVisualFormat: "V:|[containerView]|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: nil,
                views: views))
        
        containerView.addConstraints(
            NSLayoutConstraint.constraints(
                withVisualFormat: "H:|-20-[titleLabel]-20-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: nil,
                views: views))
        
        containerView.addConstraints(
            NSLayoutConstraint.constraints(
                withVisualFormat: "H:|-20-[noteTextView]-20-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: nil,
                views: views))
        
        if wideDisplay {
            containerView.addConstraints(
                NSLayoutConstraint.constraints(
                    withVisualFormat: "H:|-20-[infoVertStackView]-(>=24)-[photoButton(40)]-24-[imageView(360)]-20-|",
                    options: [.alignAllTop],
                    metrics: nil,
                    views: views))
            
            containerView.addConstraints(
                NSLayoutConstraint.constraints(
                    withVisualFormat: "V:[infoVertStackView(180)]",
                    options: NSLayoutFormatOptions(rawValue: 0),
                    metrics: nil,
                    views: views))
            
        } else if !shortDisplay {
            containerView.addConstraints(
                NSLayoutConstraint.constraints(
                    withVisualFormat: "H:|-20-[photoButton]-(>=24)-[imageView(200)]-20-|",
                    options: [.alignAllTop],
                    metrics: nil,
                    views: views))
            
            containerView.addConstraints(
                NSLayoutConstraint.constraints(
                    withVisualFormat: "H:|-20-[infoVertStackView]",
                    options: NSLayoutFormatOptions(rawValue: 0),
                    metrics: nil,
                    views: views))
        } else {
            containerView.addConstraints(
                NSLayoutConstraint.constraints(
                    withVisualFormat: "H:|-20-[photoButton]-(>=24)-[imageView(180)]-20-|",
                    options: [.alignAllTop],
                    metrics: nil,
                    views: views))
            
            containerView.addConstraints(
                NSLayoutConstraint.constraints(
                    withVisualFormat: "H:|-20-[infoVertStackView]",
                    options: NSLayoutFormatOptions(rawValue: 0),
                    metrics: nil,
                    views: views))
        }
        
        containerView.addConstraints(
            NSLayoutConstraint.constraints(
                withVisualFormat: "H:|[closeButton]|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: nil,
                views: views))
        
        if wideDisplay {
            containerView.addConstraints(
                NSLayoutConstraint.constraints(
                    withVisualFormat: "V:|-32-[titleLabel]-[noteTextView(250)]-24-[imageView(270)]-(>=8)-[closeButton]-24-|",
                    options: NSLayoutFormatOptions(rawValue: 0),
                    metrics: nil,
                    views: views))
        } else if !shortDisplay {
            containerView.addConstraints(
                NSLayoutConstraint.constraints(
                    withVisualFormat: "V:|-20-[titleLabel]-2-[noteTextView(150)]-[imageView(150)]-(>=8)-[infoVertStackView(135)]-(>=12)-[closeButton]-16-|",
                    options: NSLayoutFormatOptions(rawValue: 0),
                    metrics: nil,
                    views: views))
        } else {
            containerView.addConstraints(
                NSLayoutConstraint.constraints(
                    withVisualFormat: "V:|-16-[titleLabel]-2-[noteTextView(120)]-[imageView(135)]-(>=0)-[infoVertStackView(100)]-(>=8)-[closeButton]-8-|",
                    options: NSLayoutFormatOptions(rawValue: 0),
                    metrics: nil,
                    views: views))
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool
    {
        if (text == "\n") {
            if noteTextView.text != item.note {
                item.note = noteTextView.text
                dateString = formatter.string(from: item.modifiedDate as Date)
                modifiedDateText.text = padding + dateString
                modifiedByText.text = UIDevice.current.name
            }
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
    
    func addPhoto(_ sender: UIButton)
    {
        var photoAction: UIAlertAction?
        let photoLibrary   = NSLocalizedString("Photo_Library", comment: "Photo Library title in the photo import dialog.")
        let takePhotoTitle = NSLocalizedString("Take_Photo", comment: "Take Photo button label in photo import dialog.")
        let addPhotoTitle  = NSLocalizedString("Add_Photo", comment: "Add Photo button label in photo import dialog.")
        let cancelTitle    = NSLocalizedString("Cancel", comment: "Cancel button label in photo import dialog.")
        
        if UIImagePickerController.availableCaptureModes(for: .rear) != nil {
            photoAction = UIAlertAction(title: takePhotoTitle, style: .default, handler: { (alert: UIAlertAction!) in
                DispatchQueue.main.async {
                    self.imagePicker.allowsEditing = false
                    self.imagePicker.sourceType = .camera
                    self.present(self.imagePicker, animated: true, completion: nil)
                }
            } )
        }
        
        let alertVC = UIAlertController(
            title: addPhotoTitle,
            message: "",
            preferredStyle: .alert)
        let libraryAction = UIAlertAction(title: photoLibrary, style: .default, handler: { (alert: UIAlertAction!) in
            DispatchQueue.main.async {
                self.imagePicker.allowsEditing = false
                self.imagePicker.sourceType = .photoLibrary
                self.present(self.imagePicker, animated: true, completion: nil)
            }
        })
        
        let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel, handler: nil)

        if photoAction != nil {
            alertVC.addAction(photoAction!)
        }
        alertVC.addAction(libraryAction)
        alertVC.addAction(cancelAction)
        
        present(alertVC, animated: true, completion: nil)
    }
    
    func deletePhoto(_ sender: UIButton)
    {
        let deletePhotoTitle = NSLocalizedString("Delete_Photo", comment: "Delete Photo title for the delete photo dialog.")
        let deletePhotoMsg   = NSLocalizedString("Delete_Photo_Msg", comment: "Delete Photo question for the delete photo button.")
        let deleteTitle      = NSLocalizedString("Delete", comment: "Delete button title on the photo delete dialog.")
        let cancelTitle      = NSLocalizedString("Cancel", comment: "Cancel button label in photo delete dialog.")
        
        let alertVC = UIAlertController(
            title: deletePhotoTitle,
            message: deletePhotoMsg,
            preferredStyle: .alert)
        let deleteAction = UIAlertAction(title: deleteTitle, style: .destructive, handler: { (alert: UIAlertAction!) in
            DispatchQueue.main.async {
                self.imageView.image = nil
                self.setPhotoButton(true)
            }
        })
        let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel, handler: nil)
        alertVC.addAction(deleteAction)
        alertVC.addAction(cancelAction)
        present(alertVC, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any])
    {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            imageView.image = resizeImage(pickedImage, newWidth: 360)       // set to iPad image view dimensions
            setPhotoButton(false)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController)
    {
        dismiss(animated: true, completion: nil)
        setPhotoButton(true)
    }
    
    func setPhotoButton(_ add: Bool)
    {
        var cameraImage: UIImage?
        var tintedImage: UIImage?
        
        addPhotoButton.removeTarget(nil, action: nil, for: .allEvents)
        
        if add {
            cameraImage = UIImage(named: "Camera")
            tintedImage = UIImage(named: "Camera")!.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
            addPhotoButton.addTarget(self, action: #selector(ItemDetailViewController.addPhoto(_:)), for: UIControlEvents.touchUpInside)
        } else {
            cameraImage = UIImage(named: "Camera_delete")
            tintedImage = UIImage(named: "Camera_delete")!.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
            addPhotoButton.addTarget(self, action: #selector(ItemDetailViewController.deletePhoto(_:)), for: UIControlEvents.touchUpInside)
        }
        
        if list.listColor != nil {
            addPhotoButton.setImage(tintedImage, for: UIControlState())
            addPhotoButton.tintColor = list.listColor!
        } else {
            addPhotoButton.setImage(cameraImage, for: UIControlState())
        }
        
        // update the modified date
        self.item.setImage(imageView.image)
        dateString = formatter.string(from: item.modifiedDate as Date)
        modifiedDateText.text = padding + dateString
    }
    
////////////////////////////////////////////////////////////////
//
//  MARK: - Close method
//
////////////////////////////////////////////////////////////////
    
    func close(_ sender: UIButton)
    {
        //self.item.note = noteTextView.text
        //self.item.setImage(imageView.image)
        self.itemVC.tableView.reloadData()
        
        if item.needToSave {
            self.itemVC.appDelegate.saveListData(asynch: true)
        }
        
        // handles resizing in case the keyboard was presented in the item detail view controller
        self.itemVC.layoutAnimated(true)
        
        presentingViewController!.dismiss(animated: true, completion: nil)
    }
    
}


////////////////////////////////////////////////////////////////
//
//  MARK: - Utility methods
//
////////////////////////////////////////////////////////////////

func resizeImage(_ image: UIImage, newWidth: CGFloat) -> UIImage
{
    // scale the image
    let scale = newWidth / image.size.width
    let newHeight = image.size.height * scale
    UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
    image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return newImage!
}
