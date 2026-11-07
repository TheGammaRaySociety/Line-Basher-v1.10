//
//  WebHelpViewController.swift
//  Line Basher
//
//  Created by Smith Family on 7/13/17.
//  Copyright © 2017 GammaRay Software. All rights reserved.
//

import UIKit
import WebKit

class WebHelpViewController: UIViewController
{

    @IBOutlet weak var wbHelpView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //1. Load web site into my web view
        let myURL = URL(string: "http://gammaraysoftware.com/LineBasherHelp.html")
        let myURLRequest:URLRequest = URLRequest(url: myURL!)
        wbHelpView.load(myURLRequest)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
