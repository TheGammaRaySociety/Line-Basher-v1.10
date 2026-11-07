//
//  BashPlayViewController.swift
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
import CoreFoundation

struct voiceVariables
{
    var rate: Float = 0.0
    var pitchMultiplier: Float = 0.0
    var volume: Float = 0.5
}

class BashPlayViewController: UIViewController, SFSpeechRecognizerDelegate, GADBannerViewDelegate, UITextFieldDelegate, GADInterstitialDelegate
{
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    private var recognitionTask: SFSpeechRecognitionTask?
    
    private let audioEngine = AVAudioEngine()

    var recordedCueText: String = ""
    var recordedLineText: String = ""
    var previousCueText: String = ""
    var previousLineText: String = ""
    
    var canShowAds: Bool = true
    var interstitialAdReady: Bool = false
    var interstitial: GADInterstitial!
    
    var listenToTheCues: Bool = false
    var hintCount: Int = 0
    
    var speakItActive: Bool = false
    var speakItBufferString: String = ""
    var speakItBufferWordArray: [String] = []
    var speakItComparingString: String = ""
    var speakItDisplayString: String = ""
    
    let speechSynthesizer = AVSpeechSynthesizer()
    let validCharacters: CharacterSet = CharacterSet.alphanumerics
    
    ///@IBOutlet weak var banner: GADBannerView!
    ///@IBOutlet weak var constraintBannerRehearseBottom: NSLayoutConstraint!
    
    @IBOutlet weak var txtCueText: UITextView!
    @IBOutlet weak var txtLineText: UITextView!
    @IBOutlet weak var btnNextLine: UIButton!
    @IBOutlet weak var btnPrevLine: UIButton!
    
    @IBOutlet weak var btnSpeakCue: UIButton!
    @IBOutlet weak var btnListenToLine: UIButton!
    @IBOutlet weak var btnHint: UIButton!
    @IBOutlet weak var btnShowLine: UIButton!
    @IBOutlet weak var btnRepeatLine: UIButton!
    
    @IBOutlet weak var lblWork: UILabel!
    @IBOutlet weak var lblMainChar: UILabel!
    @IBOutlet weak var lblActScene: UILabel!
    @IBOutlet weak var lblLineNum: UILabel!
    
    @IBOutlet weak var imgCrackedBackground: UIImageView!
    @IBOutlet weak var imgTitle: UIImageView!
    
    override var prefersStatusBarHidden: Bool
    {
        get {return false}
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        ///banner.isHidden = true
        ///banner.delegate = self
        ///banner.adUnitID = "ca-app-pub-8101436191593741/5144797310"
        ///banner.rootViewController = self
        ///banner.load(GADRequest())
        
        interstitial = GADInterstitial(adUnitID: "ca-app-pub-8101436191593741/6621530511")
        interstitial.delegate = self
        let request = GADRequest()
        interstitial.load(request)
        
        btnSpeakCue.setTitle("Hear Cues", for: UIControlState.normal)
        appStoreReviewCoordinator.incrementEventCounter()
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        ///if fullVersionPurchased
        ///{
            ///constraintBannerRehearseBottom.constant = -100
            ///banner.alpha = 0
        ///} else
        ///{
            ///constraintBannerRehearseBottom.constant = 0
            ///banner.alpha = 1
        ///}
        txtCueText.font = txtCueText.font?.withSize(textSize)
        txtLineText.font = txtLineText.font?.withSize(textSize)
        
        getLineFromArray(indexToGet: dbObj.masterListCount)
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
                        self.btnListenToLine.isEnabled = true
                        
                    case .denied:
                        self.btnListenToLine.isEnabled = false
                        
                    case .restricted:
                        self.btnListenToLine.isEnabled = false
                        
                    case .notDetermined:
                        self.btnListenToLine.isEnabled = false
                    }
                }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        if interstitialCount >= numberOfLineSelectVCExitsBeforeInterstitial && (!fullVersionPurchased || showAdsEvenWhenPaid)
        {
            showFullScreenAd()
            interstitialCount = 0
        } else
        {
            print ("interstitialCount = \(interstitialCount), in BashPlayViewController.")
            interstitialCount = interstitialCount + 1
        }
       stopAudioEngine()
    }
    
    private func startSpeakItAction() throws
    {
        stopAudioEngine()
        
        // Cancel the previous task if it's running.
        if let recognitionTask = recognitionTask
        {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        
        try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
        //try audioSession.setCategory(AVAudioSessionCategoryRecord)
        try audioSession.setMode(AVAudioSessionModeMeasurement)
        try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        
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
                isFinal = result.isFinal
                self.speakItBufferString = result.bestTranscription.formattedString
                print ("speakitbufferstring = \(self.speakItBufferString)")
                self.displayCorrectlySpokenWords()
                
            }
            
            if error != nil || isFinal
            {
                self.stopAudioEngine()
                inputNode.removeTap(onBus: 0)
                print ("inputNode tap is removed.")
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat)
        {
            (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        try audioEngine.start()
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool)
    {
        if available
        {
            btnListenToLine.isEnabled = true
        } else
        {
            btnListenToLine.isEnabled = false
        }
    }
    
    func displayCorrectlySpokenWords()
    {
        //SpeakItBufferString is always set by the speech recognizer and canont be changed.
        
        speakItBufferWordArray = speakItBufferString.components(separatedBy: " ")
        speakItComparingString = dbObj.currentLine.lineText
        speakItDisplayString = encodeLine()
        
        for word in speakItBufferWordArray
        {
            var modWord: String = word
            
            if modWord == "Mr." {modWord = "Mr"}
            if modWord == "Mrs." {modWord = "Mrs"}
            if modWord == "Ms." {modWord = "Ms"}

            if speakItComparingString.localizedCaseInsensitiveContains(modWord)
            {
                var arrayOfIndicies: [Int] = []
                arrayOfIndicies = getIndicesForWordInString(sourceString: speakItComparingString, wordToFind: modWord)
                
                if arrayOfIndicies.count >= 2
                {
                    let startingIndexPosition: Int = arrayOfIndicies[0]
                    let endingIndexPosition: Int = arrayOfIndicies[1]
                    
                    let startingIndex = speakItDisplayString.index(speakItDisplayString.startIndex, offsetBy: startingIndexPosition)
                    let endingIndex = speakItDisplayString.index(speakItDisplayString.startIndex, offsetBy: endingIndexPosition)

                    if speakItDisplayString[startingIndex] == encodedCharacter && speakItDisplayString[endingIndex] == encodedCharacter
                    {
                        //Change speakItDisplayString with correct text
                        speakItDisplayString.removeSubrange(startingIndex...endingIndex)

                        let foundWord: Substring = dbObj.currentLine.lineText[startingIndex...endingIndex]
                        speakItDisplayString.insert(contentsOf: foundWord, at: startingIndex)
                        
                        var arrayOfComparingCharacters = Array(speakItComparingString)
                        
                        for iCount in startingIndexPosition...endingIndexPosition
                        {
                            arrayOfComparingCharacters[iCount] = Character("+")
                        }
                        speakItComparingString = String(arrayOfComparingCharacters)
                        
                    }
               }
            }
        }
        if btnListenToLine.alpha == 1
        {
            txtLineText.text = speakItDisplayString
        }
    }
    func getIndicesForWordInString(sourceString: String, wordToFind: String) -> [Int]
    {
        //Always return indicies of the first match found.
        var indicies: [Int] = []
        
        var searchStartIndex = sourceString.startIndex
        let searchEndIndex = sourceString.endIndex
        
        while let range = sourceString.range(of: wordToFind, options: .caseInsensitive, range: searchStartIndex..<searchEndIndex, locale: nil)
        {
            searchStartIndex = range.upperBound

            let startPos = sourceString.distance(from: dbObj.currentLine.lineText.startIndex, to: range.lowerBound)
            var endPos = sourceString.distance(from: dbObj.currentLine.lineText.startIndex, to: range.upperBound)
            endPos = endPos - 1
            indicies.append(startPos)
            indicies.append(endPos)
        }
        
        return indicies
    }
    
    func stopAudioEngine()
    {
        
        if audioEngine.isRunning
        {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            recognitionTask?.cancel()
            audioEngine.reset()
        }
        
        if speechSynthesizer.isSpeaking
        {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
        
    }
    
    @IBAction func btnRepeatLineAction(_ sender: Any)
    {
        stopAudioEngine()
        
        let feedbackGenerator = UISelectionFeedbackGenerator()
        feedbackGenerator.selectionChanged()

        getLineFromArray(indexToGet: dbObj.masterListCount)
        playCue()
    }
    
    @IBAction func btnNextLineAction(_ sender: Any)
    {
        stopAudioEngine()
        
        let feedbackGenerator = UISelectionFeedbackGenerator()
        feedbackGenerator.selectionChanged()
        
        dbObj.incrementMasterListCount()
        UIView.animate(withDuration: 0.25, animations: {
            self.btnNextLine.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        }, completion: { finished in
            UIView.animate(withDuration: 0.25, animations: {
                self.btnNextLine.transform = CGAffineTransform(scaleX: 1, y: 1)
            }, completion: nil)
        })
        getLineFromArray(indexToGet: dbObj.masterListCount)
        playCue()
    }
    
    func playCue()
    {
        if listenToTheCues
        {
            let speechUtterance = AVSpeechUtterance(string: txtCueText.text)
            let playBackVariables: voiceVariables = getVoice()
            
            speechUtterance.rate = playBackVariables.rate
            speechUtterance.pitchMultiplier = playBackVariables.pitchMultiplier
            speechUtterance.volume = playBackVariables.volume
            print ("speechUtterance.volume = \(speechUtterance.volume)")
            
            speechSynthesizer.speak(speechUtterance)
        }
    }
    
    @IBAction func btnPrevLineAction(_ sender: Any)
    {
        stopAudioEngine()
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
        
        playCue()
    }
    
    func getLineFromArray(indexToGet: Int)
    {
        guard indexToGet < dbObj.listOfLines.count else {print ("Problem getLineFromArray. Index Too High"); return}
        guard indexToGet >= 0 else {print ("Problem getLineFromArray. Index Too Low"); return}
        
        if speakItActive {toggleSpeakItButton()}
        
        if alwaysShowLines
        {
            btnHint.alpha = 0
            btnListenToLine.alpha = 0
            btnShowLine.alpha = 0
            imgTitle.alpha = 0
            imgCrackedBackground.alpha = 0
        } else
        {
            btnHint.alpha = 1
            btnListenToLine.alpha = 1
            btnShowLine.alpha = 1
            imgTitle.alpha = 1
            imgCrackedBackground.alpha = 1
        }
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
        
        print ("listoflines.count = \(dbObj.listOfLines.count)")
        print ("Line ORder5 = \(dbObj.currentLine.lineOrder), MasterListCount = \(dbObj.masterListCount)")
        
        refreshScreen(indexToGet: indexToGet)
    }

    func refreshScreen(indexToGet: Int)
    {
        if alwaysShowLines
        {
            txtLineText.text = dbObj.currentLine.lineText
            txtCueText.text = dbObj.currentLine.cueText
            imgTitle.alpha = 0
            imgCrackedBackground.alpha = 0
        } else
        {
            txtLineText.text = encodeLine()
            txtCueText.text = dbObj.currentLine.cueText
            imgTitle.alpha = 1
            imgCrackedBackground.alpha = 1
        }
        
        if dbObj.currentLine.isMonologue == "1"
        {
            txtCueText.text = stringPartOfMonologue + "\n" + dbObj.currentLine.cueText
        }
        
        lblActScene.text = "Act " + dbObj.currentLine.act + " : Sc. " + dbObj.currentLine.scene
        
        let lineOrderUnpadded: String = removePadding(originalString: dbObj.currentLine.lineOrder)
        lblLineNum.text = "Line ID: " + lineOrderUnpadded
        
        lblWork.text = dbObj.currentLine.work
        lblMainChar.text = dbObj.currentLine.mainChar
        hintCount = 0
        btnSpeakCue.alpha = 1
        
        if (indexToGet + 1) < dbObj.listOfLines.count
        {
            if dbObj.listOfLines[indexToGet + 1].isMonologue == "1" && !txtLineText.text.hasSuffix(stringContinueAsMonologue)
            {
                txtLineText.text = txtLineText.text + "\n" + stringContinueAsMonologue
            }
        }
    }
    
    func encodeLine() -> String
    {
        var monologueStringNeedsToBeAdded: Bool = false
        
        let encodedLine: String = dbObj.currentLine.lineText
        if encodedLine.hasSuffix(stringContinueAsMonologue)
        {
            monologueStringNeedsToBeAdded = true
        }
        
        var arrayOfCharacters = Array(encodedLine)
        var iCount:Int = 0
        
        for tempChar in dbObj.currentLine.lineText.unicodeScalars
        {
            if validCharacters.contains(tempChar)
            {
                arrayOfCharacters[iCount] = encodedCharacter
            } else
            {
                arrayOfCharacters[iCount] = Character(tempChar)
            }
            iCount = iCount + 1
        }
                
        var displayedLine = String(arrayOfCharacters)
        
        if monologueStringNeedsToBeAdded
        {
            displayedLine = displayedLine + "\n" + stringContinueAsMonologue
        }
        
        return displayedLine
    }
    
    func getVoice() -> voiceVariables
    {
        var currentVoice: voiceVariables = voiceVariables.init()
        
        //Implement Switch Statement to Determine Correct Voice to use
        
        currentVoice.rate = 0.5
        currentVoice.pitchMultiplier = 1.0
        currentVoice.volume = 0.75
        
        return currentVoice
    }
    
    @IBAction func btnListenAction(_ sender: Any)
    {
        if listenToTheCues
        {
            listenToTheCues = false
            btnSpeakCue.setTitle("Hear Cues", for: UIControlState.normal)
            speechSynthesizer.stopSpeaking(at: .immediate)
        } else
        {
            btnSpeakCue.setTitle("Mute Cues", for: UIControlState.normal)
            listenToTheCues = true
            playCue()
        }
    }
    
    @IBAction func btnHintAction(_ sender: Any)
    {
        stopAudioEngine()
        btnListenToLine.alpha = 0
        hintCount = hintCount + 1
        
        let maxHintChars: Int = hintCount * charsPerHint
        var numberOfHintCharsGiven: Int = 0
        var hintText = Array(encodeLine())
            
        if imgTitle.alpha == 0
        {
            hintText = Array(txtLineText.text)
        }
        var realLineText: Array = Array(dbObj.currentLine.lineText)
        
        print (dbObj.currentLine.lineText.count)
        if maxHintChars < noSpaceCharsInString()
        {
            for i in 0...(hintText.count - 1)
            {
                if hintText[i] == encodedCharacter
                {
                    numberOfHintCharsGiven = numberOfHintCharsGiven + 1
                    hintText[i] = realLineText[i]
                }
                if i >= (hintText.count - 1)
                {
                    numberOfHintCharsGiven = maxHintChars
                }
                if numberOfHintCharsGiven > charsPerHint
                {
                    break
                }
            }
            
            txtLineText.text = String(hintText)
        } else
        {
            txtLineText.text = dbObj.currentLine.lineText
            btnShowLine.alpha = 0
            btnHint.alpha = 0
        }
        
        UIView.animate(withDuration: 0.5, animations: {
            self.imgTitle.alpha = 0
            self.imgCrackedBackground.alpha = 0
            self.txtLineText.alpha = 1
            }, completion: nil)
    }
    
    func noSpaceCharsInString() -> Int
    {
        var noSpaceChars: Int = 0
        
        for char in dbObj.currentLine.lineText
        {
            if char != " " && char != encodedCharacter && char != "." && char != "," && char != "." && char != "'" && char != "!" && char != "?" && char != ":"
            {
                noSpaceChars = noSpaceChars + 1
            }
        }
        
        print ("NoSpaceChars = \(noSpaceChars)")
        return noSpaceChars
    }
    
    @IBAction func btnSpeakItAction(_ sender: Any)
    {
        toggleSpeakItButton()
    }
    
    func toggleSpeakItButton()
    {
        if !speakItActive
        {
            btnSpeakCue.alpha = 0
            btnListenToLine.alpha = 1
            btnListenToLine.setTitle("Stop!", for: .normal)
            try! startSpeakItAction()
            
            txtLineText.text = encodeLine()
            
            speakItBufferString = ""
            speakItBufferWordArray = []
            speakItActive = true
        } else
        {
            stopAudioEngine()
            btnSpeakCue.alpha = 1
            btnListenToLine.alpha = 0
            btnListenToLine.setTitle("Speak It!", for: .normal)
            
            speakItComparingString = ""
            speakItBufferString = ""
            speakItBufferWordArray = []
            speakItActive = false
        }
        
        UIView.animate(withDuration: 0.5, animations: {
            self.imgTitle.alpha = 0
            self.imgCrackedBackground.alpha = 0
            self.txtLineText.alpha = 1
        }, completion: nil)
    }
    
    @IBAction func btnShowAction(_ sender: Any)
    {
        stopAudioEngine()
        UIView.animate(withDuration: 0.5, animations: {
            self.imgTitle.alpha = 0
            self.imgCrackedBackground.alpha = 0
            self.txtLineText.alpha = 1
        }, completion: nil)
        txtLineText.text = dbObj.currentLine.lineText
        btnShowLine.alpha = 0
        btnHint.alpha = 0
        btnListenToLine.alpha = 0
    }
    
    //MARK: Ad MobStuff
    func adViewDidReceiveAd(_ bannerView: GADBannerView)
    {
        if canShowAds
        {
            ///banner.isHidden = false
        } else
        {
            ///banner.isHidden = true
        }
    }
    
    func interstitialDidReceiveAd(_ ad: GADInterstitial)
    {
        print ("Interstitial Ad is Received: BashPlayVC")
        interstitialAdReady = true
    }
    
    func adView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError)
    {
        ///banner.isHidden = true
    }
    
    func createFullScreenAd() -> GADInterstitial
    {
        let interstitialAd = GADInterstitial(adUnitID: "ca-app-pub-8101436191593741/8760361314")
        interstitialAd.load(GADRequest())
        interstitialAd.delegate = self
        return interstitialAd
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
        if (interstitial.isReady)
        {
            interstitialAdReady = false
            interstitial.present(fromRootViewController: self)
            interstitial = createFullScreenAd()
        }
    }
}

extension String
{
    subscript (i: Int) -> Character
    {
        return self[index(startIndex, offsetBy: i)]
    }
    
    subscript (i: Int) -> String
    {
        return String(self[i] as Character)
    }
    
    subscript (r: Range<Int>) -> String
    {
        let start = index(startIndex, offsetBy: r.lowerBound)
        let end = index(startIndex, offsetBy: r.upperBound - r.lowerBound)
        return String(self[Range(start ..< end)])
    }
}

extension String
{
    func trimmingCharactersNot(in charSet: CharacterSet) -> String
    {
        var s:String = ""
        for unicodeScalar in self.unicodeScalars
        {
            if charSet.contains(unicodeScalar)
            {
                s.append(String(unicodeScalar))
            }
        }
        return s
    }
}

extension Collection
{
    subscript() -> SubSequence
    {
        return self[startIndex..<endIndex]
    }
}
