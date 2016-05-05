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
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    @IBOutlet weak var namesCapitalizeSwitch: UISwitch!
    @IBOutlet weak var namesSpellCheckSwitch: UISwitch!
    @IBOutlet weak var namesAutocorrectionSwitch: UISwitch!
    @IBOutlet weak var notesCapitalizeSwitch: UISwitch!
    @IBOutlet weak var notesSpellCheckSwitch: UISwitch!
    @IBOutlet weak var notesAutocorrectionSwitch: UISwitch!
    @IBOutlet weak var picsInPrintAndEmailSwitch: UISwitch!
    //@IBOutlet weak var syncCloudOnLaunch: UISwitch!

    override func viewDidLoad()
    {
        super.viewDidLoad()
        manager.delegate = self

        // set initial values for switches
        self.namesCapitalizeSwitch.on     = appDelegate.namesCapitalize
        self.namesSpellCheckSwitch.on     = appDelegate.namesSpellCheck
        self.namesAutocorrectionSwitch.on = appDelegate.namesAutocorrection
        self.notesCapitalizeSwitch.on     = appDelegate.notesCapitalize
        self.notesSpellCheckSwitch.on     = appDelegate.notesSpellCheck
        self.notesAutocorrectionSwitch.on = appDelegate.notesAutocorrection
        self.picsInPrintAndEmailSwitch.on = appDelegate.picsInPrintAndEmail
        //self.syncCloudOnLaunch.on         = appDelegate.syncCloudOnLaunch
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
        //appDelegate.syncCloudOnLaunch    = self.syncCloudOnLaunch.on
        
        appDelegate.saveState(true)
        
        presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
    }
}

