//
//  SceneSelectViewController.swift
//  Line Basher
//
//  Created by Gregory Smith on 4/21/17.
//  Copyright © 2017 GammaRay Software. All rights reserved.
//

import UIKit
import SpriteKit
import CoreData
import Speech
import StoreKit
import GoogleMobileAds

class SceneSelectViewController: UIViewController, BannerViewDelegate, UITextFieldDelegate, UITableViewDelegate
{

    @IBOutlet weak var txtNameOfWork: UITextField!
    @IBOutlet weak var txtMainCharacter: UITextField!
    
    @IBOutlet weak var banner: BannerView!
    @IBOutlet weak var btnSceneSettings: UIBarButtonItem!
    @IBOutlet weak var btnEditScenePosition: UIBarButtonItem!
    
    var interstitial: InterstitialAd?
    var canShowAds: Bool = true
    var interstitialAdReady: Bool = false

    @IBOutlet weak var constraintBottomOfSceneTableView: NSLayoutConstraint!
    
    @IBOutlet weak var tblScenes: UITableView!
    
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
        
        tblScenes.dataSource = self
        tblScenes.delegate = self
        tblScenes.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        txtNameOfWork.delegate = self
        txtMainCharacter.delegate = self
        
        txtNameOfWork.text = dbObj.currentWork.name
        txtMainCharacter.text = dbObj.currentWork.mainChar
        
        if txtNameOfWork.text == dbObj.stringWorkPurchaseFullVersion
        {
            txtNameOfWork.text = dbObj.stringEnterNewWork
            txtMainCharacter.text = dbObj.stringEnterMainChar
        }
        
        if txtNameOfWork.text == dbObj.stringEnterNewWork
        {
            txtNameOfWork.clearsOnBeginEditing = true
        } else
        {
            txtNameOfWork.clearsOnBeginEditing = false
        }
        if txtMainCharacter.text == dbObj.stringEnterMainChar
        {
            txtMainCharacter.clearsOnBeginEditing = true
        } else
        {
            txtMainCharacter.clearsOnBeginEditing = false
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShowInScene), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHideInScene), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        if (fullVersionPurchased && !showAdsEvenWhenPaid)
        {
            banner.alpha = 0
            constraintBottomOfSceneTableView.constant = 0
        } else
        {
            banner.alpha = 1
            constraintBottomOfSceneTableView.constant = 100
        }
        dbObj.loadSceneArrayFromDB()
        dbObj.reNumberScenesInArrayAndSaveToDataBase()
        prepSceneTableView()
        tblScenes.isEditing = false
        btnEditScenePosition.title = "Arrange"
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        if txtMainCharacter.isFirstResponder || txtNameOfWork.resignFirstResponder()
        {
            checkTextFieldValues()              //Added July 14. Take out if problems start occurring
            txtMainCharacter.resignFirstResponder()
            txtNameOfWork.resignFirstResponder()
        }
        btnSceneSettings.isEnabled = true
        tblScenes.isEditing = false
        btnEditScenePosition.title = "Arrange"
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func ensureNewEntryCellIsLocatedCorrectly()
    {
        var count: Int = 0
        for scene in dbObj.listOfScenes
        {
            let tempString: String = scene.act
            if (tempString == dbObj.stringNewSceneTapHere || tempString == dbObj.stringScenePurchaseFullVersion) && tempString != dbObj.stringErrorString
            {
                let tempObject = dbObj.listOfScenes[count]
                dbObj.listOfScenes.remove(at: count)
                dbObj.listOfScenes.insert(tempObject, at: 0)           //Always Puts This At Top Of List.
            }
            count = count + 1
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool
    {
        if identifier == "GoToLines"
        {
            if txtNameOfWork.isFirstResponder || txtMainCharacter.isFirstResponder
            {
                //ResignFirstResponder is performed in the didSelect of the tableview.
                return false
            }
        }
        return true
    }
    
    func prepSceneTableView()
    {
        var newSceneFound: Bool = false
        var count: Int = 0
        for scene in dbObj.listOfScenes
        {
            if scene.act == dbObj.stringNewSceneTapHere || scene.act == dbObj.stringScenePurchaseFullVersion
            {
                newSceneFound = true
                if scene.act == dbObj.stringNewSceneTapHere && dbObj.listOfScenes.count > listOfScenesWithoutPay && !fullVersionPurchased
                {
                    dbObj.listOfScenes[count].act = dbObj.stringScenePurchaseFullVersion
                }
            }
            count = count + 1
        }
        
        if !newSceneFound
        {
            dbObj.appendToScenesArrayButNotDataBase()
        }
 
        ensureNewEntryCellIsLocatedCorrectly()
        tblScenes.reloadData()
    }
        
    @objc func keyboardWillShowInScene(sender: NSNotification)
    {
        btnSceneSettings.isEnabled = false
    }
    
    @objc func keyboardWillHideInScene(sender: NSNotification)
    {
        checkTextFieldValues()
    }

    //MARK: UITextField Stuff
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        return true
    }
    
    func checkTextFieldValues()
    {
        var modifiedWork: workInfo = dbObj.currentWork
        modifiedWork.name = txtNameOfWork.text ?? dbObj.stringErrorString
        modifiedWork.mainChar = txtMainCharacter.text ?? dbObj.stringErrorString
        
        if txtNameOfWork.text != dbObj.currentWork.name || txtMainCharacter.text != dbObj.currentWork.mainChar
        {
            if dbObj.checkIfWorkAndMainCharAreTheSame(refWork: modifiedWork.name, refMainChar: modifiedWork.mainChar)
            {
                let alert = UIAlertController(title: "Warning!", message: "You already have Work \(modifiedWork.name) and Character \(modifiedWork.mainChar). You can MERGE the lines together or CANCEL. If you MERGE, this action cannot be undone.", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Merge", style: UIAlertAction.Style.default, handler: { action in
                    dbObj.mergeTwoWorksTogether(originalWork: modifiedWork, workGettingMerged: dbObj.currentWork)
                    dbObj.loadSceneArrayFromDB()
                    self.prepSceneTableView()
                    dbObj.currentWork = modifiedWork
               }))
                alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.default, handler: { action in
                    self.txtNameOfWork.text = dbObj.currentWork.name
                    self.txtMainCharacter.text = dbObj.currentWork.mainChar
                }))
                self.present(alert, animated: true, completion: nil)
            } else
            {
                dbObj.modifySceneEntityAfterChangingWorkOrChar(oldWork: dbObj.currentWork, modifiedWork: modifiedWork)
                dbObj.modifyLineEntityAfterChangingWorkOrChar(oldWork: dbObj.currentWork, modifiedWork: modifiedWork)
                dbObj.modifyWorkEntityString(oldWork: dbObj.currentWork, modifiedWork: modifiedWork)
                dbObj.currentWork.name = txtNameOfWork.text!
                dbObj.currentWork.mainChar = txtMainCharacter.text!
                dbObj.currentScene.work = dbObj.currentWork.name
                dbObj.currentScene.mainChar = dbObj.currentWork.mainChar
            }
        }
        dbObj.currentScene.work = dbObj.currentWork.name
        dbObj.currentScene.mainChar = dbObj.currentWork.mainChar
        btnSceneSettings.isEnabled = true
    }
    @IBAction func btnArrangeScenesAction(_ sender: Any)
    {
        toggleArrangeScenes()
    }
    
    func toggleArrangeScenes()
    {
        if tblScenes.isEditing
        {
            tblScenes.isEditing = false
            btnEditScenePosition.title = "Arrange"
        } else
        {
            tblScenes.isEditing = true
            btnEditScenePosition.title = "Finish"
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
        loadFullScreenAd(adUnitID: "ca-app-pub-8101436191593741/8760361314")
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
extension SceneSelectViewController: UITableViewDataSource
{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return dbObj.listOfScenes.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 60
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let scene = dbObj.listOfScenes[indexPath.row]
        
        if indexPath.row == 0
        {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SceneCell", for: indexPath) as! SceneTableViewCell
            
            cell.textLabel?.text = scene.act
            cell.textLabel?.textColor = UIColor.blue
            cell.textLabel?.font = cell.textLabel?.font.withSize(18)
            
            cell.textLabel?.alpha = 1
            cell.lblSceneName.alpha = 0
            cell.lblSceneLines.alpha = 0
            
            print ("indexPath.row = 0, scene.act = \(scene.act), scene.scene = \(scene.scene)")
            cell.backgroundColor = UIColor.clear
            cell.backgroundView = UIImageView(image: UIImage(named: "GoldNewCellDesign"))
            return cell
        } else
        {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SceneCell", for: indexPath) as! SceneTableViewCell
            
            cell.lblSceneName?.text = "Act: " + scene.act + " , Scene: " + scene.scene
            cell.lblSceneName?.textColor = UIColor.black
            cell.lblSceneName?.font = cell.lblSceneName?.font.withSize(24)

            print ("scene.act = \(scene.act), scene.scene = \(scene.scene), indexPath.row = \(indexPath.row)")
            cell.lblSceneLines?.text = "\(dbObj.countLinesInScene(refWork: scene.work, refMainChar: scene.mainChar, refAct: scene.act, refScene: scene.scene)) Lines"
            cell.lblSceneLines?.textColor = UIColor.blue
            cell.lblSceneLines?.font = cell.lblSceneLines?.font.withSize(20)

            cell.textLabel?.alpha = 0
            cell.lblSceneName.alpha = 1
            cell.lblSceneLines.alpha = 1

            cell.backgroundColor = UIColor.clear
            cell.backgroundView = UIImageView(image: UIImage(named: "GreenNewCellDesign"))
            cell.selectedBackgroundView = UIImageView(image: UIImage(named: "GrayNewCellDesign"))
            return cell
            
        }
        
        ///return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath)
    {
        
        let scene = dbObj.listOfScenes[indexPath.row]
        if editingStyle == .delete
        {
            dbObj.deleteSceneFromDataBase(workToDelete: scene.work, mainCharToDelete: scene.mainChar, sceneToDelete: scene.scene, actToDelete: scene.act)
            
            dbObj.listOfScenes.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            
            var foundAddNewRow: Bool = false
            var count: Int = 0
            for scene in dbObj.listOfScenes
            {
                if scene.act == dbObj.stringNewSceneTapHere || scene.act == dbObj.stringScenePurchaseFullVersion
                {
                    foundAddNewRow = true
                    if scene.act == dbObj.stringScenePurchaseFullVersion && dbObj.listOfScenes.count <= listOfScenesWithoutPay
                    {
                        dbObj.listOfScenes[count].act = dbObj.stringNewSceneTapHere
                        tblScenes.reloadData()
                    }
                }
                count = count + 1
            }
            
            if !foundAddNewRow
            {
                dbObj.appendToScenesArrayButNotDataBase()
                tblScenes.reloadData()
                ensureNewEntryCellIsLocatedCorrectly()
            }
            
        } else if editingStyle == .insert
        {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
        
        if dbObj.listOfWorks.count == 0
        {
            prepSceneTableView()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        if txtMainCharacter.isFirstResponder
        {
            txtMainCharacter.resignFirstResponder()
            return
            
        }
        if txtNameOfWork.isFirstResponder
        {
            txtNameOfWork.resignFirstResponder()
            return
        }
        
        var allowSceneAccess: Bool = false
        
        if dbObj.listOfScenes.count <= listOfScenesWithoutPay || indexPath.row > 0
        {
            allowSceneAccess = true
        }
        
        if fullVersionPurchased || (!fullVersionPurchased && allowSceneAccess)
        {
            let scene = dbObj.listOfScenes[indexPath.row]
            var tempSceneInfo: sceneInfo = scene
            
            if tempSceneInfo.act == dbObj.stringNewSceneTapHere
            {
                tempSceneInfo.act = dbObj.stringEnterNewAct
                tempSceneInfo.scene = dbObj.stringEnterNewScene
                tempSceneInfo.work = dbObj.currentWork.name
                tempSceneInfo.mainChar = dbObj.currentWork.mainChar
                dbObj.addSceneToWorkInDataBase(tempSceneInfo: tempSceneInfo)
                dbObj.resetMasterListCount()
            } else
            {
                tempSceneInfo.act = scene.act
                tempSceneInfo.scene = scene.scene
                tempSceneInfo.work = dbObj.currentWork.name
                tempSceneInfo.mainChar = dbObj.currentWork.mainChar
           }
            dbObj.currentScene = tempSceneInfo
        } else
        {
            dbObj.currentScene = dbObj.listOfScenes[1]
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
        guard destinationIndexPath.row != 0 else {toggleArrangeScenes(); tblScenes.reloadData(); return}
        
        let scene: sceneInfo = dbObj.listOfScenes[sourceIndexPath.row]
        dbObj.listOfScenes.remove(at: sourceIndexPath.row)
        dbObj.listOfScenes.insert(scene, at: destinationIndexPath.row)
        
        dbObj.reNumberScenesInArrayAndSaveToDataBase()
        toggleArrangeScenes()
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
