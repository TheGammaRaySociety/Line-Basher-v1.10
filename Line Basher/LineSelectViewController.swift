//
//  LineSelectViewController.swift
//  Line Basher
//
//  Created by Gregory Smith on 4/20/17.
//  Copyright © 2017 GammaRay Software. All rights reserved.
//

import UIKit
import SpriteKit
import CoreData
import Speech
import StoreKit
import GoogleMobileAds

class LineSelectViewController: UIViewController, UITableViewDelegate, BannerViewDelegate, UITextFieldDelegate
{
    var interstitial: InterstitialAd?
    var canShowAds: Bool = true
    var interstitialAdReady: Bool = false

    @IBOutlet weak var banner: BannerView!
    @IBOutlet weak var constraintBottomLineTable: NSLayoutConstraint!
    @IBOutlet weak var btnMoveItems: UIBarButtonItem!
    
    @IBOutlet weak var txtScene: UITextField!
    @IBOutlet weak var lblScene: UILabel!
    @IBOutlet weak var txtAct: UITextField!
    @IBOutlet weak var lblAct: UILabel!
    @IBOutlet weak var tblLines: UITableView!
    
    @IBOutlet weak var btnSettings: UIBarButtonItem!
    
    var lineIsSelectedIndex: Int = -1
    
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
        
        tblLines.dataSource = self
        tblLines.delegate = self
        
        txtScene.delegate = self
        txtAct.delegate = self
        
        txtAct.text = dbObj.currentScene.act
        txtScene.text = dbObj.currentScene.scene
            
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)

        addDoneButtonOnKeyboard()
        
        NotificationCenter.default.addObserver(self, selector: #selector(lineReloadData), name: NSNotification.Name(rawValue: reloadNotificationString), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        if (fullVersionPurchased && !showAdsEvenWhenPaid)
        {
            banner.alpha = 0
            constraintBottomLineTable.constant = 0
        } else
        {
            banner.alpha = 1
            constraintBottomLineTable.constant = 100
        }
        dbObj.loadLineArrayFromDB()
        prepLineTableView()
        btnSettings.isEnabled = true
        tblLines.isEditing = false
        btnMoveItems.title = "Arrange"
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)

        if interstitialCount >= numberOfLineSelectVCExitsBeforeInterstitial && (!fullVersionPurchased || showAdsEvenWhenPaid)
        {
            showFullScreenAd()
            interstitialCount = 0
        } else
        {
            interstitialCount = interstitialCount + 1
        }
        
        if txtAct.isFirstResponder || txtScene.isFirstResponder
        {
            txtAct.resignFirstResponder()
            txtScene.resignFirstResponder()
        }
        btnSettings.isEnabled = true
        tblLines.isEditing = false
        btnMoveItems.title = "Arrange"
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool
    {
        if identifier == "NewLineSegue"
        {
            if !fullVersionPurchased && dbObj.listOfLines.count > listOfLinesWithoutPay
            {
                return false
            }
            if txtAct.isFirstResponder || txtScene.isFirstResponder
            {
                //ResignFirstResponder is performed in the didSelect function of the tableview
                return false
            }
        }
        return true
    }
    
    func ensureNewLineEntryCellIsLocatedCorrectly()
    {
        var count: Int = 0
        for _ in dbObj.listOfLines
        {
            let tempString: String = dbObj.listOfLines[count].lineText
            if (tempString == dbObj.stringEnterNewLine || tempString == dbObj.stringLinePurchaseFullVersion)
            {
                if !fullVersionPurchased && (dbObj.listOfLines.count >= listOfLinesWithoutPay)
                {
                    dbObj.listOfLines[count].lineText = dbObj.stringLinePurchaseFullVersion
                }
                let tempObject = dbObj.listOfLines[count]
                dbObj.listOfLines.remove(at: count)
                dbObj.listOfLines.insert(tempObject, at: 0)
            }
            count = count + 1
        }
    }
    
    @IBAction func btnMoveItems(_ sender: Any)
    {
        toggleMoveButton()
    }
    
    func toggleMoveButton()
    {
        if tblLines.isEditing
        {
            tblLines.isEditing = false
            btnMoveItems.title = "Arrange"
        } else
        {
            tblLines.isEditing = true
            btnMoveItems.title = "Finish"
        }
    }
    
    func prepLineTableView()
    {
        lineIsSelectedIndex = -1
        
        var newLineFound: Bool = false
        var iCount = 0              //Added iCount logic 7-12-17.
        for line in dbObj.listOfLines
        {
            let refLineText: String = line.lineText
            
            if refLineText == dbObj.stringEnterNewLine || refLineText == dbObj.stringLinePurchaseFullVersion && iCount == 0
            {
                newLineFound = true
                if refLineText == dbObj.stringEnterNewLine && dbObj.listOfLines.count > listOfLinesWithoutPay && !fullVersionPurchased
                {
                    dbObj.listOfLines[dbObj.masterListCount].lineText = dbObj.stringLinePurchaseFullVersion
                } else if refLineText == dbObj.stringLinePurchaseFullVersion && dbObj.listOfLines.count <= listOfLinesWithoutPay && !fullVersionPurchased
                {
                    dbObj.listOfLines[dbObj.masterListCount].lineText = dbObj.stringEnterNewLine
                }
            }
            iCount = iCount + 1
        }
        
        if !newLineFound
        {
            var newLine: lineInfo = lineInfo.init()
            
            newLine.act = dbObj.currentScene.act
            newLine.mainChar = dbObj.currentScene.mainChar
            if !fullVersionPurchased && dbObj.listOfLines.count > listOfLinesWithoutPay
            {
                newLine.lineText = dbObj.stringLinePurchaseFullVersion
            } else
            {
                newLine.lineText = dbObj.stringEnterNewLine
            }
            newLine.scene = dbObj.currentScene.scene
            newLine.work = dbObj.currentScene.work
            dbObj.listOfLines.append(newLine)
        }
        
        ensureNewLineEntryCellIsLocatedCorrectly()
        if dbObj.listOfLines[0].lineText == dbObj.stringNewLineTapHere
        {
            dbObj.listOfLines[0].lineText = dbObj.stringEnterNewLine
        }
        
        tblLines.reloadData()
    }
    
    func addDoneButtonOnKeyboard()
    {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 50))
        doneToolbar.barStyle       = .default
        let flexSpace              = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        //let done: UIBarButtonItem  = UIBarButtonItem(title: "Finish", style: UIBarButtonItem.Style.done, target: self, action: #selector(doneButtonIsPressed))
        let done: UIBarButtonItem  = UIBarButtonItem(title: "Finish", style: UIBarButtonItem.Style.done, target: self, action: #selector(finishButtonIsPressed))

        var items = [UIBarButtonItem]()
        items.append(flexSpace)
        items.append(done)
        
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        
        txtScene.inputAccessoryView = doneToolbar
        txtAct.inputAccessoryView = doneToolbar
    }
    
    @objc func doneButtonIsPressed()
    {
        txtAct.resignFirstResponder()
        txtScene.resignFirstResponder()
        btnSettings.isEnabled = true
        
        var tempSceneInfo: sceneInfo = sceneInfo.init()
        tempSceneInfo.act = txtAct.text!
        tempSceneInfo.scene = txtScene.text!
        tempSceneInfo.work = dbObj.currentScene.work
        tempSceneInfo.mainChar = dbObj.currentScene.mainChar
        
        //Need to see if a change was made. If a change then proceed with the logic.
        
        if tempSceneInfo.act != dbObj.currentScene.act || tempSceneInfo.scene != dbObj.currentScene.scene
        {
            if dbObj.checkIfActAndSceneAreTheSame(checkScene: tempSceneInfo)
            {
                let alert = UIAlertController(title: "Warning!", message: "You already have Act \(tempSceneInfo.act) and Scene \(tempSceneInfo.scene). You can MERGE the lines together or CANCEL. If you MERGE, this action cannot be undone.", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Merge", style: UIAlertAction.Style.default, handler: { action in
                    self.mergeDataBaseWithSameActAndScene()
                    dbObj.loadLineArrayFromDB()
                    dbObj.reNumberLinesInArrayAndSaveToDataBase()
                    self.prepLineTableView()
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.default, handler: { action in
                    self.txtAct.text = dbObj.currentScene.act
                    self.txtScene.text = dbObj.currentScene.scene
                }))
               self.present(alert, animated: true, completion: nil)
            } else
            {
                changeDataBaseWhenActOrSceneChanges(actString: txtAct.text!, sceneString: txtScene.text!)
            }
        }
    }
    
    func mergeDataBaseWithSameActAndScene()
    {
        var mergingScene: sceneInfo = dbObj.currentScene
        mergingScene.act = txtAct.text!
        mergingScene.scene = txtScene.text!
        
        print("scene getting merged into: a\(mergingScene.act) s\(mergingScene.scene)")
        print("scene getting deleted: a\(dbObj.currentScene.act) s\(dbObj.currentScene.scene)")
        dbObj.mergeTwoScenesTogether(originalScene: mergingScene, sceneGettingMerged: dbObj.currentScene)
        
        dbObj.currentScene = mergingScene
    }
    
    func changeDataBaseWhenActOrSceneChanges(actString: String, sceneString: String)
    {
       if actString != dbObj.currentScene.act || sceneString != dbObj.currentScene.scene
       {
            var newSceneInfo: sceneInfo = dbObj.currentScene
        
            newSceneInfo.act = actString
            newSceneInfo.scene = sceneString
        
            dbObj.modifySceneEntityAfterChangingSceneOrAct(oldScene: dbObj.currentScene, newScene: newSceneInfo)
            dbObj.modifyLineEntityAfterChangingSceneOrAct(newScene: newSceneInfo, oldScene: dbObj.currentScene)
        
            dbObj.currentScene = newSceneInfo
        }
    }

    @objc func lineReloadData()
    {
        print ("listOfLines.count = \(dbObj.listOfLines.count)")
        self.lineIsSelectedIndex = -1
        self.prepLineTableView()

        //DispatchQueue.main.async { self.tblLines.reloadData() }         //Never played with threads before. This could be causing problems.
    }
    
    @objc func keyboardWillShow(sender: NSNotification)
    {
        btnSettings.isEnabled = false
    }
    
    @objc func keyboardWillHide(sender: NSNotification)
    {
        doneButtonIsPressed()
    }
    
    @objc func finishButtonIsPressed()
    {
        txtAct.resignFirstResponder()
        txtScene.resignFirstResponder()
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
extension LineSelectViewController: UITableViewDataSource
{
        
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return dbObj.listOfLines.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        if lineIsSelectedIndex >= 0 && indexPath.row == lineIsSelectedIndex
        {
            return 120
        } else
        {
            return 60
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        var line = dbObj.listOfLines[indexPath.row]
        
        if indexPath.row == 0
        {
            let cell: UITableViewCell =
            {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "WorkCell") else
                {
                    // Never fails:
                    return UITableViewCell(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "WorkCell")
                }
                return cell
            }()
            
            if !fullVersionPurchased && dbObj.listOfLines.count > listOfLinesWithoutPay
            {
                line.lineText = dbObj.stringLinePurchaseFullVersion
                cell.textLabel?.font = cell.textLabel?.font.withSize(18)
            } else
            {
                line.lineText = dbObj.stringEnterNewLine
                cell.textLabel?.font = cell.textLabel?.font.withSize(24)
            }
            line.lineID = ""
            cell.textLabel!.text = line.lineText
            cell.textLabel!.textColor = UIColor.blue
            cell.textLabel!.textAlignment = .left
            
            cell.backgroundColor = UIColor.clear
            cell.backgroundView = UIImageView(image: UIImage(named: "GoldNewCellDesign"))
            return cell
        } else
        {
            let cell = tableView.dequeueReusableCell(withIdentifier: "BasherCell", for: indexPath) as! BasherTableViewCell
            if line.lineText == "" {line.lineText = dbObj.stringEnterNewLine}
            
            //cell.delegate = self
            cell.lblLines.text = line.lineText
            cell.lblLines.textColor = UIColor.black
            cell.lblLines.textAlignment = .center
            cell.lblLines.font = cell.lblLines.font.withSize(18)
            
            cell.backgroundColor = UIColor.clear
            cell.backgroundView = UIImageView(image: UIImage(named: "BlueNewCellDesign"))
            cell.selectedBackgroundView = UIImageView(image: UIImage(named: "GrayNewCellDesign"))
            
            cell.btnEdit.alpha = 0
            cell.btnRehearse.alpha = 0
            cell.btnCopyLine.alpha = 0
            return cell
        }
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath)
    {
        let line = dbObj.listOfLines[indexPath.row]
        print ("Verify Delete Text = \(dbObj.listOfLines[indexPath.row])")
        
        let managedContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let fetchRequestLine = NSFetchRequest<NSManagedObject>(entityName: "Line")
        fetchRequestLine.predicate = NSPredicate(format: "(lineID == %@)", line.lineID)
        
        var linesFromDB: [NSManagedObject] = []
        
        do
        {
            linesFromDB = try managedContext.fetch(fetchRequestLine)
        } catch let error as NSError
        {
            print("Could not fetch Scenes. \(error), \(error.userInfo)")
        }
        
        guard linesFromDB.count != 0 else {print ("Line Delete Error - No Lines to Delete"); return}
        
        if linesFromDB.count > 1
        {
            print ("Line Delete Error - Several Lines to Delete")
        }
        
        let lineFromDB = linesFromDB[0]
        
        if editingStyle == .delete
        {
            lineIsSelectedIndex = -1
            
            managedContext.delete(lineFromDB)
            do
            {
                try managedContext.save()
            } catch let error as NSError
            {
                print("Error While Deleting Work: \(error.userInfo)")
            }
            
            dbObj.listOfLines.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            
        } else if editingStyle == .insert
        {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
        dbObj.reNumberLinesInArrayAndSaveToDataBase()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        if txtAct.isFirstResponder {txtAct.resignFirstResponder(); return}
        if txtScene.isFirstResponder {txtScene.resignFirstResponder(); return}
        
        var refLine:lineInfo = dbObj.listOfLines[indexPath.row]
        print ("Selected Row = \(indexPath.row); refLine.text = \(refLine.lineText)")
        
        if !fullVersionPurchased && dbObj.listOfLines.count > listOfLinesWithoutPay && indexPath.row == 0
        {
            print ("Too Many Lines. Full Version Not Paid.")
            return
        }
        
        if indexPath.row == 0
        {
            //Need to Append here in order to get LineOrder Correct.
            refLine = lineInfo.init()
            dbObj.listOfLines.append(refLine)
            dbObj.setMasterListCountToEndOfLineArray()
            
            //Be sure to keep LineID = ""
            dbObj.currentLine.lineText = dbObj.stringNewLineTapHere
            dbObj.currentLine.cueText = dbObj.stringNewCueTapHere
            dbObj.currentLine.work = dbObj.currentScene.work
            dbObj.currentLine.mainChar = dbObj.currentScene.mainChar
            dbObj.currentLine.act = dbObj.currentScene.act              //was txtAct.text!
            dbObj.currentLine.scene =  dbObj.currentScene.scene         //txtScene.text!
            dbObj.currentLine.lineOrder = ("\(dbObj.masterListCount)")
            dbObj.currentLine.lineOrder = dbObj.currentLine.lineOrder.leftPadding(toLength: 5, withPad: "0")
            dbObj.currentLine.blocking = ""
            dbObj.currentLine.cueChar = ""
            dbObj.currentLine.isMonologue = "0"
            dbObj.currentLine.lineID = ""
            
            //Put line in last position of the array with the correct information.
            dbObj.listOfLines[dbObj.masterListCount] = dbObj.currentLine
            print ("listoflines.count = \(dbObj.listOfLines.count)")
            print ("Line ORder4 = \(dbObj.listOfLines[dbObj.masterListCount].lineOrder), MasterListCount = \(dbObj.masterListCount)")
        } else
        {
            dbObj.setMasterListCountToIndex(index: indexPath.row)
            dbObj.currentLine = dbObj.listOfLines[dbObj.masterListCount]
            
            if lineIsSelectedIndex < 0
            {
                lineIsSelectedIndex = indexPath.row
                let currentCell: BasherTableViewCell = tblLines.cellForRow(at: indexPath) as! BasherTableViewCell
                
                UIView.animate(withDuration: 0.25, animations: {
                    currentCell.btnRehearse.alpha = 1
                    currentCell.btnEdit.alpha = 1
                    currentCell.btnCopyLine.alpha = 1
                })
            } else
            {
                lineIsSelectedIndex = -1
                let currentCell: BasherTableViewCell = tblLines.cellForRow(at: indexPath) as! BasherTableViewCell
                
                UIView.animate(withDuration: 0.25, animations: {
                    currentCell.btnRehearse.alpha = 0
                    currentCell.btnEdit.alpha = 0
                    currentCell.btnCopyLine.alpha = 0
                })
                tblLines.deselectRow(at: indexPath, animated: true)
            }
            tblLines.beginUpdates()
            tblLines.endUpdates()
            tblLines.scrollToRow(at: indexPath, at: .middle, animated: true)
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
        guard destinationIndexPath.row != 0 else {toggleMoveButton(); tblLines.reloadData(); return}
        
        let line: lineInfo = dbObj.listOfLines[sourceIndexPath.row]
        dbObj.listOfLines.remove(at: sourceIndexPath.row)
        dbObj.listOfLines.insert(line, at: destinationIndexPath.row)
        
        dbObj.reNumberLinesInArrayAndSaveToDataBase()
        toggleMoveButton()
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

