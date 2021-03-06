//
//  AppSettingsViewController.swift
//  EnList
//
//  Created by Steven Gentry on 4/16/16.
//  Copyright © 2016 Steven Gentry. All rights reserved.
//

import UIKit

class AppSettingsViewController: UIAppViewController
{
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    @IBOutlet weak var namesCapitalizeSwitch: UISwitch!
    @IBOutlet weak var namesSpellCheckSwitch: UISwitch!
    @IBOutlet weak var namesAutocorrectionSwitch: UISwitch!
    @IBOutlet weak var notesCapitalizeSwitch: UISwitch!
    @IBOutlet weak var notesSpellCheckSwitch: UISwitch!
    @IBOutlet weak var notesAutocorrectionSwitch: UISwitch!
    @IBOutlet weak var picsInPrintAndEmailSwitch: UISwitch!

    override func viewDidLoad()
    {
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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func close(_ sender: UIButton)
    {
        // update app delegate values from switches
        appDelegate.namesCapitalize      = self.namesCapitalizeSwitch.isOn
        appDelegate.namesSpellCheck      = self.namesSpellCheckSwitch.isOn
        appDelegate.namesAutocorrection  = self.namesAutocorrectionSwitch.isOn
        appDelegate.notesCapitalize      = self.notesCapitalizeSwitch.isOn
        appDelegate.notesSpellCheck      = self.notesSpellCheckSwitch.isOn
        appDelegate.notesAutocorrection  = self.notesAutocorrectionSwitch.isOn
        appDelegate.picsInPrintAndEmail  = self.picsInPrintAndEmailSwitch.isOn
        
        appDelegate.saveState(async: true)
        
        presentingViewController!.dismiss(animated: true, completion: nil)
    }
}

