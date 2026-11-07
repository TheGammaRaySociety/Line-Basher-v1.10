//
//  TableViewLogic.swift
//  Line Basher
//
//  Created by Gregory Smith on 4/22/17.
//  Copyright © 2017 GammaRay Software. All rights reserved.
//

import CoreData
import Foundation
import UIKit

//FIXME: If this is to be an inapp purchase, this needs to be false. If this is to be purchased app, then this needs to be true.
var fullVersionPurchased: Bool = true
var showAdsEvenWhenPaid: Bool = false

var listOfWorksWithoutPay: Int = 1
var listOfScenesWithoutPay: Int = 3
var listOfLinesWithoutPay: Int = 15
var numberOfLineSelectVCExitsBeforeInterstitial: Int = 3
var interstitialCount: Int = 0

var textSize: CGFloat = 22.5
var charsPerHint: Int = 5
var encodedCharacter: Character = "*"
var alwaysShowLines: Bool = false
var debugModeIssOn: Bool = false        //Must be set to false at release.

var stringPartOfMonologue: String = "(Part of Monologue)"
var stringContinueAsMonologue: String = "[CONTINUE AS MONOLOGUE]"

enum workEntity: String
{
    case mainChar = "mainChar"
    case name = "name"
    case workOrder = "spare1"
    case spare2 = "spare2"
    case nothing = ""
}

enum charactersEntity: String
{
    case charName = "charName"
    case work = "work"
    case spare1 = "spare1"
    case spare2 = "spare2"
    case nothing = ""
}

enum sceneEntity: String
{
    case act = "act"
    case scene = "scene"
    case mainChar = "mainChar"
    case sceneOrder = "spare1"
    case spare2 = "spare2"
    case work = "work"
    case nothing = ""
}

enum lineEntity: String
{
    case lineOrder = "lineOrder"
    case act = "act"
    case blocking = "blocking"          //USed for both blocking and motivation
    case mainChar = "mainChar"
    case cueText = "cueText"
    case lineText = "lineText"
    case cueChar = "motivation"         //This will be the field to associated the cueCharacter
    case scene = "scene"
    case lineID = "lineID"
    case isMonologue = "spare2"
    case work = "work"
}

struct workInfo
{
    var mainChar: String = ""
    var name: String = ""
    var workOrder: String = ""
    var spare2: String = ""
    var nothing: String = ""
}

struct sceneInfo
{
    var act: String = ""
    var scene: String = ""
    var mainChar: String = ""
    var sceneOrder: String = ""
    var spare2: String = ""
    var work: String = ""
    var nothing: String = ""
}

struct lineInfo
{
    var lineOrder: String = ""
    var act: String = ""
    var blocking: String = ""
    var mainChar: String = ""
    var cueText: String = ""
    var lineText: String = ""
    var cueChar: String = ""
    var scene: String = ""
    var lineID: String = ""
    var isMonologue: String = "0"
    var work: String = ""    
}

struct searchActAndScene
{
    var searchAct: String = ""
    var searchScene: String = ""
}

class dataBaseObject
{
    var listOfWorks: [workInfo] = []
    var listOfScenes: [sceneInfo] = []
    var listOfLines: [lineInfo] = []
    var listOfCharsInWork: [NSManagedObject] = []
    
    var stringNewWorkTapHere: String = "Tap Here To Add A Work!"
    var stringNewSceneTapHere: String = "Tap Here To Add A Scene!"
    var stringNewCueTapHere: String = "(Enter the Cue or Several Cues Here. Put Stage Directions in parenthesis.)"
    var stringNewLineTapHere: String = "(Enter Your Line Here. Put Stage Directions in parenthesis.)"
    var stringEnterNewWork: String = "Enter New Work"
    var stringEnterMainChar: String = "Enter Main Character"
    var stringEnterNewAct: String = "Enter Act"
    var stringEnterNewScene: String = "Enter Scene"
    var stringEnterNewLine: String = "Tap Here To Enter New Line"
    var stringErrorString: String = "Error"
    var stringWorkPurchaseFullVersion = "One Work Limit: Purchase Full Version"
    var stringScenePurchaseFullVersion = "3 Scene Limit: Purchase Full Version"
    var stringLinePurchaseFullVersion = "15 Line Limit: Purchase Full Version"
    
    var currentLine: lineInfo = lineInfo.init()
    var currentWork: workInfo = workInfo.init()
    var currentScene: sceneInfo = sceneInfo.init()
    
    var masterListCount: Int = 0
    
    init()
    {
        getUserDefaults()
        loadWorksArrayFromDB()
        
        if fullVersionPurchased
        {
            stringWorkPurchaseFullVersion = stringNewWorkTapHere
            stringScenePurchaseFullVersion = stringNewSceneTapHere
            stringLinePurchaseFullVersion = stringNewLineTapHere
        }
        
    }
    
    func loadWorksArrayFromDB()
    {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {return}

        listOfWorks.removeAll()
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequestWork = NSFetchRequest<NSManagedObject>(entityName: "Work")
        
        var tempWorks: [NSManagedObject] = []
        
        do
        {
            tempWorks = try managedContext.fetch(fetchRequestWork)
        } catch let error as NSError
        {
            print("Could not fetch Works. \(error), \(error.userInfo)")
        }
        
        for work in tempWorks
        {
            var tempWorkInfo: workInfo = workInfo.init()
            
            tempWorkInfo.mainChar = work.value(forKey: workEntity.mainChar.rawValue) as? String ?? stringErrorString
            tempWorkInfo.name = work.value(forKey: workEntity.name.rawValue) as? String ?? stringErrorString
            tempWorkInfo.workOrder = work.value(forKey: workEntity.workOrder.rawValue) as? String ?? stringErrorString
            tempWorkInfo.spare2 = work.value(forKey: workEntity.spare2.rawValue) as? String ?? stringErrorString
            
            listOfWorks.append(tempWorkInfo)
        }
        
        let sortedWorks: [workInfo] = listOfWorks.sorted(by: {$0.workOrder < $1.workOrder})
        
        for work in sortedWorks
        {
            print ("work order = \(work.workOrder); work text = \(work.name)")
        }
        listOfWorks = sortedWorks
    }
    
    func loadSceneArrayFromDB()
    {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {return}
        
        listOfScenes.removeAll()
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequestScene = NSFetchRequest<NSManagedObject>(entityName: "Scene")
        
        fetchRequestScene.predicate = NSPredicate(format: "(work == %@) AND (mainChar == %@)", currentWork.name, currentWork.mainChar)
        
        var tempScenes: [NSManagedObject] = []
        
        do
        {
            tempScenes = try managedContext.fetch(fetchRequestScene)
        } catch let error as NSError
        {
            print("Could not fetch Scenes. \(error), \(error.userInfo)")
        }
        
        for scene in tempScenes
        {
            var tempSceneInfo: sceneInfo = sceneInfo.init()
            
            tempSceneInfo.act = scene.value(forKey: sceneEntity.act.rawValue) as? String ?? dbObj.stringErrorString
            tempSceneInfo.scene = scene.value(forKey: sceneEntity.scene.rawValue) as? String ?? dbObj.stringErrorString
            tempSceneInfo.mainChar = scene.value(forKey: sceneEntity.mainChar.rawValue) as? String ?? dbObj.stringErrorString
            tempSceneInfo.sceneOrder = scene.value(forKey: sceneEntity.sceneOrder.rawValue) as? String ?? dbObj.stringErrorString
            tempSceneInfo.spare2 = scene.value(forKey: sceneEntity.spare2.rawValue) as? String ?? dbObj.stringErrorString
            tempSceneInfo.work = scene.value(forKey: sceneEntity.work.rawValue) as? String ?? dbObj.stringErrorString
            
            listOfScenes.append(tempSceneInfo)
        }
        
        let sortedScenes: [sceneInfo] = listOfScenes.sorted(by: {$0.sceneOrder < $1.sceneOrder})
        
        ///for scene in sortedScenes
        ///{
            ///print ("scene order = \(scene.sceneOrder); act text = \(scene.act)")
        ///}
        listOfScenes = sortedScenes
    }
    
    func loadLineArrayFromDB()
    {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {return}
        
        var fetchedArray: [NSManagedObject] = []
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequestLine = NSFetchRequest<NSManagedObject>(entityName: "Line")
        
        fetchRequestLine.predicate = NSPredicate(format: "(work == %@) AND (mainChar == %@) AND (act == %@) AND (scene == %@)", currentWork.name, currentWork.mainChar, currentScene.act, currentScene.scene)
        
        do
        {
            fetchedArray = try managedContext.fetch(fetchRequestLine)
            print ("Loading Lines. Number of Lines = \(fetchedArray.count)")
        } catch let error as NSError
        {
            print("Could not fetch Lines. \(error), \(error.userInfo)")
        }
        
        listOfLines.removeAll()
        for lineFromDB in fetchedArray
        {
            var lineForArray: lineInfo = lineInfo.init()
            lineForArray.act = "\(currentScene.act)"
            lineForArray.blocking = lineFromDB.value(forKey: lineEntity.blocking.rawValue) as? String ?? dbObj.stringErrorString
            lineForArray.mainChar = "\(currentWork.mainChar)"
            lineForArray.cueText = lineFromDB.value(forKey: lineEntity.cueText.rawValue) as? String ?? dbObj.stringErrorString
            lineForArray.lineText = lineFromDB.value(forKey: lineEntity.lineText.rawValue) as? String ?? dbObj.stringErrorString
            lineForArray.cueChar = lineFromDB.value(forKey: lineEntity.cueChar.rawValue) as? String ?? dbObj.stringErrorString
            lineForArray.scene = "\(currentScene.scene)"
            lineForArray.lineID = lineFromDB.value(forKey: lineEntity.lineID.rawValue) as? String ?? dbObj.stringErrorString
            lineForArray.isMonologue = lineFromDB.value(forKey: lineEntity.isMonologue.rawValue) as? String ?? dbObj.stringErrorString
            lineForArray.work = "\(currentWork.name)"
            lineForArray.lineOrder = lineFromDB.value(forKey: lineEntity.lineOrder.rawValue) as? String ?? dbObj.stringErrorString
            listOfLines.append(lineForArray)
        }
        
        if listOfLines.isEmpty
        {
            var lineForArray: lineInfo = lineInfo.init()
            lineForArray.act = "\(currentScene.act)"
            lineForArray.blocking = ""
            lineForArray.mainChar = "\(currentWork.mainChar)"
            lineForArray.cueText = ""
            lineForArray.lineText = dbObj.stringEnterNewLine
            lineForArray.cueChar = ""
            lineForArray.scene = "\(currentScene.scene)"
            lineForArray.lineID = ""
            lineForArray.isMonologue = "0"
            lineForArray.work = "\(currentWork.name)"
            lineForArray.lineOrder = "1"
            lineForArray.lineOrder = lineForArray.lineOrder.leftPadding(toLength: 5, withPad: "0")
            listOfLines.append(lineForArray)
            currentLine = lineForArray
        } else
        {
            let sortedLines: [lineInfo] = listOfLines.sorted(by: {$0.lineOrder < $1.lineOrder})
            listOfLines = sortedLines
        }
    }
    
    func appendToWorkArrayButNotDatabase()
    {
        var newWork: workInfo = workInfo.init()
        if fullVersionPurchased
        {
            newWork.name = stringNewWorkTapHere
        } else if !fullVersionPurchased && (listOfWorks.count <= listOfWorksWithoutPay - 1)
        {
            newWork.name = stringNewWorkTapHere
        } else
        {
            newWork.name = stringWorkPurchaseFullVersion
        }
        newWork.mainChar = ""
        newWork.workOrder = ""
        newWork.spare2 = ""
        
        listOfWorks.append(newWork)
        print ("Appending Work To Array But Not Database")
    }
    
    func deleteWorkFromDataBase(workToDelete: String, mainCharToDelete: String)
    {
        guard  let appDelegate = UIApplication.shared.delegate as? AppDelegate else {return}
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequestWork = NSFetchRequest<NSManagedObject>(entityName: "Work")
        
        fetchRequestWork.predicate = NSPredicate(format: "(name == %@) AND (mainChar == %@)", workToDelete, mainCharToDelete)
        print (fetchRequestWork.predicate ?? dbObj.stringErrorString)
        
        var workObjects: [NSManagedObject] = []
        
        do
        {
            workObjects = try managedContext.fetch(fetchRequestWork)
            print ("Number of Works to delete in Database = \(workObjects.count)")
        } catch let error as NSError
        {
            print("Could not fetch Works. \(error), \(error.userInfo)")
        }
        for object in workObjects {managedContext.delete(object)}
        
        let fetchRequestScene = NSFetchRequest<NSManagedObject>(entityName: "Scene")
        
        fetchRequestScene.predicate = NSPredicate(format: "(work == %@) AND (mainChar == %@)", workToDelete, mainCharToDelete)
        
        var sceneObjects: [NSManagedObject] = []
        
        do
        {
            sceneObjects = try managedContext.fetch(fetchRequestScene)
            print ("Number of Scenes to delete in Database = \(sceneObjects.count)")
        } catch let error as NSError
        {
            print("Could not fetch Scenes. \(error), \(error.userInfo)")
        }
        for object in sceneObjects {managedContext.delete(object)}
        
        let fetchRequestLine = NSFetchRequest<NSManagedObject>(entityName: "Line")
        
        fetchRequestLine.predicate = NSPredicate(format: "(work == %@) AND (mainChar == %@)", workToDelete, mainCharToDelete)
        
        var lineObjects: [NSManagedObject] = []
        
        do
        {
            lineObjects = try managedContext.fetch(fetchRequestLine)
            print ("Number of Lines to delete in Database = \(lineObjects.count)")
        } catch let error as NSError
        {
            print("Could not fetch Lines. \(error), \(error.userInfo)")
        }
        for object in lineObjects {managedContext.delete(object)}
        
        do
        {
            try managedContext.save()
        } catch let error as NSError
        {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    func addWorkToDataBase(workToAdd: String, mainCharToAdd: String)
    {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {return}
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let entity = NSEntityDescription.entity(forEntityName: "Work", in: managedContext)!
        
        let newWork = NSManagedObject(entity: entity, insertInto: managedContext)
        
        newWork.setValue(workToAdd, forKeyPath: workEntity.name.rawValue)
        newWork.setValue(mainCharToAdd, forKeyPath: workEntity.mainChar.rawValue)
        newWork.setValue("", forKeyPath: workEntity.workOrder.rawValue)
        newWork.setValue("", forKeyPath: workEntity.spare2.rawValue)
        
        var tempWorkInfo: workInfo = workInfo.init()
        tempWorkInfo.name = workToAdd
        tempWorkInfo.mainChar = mainCharToAdd
        
        do
        {
            try managedContext.save()
            listOfWorks.append(tempWorkInfo)
            print ("Added Work. Number of Works = \(listOfWorks.count - 1)")
        } catch let error as NSError
        {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    func modifyWorkEntityString (oldWork: workInfo, modifiedWork: workInfo)
    {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {return}
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequestWork = NSFetchRequest<NSManagedObject>(entityName: "Work")
        
        fetchRequestWork.predicate = NSPredicate(format: "(name == %@) AND (mainChar == %@)", oldWork.name, oldWork.mainChar)
        var activeObjects: [NSManagedObject] = []
        
        do
        {
            activeObjects = try managedContext.fetch(fetchRequestWork)
            print ("Number of Works in Database = \(activeObjects.count)")
        } catch let error as NSError
        {
            print("Could not fetch Works. \(error), \(error.userInfo)")
        }
        
        if activeObjects.count > 1
        {
            print ("WARNING! Multiple Works being modified.")
        } else if activeObjects.count == 0
        {
            print ("WARNING! No Works being modified")
        }
        
        //Modify Value
        for object in activeObjects
        {
            object.setValue(modifiedWork.name, forKey: workEntity.name.rawValue)
            object.setValue(modifiedWork.mainChar, forKey: workEntity.mainChar.rawValue)
        }
        
        //Save Database With Modified Value
        do
        {
            try managedContext.save()
            print ("Work Entity Saved after Being Modified.")
        } catch let error as NSError
        {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    func modifySceneEntityAfterChangingSceneOrAct(oldScene: sceneInfo, newScene: sceneInfo)
    {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {return}
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequestScene = NSFetchRequest<NSManagedObject>(entityName: "Scene")
        
        fetchRequestScene.predicate = NSPredicate(format: "(work == %@) AND (mainChar == %@) AND (act == %@) AND (scene == %@)", oldScene.work, oldScene.mainChar, oldScene.act, oldScene.scene)
        var activeObjects: [NSManagedObject] = []
        
        do
        {
            activeObjects = try managedContext.fetch(fetchRequestScene)
            print ("Number of Scenes Found to Modify (Should be 1) = \(activeObjects.count)")
        } catch let error as NSError
        {
            print("Could not fetch Scenes. \(error), \(error.userInfo)")
        }
        
        if activeObjects.count > 1
        {
            print ("WARNING! Multiple Works being modified.")
        } else if activeObjects.count == 0
        {
            print ("WARNING! No Works being modified")
        }
        
        for object in activeObjects
        {
            //Modify Value
            object.setValue(newScene.act, forKey: sceneEntity.act.rawValue)
            object.setValue(newScene.scene, forKey: sceneEntity.scene.rawValue)
        }
        
        //Save Database With Modified Value
        do
        {
            try managedContext.save()
        } catch let error as NSError
        {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }

    func modifySceneEntityAfterChangingWorkOrChar (oldWork: workInfo, modifiedWork: workInfo)
    {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {return}
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequestScene = NSFetchRequest<NSManagedObject>(entityName: "Scene")
        
        fetchRequestScene.predicate = NSPredicate(format: "(work == %@) AND (mainChar == %@)", oldWork.name, oldWork.mainChar)
        var activeObjects: [NSManagedObject] = []
        
        do
        {
            activeObjects = try managedContext.fetch(fetchRequestScene)
        } catch let error as NSError
        {
            print("Could not fetch Scenes. \(error), \(error.userInfo)")
        }

        for object in activeObjects
        {
            //Modify Value
            object.setValue(modifiedWork.name, forKey: sceneEntity.work.rawValue)
            object.setValue(modifiedWork.mainChar, forKey: sceneEntity.mainChar.rawValue)
        }
        
        //Save Database With Modified Value
        do
        {
            try managedContext.save()
        } catch let error as NSError
        {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    func appendToScenesArrayButNotDataBase()
    {
        var newScene: sceneInfo = sceneInfo.init()
        if fullVersionPurchased
        {
            newScene.act = stringNewSceneTapHere
        } else if !fullVersionPurchased && (listOfScenes.count <= listOfScenesWithoutPay - 1)      //This needs to be one less the limit
        {
            newScene.act = stringNewSceneTapHere
        } else
        {
            newScene.act = stringScenePurchaseFullVersion
        }
        newScene.work = currentWork.name
        newScene.scene = ""
        newScene.mainChar = currentWork.mainChar
        newScene.sceneOrder = ""
        newScene.spare2 = ""
        
        listOfScenes.append(newScene)
        print ("Appending Scene To Array But Not Database")
    }
    
    func addSceneToWorkInDataBase(tempSceneInfo: sceneInfo)
    {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {return}
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let entity = NSEntityDescription.entity(forEntityName: "Scene", in: managedContext)!
        
        let newScene = NSManagedObject(entity: entity, insertInto: managedContext)
        
        newScene.setValue(tempSceneInfo.work, forKeyPath: sceneEntity.work.rawValue)
        newScene.setValue(tempSceneInfo.act, forKeyPath: sceneEntity.act.rawValue)
        newScene.setValue(tempSceneInfo.scene, forKeyPath: sceneEntity.scene.rawValue)
        newScene.setValue(tempSceneInfo.mainChar, forKeyPath: sceneEntity.mainChar.rawValue)
        newScene.setValue("", forKeyPath: sceneEntity.sceneOrder.rawValue)
        newScene.setValue("", forKeyPath: sceneEntity.spare2.rawValue)
        
        do
        {
            try managedContext.save()
            print ("Added New Scene To \(tempSceneInfo.work), Number of Scenes = \(listOfScenes.count - 1)")
        } catch let error as NSError
        {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    func deleteSceneFromDataBase(workToDelete: String, mainCharToDelete: String, sceneToDelete: String, actToDelete: String)
    {
        guard  let appDelegate = UIApplication.shared.delegate as? AppDelegate else {return}
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequestScene = NSFetchRequest<NSManagedObject>(entityName: "Scene")
        
        fetchRequestScene.predicate = NSPredicate(format: "(work == %@) AND (mainChar == %@) AND (act == %@) AND (scene == %@)", workToDelete, mainCharToDelete, actToDelete, sceneToDelete)
        
        var sceneObjects: [NSManagedObject] = []
        
        do
        {
            sceneObjects = try managedContext.fetch(fetchRequestScene)
            print ("Number of Scenes to delete in Database = \(sceneObjects.count)")
        } catch let error as NSError
        {
            print("Could not fetch Scenes. \(error), \(error.userInfo)")
        }
        for object in sceneObjects {managedContext.delete(object)}
        
        let fetchRequestLine = NSFetchRequest<NSManagedObject>(entityName: "Line")
        
        fetchRequestLine.predicate = NSPredicate(format: "(work == %@) AND (mainChar == %@) AND (act == %@) AND (scene == %@)", workToDelete, mainCharToDelete, actToDelete, sceneToDelete)
        
        var lineObjects: [NSManagedObject] = []
        
        do
        {
            lineObjects = try managedContext.fetch(fetchRequestLine)
            print ("Number of Lines to delete in Database = \(lineObjects.count)")
        } catch let error as NSError
        {
            print("Could not fetch Lines. \(error), \(error.userInfo)")
        }
        for object in lineObjects {managedContext.delete(object)}
        
        do
        {
            try managedContext.save()
        } catch let error as NSError
        {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    func mergeTwoScenesTogether(originalScene: sceneInfo, sceneGettingMerged: sceneInfo)
    {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {return}
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequestLinesFromMergingScene = NSFetchRequest<NSManagedObject>(entityName: "Line")
        var activeObjects: [NSManagedObject] = []
        
        //Change Lines of mergingScene
        fetchRequestLinesFromMergingScene.predicate = NSPredicate(format: "(work == %@) AND (mainChar == %@) AND (act == %@) and (scene == %@)", sceneGettingMerged.work, sceneGettingMerged.mainChar, sceneGettingMerged.act, sceneGettingMerged.scene)
        
        do
        {
            activeObjects = try managedContext.fetch(fetchRequestLinesFromMergingScene)
        } catch let error as NSError
        {
            print("Could not fetch the scene that is getting merged into. \(error), \(error.userInfo)")
        }
        
        for object in activeObjects
        {
            object.setValue(originalScene.act, forKey: lineEntity.act.rawValue)
            object.setValue(originalScene.scene, forKey: lineEntity.scene.rawValue)
        }
        
        do
        {
            try managedContext.save()
        } catch let error as NSError
        {
            print("Could not save. \(error), \(error.userInfo)")
        }
        
        //Delete mergingScene from database
        let fetchRequestSceneToDelete = NSFetchRequest<NSManagedObject>(entityName: "Scene")
        
        fetchRequestSceneToDelete.predicate = NSPredicate(format: "(work == %@) AND (mainChar == %@) AND (act == %@) and (scene == %@)", sceneGettingMerged.work, sceneGettingMerged.mainChar, sceneGettingMerged.act, sceneGettingMerged.scene)
        activeObjects = []
        
        do
        {
            activeObjects = try managedContext.fetch(fetchRequestSceneToDelete)
        } catch let error as NSError
        {
            print("Could not fetch the scene that getting deleted from merge. \(error), \(error.userInfo)")
        }
        
        for object in activeObjects
        {
            managedContext.delete(object)
        }
        
        do
        {
            try managedContext.save()
        } catch let error as NSError
        {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    func modifyLineEntityAfterChangingSceneOrAct(newScene: sceneInfo, oldScene: sceneInfo)
    {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {return}
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequestLine = NSFetchRequest<NSManagedObject>(entityName: "Line")
        
        fetchRequestLine.predicate = NSPredicate(format: "(work == %@) AND (mainChar == %@) AND (act == %@) AND (scene == %@)", oldScene.work, oldScene.mainChar, oldScene.act, oldScene.scene)
        var activeObjects: [NSManagedObject] = []
        
        do
        {
            activeObjects = try managedContext.fetch(fetchRequestLine)
            print ("Number of Lines in Scene = \(activeObjects.count)")
        } catch let error as NSError
        {
            print("Could not fetch Lines. \(error), \(error.userInfo)")
        }
        
        for object in activeObjects
        {
            //Modify Value
            object.setValue(newScene.act, forKey: lineEntity.act.rawValue)
            object.setValue(newScene.scene, forKey: lineEntity.scene.rawValue)
        }
        
        //Save Database With Modified Value
        do
        {
            try managedContext.save()
        } catch let error as NSError
        {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    func mergeTwoWorksTogether(originalWork: workInfo, workGettingMerged: workInfo)
    {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {return}
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequestLinesFromMergingWork = NSFetchRequest<NSManagedObject>(entityName: "Line")
        var activeObjects: [NSManagedObject] = []
        
        //Change Lines of mergingWork
        fetchRequestLinesFromMergingWork.predicate = NSPredicate(format: "(work == %@) AND (mainChar == %@)", workGettingMerged.name, workGettingMerged.mainChar)
        
        do
        {
            activeObjects = try managedContext.fetch(fetchRequestLinesFromMergingWork)
        } catch let error as NSError
        {
            print("Could not fetch the line that is getting merged into. \(error), \(error.userInfo)")
        }
        
        for object in activeObjects
        {
            object.setValue(originalWork.name, forKey: lineEntity.work.rawValue)
            object.setValue(originalWork.mainChar, forKey: lineEntity.mainChar.rawValue)
        }
        
        do
        {
            try managedContext.save()
        } catch let error as NSError
        {
            print("Could not save. \(error), \(error.userInfo)")
        }
        
        //Change Scenes of mergingWork
        let fetchRequestScenesFromMergingWork = NSFetchRequest<NSManagedObject>(entityName: "Scene")
        activeObjects = []
        
        fetchRequestScenesFromMergingWork.predicate = NSPredicate(format: "(work == %@) AND (mainChar == %@)", workGettingMerged.name, workGettingMerged.mainChar)
        
        do
        {
            activeObjects = try managedContext.fetch(fetchRequestScenesFromMergingWork)
        } catch let error as NSError
        {
            print("Could not fetch the scene that is getting merged into. \(error), \(error.userInfo)")
        }
        
        for object in activeObjects
        {
            object.setValue(originalWork.name, forKey: sceneEntity.work.rawValue)
            object.setValue(originalWork.mainChar, forKey: sceneEntity.mainChar.rawValue)
        }
        
        do
        {
            try managedContext.save()
        } catch let error as NSError
        {
            print("Could not save. \(error), \(error.userInfo)")
        }
        
        //Remove Duplicate Scenes if any
        activeObjects = []
        let fetchRequestScenes = NSFetchRequest<NSManagedObject>(entityName: "Scene")
        do
        {
            activeObjects = try managedContext.fetch(fetchRequestScenes)
        } catch let error as NSError
        {
            print("Could not fetch Works. \(error), \(error.userInfo)")
        }
        
        var listOfActSceneCombos: [searchActAndScene] = []
        
        for scene in activeObjects
        {
            var putInArray: Bool = true
            var tempStruct: searchActAndScene = searchActAndScene.init()
            tempStruct.searchAct = scene.value(forKey: sceneEntity.act.rawValue) as? String ?? dbObj.stringErrorString
            tempStruct.searchScene = scene.value(forKey: sceneEntity.scene.rawValue) as? String ?? dbObj.stringErrorString
            
            for actScene in listOfActSceneCombos
            {
                if tempStruct.searchAct == actScene.searchAct && tempStruct.searchScene == actScene.searchScene
                {
                    putInArray = false
                }
            }
            if putInArray
            {
                listOfActSceneCombos.append(tempStruct)
            } else
            {
                managedContext.delete(scene)
            }
        }
        
        do
        {
            try managedContext.save()
        } catch let error as NSError
        {
            print("Could not save. \(error), \(error.userInfo)")
        }
        
        //Delete mergingWork from database
        let fetchRequestWorkToDelete = NSFetchRequest<NSManagedObject>(entityName: "Work")
        
        fetchRequestWorkToDelete.predicate = NSPredicate(format: "(name == %@) AND (mainChar == %@)", workGettingMerged.name, workGettingMerged.mainChar)
        activeObjects = []
        
        do
        {
            activeObjects = try managedContext.fetch(fetchRequestWorkToDelete)
        } catch let error as NSError
        {
            print("Could not fetch the scene that getting deleted from merge. \(error), \(error.userInfo)")
        }
        
        for object in activeObjects
        {
            managedContext.delete(object)
        }
        
        do
        {
            try managedContext.save()
        } catch let error as NSError
        {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    func modifyLineEntityAfterChangingWorkOrChar(oldWork: workInfo, modifiedWork: workInfo)
    {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {return}
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequestLine = NSFetchRequest<NSManagedObject>(entityName: "Line")
        
        fetchRequestLine.predicate = NSPredicate(format: "(work == %@) AND (mainChar == %@)", oldWork.name, oldWork.mainChar)
        var activeObjects: [NSManagedObject] = []
        
        do
        {
            activeObjects = try managedContext.fetch(fetchRequestLine)
        } catch let error as NSError
        {
            print("Could not fetch Scenes. \(error), \(error.userInfo)")
        }
        
        for object in activeObjects
        {
            object.setValue(modifiedWork.name, forKey: lineEntity.work.rawValue)
            object.setValue(modifiedWork.mainChar, forKey: lineEntity.mainChar.rawValue)
        }
        
        //Save Database With Modified Value
        do
        {
            try managedContext.save()
        } catch let error as NSError
        {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }

    func modifyLineEntityString (lineToModify: lineInfo)
    {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {return}
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequestLine = NSFetchRequest<NSManagedObject>(entityName: "Line")
        let refLineID: String = lineToModify.lineID
        print ("Looking for LineID: \(lineToModify.lineID)")
        
        fetchRequestLine.predicate = NSPredicate(format: "(lineID == %@)", refLineID)
        var lineFromDBToModify: [NSManagedObject] = []
        
        do
        {
            lineFromDBToModify = try managedContext.fetch(fetchRequestLine)
        } catch let error as NSError
        {
            print("Could not save. \(error), \(error.userInfo)")
        }
        
        guard lineFromDBToModify.count == 1 else {print ("Error in modifyLineEntityString. DB Count = \(lineFromDBToModify.count)"); return}
        
        lineFromDBToModify[0].setValue(lineToModify.act, forKeyPath: lineEntity.act.rawValue)
        lineFromDBToModify[0].setValue(lineToModify.blocking, forKey: lineEntity.blocking.rawValue)
        lineFromDBToModify[0].setValue(lineToModify.mainChar, forKey: lineEntity.mainChar.rawValue)
        lineFromDBToModify[0].setValue(lineToModify.cueText, forKey: lineEntity.cueText.rawValue)
        lineFromDBToModify[0].setValue(lineToModify.lineText, forKey: lineEntity.lineText.rawValue)
        lineFromDBToModify[0].setValue(lineToModify.cueChar, forKey: lineEntity.cueChar.rawValue)
        lineFromDBToModify[0].setValue(lineToModify.scene, forKey: lineEntity.scene.rawValue)
        lineFromDBToModify[0].setValue(lineToModify.lineID, forKey: lineEntity.lineID.rawValue)
        lineFromDBToModify[0].setValue(lineToModify.isMonologue, forKey: lineEntity.isMonologue.rawValue)
        lineFromDBToModify[0].setValue(lineToModify.work, forKey: lineEntity.work.rawValue)
        lineFromDBToModify[0].setValue(lineToModify.lineOrder, forKey: lineEntity.lineOrder.rawValue)
        
        do
        {
            try managedContext.save()
        } catch let error as NSError
        {
            print("Could not save. \(error), \(error.userInfo)")
        }
        
        listOfLines[masterListCount] = lineToModify
    }
    
    func addLineToDataBase(lineToAdd: lineInfo, setCurrentLineID: Bool)
    {
        //Always assume the lineToAdd is dbObj.currentLine. If not, this will not work because I'm setting the lineID to dbObj.currentLine
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {return}
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let entity = NSEntityDescription.entity(forEntityName: "Line", in: managedContext)!
        
        let newLine = NSManagedObject(entity: entity, insertInto: managedContext)
        
            let stringFromDate = Date().iso8601    // "2017-03-22T13:22:13.933Z"
            
            if let dateFromString = stringFromDate.dateFromISO8601
            {
                print("Adding Line ID = \(dateFromString.iso8601)")      // "2017-03-22T13:22:13.933Z"
                newLine.setValue(dateFromString.iso8601, forKey: lineEntity.lineID.rawValue)
                if setCurrentLineID
                {
                    currentLine.lineID = dateFromString.iso8601
                }
            } else
            {
                print ("Error in addLineToArrayButNotToDataBase")
            }
        
         newLine.setValue(lineToAdd.act, forKeyPath: lineEntity.act.rawValue)
         newLine.setValue(lineToAdd.blocking, forKey: lineEntity.blocking.rawValue)
         newLine.setValue(lineToAdd.mainChar, forKey: lineEntity.mainChar.rawValue)
         newLine.setValue(lineToAdd.cueText, forKey: lineEntity.cueText.rawValue)
         newLine.setValue(lineToAdd.lineText, forKey: lineEntity.lineText.rawValue)
         newLine.setValue(lineToAdd.cueChar, forKey: lineEntity.cueChar.rawValue)
         newLine.setValue(lineToAdd.scene, forKey: lineEntity.scene.rawValue)
         newLine.setValue(lineToAdd.lineOrder, forKey: lineEntity.lineOrder.rawValue)
         newLine.setValue(lineToAdd.isMonologue, forKey: lineEntity.isMonologue.rawValue)
         newLine.setValue(lineToAdd.work, forKey: lineEntity.work.rawValue)
        
         do
         {
            try managedContext.save()
         } catch let error as NSError
         {
            print("Could not save. \(error), \(error.userInfo)")
         }
    }
    
    func copyLineToDatabase(lineToCopy: lineInfo)
    {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {return}
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let entity = NSEntityDescription.entity(forEntityName: "Line", in: managedContext)!
        
        let copyLine = NSManagedObject(entity: entity, insertInto: managedContext)
        
        let stringFromDate = Date().iso8601    // "2017-03-22T13:22:13.933Z"
        
        if let dateFromString = stringFromDate.dateFromISO8601
        {
            print("Adding Line ID From Copy= \(dateFromString.iso8601)")      // "2017-03-22T13:22:13.933Z"
            copyLine.setValue(dateFromString.iso8601, forKey: lineEntity.lineID.rawValue)
        } else
        {
            print ("Error in copyLineToArrayButNotToDataBase")
        }
        
        copyLine.setValue(lineToCopy.act, forKeyPath: lineEntity.act.rawValue)
        copyLine.setValue(lineToCopy.blocking, forKey: lineEntity.blocking.rawValue)
        copyLine.setValue(lineToCopy.mainChar, forKey: lineEntity.mainChar.rawValue)
        copyLine.setValue(lineToCopy.cueText, forKey: lineEntity.cueText.rawValue)
        copyLine.setValue(lineToCopy.lineText, forKey: lineEntity.lineText.rawValue)
        copyLine.setValue(lineToCopy.cueChar, forKey: lineEntity.cueChar.rawValue)
        copyLine.setValue(lineToCopy.scene, forKey: lineEntity.scene.rawValue)
        copyLine.setValue(lineToCopy.lineOrder, forKey: lineEntity.lineOrder.rawValue)
        copyLine.setValue(lineToCopy.isMonologue, forKey: lineEntity.isMonologue.rawValue)
        copyLine.setValue(lineToCopy.work, forKey: lineEntity.work.rawValue)
        
        do
        {
            try managedContext.save()
        } catch let error as NSError
        {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    func reNumberLinesInArrayAndSaveToDataBase()
    {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {return}
        
        var index: Int = 0
        var plus1InEffect: Bool = false
        
        if listOfLines.count > 0
        {
            for iCount in 0...(listOfLines.count - 1)
            {
                if listOfLines[iCount].lineText == stringEnterNewLine || listOfLines[iCount].lineText == stringNewLineTapHere || listOfLines[iCount].lineText == stringLinePurchaseFullVersion
                {
                    if iCount == 0
                    {
                        listOfLines[iCount].lineOrder = "0"
                        listOfLines[iCount].lineOrder = listOfLines[iCount].lineOrder.leftPadding(toLength: 5, withPad: "0")
                    }
                } else
                {
                    if iCount == 0
                    {
                        plus1InEffect = true
                    }
                    
                    if plus1InEffect           //If the 0 element is NOT stringEnterNewLine or stringNewLineTapHere ...
                    {
                        index = iCount + 1
                    } else
                    {
                        index = iCount
                    }
                    listOfLines[iCount].lineOrder = ("\(index)")
                    listOfLines[iCount].lineOrder = listOfLines[iCount].lineOrder.leftPadding(toLength: 5, withPad: "0")
                }
                ///print ("RenumberLinesInArray. lineOrder = \(listOfLines[iCount].lineOrder), text = \(listOfLines[iCount].lineText)")
            }
        }
        //Write to Database the line order.
        for line in listOfLines
        {
            let managedContext = appDelegate.persistentContainer.viewContext
            let fetchRequestLine = NSFetchRequest<NSManagedObject>(entityName: "Line")
            
            fetchRequestLine.predicate = NSPredicate(format: "(lineID == %@)", line.lineID)
            var lineFromDBToModify: [NSManagedObject] = []
            
            do
            {
                lineFromDBToModify = try managedContext.fetch(fetchRequestLine)
            } catch let error as NSError
            {
                print("Could not save. \(error), \(error.userInfo)")
            }
            
            if lineFromDBToModify.count == 1
            {
                lineFromDBToModify[0].setValue(line.lineOrder, forKeyPath: lineEntity.lineOrder.rawValue)
                ///print ("Saving to DB: LineOrder = \(line.lineOrder); LineText = \(line.lineText)")
            } else
            {
                print ("Error in modifyLineEntityString. DB Count = \(lineFromDBToModify.count)")
            }
            
            do
            {
                try managedContext.save()
            } catch let error as NSError
            {
                print("Could not save. \(error), \(error.userInfo)")
            }
        }
    }
    
    func reNumberScenesInArrayAndSaveToDataBase()
    {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {return}
        
        var index: Int = 0
        
        if listOfScenes.count > 0
        {
            for iCount in 0...(listOfScenes.count - 1)
            {
                if listOfScenes[iCount].act == stringEnterNewAct || listOfScenes[iCount].act == stringNewSceneTapHere
                {
                    listOfScenes[iCount].sceneOrder = "0"
                } else
                {
                    index = index + 1
                    listOfScenes[iCount].sceneOrder = ("\(index)")
                }
                listOfScenes[iCount].sceneOrder = listOfScenes[iCount].sceneOrder.leftPadding(toLength: 5, withPad: "0")
                ///print ("RenumberLinesInArray. sceneOrder = \(listOfScenes[iCount].sceneOrder), text = \(listOfScenes[iCount].act)")
            }
        }
        //For each scene in the array, find the database element that matches.
        //Then change it.
        
        for scene in listOfScenes
        {
            let managedContext = appDelegate.persistentContainer.viewContext
            let fetchRequestScene = NSFetchRequest<NSManagedObject>(entityName: "Scene")
            
            fetchRequestScene.predicate = NSPredicate(format: "(work == %@) AND (mainChar == %@) AND (act == %@) AND (scene == %@)", scene.work, scene.mainChar, scene.act, scene.scene)
            var sceneFromDBToModify: [NSManagedObject] = []
            
            do
            {
                sceneFromDBToModify = try managedContext.fetch(fetchRequestScene)
            } catch let error as NSError
            {
                print("Could not save. \(error), \(error.userInfo)")
            }
            
            if sceneFromDBToModify.count == 1
            {
                sceneFromDBToModify[0].setValue(scene.sceneOrder, forKeyPath: sceneEntity.sceneOrder.rawValue)
                ///print ("Saving to DB: SceneOrder = \(scene.sceneOrder); act = \(scene.act)")
            } else
            {
                print ("Error in modifySceneEntityString. DB Count = \(sceneFromDBToModify.count)")
            }
            
            do
            {
                try managedContext.save()
            } catch let error as NSError
            {
                print("Could not save. \(error), \(error.userInfo)")
            }
        }
    }
    
    func reNumberWorksInArrayAndSaveToDataBase()
    {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {return}
        
        var index: Int = 0
        
        if listOfWorks.count > 0
        {
            for iCount in 0...(listOfWorks.count - 1)
            {
                if listOfWorks[iCount].name == stringEnterNewWork || listOfWorks[iCount].name == stringNewWorkTapHere
                {
                    listOfWorks[iCount].workOrder = "0"
                } else
                {
                    index = index + 1
                    listOfWorks[iCount].workOrder = ("\(index)")
                }
                listOfWorks[iCount].workOrder = listOfWorks[iCount].workOrder.leftPadding(toLength: 5, withPad: "0")
                ///print ("RenumberLinesInArray. WorkOrder = \(listOfWorks[iCount].workOrder), text = \(listOfWorks[iCount].name)")
            }
        }
        for work in listOfWorks
        {
            let managedContext = appDelegate.persistentContainer.viewContext
            let fetchRequestWork = NSFetchRequest<NSManagedObject>(entityName: "Work")
            
            fetchRequestWork.predicate = NSPredicate(format: "(name == %@) AND (mainChar == %@)", work.name, work.mainChar)
            var workFromDBToModify: [NSManagedObject] = []
            
            do
            {
                workFromDBToModify = try managedContext.fetch(fetchRequestWork)
            } catch let error as NSError
            {
                print("Could not save. \(error), \(error.userInfo)")
            }
            
            if workFromDBToModify.count == 1
            {
                workFromDBToModify[0].setValue(work.workOrder, forKeyPath: workEntity.workOrder.rawValue)
                ///print ("Saving to DB: WorkOrder = \(work.workOrder); work = \(work.name)")
            } else
            {
                print ("Error in modifyWorkEntityString. DB Count = \(workFromDBToModify.count)")
            }
            
            do
            {
                try managedContext.save()
            } catch let error as NSError
            {
                print("Could not save. \(error), \(error.userInfo)")
            }
        }
    }
    
    func checkIfActAndSceneAreTheSame(checkScene: sceneInfo) -> Bool
    {
        var tempBool: Bool = false
        var tempAct: String = ""
        var tempScene: String = ""
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {return false}
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequestLine = NSFetchRequest<NSManagedObject>(entityName: "Scene")
        
        fetchRequestLine.predicate = NSPredicate(format: "(work == %@) AND (mainChar == %@)", checkScene.work, checkScene.mainChar)
        var scenes: [NSManagedObject] = []
        
        do
        {
            scenes = try managedContext.fetch(fetchRequestLine)
            print ("checkIfActAndSceneAreTheSame: Scenes Found = \(scenes.count)")
        } catch let error as NSError
        {
            print("Could not save. \(error), \(error.userInfo)")
        }
        
        for scene in scenes
        {
            tempAct = scene.value(forKey: sceneEntity.act.rawValue) as? String ?? ""
            tempScene = scene.value(forKey: sceneEntity.scene.rawValue) as? String ?? ""
            
            if tempScene == checkScene.scene && tempAct == checkScene.act
            {
                tempBool = true
            }
        }
        
        return tempBool
    }
    
    func checkIfWorkAndMainCharAreTheSame(refWork: String, refMainChar: String) -> Bool
    {
        var tempBool: Bool = false
        var tempWork: String = ""
        var tempMainChar: String = ""
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {return false}
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequestLine = NSFetchRequest<NSManagedObject>(entityName: "Work")
        
        fetchRequestLine.predicate = NSPredicate(format: "(name == %@) AND (mainChar == %@)", refWork, refMainChar)
        var works: [NSManagedObject] = []
        
        do
        {
            works = try managedContext.fetch(fetchRequestLine)
        } catch let error as NSError
        {
            print("Could not save. \(error), \(error.userInfo)")
        }
        
        for work in works
        {
            tempWork = work.value(forKey: workEntity.name.rawValue) as? String ?? stringErrorString
            tempMainChar = work.value(forKey: workEntity.mainChar.rawValue) as? String ?? stringErrorString
            
            if tempWork == refWork && tempMainChar == refMainChar
            {
                tempBool = true
            }
        }
        
        return tempBool
    }
    
    func countLinesInScene(refWork: String, refMainChar: String, refAct: String, refScene: String) -> Int
    {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {return 0}
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequestLine = NSFetchRequest<NSManagedObject>(entityName: "Line")
        
        fetchRequestLine.predicate = NSPredicate(format: "(act == %@) AND (scene == %@) AND (work == %@) AND (mainChar == %@)", refAct, refScene, refWork, refMainChar)
        var lines: [NSManagedObject] = []
        
        do
        {
            lines = try managedContext.fetch(fetchRequestLine)
        } catch let error as NSError
        {
            print("Could not save. \(error), \(error.userInfo)")
        }

        return lines.count
    }
    
    func countScenesInWork(refWork: String, refMainChar: String) -> Int
    {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {return 0}
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequestScene = NSFetchRequest<NSManagedObject>(entityName: "Scene")
        
        print (refWork, refMainChar)
        fetchRequestScene.predicate = NSPredicate(format: "(work == %@) AND (mainChar == %@)", refWork, refMainChar)
        var scenes: [NSManagedObject] = []
        
        do
        {
            scenes = try managedContext.fetch(fetchRequestScene)
        } catch let error as NSError
        {
            print("Could not save. \(error), \(error.userInfo)")
        }
        
        return scenes.count
    }
    
    func countLinesInWork(refWork: String, refMainChar: String) -> Int
    {
        var cumLines: Int = 0
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {return 0}
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequestLine = NSFetchRequest<NSManagedObject>(entityName: "Scene")
        
        fetchRequestLine.predicate = NSPredicate(format: "(work == %@)", refWork)
        var scenes: [NSManagedObject] = []
        
        do
        {
            scenes = try managedContext.fetch(fetchRequestLine)
        } catch let error as NSError
        {
            print("Could not save. \(error), \(error.userInfo)")
        }
        
        var refScene: String = ""
        var refAct: String = ""
        
        for scene in scenes
        {
            refScene = scene.value(forKey: sceneEntity.scene.rawValue) as? String ?? ""
            refAct = scene.value(forKey: sceneEntity.act.rawValue) as? String ?? ""
            cumLines = cumLines + countLinesInScene(refWork: refWork, refMainChar: refMainChar, refAct: refAct, refScene: refScene)
        }
        
        return cumLines
    }
    
    func getUserDefaults()
    {
        let defaults = UserDefaults.standard
        
        charsPerHint = defaults.object(forKey: "charsPerHint") as? Int ?? 10
        textSize = defaults.object(forKey: "textSize") as? CGFloat ?? 22.5
        
        let stringAlwaysShowLines = defaults.object(forKey: "alwaysShowLines") as? String ?? "0"
        if stringAlwaysShowLines == "1"
        {
            alwaysShowLines = true
        } else
        {
            alwaysShowLines = false
        }
        
        let stringFullVersionPurchased = defaults.object(forKey: "fullVersionPurchased") as? String ?? "0"
        if stringFullVersionPurchased == "1"
        {
            fullVersionPurchased = true
        } else
        {
            //FIXME: This should be false if using InApp Purchase
            fullVersionPurchased = true
        }
        
        ///Must be sure debugModeIsOn = false before release.
        if debugModeIssOn
        {
            fullVersionPurchased = true
        }
    }
    
    func setUserDefaults()
    {
        let defaults = UserDefaults.standard
        
        defaults.set(charsPerHint, forKey: "charsPerHint")
        defaults.set(textSize, forKey: "textSize")
        
        if alwaysShowLines
        {
            defaults.set("1", forKey: "alwaysShowLines")
        } else
        {
            defaults.set("0", forKey: "alwaysShowLines")
        }
        
        if fullVersionPurchased
        {
            defaults.set("1", forKey: "fullVersionPurchased")
        } else
        {
            defaults.set("0", forKey: "fullVersionPurchased")
        }
        
        defaults.synchronize()
    }
    
    func incrementMasterListCount()
    {
        masterListCount = masterListCount + 1
        if masterListCount >= listOfLines.count
        {
            masterListCount = listOfLines.count - 1
        }
        print ("IncrementMasterListCount. Now = \(masterListCount)")
    }
    
    func decrementMasterListCount()
    {
        //The Zero position is always the "Tap Here ..." element.
        masterListCount = masterListCount - 1
        if masterListCount < 1
        {
            masterListCount = 1
        }
        print ("DecrementMasterListCount. Now = \(masterListCount)")
    }
    
    func resetMasterListCount()
    {
        masterListCount = 1
        print ("ResetMasterListCount. Now = \(masterListCount)")
    }
    
    func setMasterListCountToEndOfLineArray()
    {
        masterListCount = listOfLines.count - 1
        print ("setMasterListCountToEndOfLineArray. Now = \(masterListCount)")
    }
    
    func setMasterListCountToIndex(index: Int)
    {
        //The Zero position is always the "Tap Here ..." element.
        if index < 1
        {
            print ("Warning: MasterListCount Set Below 0")
            masterListCount = 1
        } else if index >= listOfLines.count
        {
            print (" Warning: MasterListCount Set Above or equal to listoflines.count")
            masterListCount = listOfLines.count - 1
        } else
        {
            masterListCount = index
        }
        print ("setMasterListCountToIndex. Now = \(masterListCount)")
    }
    
    func actionNoAdsInAppPurchasePaid()
    {
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
}

extension Formatter
{
    static let iso8601: DateFormatter =
    {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        return formatter
    }()
}
extension Date
{
    var iso8601: String
    {
        return Formatter.iso8601.string(from: self)
    }
}

extension String
{
    var dateFromISO8601: Date?
    {
        return Formatter.iso8601.date(from: self)   // "Mar 22, 2017, 10:22 AM"
    }
}

var dbObj: dataBaseObject = dataBaseObject.init()

