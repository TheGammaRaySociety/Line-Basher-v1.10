//
//  SettingsViewController.swift
//  Line Basher
//
//  Created by Smith Family on 6/26/17.
//  Copyright © 2017 GammaRay Software. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController, UITextFieldDelegate
{
    @IBOutlet weak var lblTextSize: UILabel!
    @IBOutlet weak var txtCharsPerHint: UITextField!
    @IBOutlet weak var switchAlwaysShowLines: UISwitch!
    
    @IBOutlet weak var viewGetFullVersionDesc: UIView!
    @IBOutlet weak var btnGetFullVersion: UIButton!
    @IBOutlet weak var btnZoahArcade: UIButton!
    @IBOutlet weak var btnLifePoint: UIButton!
    @IBOutlet weak var sliderTextSize: UISlider!
    @IBOutlet weak var btnRestorePurchases: UIButton!
    
    @IBOutlet weak var lblHelpAnIndieDev: UILabel!
    @IBOutlet weak var switchAdsOn: UISwitch!
    @IBOutlet weak var lblAdsOn: UILabel!
    
    @IBOutlet weak var btnZoahThello: UIButton!
    @IBOutlet weak var btnGammaRay: UIButton!
    @IBOutlet weak var spnrPurchase: UIActivityIndicatorView!
    
    override var prefersStatusBarHidden: Bool
        {
        get {return false}
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        lblTextSize.font = lblTextSize.font.withSize(textSize)
        sliderTextSize.value = Float(textSize)
        
        txtCharsPerHint.text = "\(charsPerHint)"
        
        switchAlwaysShowLines.setOn(alwaysShowLines, animated: false)
        switchAdsOn.setOn(showAdsEvenWhenPaid, animated: false)
        
        NotificationCenter.default.addObserver(self, selector: #selector(purchaseHasBeenConfirmed), name: NSNotification.Name(rawValue: IAPHelper.IAPHelperPurchaseNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(purchaseFailed), name: NSNotification.Name(rawValue: IAPHelper.IAPHelperPurchaseFailed), object: nil)

        addDoneButtonOnKeyboard()
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        spnrPurchase.alpha = 0
        spnrPurchase.stopAnimating()
        btnRestorePurchases.setTitle("Restore", for: UIControlState.normal)
        btnGetFullVersion.setTitle("Purchase", for: UIControlState.normal)
        checkFullVersionGraphics()
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        textSize = CGFloat(sliderTextSize.value)
        charsPerHint = Int(txtCharsPerHint.text!) ?? 10
        alwaysShowLines = switchAlwaysShowLines.isOn
        dbObj.setUserDefaults()
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func checkFullVersionGraphics()
    {
        if fullVersionPurchased
        {
            viewGetFullVersionDesc.alpha = 0
            btnGetFullVersion.alpha = 0
            btnRestorePurchases.alpha = 0
            lblAdsOn.alpha = 1
            lblHelpAnIndieDev.alpha = 1
            switchAdsOn.alpha = 1
        } else
        {
            viewGetFullVersionDesc.alpha = 1
            btnGetFullVersion.alpha = 1
            btnRestorePurchases.alpha = 1
            lblAdsOn.alpha = 0
            lblHelpAnIndieDev.alpha = 0
            switchAdsOn.alpha = 0
        }
    }
    
    func addDoneButtonOnKeyboard()
    {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 50))
        doneToolbar.barStyle       = UIBarStyle.default
        let flexSpace              = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem  = UIBarButtonItem(title: "Finish", style: UIBarButtonItemStyle.done, target: self, action: #selector(doneButtonIsPressed))
        
        var items = [UIBarButtonItem]()
        items.append(flexSpace)
        items.append(done)
        
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        
        txtCharsPerHint.inputAccessoryView = doneToolbar
    }
    
    @objc func doneButtonIsPressed()
    {
        txtCharsPerHint.resignFirstResponder()
        
        if let tempHintChars: Int = Int(txtCharsPerHint.text!)
        {
            if tempHintChars > 0 && tempHintChars <= 50
            {
                txtCharsPerHint.text = "\(tempHintChars)"
                charsPerHint = tempHintChars
            } else
            {
                txtCharsPerHint.text = "/(charsPerHint)"
            }
        } else
        {
            txtCharsPerHint.text = "/(charsPerHint)"
        }
    }
    
    @IBAction func showLineAction(_ sender: UISwitch)
    {
        if switchAlwaysShowLines.isOn
        {
            alwaysShowLines = true
            switchAlwaysShowLines.setOn(true, animated: true)
        } else
        {
            alwaysShowLines = false
            switchAlwaysShowLines.setOn(false, animated: true)
        }
    }
    
    @IBAction func showAdsAction(_ sender: Any)
    {
        if switchAdsOn.isOn
        {
            showAdsEvenWhenPaid = true
            switchAdsOn.setOn(true, animated: true)
            print ("Show Ads is On")
        } else
        {
            showAdsEvenWhenPaid = false
            switchAdsOn.setOn(false, animated: true)
            print ("Show Ads is Off")
        }
        
    }
    
    @IBAction func lineSizeAction(_ sender: Any)
    {
        let currentValue = sliderTextSize.value
        
        lblTextSize.font = lblTextSize.font.withSize(CGFloat(currentValue))
    }
    
    @IBAction func btnGammaRayAction(_ sender: Any)
    {
        if let url = URL(string: "http://www.gammaraysoftware.com")
        {
            UIApplication.shared.open(url, options: [:])
        }
    }
    
    @IBAction func btnZoahThelloAction(_ sender: Any)
    {
        if let url = URL(string: "https://itunes.apple.com/us/app/zoah-thello/id1260674883?ls=1&mt=8")
        {
            UIApplication.shared.open(url, options: [:])
        }
    }
    
    @IBAction func btnZoahArcadeAction(_ sender: Any)
    {
            if let url = URL(string: "http://itunes.apple.com/us/app/zoah-arcade/id1140731857?mt=8")
        {
            UIApplication.shared.open(url, options: [:])
        }
    }
    
    @IBAction func btnLifePointAction(_ sender: Any)
    {
        if let url = URL(string: "http://itunes.apple.com/us/app/lifepoint-tracker/id590198757?mt=8")
        {
            UIApplication.shared.open(url, options: [:])
        }
    }
    
    @IBAction func btnRestorePurchaseAction(_ sender: Any)
    {
        spnrPurchase.alpha = 1
        spnrPurchase.startAnimating()
        btnRestorePurchases.setTitle("Working", for: UIControlState.normal)
        LineBasherProducts.store.restorePurchases()
    }
    
    @IBAction func btnPayFullVersionAction(_ sender: Any)
    {
        spnrPurchase.alpha = 1
        spnrPurchase.startAnimating()
        btnGetFullVersion.setTitle("Working", for: UIControlState.normal)
        if LineBasherProducts.store.listOfProducts.count > 0
        {
            for p in LineBasherProducts.store.listOfProducts
            {
                if p.localizedTitle == "FullVersion"
                {
                    LineBasherProducts.store.buyProduct(p)
                 }
            }
        }
    }
    
    @objc func purchaseFailed()
    {
        viewGetFullVersionDesc.alpha = 1
        btnGetFullVersion.alpha = 1
        btnRestorePurchases.alpha = 1
        btnGetFullVersion.setTitle("Purchase", for: UIControlState.normal)
        btnRestorePurchases.setTitle("Restore", for: UIControlState.normal)
        spnrPurchase.stopAnimating()
        spnrPurchase.alpha = 0
    }
    
    @objc func purchaseHasBeenConfirmed()
    {
        viewGetFullVersionDesc.alpha = 0
        btnGetFullVersion.alpha = 0
        btnRestorePurchases.alpha = 0
        spnrPurchase.stopAnimating()
        spnrPurchase.alpha = 0
    }
}
