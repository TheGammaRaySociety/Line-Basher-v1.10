//
//  BashEntryViewController.swift
//  Line Basher
//
//  Created by Gregory Smith on 4/3/17.
//  Copyright © 2017 GammaRay Software. All rights reserved.
//

import UIKit
import SpriteKit
import CoreData
import Speech
import StoreKit
import GoogleMobileAds
import CoreFoundation

class BashEntryViewController: UIViewController, SFSpeechRecognizerDelegate, UITextFieldDelegate, UITableViewDelegate, AVSpeechSynthesizerDelegate
{
    // MARK: Properties
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    private var recognitionTask: SFSpeechRecognitionTask?
    
    private let audioEngine = AVAudioEngine()
    
    var recordedCueText: String = ""
    var recordedLineText: String = ""
    var previousCueText: String = ""
    var previousLineText: String = ""
    var playBackLine: Bool = false

    var canShowAds: Bool = true
    var interstitialAdReady: Bool = false
    var interstitial: InterstitialAd?
    
    var originalCenterLocation: CGPoint = CGPoint.zero
    
    let bannerSizeAdHeight: CGFloat = 100.0
    let speechSynthesizer = AVSpeechSynthesizer()
    var speechUtterance: AVSpeechUtterance!

    var bufferKeyboardHeight: CGFloat = 0             //This variable exists because I don't understand iOS keyboards.
    
    ///@IBOutlet weak var banner: GADBannerView!
    ///@IBOutlet weak var constraintBannerEditBottom: NSLayoutConstraint!
    
    @IBOutlet var lineTextView : UITextView!
    @IBOutlet var cueTextView : UITextView!
    @IBOutlet weak var viewLineView: UIView!
    @IBOutlet weak var viewCueView: UIView!
    @IBOutlet weak var viewStatusView: UIView!
    @IBOutlet var viewMainView: UIView!
    
    @IBOutlet weak var btnCueClearText: UIButton!
    @IBOutlet weak var btnLineClearText: UIButton!
    @IBOutlet weak var btnNextLine: UIButton!
    @IBOutlet weak var btnPrevLine: UIButton!
    @IBOutlet weak var switchMonologue: UISwitch!
    @IBOutlet weak var lblMonologue: UILabel!
    @IBOutlet weak var btnPlayBack: UIButton!
    
    @IBOutlet weak var lblLineNum: UILabel!
    @IBOutlet weak var lblActScene: UILabel!
    @IBOutlet weak var lblChar: UILabel!
    @IBOutlet weak var lblWork: UILabel!
    
    @IBOutlet var recordLineButton : UIButton!
    @IBOutlet var recordCueButton : UIButton!
    
    @IBOutlet weak var constLineTextBottom: NSLayoutConstraint!
    
    override var prefersStatusBarHidden: Bool
    {
        get {return false}
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // Disable the record buttons until authorization has been granted.
        recordLineButton.isEnabled = false
        speechSynthesizer.delegate = self
        
        ///banner.isHidden = true
        ///banner.delegate = self
        //banner.adUnitID = "ca-app-pub-8101436191593741/5144797310"
        ///banner.rootViewController = self
       ///banner.load(GADRequest())
        
        loadFullScreenAd(adUnitID: "ca-app-pub-8101436191593741/6621530511")

        addDoneButtonOnKeyboard()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        ///if fullVersionPurchased
        ///{
        ///    constraintBannerEditBottom.constant = -100
        ///    banner.alpha = 0
        ///} else
        ///{
        ///    constraintBannerEditBottom.constant = 0
        ///    banner.alpha = 1
        ///}

        lineTextView.font = lineTextView.font?.withSize(textSize)
        cueTextView.font = cueTextView.font?.withSize(textSize)
        getLineFromArray(indexToGet: dbObj.masterListCount)
    }
    
    override func viewDidDisappear(_ animated: Bool)
    {
        closeAllAudioEngines()
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        speechRecognizer.delegate = self
        
        SFSpeechRecognizer.requestAuthorization { authStatus in
            /*
             The callback may not be called on the main thread. Add an
             operation to the main queue to update the record button's state.
             */
            OperationQueue.main.addOperation
            {
                switch authStatus
                {
                case .authorized:
                    self.recordLineButton.isEnabled = true
                    self.recordCueButton.isEnabled = true
                    
                case .denied:
                    self.recordLineButton.isEnabled = false
                    self.recordLineButton.setTitle("User denied access to speech recognition", for: .disabled)
                    self.recordCueButton.isEnabled = false
                    self.recordCueButton.setTitle("User denied access to speech recognition", for: .disabled)
                    
                case .restricted:
                    self.recordLineButton.isEnabled = false
                    self.recordLineButton.setTitle("Speech recognition restricted on this device", for: .disabled)
                    self.recordCueButton.isEnabled = false
                    self.recordCueButton.setTitle("Speech recognition restricted on this device", for: .disabled)
                    
                case .notDetermined:
                    self.recordLineButton.isEnabled = false
                    self.recordLineButton.setTitle("Speech recognition not yet authorized", for: .disabled)
                    self.recordCueButton.isEnabled = false
                    self.recordCueButton.setTitle("Speech recognition not yet authorized", for: .disabled)
                @unknown default:
                    self.recordLineButton.isEnabled = false
                    self.recordCueButton.isEnabled = false
                }
            }
        }
    }
    
    private func startRecordingLine() throws
    {
        // Cancel the previous task if it's running.
        closeAllAudioEngines()
        if let recognitionTask = recognitionTask
        {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .measurement)              //Just added with: ... might be a problem.
        //try audioSession.setCategory(AVAudioSessionCategoryRecord)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        
        // Configure request so that results are returned before audio recording is finished
        recognitionRequest?.shouldReportPartialResults = true
        
        // A recognition task represents a speech recognition session.
        // We keep a reference to the task so that it can be cancelled.
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest!) { result, error in
            var isFinal = false
            
            if let result = result
            {
                self.lineTextView.text = self.previousLineText + " " + result.bestTranscription.formattedString
                isFinal = result.isFinal
                if self.lineTextView.text.last != "." && self.lineTextView.text.last != "!" && self.lineTextView.text.last != "?"
                {
                    self.lineTextView.text = self.lineTextView.text + ". "
                }
                let bottom = self.lineTextView.contentSize.height - self.lineTextView.bounds.size.height
                if bottom > 0
                {
                    self.lineTextView.setContentOffset(CGPoint(x: 0, y: bottom), animated: true)
                }
            }
            
            if error != nil || isFinal
            {
                self.audioEngine.stop()
                self.recognitionRequest?.endAudio()
                self.recognitionTask?.cancel()
                self.audioEngine.reset()
                
                inputNode.removeTap(onBus: 0)
                
                //self.recognitionRequest = nil
                //self.recognitionTask = nil
                
                self.recordLineButton.isEnabled = true
            }
        }
        
       let recordingFormat = inputNode.outputFormat(forBus: 0)
        
       inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        try audioEngine.start()
    }

    private func startRecordingCue() throws
    {
        // Cancel the previous task if it's running.
        closeAllAudioEngines()
        if let recognitionTask = recognitionTask
        {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .measurement)
        //try audioSession.setCategory(AVAudioSessionCategoryRecord)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode 
        
        // Configure request so that results are returned before audio recording is finished
        recognitionRequest?.shouldReportPartialResults = true
        
        // A recognition task represents a speech recognition session.
        // We keep a reference to the task so that it can be cancelled.
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest!) { result, error in
            var isFinal = false
            
            if let result = result
            {
                self.cueTextView.text = self.previousCueText + " " + result.bestTranscription.formattedString
                isFinal = result.isFinal
                if self.cueTextView.text.last != "." && self.cueTextView.text.last != "!" && self.cueTextView.text.last != "?"
                {
                    self.cueTextView.text = self.cueTextView.text + ". "
                }
                let bottom = self.cueTextView.contentSize.height - self.cueTextView.bounds.size.height
                
                if bottom > 0
                {
                    self.cueTextView.setContentOffset(CGPoint(x: 0, y: bottom), animated: true)
                }
            }
            
            if error != nil || isFinal
            {
                self.audioEngine.stop()
                self.recognitionRequest?.endAudio()
                self.recognitionTask?.cancel()
                self.audioEngine.reset()
                
                inputNode.removeTap(onBus: 0)
                
                //self.recognitionRequest = nil
                //self.recognitionTask = nil
                
                self.recordCueButton.isEnabled = true
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        try audioEngine.start()
    }

    // MARK: SFSpeechRecognizerDelegate
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool)
    {
        if available
        {
            recordCueButton.isEnabled = true
            recordLineButton.isEnabled = true
        } else
        {
            print ("Speech Recognizer is not available")
        }
    }
    
    // MARK: Interface Builder actions
    
    @IBAction func recordLineButtonAction()
    {
        toggleLineButton()
    }
    
    func toggleLineButton()
    {
        if speechSynthesizer.isSpeaking
        {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
        
        if audioEngine.isRunning
        {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            recognitionTask?.cancel()
            audioEngine.reset()
            
            recordLineButton.isEnabled = false
            self.recordLineButton.setTitle("Record", for: UIControl.State.normal)
            if cueTextView.isFirstResponder
            {
                cueTextView.resignFirstResponder()
            }
            if lineTextView.isFirstResponder
            {
                lineTextView.resignFirstResponder()
            }
            UIView.animate(withDuration: 0.3, animations: {
                self.btnPrevLine.alpha = 1
                self.btnNextLine.alpha = 1
                self.btnCueClearText.alpha = 1
                self.btnLineClearText.alpha = 1
                self.switchMonologue.alpha = 1
                self.lblMonologue.alpha = 1
                self.recordCueButton.alpha = 1
                self.btnPlayBack.alpha = 1
                })
        } else
        {
            if lineTextView.text.contains(dbObj.stringNewLineTapHere)
            {
                self.previousLineText = ""
                self.lineTextView.text = ""
            } else
            {
                self.previousLineText = self.lineTextView.text
            }
            try! startRecordingLine()
            self.recordLineButton.setTitle("End.", for: UIControl.State.normal)
            UIView.animate(withDuration: 0.3, animations: {
                self.btnPrevLine.alpha = 0
                self.btnNextLine.alpha = 0
                self.btnCueClearText.alpha = 0
                self.btnLineClearText.alpha = 0
                self.recordCueButton.alpha = 0
                self.switchMonologue.alpha = 0
                self.lblMonologue.alpha = 0
                self.btnPlayBack.alpha = 0
                })
        }
    }
    
    @IBAction func switchPartOfMonologueAction(_ sender: Any)
    {
        if switchMonologue.isOn
        {
            cueTextView.isEditable = false
            if dbObj.masterListCount - 1 > 0
            {
                dbObj.listOfLines[dbObj.masterListCount - 1].lineText = dbObj.listOfLines[dbObj.masterListCount - 1].lineText.replacingOccurrences(of: stringContinueAsMonologue, with: "")
                cueTextView.text = dbObj.listOfLines[dbObj.masterListCount - 1].lineText
            }
        } else
        {
            cueTextView.text = ""
            cueTextView.isEditable = true
        }
    }
    
    @IBAction func recordCueButtonAction()
    {
        toggleCueButton()
    }
    
    func toggleCueButton()
    {
        if speechSynthesizer.isSpeaking
        {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }

        if audioEngine.isRunning
        {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            recognitionTask?.cancel()
            audioEngine.reset()
            
            recordCueButton.isEnabled = false
            self.recordCueButton.setTitle("Record", for: UIControl.State.normal)
            if cueTextView.isFirstResponder
            {
                cueTextView.resignFirstResponder()
            }
            if lineTextView.isFirstResponder
            {
                lineTextView.resignFirstResponder()
            }
            UIView.animate(withDuration: 0.3, animations: {
                self.btnPrevLine.alpha = 1
                self.btnNextLine.alpha = 1
                self.btnCueClearText.alpha = 1
                self.btnLineClearText.alpha = 1
                self.recordLineButton.alpha = 1
                self.switchMonologue.alpha = 1
                self.lblMonologue.alpha = 1
                self.btnPlayBack.alpha = 1
                })
        } else
        {
            if cueTextView.text == dbObj.stringNewCueTapHere
            {
                self.previousCueText = ""
                self.cueTextView.text = ""
            } else
            {
                self.previousCueText = self.cueTextView.text
            }
            try! startRecordingCue()
            self.recordCueButton.setTitle("End.", for: UIControl.State.normal)
            UIView.animate(withDuration: 0.3, animations: {
                self.btnPrevLine.alpha = 0
                self.btnNextLine.alpha = 0
                self.btnCueClearText.alpha = 0
                self.btnLineClearText.alpha = 0
                self.recordLineButton.alpha = 0
                self.switchMonologue.alpha = 0
                self.lblMonologue.alpha = 0
                self.btnPlayBack.alpha = 0
                })
        }
    }
    
    @IBAction func btnPlayBackAction(_ sender: Any)
    {
        togglePlayBackAction()
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance)
    {
        utterance.volume = 1.0
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance)
    {
        utterance.volume = 1.0
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance)
    {
        if playBackLine {togglePlayBackAction()}
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance)
    {
        if playBackLine {togglePlayBackAction()}
    }
    
    func togglePlayBackAction()
    {
        if playBackLine
        {
            playBackLine = false
            btnPlayBack.setTitle("Play Back", for: UIControl.State.normal)
            speechSynthesizer.pauseSpeaking(at: .immediate)
            //speechSynthesizer.stopSpeaking(at: .immediate)
        } else
        {
            btnPlayBack.setTitle("Stop", for: UIControl.State.normal)
            playBackLine = true
            speakLineAloud()
        }
    }
    
    func getVoice() -> voiceVariables
    {
        var currentVoice: voiceVariables = voiceVariables.init()
        
        //Implement Switch Statement to Determine Correct Voice to use
        
        currentVoice.rate = 0.5
        currentVoice.pitchMultiplier = 1.0
        currentVoice.volume = 1.0
        
        return currentVoice
    }

    func speakLineAloud()
    {
        guard  playBackLine else {return}
        let playBackVariables: voiceVariables = getVoice()
        if !speechSynthesizer.isPaused
        {
            self.speechUtterance = AVSpeechUtterance(string: lineTextView.text)
            ///let speechUtterance = AVSpeechUtterance(string: lineTextView.text)
            
            speechUtterance.rate = playBackVariables.rate
            speechUtterance.pitchMultiplier = playBackVariables.pitchMultiplier
            speechUtterance.volume = playBackVariables.volume
            
            speechSynthesizer.speak(speechUtterance)
        } else
        {
            speechUtterance.volume = playBackVariables.volume
            speechSynthesizer.continueSpeaking()
        }
    }
    
    func closeAllAudioEngines()
    {
        if audioEngine.isRunning
        {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            recognitionTask?.cancel()
            audioEngine.reset()

            recordCueButton.isEnabled = true
            self.recordCueButton.setTitle("Record", for: UIControl.State.normal)
            recordLineButton.isEnabled = true
            self.recordLineButton.setTitle("Record", for: UIControl.State.normal)
            
            if cueTextView.isFirstResponder
            {
                cueTextView.resignFirstResponder()
            }
            if lineTextView.isFirstResponder
            {
                lineTextView.resignFirstResponder()
            }
        }
        
        if speechSynthesizer.isSpeaking
        {
            playBackLine = false
            btnPlayBack.setTitle("Play Back", for: UIControl.State.normal)
            speechSynthesizer.pauseSpeaking(at: .immediate)
        }
    }

    @IBAction func btnNextLineAction(_ sender: Any)
    {
        closeAllAudioEngines()
        guard !lineTextView.isFirstResponder else {return}
        guard !cueTextView.isFirstResponder else {return}
        
        let _ = checkIfSomthingChanged()
        
        let feedbackGenerator = UISelectionFeedbackGenerator()
        feedbackGenerator.selectionChanged()
        
        if !fullVersionPurchased && dbObj.masterListCount >= listOfLinesWithoutPay
        {
            return
        }
        
        if ((dbObj.masterListCount + 1) >= dbObj.listOfLines.count) && (lineTextView.text != dbObj.stringNewLineTapHere)
        {
            //New Line.
            let _ = checkIfSomthingChanged()        //Save any changes first. We cannot increment MasterListCount until the save is made.
            setUpNewLineAtEnd()         //Note: This is where I call incrementMasterListCount()
        } else
        {
            //Go To Next Line
            dbObj.incrementMasterListCount()
            
            UIView.animate(withDuration: 0.25, animations: {
                self.btnNextLine.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
            }, completion: { finished in
                UIView.animate(withDuration: 0.25, animations: {
                    self.btnNextLine.transform = CGAffineTransform(scaleX: 1, y: 1)
                }, completion: nil)
            })
            getLineFromArray(indexToGet: dbObj.masterListCount)
        }
     }
    
    @IBAction func btnPrevLineAction(_ sender: Any)
    {
        closeAllAudioEngines()
        guard !lineTextView.isFirstResponder else {return}
        guard !cueTextView.isFirstResponder else {return}
        
        let _ = checkIfSomthingChanged()
        
        let feedbackGenerator = UISelectionFeedbackGenerator()
        feedbackGenerator.selectionChanged()
        
        dbObj.decrementMasterListCount()
        
        UIView.animate(withDuration: 0.25, animations: {
            self.btnPrevLine.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        }, completion: { finished in
            UIView.animate(withDuration: 0.25, animations: {
                self.btnPrevLine.transform = CGAffineTransform(scaleX: 1, y: 1)
            }, completion: nil)
        })
        
        getLineFromArray(indexToGet: dbObj.masterListCount)
    }
    
    func checkIfSomthingChanged() -> Bool
    {
        var somethingHasChanged: Bool = false
        
        if lineTextView.text != dbObj.currentLine.lineText {somethingHasChanged = true}
        if cueTextView.text != dbObj.currentLine.cueText {somethingHasChanged = true}
        if switchMonologue.isOn && dbObj.currentLine.isMonologue == "0" {somethingHasChanged = true}
        if switchMonologue.isOn == false && dbObj.currentLine.isMonologue == "1" {somethingHasChanged = true}
        
        if somethingHasChanged
        {
            if dbObj.currentLine.lineID == ""
            {
                //This assumes the line has alreeady been added to the array.
                dbObj.currentLine = lineInfo.init()
                dbObj.currentLine.act = dbObj.currentScene.act
                dbObj.currentLine.blocking = ""
                dbObj.currentLine.cueText = cueTextView.text
                dbObj.currentLine.lineID = ""
                dbObj.currentLine.lineText = lineTextView.text
                dbObj.currentLine.mainChar = dbObj.currentScene.mainChar
                dbObj.currentLine.cueChar = ""
                dbObj.currentLine.scene = dbObj.currentScene.scene
                
                if dbObj.currentLine.lineText == ""
                {
                    dbObj.currentLine.lineText = "-"
                }
                
                if switchMonologue.isOn
                {
                    dbObj.currentLine.isMonologue = "1"
                } else
                {
                    dbObj.currentLine.isMonologue = "0"
                }
                dbObj.currentLine.work = dbObj.currentScene.work
                
                dbObj.currentLine.lineOrder = ("\(dbObj.masterListCount)")
                dbObj.currentLine.lineOrder = dbObj.currentLine.lineOrder.leftPadding(toLength: 5, withPad: "0")
                
                dbObj.listOfLines[dbObj.masterListCount] = dbObj.currentLine
                dbObj.addLineToDataBase(lineToAdd: dbObj.currentLine, setCurrentLineID: true)
                dbObj.reNumberLinesInArrayAndSaveToDataBase()
                print ("listoflines.count = \(dbObj.listOfLines.count)")
                print ("Line ORder1 = \(dbObj.currentLine.lineOrder), MasterListCount = \(dbObj.masterListCount): MasterListCount Should = line order")
                
            } else
            {
                dbObj.currentLine.lineText = lineTextView.text
                dbObj.currentLine.cueText = cueTextView.text
                if switchMonologue.isOn
                {
                    dbObj.currentLine.isMonologue = "1"
                } else
                {
                    dbObj.currentLine.isMonologue = "0"
                }

                dbObj.modifyLineEntityString(lineToModify: dbObj.currentLine)
            }
        }
        
        return somethingHasChanged
    }
    
    @IBAction func cueClearTextAction(_ sender: UIButton)
    {
        cueTextView.text = ""
    }
    
    @IBAction func lineClearTextAction(_ sender: UIButton)
    {
        lineTextView.text = ""
    }
    
    func getLineFromArray(indexToGet: Int)
    {
        // indexToGet has the first entry as index = 1
        // listOfLines has the first entry as index = 0
        dbObj.currentLine = lineInfo.init()
        
        dbObj.currentLine.act = dbObj.listOfLines[indexToGet].act
        dbObj.currentLine.blocking = dbObj.listOfLines[indexToGet].blocking
        dbObj.currentLine.cueText = dbObj.listOfLines[indexToGet].cueText
        dbObj.currentLine.lineID = dbObj.listOfLines[indexToGet].lineID
        dbObj.currentLine.lineText = dbObj.listOfLines[indexToGet].lineText
        dbObj.currentLine.mainChar = dbObj.listOfLines[indexToGet].mainChar
        dbObj.currentLine.cueChar = dbObj.listOfLines[indexToGet].cueChar
        dbObj.currentLine.scene = dbObj.listOfLines[indexToGet].scene
        dbObj.currentLine.isMonologue = dbObj.listOfLines[indexToGet].isMonologue
        dbObj.currentLine.work = dbObj.listOfLines[indexToGet].work
        dbObj.currentLine.lineOrder = dbObj.listOfLines[indexToGet].lineOrder
        
        print ("lineID = \(dbObj.listOfLines[indexToGet].lineID)")
        print ("Line ORder2 = \(dbObj.currentLine.lineOrder), MasterListCount = \(dbObj.masterListCount)")
        
        refreshScreen(indexToGet: indexToGet)
    }
    
    func refreshScreen(indexToGet: Int)
    {
        lineTextView.text = dbObj.currentLine.lineText
        cueTextView.text = dbObj.currentLine.cueText
        
        if dbObj.currentLine.isMonologue == "1"
        {
            switchMonologue.isOn = true
            cueTextView.isEditable = false
        } else
        {
            switchMonologue.isOn = false
            cueTextView.isEditable = true
        }
        
        if dbObj.currentLine.act == dbObj.stringEnterNewAct || dbObj.currentLine.scene == dbObj.stringEnterNewScene
        {
            lblActScene.text = "Invalid Act/Scene"
        } else
        {
            lblActScene.text = "Act " + dbObj.currentLine.act + " : Sc. " + dbObj.currentLine.scene
        }
        
        let lineOrderUnpadded: String = removePadding(originalString: dbObj.currentLine.lineOrder)
        
        lblLineNum.text = "Line ID: " + lineOrderUnpadded
        
        lblWork.text = dbObj.currentLine.work
        lblChar.text = dbObj.currentLine.mainChar
        
        if lineTextView.text == "" || lineTextView.text == dbObj.stringEnterNewLine
        {
            lineTextView.text = dbObj.stringNewLineTapHere
            dbObj.currentLine.lineText = dbObj.stringNewLineTapHere
        }
        if cueTextView.text == ""
        {
            cueTextView.text = dbObj.stringNewCueTapHere
            dbObj.currentLine.cueText = dbObj.stringNewCueTapHere
        }

        if dbObj.masterListCount - 1 > 0
        {
            let tempString = dbObj.listOfLines[dbObj.masterListCount - 1].lineText
            if switchMonologue.isOn && tempString != dbObj.currentLine.cueText
            {
                cueTextView.text = dbObj.listOfLines[dbObj.masterListCount - 1].lineText
            }
        }
        if (indexToGet + 1) < dbObj.listOfLines.count
        {
            if dbObj.listOfLines[indexToGet + 1].isMonologue == "1" && !lineTextView.text.hasSuffix(stringContinueAsMonologue)
            {
                lineTextView.text = lineTextView.text + "\n" + stringContinueAsMonologue
            }
        }

    }
    
    func setUpNewLineAtEnd()
    {
        //This can only be called from "Next Line" Button.
        let tempLine: lineInfo = lineInfo.init()
        dbObj.listOfLines.append(tempLine)
        
        dbObj.incrementMasterListCount()
        dbObj.currentLine.act = dbObj.currentScene.act
        dbObj.currentLine.scene = dbObj.currentScene.scene
        dbObj.currentLine.work = dbObj.currentScene.work
        dbObj.currentLine.mainChar = dbObj.currentScene.mainChar
        dbObj.currentLine.blocking = ""
        dbObj.currentLine.cueText = dbObj.stringNewCueTapHere
        dbObj.currentLine.lineText = dbObj.stringNewLineTapHere
        dbObj.currentLine.cueChar = ""
        dbObj.currentLine.isMonologue = "0"
        dbObj.currentLine.lineID = ""
        dbObj.currentLine.lineOrder = ("\(dbObj.masterListCount)")
        dbObj.currentLine.lineOrder = dbObj.currentLine.lineOrder.leftPadding(toLength: 5, withPad: "0")
        
        dbObj.listOfLines[dbObj.masterListCount] = dbObj.currentLine
        
        print ("listoflines.count = \(dbObj.listOfLines.count)")
        print ("Line ORder3 = \(dbObj.currentLine.lineOrder), MasterListCount = \(dbObj.masterListCount)")
        
        refreshScreen(indexToGet: dbObj.listOfLines.count)
    }

    func addDoneButtonOnKeyboard()
    {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 50))
        doneToolbar.barStyle       = .default
        let flexSpace              = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem  = UIBarButtonItem(title: "Finish", style: UIBarButtonItem.Style.done, target: self, action: #selector(doneButtonIsPressed))
        
        var items = [UIBarButtonItem]()
        items.append(flexSpace)
        items.append(done)
        
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        
        lineTextView.inputAccessoryView = doneToolbar
        cueTextView.inputAccessoryView = doneToolbar
    }

    @objc func doneButtonIsPressed()
    {
        let _ = checkIfSomthingChanged()
        closeAllAudioEngines()
        cueTextView.resignFirstResponder()
        lineTextView.resignFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        let _ = checkIfSomthingChanged()
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: self.view.window)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: self.view.window)
    }
    
    @objc func keyboardWillShow(sender: NSNotification)
    {
        closeAllAudioEngines()
        if cueTextView.isFirstResponder
        {
            if cueTextView.text.contains(dbObj.stringNewCueTapHere)
            {
                cueTextView.text = ""
            }
            viewLineView.alpha = 0
            viewStatusView.alpha = 0
            btnNextLine.alpha = 0
            btnPrevLine.alpha = 0
        }
        
        if lineTextView.isFirstResponder
        {
            if lineTextView.text.contains(dbObj.stringNewLineTapHere)
            {
                lineTextView.text = ""
            }
            viewCueView.alpha = 0
            viewStatusView.alpha = 0
            btnNextLine.alpha = 0
            btnPrevLine.alpha = 0
        }
        
        guard lineTextView.isFirstResponder else {return}
        guard originalCenterLocation == CGPoint.zero else {return}
        
        originalCenterLocation = viewMainView.center
        let offsetBufferForLine: CGFloat = 25                //This is to ensure the buttons are not above the top.
        
        ///if let keyboardSize = (sender.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue
        if let keyboardSize = (sender.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        {
            let keyboardHeight: CGFloat = keyboardSize.height
            
            if bufferKeyboardHeight <= 0
            {
                bufferKeyboardHeight = keyboardHeight
            }
            
            var newCenter: CGPoint = viewMainView.center
            newCenter.y = newCenter.y - (bufferKeyboardHeight - offsetBufferForLine)
            
            UIView.animate(withDuration: 0.5, animations: {
                self.viewMainView.center = newCenter
                self.constLineTextBottom.constant = 20
            })
        }
    }
    
    @objc func keyboardWillHide(sender: NSNotification)
    {
        viewCueView.alpha = 1
        viewStatusView.alpha = 1
        btnNextLine.alpha = 1
        btnPrevLine.alpha = 1
        viewLineView.alpha = 1
        switchMonologue.alpha = 1
        lblMonologue.alpha = 1
        btnLineClearText.alpha = 1
        btnCueClearText.alpha = 1
        recordCueButton.alpha = 1
        recordLineButton.alpha = 1
        btnPlayBack.alpha = 1
        
        guard originalCenterLocation != CGPoint.zero else {return}
        viewMainView.center = originalCenterLocation
        originalCenterLocation = CGPoint.zero
        constLineTextBottom.constant = 0
    }
    

    //MARK: Ad MobStuff
    func loadFullScreenAd(adUnitID: String)
    {
        InterstitialAd.load(with: adUnitID, request: Request()) { [weak self] ad, _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let ad = ad {
                    print ("Interstitial Ad is Received: BashEntryVC")
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
        ///banner.load(GADRequest())
    }
    
    func hideAdsInGame ()
    {
        canShowAds = false
        ///banner.isHidden = true
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

extension String
{
    func leftPadding(toLength: Int, withPad character: Character) -> String
    {
        let newLength = self.count
        if newLength < toLength
        {
            return String(repeatElement(character, count: toLength - newLength)) + self
        } else
        {
            return self
            ///If the string is too long to pad, then just return the original string. The command before was used, but I think it is better to just return 'self'.
            ///return self.substring(from: index(self.startIndex, offsetBy: newLength - toLength))
        }
    }
}

func removePadding(originalString: String) -> String
{
    var unPaddedString: String = ""
    var firstNonZeroFound: Bool = false
    
    for char in originalString
    {
        if char == "0"
        {
            if firstNonZeroFound
            {
                unPaddedString = unPaddedString + String(char)
            }
        } else
        {
            unPaddedString = unPaddedString + String(char)
            firstNonZeroFound = true
        }
    }
    return unPaddedString
}



