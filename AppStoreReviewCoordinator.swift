//
//  AppStoreReviewCoordinator.swift
//  BillMinder
//
//  Created by Jim Spencer on 9/9/17.
//  Copyright © 2017 Jim Spencer. All rights reserved.
//
// Thank you, Jim. From GammaRaySoftare!
import UIKit
import StoreKit

class AppStoreReviewCoordinator: NSObject {
    
    let runTriggerCount = 5   //Set this to the number of runs you want before the review is requested.
    let eventTriggerCount = 1  //Set this for the number of triggers you want before the review is requested.
    
    var runCounter : Int {
        get {
            return UserDefaults.standard.integer(forKey: "AppStoreCoordinatorRunCounter")
        }
        set {
            if newValue == runCounter {return}
            UserDefaults.standard.setValue(newValue, forKey: "AppStoreCoordinatorRunCounter")
            UserDefaults.standard.synchronize()
        }
    }
    
    var eventCounter : Int {
        get {
            return UserDefaults.standard.integer(forKey: "AppStoreCoordinatorEventCounter")
        }
        set {
            if newValue == eventCounter {return}
            UserDefaults.standard.setValue(newValue, forKey: "AppStoreCoordinatorEventCounter")
            UserDefaults.standard.synchronize()
        }
    }
    
    func incrementRunCounter() {
        //Don't prompt for free users.
        guard fullVersionPurchased else {return}

        self.runCounter = self.runCounter + 1
        
        print("Run Counter: \(self.runCounter)")
        
        if self.runCounter >= self.runTriggerCount {
            self.requestReview()
            self.runCounter = 0
        }
    }
    
    //  Add this line to any place in your code to trigger from special events.
    //  appStoreReviewCoordinator.incrementEventCounter()
    
    func incrementEventCounter() {
        //Don't prompt for free users.
        guard fullVersionPurchased else {return}
        
        self.eventCounter = self.eventCounter + 1
        
        print("Event Counter: \(self.eventCounter)")
        
        if self.eventCounter >= self.runTriggerCount {
            self.requestReview()
            self.eventCounter = 0
        }
    }
    
    //Request the review. Apple will handle showing this only once so you can keep calling it.
    //Just because you call it the first time, Apple may not show it.
    func requestReview() {
        SKStoreReviewController.requestReview()
    }
}

var appStoreReviewCoordinator = AppStoreReviewCoordinator()
var bufferKeyboardHeight: CGFloat = 300
