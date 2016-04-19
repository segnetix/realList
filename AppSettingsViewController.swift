//
//  AppSettingsViewController.swift
//  EnList
//
//  Created by Steven Gentry on 4/16/16.
//  Copyright © 2016 Steven Gentry. All rights reserved.
//

import UIKit

class AppSettingsViewController: UIViewController
{
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
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

        // set initial values for switches
        self.namesCapitalizeSwitch.on     = appDelegate.namesCapitalize
        self.namesSpellCheckSwitch.on     = appDelegate.namesSpellCheck
        self.namesAutocorrectionSwitch.on = appDelegate.namesAutocorrection
        self.notesCapitalizeSwitch.on     = appDelegate.notesCapitalize
        self.notesSpellCheckSwitch.on     = appDelegate.notesSpellCheck
        self.notesAutocorrectionSwitch.on = appDelegate.notesAutocorrection
        self.picsInPrintAndEmailSwitch.on = appDelegate.picsInPrintAndEmail
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func close(sender: UIButton)
    {
        // update app delegate values from switches
        appDelegate.namesCapitalize      = self.namesCapitalizeSwitch.on
        appDelegate.namesSpellCheck      = self.namesSpellCheckSwitch.on
        appDelegate.namesAutocorrection  = self.namesAutocorrectionSwitch.on
        appDelegate.notesCapitalize      = self.notesCapitalizeSwitch.on
        appDelegate.notesSpellCheck      = self.notesSpellCheckSwitch.on
        appDelegate.notesAutocorrection  = self.notesAutocorrectionSwitch.on
        appDelegate.picsInPrintAndEmail  = self.picsInPrintAndEmailSwitch.on
        
        presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
    }
}

