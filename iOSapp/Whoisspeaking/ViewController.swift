//
//  ViewController.swift
//  Whoisspeaking
//
//  Created by RongWei Ji on 11/18/23.
//
// here is main logic for the ui
// 1. open app directly dect speaking ,and send to server to anay
//    - no record on server ,returen infor -directly to train who you are
//
//    - yes record return who is speaking
// beacuse using a exsiting rep , no ability to creat branch in xcode .
// add new branch commit
// startreco - yes start

import UIKit


class ViewController: UIViewController,AudioFeatureExtractorDelegate {
    // fuction get the pitch and amp to send to server
    func audioFeatureExtract(pitch: Double, amp: Double) {
        print("pitch\(pitch);amp\(amp)")
        voiceDataHandle(pitch: pitch, amp: amp)
    }
    let RECOGNIZING_B_LABLE="Recognizing Say Something"
    let RECOGNIZE_B_DEFAULT="Start Recognize"
    let ADDRECOG_B_LABLE="Say Something"
    let ADDRECOG_B_DEFAULT="ADD Recognize"
    
    @IBOutlet weak var startRecoButton: UIButton!
    
    @IBOutlet weak var resultLabel: UILabel!
    
    @IBOutlet weak var addRecoButton: UIButton!
    
    @IBOutlet weak var nameText: UITextField!
    
    let voiceOperationQueue=OperationQueue()
    var buffer=Buffer()
    var isWaitingForData=false
    
    // set the flag to start the animation of the listenning action
    var isListening=false{
        didSet{
            if isListening{
                startAnimation()
            }else{
                stopAnimation()
            }
        }
    }
    var isRecognizing=false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        testAudioFeaturte()
    }

    // detect the voice and - add recognization ,- recognize now voice
    // handle the data from the buffer to array
    func voiceDataHandle(pitch:Double,amp:Double){
        
        if(isListening){
            if(pitch>60){// filter the background
                self.buffer.addNewData(fData: pitch, aData: amp)// add the data
            }
            // comm the server
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: {
                self.voiceOperationQueue.addOperation {
                    // something large enough happened to warrant
                    self.voiceEventOccured()   //call the func to send data to server
                }
            })
        }
    }
    
    //communicat the server
    func voiceEventOccured(){
        
        if isRecognizing{
            // send the voice data
            getPrediction(_array: self.buffer.getDataAsVector())
         
        }else{
            // send the voice with label
            // check the tesfield
            if let label=nameText.text{
                sendFeatures(_array: self.buffer.getDataAsVector(), _label: label)
                setDelayedWaitingToTrue(2.0)
            }
            
        }
    }
    
    // for the time delay, have more data to send to server 
    func setDelayedWaitingToTrue(_ time:Double){
           DispatchQueue.main.asyncAfter(deadline: .now() + time, execute: {
               self.isWaitingForData = true
           })
       }
    
 
    // button action start the recognition of the voice
    func startRecog(){
        if(!isListening ){
            isListening=true
            isRecognizing=true
           
        }else{
            isListening=false
            isRecognizing=false
        }
    }
    
    //button action add the voice to server
    func addRecog(){
        if nameText.text==nil{
            messageInfor(_message: "Please type your name")
        }else{
            if(!isListening){
                isListening=true
                isRecognizing=false
            }else{
                isListening=false
                isRecognizing=false
            }
        }
      
     
    }
    
    func sendFeatures(_array:[Double],_label:String){
        
    }
    
    func getPrediction(_array:[Double]){
        
    }
    
    // this is functional test func
    func testAudioFeaturte(){
        let audioFeatureExInstanc=AudioFeatureExtractor()
        audioFeatureExInstanc.delegate=self
        audioFeatureExInstanc.start()
    }
    
    // a func to tell user by a dialog
    func messageInfor(_message:String){
        print("Message:\(_message)")
    }
    
    
    @IBAction func startRecoAction(_ sender: Any) {
        startRecog()
    }
    
    @IBAction func addRecoAction(_ sender: Any) {
        addRecog()
    }
    
    
   
    
    
    
    
    // a animation show the listenning status
    func startAnimation(){
        
    }
    func stopAnimation(){
        
    }
}

