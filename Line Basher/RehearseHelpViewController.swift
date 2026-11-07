//
//  RehearseHelpViewController.swift
//  Line Basher
//
//  Created by Smith Family on 7/12/17.
//  Copyright © 2017 GammaRay Software. All rights reserved.
//

import UIKit
import SpriteKit
import CoreData
import Speech
import StoreKit
import GoogleMobileAds
import CoreFoundation

class RehearseHelpViewController: UIViewController
{
    
    @IBOutlet weak var btnRehearseHelpAction: UIButton!
    @IBOutlet weak var txtHelpText: UITextView!
    
    override func viewDidLoad()
    {
        
    }
    
    @IBAction func btnCloseHelp(_ sender: Any)
    {
        navigationController?.popViewController(animated: true)
        
        dismiss(animated: true, completion: nil)
    }
}
