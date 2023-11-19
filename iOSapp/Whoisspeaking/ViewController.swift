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

class ViewController: UIViewController {

    @IBOutlet weak var startRecoButton: UIButton!
    
    @IBOutlet weak var resultLabel: UILabel!
    
    @IBOutlet weak var addRecoButton: UIButton!
    
    
    @IBOutlet weak var nameText: UITextField!
    
    
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
    var isAdding=false
    var isRecognizing=false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        testAudioFeaturte()
    }

    
    @IBAction func startRecoAction(_ sender: Any) {
    }
    
    @IBAction func addRecoAction(_ sender: Any) {
    }
    
    
    // start the recognition of the voice
    func startRecog(){
      
    }
    
    // add the voice to server
    func addRecog(){
        
    }
    
    // this is functional test func
    func testAudioFeaturte(){
        let audioFeatureExInstanc=AudioFeatureExtractor()
        audioFeatureExInstanc.start()
    }
    
    
    
    
    // a animation show the listenning status
    func startAnimation(){
        
    }
    func stopAnimation(){
        
    }
}

