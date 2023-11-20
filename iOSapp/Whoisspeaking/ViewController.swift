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
    // delegate function
    // fuction get the pitch and amp to send to server
    func audioFeatureExtract(pitch: Double, amp: Double) {
       
        voiceDataHandle(pitch: pitch, amp: amp)
    }
    let RECOGNIZING_B_LABLE="Recognizing Say Something"
    let RECOGNIZE_B_DEFAULT="Start Recognize"
    let ADDRECOG_B_LABLE="Say Something"
    let ADDRECOG_B_DEFAULT="ADD Recognize"
    
    let POST_PREDICTKNN="/PredictOne?model_name=KNN"
    let POST_PREDICTBT="/PredictOne?model_name=BT"
    
    @IBOutlet weak var startRecoButton: UIButton!
    
    @IBOutlet weak var resultLabel: UILabel!
    
    @IBOutlet weak var addRecoButton: UIButton!
    
    @IBOutlet weak var nameText: UITextField!
    
    let voiceOperationQueue=OperationQueue()
    var buffer=Buffer()
    var isWaitingForData=false
    var addName:String="Default"
    
    
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
                print("addingdata\(buffer)")
            }
            // comm the server
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: {
                self.voiceOperationQueue.addOperation {
                    // something large enough happened to warrant
                    self.voiceEventOccured()   //call the func to send data to server
                }
            })
        }else{
            
        }
    }
    
    //communicat the server
    func voiceEventOccured(){
        if isRecognizing{
            // send the voice data
            getPrediction(array: self.buffer.getDataAsVector())
         
        }else{
            // send the voice with label
            sendFeatures(array: self.buffer.getDataAsVector(), label: addName)
            setDelayedWaitingToTrue(2.0)
         
        }
    }
    
    //set the time delay for more data.
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
            startRecoButton.setTitle(RECOGNIZING_B_LABLE, for: .normal)
        }else{
            isListening=false
            isRecognizing=false
            startRecoButton.setTitle(RECOGNIZE_B_DEFAULT, for: .normal)
        }
    }
    
    //button action add the voice to server
    func addRecog(){
        if nameText.text != nil{
            if(!isListening){
                isListening=true
                isRecognizing=false
                addRecoButton.setTitle(ADDRECOG_B_LABLE, for: .normal)
                addName=nameText.text ?? "Default"
            }else{
                isListening=false
                isRecognizing=false
                addRecoButton.setTitle(ADDRECOG_B_DEFAULT, for: .normal)
                getUpdateModel()// anounce the server to do the train
            }
        }else{
             messageInfor(_message: "Type your name")
        }
      
     
    }
    
    // update the model
    func getUpdateModel(){
        let connectM=ConnectManager.shared
        connectM.sendGetRequest(endpoint: "/UpdateModel", completion: {result in
            switch result {
            case .success(let data):
                // Handle the success case, e.g., parse the response data
                print("Request successful. Response data: \(data)")
                
            case .failure(let error):
                // Handle the failure case, e.g., display an error message
                print("Request failed. Error: \(error)")
            }
            
        })
    }
    
    
    // upload the feature
    func sendFeatures(array:[Double],label:String){
        let connectM=ConnectManager.shared
        let jasonUpload:NSDictionary=["feature":array,"label":label,"dsid":1]
        let requestData:Data?=self.convertDictionaryToData(with: jasonUpload)
        connectM.sendPostRequest(endpoint: "/AddDataPoint", jsonData: requestData!, completion: {result in
            switch result {
            case .success(let data):
                // Handle the success case, e.g., parse the response data
                print("Request successful. Response data: \(data)")
                
            case .failure(let error):
                // Handle the failure case, e.g., display an error message
                print("Request failed. Error: \(error)")
            }
        })
    }
    
    // train done and get the result
    func getPrediction(array:[Double]){
        let connectM=ConnectManager.shared
        let jasonUpload:NSDictionary=["feature":array,"dsid":1]
        let requestData:Data?=self.convertDictionaryToData(with: jasonUpload)
        connectM.sendPostRequest(endpoint: "/PredictOne", jsonData: requestData!, completion: {result in
            switch result {
            case .success(let data):
                // Handle the success case, e.g., parse the response data
                print("Request successful. Response data: \(data)")
                let jsonDictionary = self.convertDataToDictionary(with: data)
                                
                // I send the error message from the server to deal with the situation that i have no module ready
                if let labelResponse = jsonDictionary["prediction"] {
                print("prediction:\(labelResponse)")
                }else if let errorInfor = jsonDictionary["error"]{
                print(errorInfor)
                }else{
                print("Something Error We are dealing with")
                }
                
            case .failure(let error):
                // Handle the failure case, e.g., display an error message
                print("Request failed. Error: \(error)")
            }
            
        })
        
        
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
    
    //MARK: JSON Conversion Functions
       func convertDictionaryToData(with jsonUpload:NSDictionary) -> Data?{
           do { // try to make JSON and deal with errors using do/catch block
               let requestBody = try JSONSerialization.data(withJSONObject: jsonUpload, options:JSONSerialization.WritingOptions.prettyPrinted)
               return requestBody
           } catch {
               print("json error: \(error.localizedDescription)")
               return nil
           }
       }
       
       func convertDataToDictionary(with data:Data?)->NSDictionary{
           do { // try to parse JSON and deal with errors using do/catch block
               let jsonDictionary: NSDictionary =
                   try JSONSerialization.jsonObject(with: data!,
                                                 options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
               
               return jsonDictionary
               
           } catch {
               
               if let strData = String(data:data!, encoding:String.Encoding(rawValue: String.Encoding.utf8.rawValue)){
                               print("printing JSON received as string: "+strData)
               }else{
                   print("json error: \(error.localizedDescription)")
               }
               return NSDictionary() // just return empty
           }
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

