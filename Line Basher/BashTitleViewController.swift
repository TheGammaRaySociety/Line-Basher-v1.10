//
//  BashTitleViewController.swift
//  Line Basher
//
//  Created by Gregory Smith on 4/20/17.
//  Copyright © 2017 GammaRay Software. All rights reserved.
//

import UIKit
import StoreKit
import GoogleMobileAds

class BashTitleViewController: UIViewController, BannerViewDelegate, UITextFieldDelegate, UITableViewDelegate
{

    @IBOutlet weak var banner: BannerView!
    var interstitial: InterstitialAd?
    var canShowAds: Bool = true
    var interstitialAdReady: Bool = false
    
    @IBOutlet weak var imgTitle: UIImageView!
    @IBOutlet weak var tblWorks: UITableView!

    @IBOutlet weak var constraintTblWorkBottom: NSLayoutConstraint!
    @IBOutlet var gstReOrderWorkTable: UILongPressGestureRecognizer!
    
    @IBOutlet weak var btnArrangeWorks: UIBarButtonItem!
    
    override var prefersStatusBarHidden: Bool
        {
        get {return false}
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()

        banner.isHidden = true
        banner.delegate = self
        banner.adUnitID = "ca-app-pub-8101436191593741/5144797310"
        banner.rootViewController = self
        banner.loadRequest(Request())
        
        loadFullScreenAd(adUnitID: "ca-app-pub-8101436191593741/6621530511")
        
        LineBasherProducts.store.requestProducts(completionHandler: {_,_ in })
        
        tblWorks.dataSource = self
        tblWorks.delegate = self
        tblWorks.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        prepWorkTableView()
        
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        if (fullVersionPurchased && !showAdsEvenWhenPaid)
        {
            banner.alpha = 0
            constraintTblWorkBottom.constant = 0
        } else
        {
            banner.alpha = 1
            constraintTblWorkBottom.constant = 150
        }

        dbObj.loadWorksArrayFromDB()
        dbObj.reNumberWorksInArrayAndSaveToDataBase()
        prepWorkTableView()
        tblWorks.isEditing = false
        btnArrangeWorks.title = "Arrange"
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        tblWorks.isEditing = false
        btnArrangeWorks.title = "Arrange"
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
    
    func prepWorkTableView()
    {
        var newWorkFound: Bool = false
        var count: Int = 0
        
        for work in dbObj.listOfWorks
        {
            if work.name == dbObj.stringNewWorkTapHere || work.name == dbObj.stringWorkPurchaseFullVersion
            {
                if dbObj.listOfWorks.count > 1 && !fullVersionPurchased && work.name == dbObj.stringNewWorkTapHere
                {
                    dbObj.listOfWorks[count].name = dbObj.stringWorkPurchaseFullVersion
                }
                newWorkFound = true
            }
            count = count + 1
        }
        
        if !newWorkFound
        {
            print ("New Work wasn't found - Add")
            dbObj.appendToWorkArrayButNotDatabase()
        }
        ensureNewWorkRowIsLocatedCorrectly()
        tblWorks.reloadData()
    }
    
    func ensureNewWorkRowIsLocatedCorrectly()
    {
        var count: Int = 0
        for work in dbObj.listOfWorks
        {
            let tempString: String = work.name
            if (tempString == dbObj.stringNewWorkTapHere || tempString == dbObj.stringWorkPurchaseFullVersion) && tempString != dbObj.stringErrorString
            {
                let tempObject = dbObj.listOfWorks[count]
                dbObj.listOfWorks.remove(at: count)
                dbObj.listOfWorks.insert(tempObject, at: 0)
            }
            count = count + 1
        }
    }
    @IBAction func editingWorkTableAction(_ sender: Any)
    {
        toggleArrangeWorks()
    }
    
    func toggleArrangeWorks()
    {
        if tblWorks.isEditing
        {
            tblWorks.isEditing = false
            btnArrangeWorks.title = "Arrange"
        } else
        {
            tblWorks.isEditing = true
            btnArrangeWorks.title = "Finish"
        }
    }
    
    //MARK: Ad MobStuff
    func bannerViewDidReceiveAd(_ bannerView: BannerView)
    {
        if canShowAds
        {
            banner.isHidden = false
        } else
        {
            banner.isHidden = true
        }
    }
    
    func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error)
    {
        banner.isHidden = true
    }
    
    func loadFullScreenAd(adUnitID: String)
    {
        InterstitialAd.load(with: adUnitID, request: Request()) { [weak self] ad, _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let ad = ad {
                    self.interstitial = ad
                    self.interstitialAdReady = true
                } else {
                    self.interstitialAdReady = false
                }
            }
        }
    }
    
    func createFullScreenAd()
    {
        loadFullScreenAd(adUnitID: "ca-app-pub-8101436191593741/6621530511")
    }
    
    func showAdsInGame ()
    {
        canShowAds = true
        banner.loadRequest(Request())
    }
    
    func hideAdsInGame ()
    {
        canShowAds = false
        banner.isHidden = true
    }
    
    func showFullScreenAd ()
    {
        guard let ad = interstitial else { return }
        interstitial = nil
        interstitialAdReady = false
        ad.present(from: self)
        createFullScreenAd()
    }
}

// MARK: - UITableViewDataSource
extension BashTitleViewController: UITableViewDataSource
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return dbObj.listOfWorks.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
            return 60
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        
        let work = dbObj.listOfWorks[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "WorkCell", for: indexPath) as! WorkTableViewCell
        
        let nameOfWorkString: String = work.name
        let mainCharString: String = work.mainChar
        
        if indexPath.row == 0
        {
            cell.textLabel?.text = nameOfWorkString
            cell.textLabel?.textColor = UIColor.blue
            cell.textLabel?.font = cell.textLabel?.font.withSize(20)
            
            cell.textLabel?.alpha = 1
            cell.lblMainTitle.alpha = 0
            cell.lblSubTitle.alpha = 0
            
            cell.backgroundColor = UIColor.clear
            cell.backgroundView = UIImageView(image: UIImage(named: "GoldNewCellDesign"))
        } else
        {
            cell.lblMainTitle?.text = nameOfWorkString + " : " + mainCharString
            cell.lblMainTitle?.textColor = UIColor.black
            cell.lblMainTitle?.font = cell.lblMainTitle?.font.withSize(24)
            
            let numScenes = dbObj.countScenesInWork(refWork: nameOfWorkString, refMainChar: mainCharString)
            cell.lblSubTitle?.text = "\(numScenes) Scenes"
            cell.lblSubTitle?.textColor = UIColor.blue
            cell.lblSubTitle?.font = cell.lblSubTitle?.font.withSize(20)
            
            cell.textLabel?.alpha = 0
            cell.lblMainTitle.alpha = 1
            cell.lblSubTitle.alpha = 1
            
            cell.backgroundColor = UIColor.clear
            cell.backgroundView = UIImageView(image: UIImage(named: "RedNewCellDesign"))
            cell.selectedBackgroundView = UIImageView(image: UIImage(named: "GrayNewCellDesign"))
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath)
    {        
        let work = dbObj.listOfWorks[indexPath.row]
        let refWork = work.name
        let refScene = work.mainChar

        if editingStyle == .delete
        {
            dbObj.deleteWorkFromDataBase(workToDelete: refWork, mainCharToDelete: refScene)
            
            dbObj.listOfWorks.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            
            var tempWorkName: String = ""
            var foundAddNewRow: Bool = false
            for work in dbObj.listOfWorks
            {
                tempWorkName = work.name
                if tempWorkName == dbObj.stringNewWorkTapHere || tempWorkName == dbObj.stringWorkPurchaseFullVersion
                {
                    foundAddNewRow = true
                }
            }
            if !foundAddNewRow
            {
                dbObj.appendToWorkArrayButNotDatabase()
                tblWorks.reloadData()
            }
            
        }
        
        if dbObj.listOfWorks.count == 0
        {
            prepWorkTableView()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        var allowWorkCreation: Bool = false
        
        if !fullVersionPurchased && dbObj.listOfWorks.count <= listOfWorksWithoutPay
        {
            allowWorkCreation = true
        }
        
        if fullVersionPurchased || (!fullVersionPurchased && allowWorkCreation)
        {
            var work = dbObj.listOfWorks[indexPath.row]
            let addedWorkName: String = work.name
            
            if addedWorkName == dbObj.stringNewWorkTapHere
            {
                work.name = dbObj.stringEnterNewWork
                work.mainChar = dbObj.stringEnterMainChar
                dbObj.addWorkToDataBase(workToAdd: work.name, mainCharToAdd: work.mainChar)
            }
            dbObj.currentWork = work
            print (dbObj.currentWork)
        } else if !fullVersionPurchased && !allowWorkCreation
        {
            let endOfArrayIndex = dbObj.listOfWorks.count - 1
            dbObj.currentWork = dbObj.listOfWorks[endOfArrayIndex]
        }
    }
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool
    {
        if indexPath.row == 0
        {
            return false
        } else
        {
            return true
        }
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath)
    {
        guard destinationIndexPath.row != 0 else {toggleArrangeWorks(); tblWorks.reloadData(); return}
        
        let work: workInfo = dbObj.listOfWorks[sourceIndexPath.row]
        dbObj.listOfWorks.remove(at: sourceIndexPath.row)
        dbObj.listOfWorks.insert(work, at: destinationIndexPath.row)
        
        dbObj.reNumberWorksInArrayAndSaveToDataBase()
        toggleArrangeWorks()
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle
    {
        if indexPath.row == 0
        {
            return .none
        } else
        {
            return .delete
        }
    }
    
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool
    {
        return false
    }
}

