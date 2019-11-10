//
//  AppSettingsViewController.swift
//  EnList
//
//  Created by Steven Gentry on 4/16/16.
//  Copyright © 2016 Steven Gentry. All rights reserved.
//

import UIKit

class AppSettingsViewController: UIAppViewController {
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    @IBOutlet weak var namesCapitalizeSwitch: UISwitch!
    @IBOutlet weak var namesSpellCheckSwitch: UISwitch!
    @IBOutlet weak var namesAutocorrectionSwitch: UISwitch!
    @IBOutlet weak var notesCapitalizeSwitch: UISwitch!
    @IBOutlet weak var notesSpellCheckSwitch: UISwitch!
    @IBOutlet weak var notesAutocorrectionSwitch: UISwitch!
    @IBOutlet weak var picsInPrintAndEmailSwitch: UISwitch!
    @IBOutlet weak var doneButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        manager.delegate = self

        // set initial values for switches
        self.namesCapitalizeSwitch.isOn     = appDelegate.namesCapitalize
        self.namesSpellCheckSwitch.isOn     = appDelegate.namesSpellCheck
        self.namesAutocorrectionSwitch.isOn = appDelegate.namesAutocorrection
        self.notesCapitalizeSwitch.isOn     = appDelegate.notesCapitalize
        self.notesSpellCheckSwitch.isOn     = appDelegate.notesSpellCheck
        self.notesAutocorrectionSwitch.isOn = appDelegate.notesAutocorrection
        self.picsInPrintAndEmailSwitch.isOn = appDelegate.picsInPrintAndEmail
        
        doneButton.backgroundColor = UIColor.clear
        doneButton.layer.cornerRadius = 5
        doneButton.layer.borderWidth = 1
        doneButton.layer.borderColor = doneButton.tintColor.cgColor
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func close(_ sender: UIButton) {
        // update app delegate values from switches
        appDelegate.namesCapitalize      = self.namesCapitalizeSwitch.isOn
        appDelegate.namesSpellCheck      = self.namesSpellCheckSwitch.isOn
        appDelegate.namesAutocorrection  = self.namesAutocorrectionSwitch.isOn
        appDelegate.notesCapitalize      = self.notesCapitalizeSwitch.isOn
        appDelegate.notesSpellCheck      = self.notesSpellCheckSwitch.isOn
        appDelegate.notesAutocorrection  = self.notesAutocorrectionSwitch.isOn
        appDelegate.picsInPrintAndEmail  = self.picsInPrintAndEmailSwitch.isOn
        
        DataPersistenceCoordinator.saveState(async: true)
        
        presentingViewController!.dismiss(animated: true, completion: nil)
    }
}

