// //
// //  StartScreen.swift
// //  Identy1
// //
// //  Created by Sumuga on 2/20/18.
// //  Copyright © 2018 Sumuga. All rights reserved.
// //

// import UIKit
// import WebKit
// import SystemConfiguration
// import Identy

// class InitialViewController: UIViewController, UIGestureRecognizerDelegate,UIDocumentInteractionControllerDelegate,UITextFieldDelegate {
//     var handScanTypeArray: [HandScanType] = []
//     @IBOutlet weak var leftHandCheckBox: UIButton!
//     @IBOutlet weak var rightHandCheckBox: UIButton!
//     @IBOutlet weak var leftThumbCheckBox: UIButton!
//     @IBOutlet weak var rightThumbCheckBox: UIButton!
//     @IBOutlet weak var twoThumbCheckBox: UIButton!
//     @IBOutlet weak var verify: UIButton!
//     @IBOutlet weak var enroll: UIButton!
//     @IBOutlet weak var versionLabel: UILabel!
//     @IBOutlet weak var usernameTextField: UITextField!
//     @IBOutlet weak var hintLabel : UILabel!
//     var menuModelObj = MenuModel()
    
//     private var usersArray: [String] = []
//     private var isLeftMissingFingerSelected: Bool! = false
//     private var isRightMissingFingerSelected: Bool! = false
//     private var leftMissingFingerCount = 0
//     private var rightMissingFingerCount = 0
//     private var rightMissingArray: [Int] = []
//     private var leftMissingArray: [Int] = []
// //    var appDelegate = UIApplication.shared.delegate as! AppDelegate

//     let activityIndicator = UIActivityIndicatorView( )
//        let loadingView = UIView() // View to dim the background
//        let loadingLabel = UILabel()

//     var identyUser: IdentyFramework.Identy_User?
//     func applicationDidReceiveMemoryWarning(application: UIApplication) {
//         URLCache.shared.removeAllCachedResponses()
//     }

//        override func viewWillAppear(_ animated: Bool) {
//         let appearance = UIBarButtonItem.appearance(whenContainedInInstancesOf: [UINavigationBar.self])
//         appearance.setTitleTextAttributes([NSAttributedString.Key.font : UIFont.systemFont(ofSize: 0.1), NSAttributedString.Key.foregroundColor : UIColor.clear], for: .normal)
//         self.leftHandCheckBox.isHidden = false
//         self.rightHandCheckBox.isHidden = false
//         self.leftThumbCheckBox.isHidden = true
//         self.rightThumbCheckBox.isHidden = true
// //        self.twoThumbCheckBox.isHidden = false
//         self.leftThumbCheckBox.setTitle("Left Thumb", for: .normal)
//         self.rightThumbCheckBox.setTitle("Right Thumb", for: .normal)
// //        self.hintLabel.isHidden = false
//         self.verify.isHidden = true
//         self.usernameTextField.isHidden = false
//         self.usernameTextField.placeholder = "Enter NIDA here"

//         super.viewWillAppear(false)
//     }


//     private func getLeftMissingFingerValues(leftString: String) -> [HandScanType] {
//         var array: [HandScanType] = []
//         let letfData = leftString.data(using: .utf8)
//         do{
//             let values = try JSONSerialization.jsonObject(with: letfData!, options: []) as? [Int]
//             for fingerValue in values! {
//                 let fingerType = HandScanType.init(rawValue: fingerValue)!
//                 self.leftMissingArray.append(fingerValue)
//                 array.append(fingerType)
//             }
//         }catch {
//         }
//         return array
//     }
//     private func getRightMissingFingerValues(rightString: String) -> [HandScanType] {
//         var array: [HandScanType] = []
//         let rightData = rightString.data(using: .utf8)
//         do{
//             let values = try JSONSerialization.jsonObject(with: rightData!, options: []) as? [Int]
//             for fingerValue in values! {
//                 let fingerType = HandScanType.init(rawValue: fingerValue)!
//                 self.rightMissingArray.append(fingerValue)
//                 array.append(fingerType)
//             }
//         }catch {
//         }
//         return array
//     }
//     private func missingFingerValidation(){
//         if self.leftMissingFingerCount > 0 && self.leftMissingFingerCount < 4 {
//             var fingers: [String] = []
//             for f in self.leftMissingArray {
//                 switch f {
//                 case 2:
//                     let fingerName = HandScanType.init(rawValue: 2)
//                     fingers.append(fingerName!.toString)
//                     break
//                 case 3:
//                     let fingerName = HandScanType.init(rawValue: 3)
//                     fingers.append(fingerName!.toString)
//                     break
//                 case 4:
//                     let fingerName = HandScanType.init(rawValue: 4)
//                     fingers.append(fingerName!.toString)
//                     break
//                 case 5:
//                     let fingerName = HandScanType.init(rawValue: 5)
//                     fingers.append(fingerName!.toString)
//                     break
//                 default:
//                     break
//                 }
//             }
//             self.leftHandCheckBox.setTitle("Left \(self.leftMissingFingerCount) Finger", for: .normal)
//             self.isLeftMissingFingerSelected = true
//         }else{
//             self.leftHandCheckBox.setTitle("Left Four Fingers", for: .normal)
//             self.isLeftMissingFingerSelected = false
//         }
//         if self.rightMissingFingerCount > 0 && self.rightMissingFingerCount < 4 {
//             var fingers: [String] = []
//             for f in self.rightMissingArray {
//                 switch f {
//                 case 7:
//                     let fingerName = HandScanType.init(rawValue: 7)
//                     fingers.append(fingerName!.toString)
//                     break
//                 case 8:
//                     let fingerName = HandScanType.init(rawValue: 8)
//                     fingers.append(fingerName!.toString)
//                     break
//                 case 9:
//                     let fingerName = HandScanType.init(rawValue: 9)
//                     fingers.append(fingerName!.toString)
//                     break
//                 case 10:
//                     let fingerName = HandScanType.init(rawValue: 10)
//                     fingers.append(fingerName!.toString)
//                     break
//                 default:
//                     break
//                 }
//             }
//             self.rightHandCheckBox.setTitle("Right \(self.rightMissingFingerCount) Finger", for: .normal)
//             self.isRightMissingFingerSelected = true
//         }else{
//             self.rightHandCheckBox.setTitle("Right Four Fingers", for: .normal)
//             self.isRightMissingFingerSelected = false
//         }
//     }

//     override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//         self.view.endEditing(true)
//     }
    

//     //MARK: Enroll
//     @IBAction func enroll(_ sender: Any) {
        
//         if self.leftHandCheckBox.isSelected &&  self.rightHandCheckBox.isSelected{
            
                

//             showDialog(title: "Error", message: "Select any one hand")
             
//         }
//         else if self.leftHandCheckBox.isSelected || self.rightHandCheckBox.isSelected
//         {
//             self.enrollFingerWithPath()

//         }
//     }
    
//     func saveStringToDocumentDirectory(_ string: String, withFileName fileName: String) {
//         // 1. Get the path to the document directory
//         guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
//             print("Document directory not found")
//             return
//         }

//         // 2. Create the file URL
//         let fileURL = documentDirectory.appendingPathComponent(fileName)

//         // 3. Convert the string to Data
//         guard let data = string.data(using: .utf8) else {
//             print("Failed to convert string to data")
//             return
//         }

//         // 4. Write the data to the file URL
//         do {
//             try data.write(to: fileURL)
//             print("File saved successfully at \(fileURL)")
//         } catch {
//             print("Failed to write file: \(error.localizedDescription)")
//         }
//     }
    
//     func enrollFingerWithPath(){
//         let instance = FingerSdk.setFingerUpInstance(handScanArray: handScanTypeArray, menuModelObj: menuModelObj)
//         self.validateAndAssignSelection()
        
//         instance.capture(viewcontrol: self, onResponse: { (response,transactionID, noOfAttempts) in
//             if let json = response?.toJson(){
                
         
                
//                 self.postApiCall(json: json)
                
//                 self.saveStringToDocumentDirectory(json, withFileName: "enroll_finger_6.1.0.json")
//             }
//             if let response = response?.responseDictionary{
//                 FingerSdk.parseResponse(from:response, isEnroll: true)
//             }
//         }, onErrorResponse: {(error,reponse,transid,noOfAttempts) in
//                 print(error)
//         }, onAttempt: {(attempts) in
//                          let attempts_array = attempts
//                          guard attempts_array != nil else{
//                              return
//                          }
//                          for attempt in attempts_array! {
//                              print("As level",attempt.getAsHighestSecurityLevelReached())
//                          }})
        
        
        
//   //      instance.enroll(viewcontrol: self, user: self.identyUser, onResponse: { (response,transactionID, noOfAttempts) in
//     //        if let json = response?.toJson(){
//       //          self.saveStringToDocumentDirectory(json, withFileName: "enroll_finger_6.1.0.json")
//         //    }
//           //  if let response = response?.responseDictionary{
//             //    FingerSdk.parseResponse(from:response, isEnroll: true)
//             //}
//        // }, onErrorResponse: { (error,response,transactionID, noOfAttempts) in
//        //         print(error)
//         //}) { (attempts) in
//          //   let attempts_array = attempts
//           //  guard attempts_array != nil else{
//            //     return
//             //}
//            // for attempt in attempts_array! {
//            //     print("As level",attempt.getAsHighestSecurityLevelReached())
//            // }
//        /// }
        
//     }
    
//     //MARK: Verify
//     @IBAction func verify(_ sender: Any) {
//         self.veriyFingerWithPath()
//     }
//     func veriyFingerWithPath(){
//         self.validateAndAssignSelection()
//         let instance = FingerSdk.setFingerUpInstance(handScanArray: handScanTypeArray, menuModelObj: self.menuModelObj)
//         instance.verify(viewcontrol: self, user: identyUser, onResponse: { (response,transactionID, noOfAttempts) in

//             if let json = response?.toJson(){
//                 self.saveStringToDocumentDirectory(json, withFileName: "verify_finger_6.1.0.json")
//             }
            
//             if let response = response?.responseDictionary{
//                 FingerSdk.parseResponse(from:response, isEnroll: false)
                
//             }
            
//         }, onErrorResponse: { (error,response,transactionID, noOfAttempts) in
            
            
//         }) { (attempts) in
//             let attempts_array = attempts
//             guard attempts_array != nil else{
//                 return
//             }
//             for attempt in attempts_array! {
//                 print("As level",attempt.getAsHighestSecurityLevelReached())
//             }
//         }
        
//     }
    
//     //MARK:- Methods
//     func setAttributedText(labelString: String) -> NSMutableAttributedString {
//         let attString = NSMutableAttributedString.init(string: labelString)
//         let rangeOfString: NSRange = (labelString as NSString).range(of: labelString)
//         attString.addAttribute(NSAttributedString.Key.underlineStyle, value: NSUnderlineStyle.single.rawValue , range: rangeOfString)
//         return attString
//     }
//     func validateAndAssignSelection(){
//         self.handScanTypeArray.removeAll()
//         if self.leftHandCheckBox.isSelected {
//             if self.isLeftMissingFingerSelected {
//                 _ = self.leftMissingArray.map { (fingerValue) in
//                     let fingerType = HandScanType.init(rawValue: fingerValue)!
//                     self.handScanTypeArray.append(fingerType)
//                 }
//             }else{
//                 self.handScanTypeArray.append(.l4f)
//             }
//         }
//         if self.rightHandCheckBox.isSelected {
//             if self.isRightMissingFingerSelected {
//                 _ = self.rightMissingArray.map { (fingerValue) in
//                     let fingerType = HandScanType.init(rawValue: fingerValue)!
//                     self.handScanTypeArray.append(fingerType)
//                 }
//             }else{
//                 self.handScanTypeArray.append(.r4f)
//             }
//         }
//         if self.leftThumbCheckBox.isSelected {
//             self.handScanTypeArray.append(.leftThumb)
//         }
//         if self.rightThumbCheckBox.isSelected {
//             self.handScanTypeArray.append(.rightThumb)
//         }
//         //            if self.twoThumbCheckBox.isSelected {
//         //                self.handScanTypeArray.append(.twoThumb)
//         //            }
//     }
    
    
//     /////////////////changed
    
  

//     func showLoader() {
//            DispatchQueue.main.async {
//                self.loadingView.isHidden = false
//                self.activityIndicator.startAnimating()
//            }
//        }

//        // Function to hide the loader
//        func hideLoader() {
//            DispatchQueue.main.async {
//                self.activityIndicator.stopAnimating()
//                self.loadingView.isHidden = true
//            }
//        }
    
//     // Function to show success or failure dialogs
//      func showDialog(title: String, message: String) {
//          DispatchQueue.main.async {
//              let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
//              alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
//              self.present(alertController, animated: true, completion: nil)
//          }
//      }

//     func parseMessage(from data: Data) -> String? {
//            do {
//                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
//                   let message = json["message"] as? String {
//                    return message
//                }
//            } catch {
//                print("Failed to parse response data: \(error)")
//            }
//            return nil
//        }
    
//      // Function to make the POST API call
//     func postApiCall(json:String) {
//          // Start showing the loader
//          showLoader()
         
//          // The API endpoint URL
//          guard let url = URL(string: "https://staging.ara.co.tz/api/v1/fingerScan") else {
//              print("Invalid URL")
//              hideLoader()
//              showDialog(title: "Error", message: "Invalid URL")
//              return
//          }

//          // Create the request
//          var request = URLRequest(url: url)
//          request.httpMethod = "POST"
//          request.setValue("application/json", forHTTPHeaderField: "Content-Type")

//          // Create the JSON body
// //         let json1:[String:Any] = [
// //                "document_id": "6",
// //              "user_id": "2981",
// //              "device_token": "dnrVAYgnRmyDV6kfeEOYpH:APA91bFfShbI0mTG0IxhBuKCecjsOAj2uW9FKu-WrfSVfTmyYV74r25qJw7bsIaG7EGGGPYbiqY6PrhF10LcrV4URbJv2TzLMP0t4q1WYIdBY58jbJ4nFeHxoBqZbTgP4L9ztn7IueDp",
// //              "device_type": "Android",
// //              "language_code": "en",
// //              "lat": "37.4219983",
// //              "lng": "-122.084",
// //              "int_udid": "UE1A.230829.036.A1",
// //              "device_brand": "google",
// //              "device_name": "emu64xa",
// //              "app_version": "3.0.5 (156)"
// //            ]
        
//         let fingerData = generateFingerResponse(rawResponse: json)
// //        let test = String(fingerData.filter { !" \n\t\r".contains($0) })
//         let  nida = usernameTextField.text
// //        let data = test.replacingOccurrences(of: "\n", with: "")
// //        debugPrint("finger data: "+data);
//         let jsonDict: [String: Any] = [
//             "data": [
//                 "finger1": [
//                     "hand": "left",
//                     "finger": "little",
//                     "WSQ": "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"
//                 ]
//             ],
//             "hand_type": "left"
//         ]
        
//         if let jsonData = try? JSONSerialization.data(withJSONObject: fingerData, options: .prettyPrinted),
//            let jsonString = String(data: jsonData, encoding: .utf8) {
//             print(jsonString)
            
            
            
//             let json2 = RequestBody(document_id: "6", nida_number: nida!, user_id: "2981", device_token: "dnrVAYgnRmyDV6kfeEOYpH:APA91bFfShbI0mTG0IxhBuKCecjsOAj2uW9FKu-WrfSVfTmyYV74r25qJw7bsIaG7EGGGPYbiqY6PrhF10LcrV4URbJv2TzLMP0t4q1WYIdBY58jbJ4nFeHxoBqZbTgP4L9ztn7IueDp", device_type: "iOS", language_code: "en", lat: "37.4219983", lng: "-122.084", int_udid: "UE1A.230829.036.A1", device_brand: "apple", device_name: "iphone", app_version: "3.0.5 (156)",  finger_data: jsonString)
            
//              // Convert the request body to JSON data
//              do {
                 
//                  let jsonData = try JSONEncoder().encode(json2)
                 
//                  request.httpBody = jsonData
//                  request.timeoutInterval = 300
//              } catch {
//                  print("Failed to encode request body: \(error)")
//                  hideLoader()
//                  showDialog(title: "Error", message: "Failed to encode request body")
//                  return
//              }

//              // Create the URLSession task
//              let task = URLSession.shared.dataTask(with: request) { data, response, error in
//                  // Hide the loader
//                  self.hideLoader()

//                  // Check for any errors
//                  if let error = error {
//                      print("Error making POST request: \(error)")
//                      self.showDialog(title: "Failure", message: "\(error.localizedDescription)")
//                      return
//                  }

//                  // Check the response status code
//                  if let httpResponse = response as? HTTPURLResponse {
//                                 print("Response status code: \(httpResponse.statusCode)")
//                                 if let data = data {
//                                     if let message = self.parseMessage(from: data) {
//                                         if (200...299).contains(httpResponse.statusCode) {
//                                             // Success
//                                             self.showDialog(title: "From server  ", message: message)
//                                         } else {
//                                             // Failure
//                                             self.showDialog(title: "Failure", message: message)
//                                         }
//                                     } else {
//                                         self.showDialog(title: "Error", message: "No message in response")
//                                     }
//                                 }
//                             }

//                  // Check if data was returned
//                  if let data = data {
//                      do {
//                          // Try to decode the response (if it's JSON)
//                          let jsonResponse = try JSONSerialization.jsonObject(with: data, options: [])
//                          print("Response JSON: \(jsonResponse)")
//                      } catch {
//                          print("Failed to parse response data: \(error)")
//                          self.showDialog(title: "Error", message: "Failed to parse response data")
//                      }
//                  }
//              }

//              // Start the task
//              task.resume()
//         }

        
// //        let testing = JSONEncoder.encode(data)
      
//      }
    
    

//     func generateFingerResponse(rawResponse:String) -> [String: Any]  {
//         let jsonDict: [String: Any] = [
//             "data": [
//                 "finger1": [
//                     "hand": "left",
//                     "finger": "little",
//                     "WSQ": "your wsq data"
//                 ]
//             ],
//             "hand_type": "left"
//         ]
//         var formattedJSON = [String: Any]()
//         var fingersDataJson = [String: Any]()
//         var hand = "";
//         if self.leftHandCheckBox.isSelected {
//              hand = "left"
//         }
//         else
//         {
//             hand = "right"
//         }
        
//         if let jsonFingers = try? JSONSerialization.jsonObject(with: Data(rawResponse.utf8), options: []) as? [String: Any],
//            let data = jsonFingers["data"] as? [String: Any] {
            
//             if hand == "left" {
//                 if let leftIndexData = data["leftindex"] as? [String: Any] {
//                     var leftIndexJson = [String: Any]()
//                     leftIndexJson["hand"] = hand
//                     leftIndexJson["finger"] = "index"
                    
//                     // Access the list of WSQ dictionaries and get the first one
//                     if let wsqArray = (leftIndexData["templates"] as? [String: Any])?["WSQ"] as? [[String: Any]],
//                        let firstWSQ = wsqArray.first {
//                         // Extract the "DEFAULT" value from the first WSQ dictionary
//                         leftIndexJson["WSQ"] = firstWSQ["DEFAULT"] as? String
//                     }
                    
//                     // Add the constructed leftIndexJson to the fingersDataJson
//                     fingersDataJson["finger1"] = leftIndexJson
//                 }

// //
// //                if let leftIndexData = data["leftindex"] as? [String: Any] {
// //                    var leftIndexJson = [String: Any]()
// //                    leftIndexJson["hand"] = hand
// //                    leftIndexJson["finger"] = "index"
// //                    
// //                    if let wsq = (leftIndexData["templates"] as? [String: Any])?["WSQ"] as? [String: String] {
// //                        leftIndexJson["WSQ"] = wsq["DEFAULT"]
// //                    }
// //                    fingersDataJson["finger1"] = leftIndexJson
// //                }
//                 if let leftMiddleData = data["leftmiddle"] as? [String: Any] {
//                     var leftMiddleJson = [String: Any]()
//                     leftMiddleJson["hand"] = hand
//                     leftMiddleJson["finger"] = "middle"
// //                    if let wsq = (leftMiddleData["templates"] as? [String: Any])?["WSQ"] as? [String: String] {
// //                        leftMiddleJson["WSQ"] = wsq["DEFAULT"]
// //                    }
//                     // Access the list of WSQ dictionaries and get the first one
//                     if let wsqArray = (leftMiddleData["templates"] as? [String: Any])?["WSQ"] as? [[String: Any]],
//                        let firstWSQ = wsqArray.first {
//                         // Extract the "DEFAULT" value from the first WSQ dictionary
//                         leftMiddleJson["WSQ"] = firstWSQ["DEFAULT"] as? String
//                     }
//                     fingersDataJson["finger2"] = leftMiddleJson
//                 }
//                 if let leftRingData = data["leftring"] as? [String: Any] {
//                     var leftRingJson = [String: Any]()
//                     leftRingJson["hand"] = hand
//                     leftRingJson["finger"] = "ring"
// //                    if let wsq = (leftRingData["templates"] as? [String: Any])?["WSQ"] as? [String: String] {
// //                        leftRingJson["WSQ"] = wsq["DEFAULT"]
// //                    }
//                     if let wsqArray = (leftRingData["templates"] as? [String: Any])?["WSQ"] as? [[String: Any]],
//                        let firstWSQ = wsqArray.first {
//                         // Extract the "DEFAULT" value from the first WSQ dictionary
//                         leftRingJson["WSQ"] = firstWSQ["DEFAULT"] as? String
//                     }
//                     fingersDataJson["finger3"] = leftRingJson
//                 }
                
//                 if let leftLittleData = data["leftlittle"] as? [String: Any] {
//                     var leftLittleJson = [String: Any]()
//                     leftLittleJson["hand"] = hand
//                     leftLittleJson["finger"] = "little"
// //                    if let wsq = (leftLittleData["templates"] as? [String: Any])?["WSQ"] as? [String: String] {
// //                        leftLittleJson["WSQ"] = wsq["DEFAULT"]
// //                    }
//                     if let wsqArray = (leftLittleData["templates"] as? [String: Any])?["WSQ"] as? [[String: Any]],
//                        let firstWSQ = wsqArray.first {
//                         // Extract the "DEFAULT" value from the first WSQ dictionary
//                         leftLittleJson["WSQ"] = firstWSQ["DEFAULT"] as? String
//                     }
//                     fingersDataJson["finger4"] = leftLittleJson
//                 }
//             } else if hand == "right" {
//                 if let rightIndexData = data["rightindex"] as? [String: Any] {
//                     var rightIndexJson = [String: Any]()
//                     rightIndexJson["hand"] = hand
//                     rightIndexJson["finger"] = "index"
// //                    if let wsq = (rightIndexData["templates"] as? [String: Any])?["WSQ"] as? [String: String] {
// //                        rightIndexJson["WSQ"] = wsq["DEFAULT"]
// //                    }
//                     if let wsqArray = (rightIndexData["templates"] as? [String: Any])?["WSQ"] as? [[String: Any]],
//                        let firstWSQ = wsqArray.first {
//                         // Extract the "DEFAULT" value from the first WSQ dictionary
//                         rightIndexJson["WSQ"] = firstWSQ["DEFAULT"] as? String
//                     }
//                     fingersDataJson["finger1"] = rightIndexJson
//                 }
//                 if let rightMiddleData = data["rightmiddle"] as? [String: Any] {
//                     var rightMiddleJson = [String: Any]()
//                     rightMiddleJson["hand"] = hand
//                     rightMiddleJson["finger"] = "middle"
// //                    if let wsq = (rightMiddleData["templates"] as? [String: Any])?["WSQ"] as? [String: String] {
// //                        rightMiddleJson["WSQ"] = wsq["DEFAULT"]
// //                    }
//                     if let wsqArray = (rightMiddleData["templates"] as? [String: Any])?["WSQ"] as? [[String: Any]],
//                        let firstWSQ = wsqArray.first {
//                         // Extract the "DEFAULT" value from the first WSQ dictionary
//                         rightMiddleJson["WSQ"] = firstWSQ["DEFAULT"] as? String
//                     }
//                     fingersDataJson["finger2"] = rightMiddleJson
//                 }
//                 if let rightRingData = data["rightring"] as? [String: Any] {
//                     var rightRingJson = [String: Any]()
//                     rightRingJson["hand"] = hand
//                     rightRingJson["finger"] = "ring"
// //                    if let wsq = (rightRingData["templates"] as? [String: Any])?["WSQ"] as? [String: String] {
// //                        rightRingJson["WSQ"] = wsq["DEFAULT"]
// //                    }
//                     if let wsqArray = (rightRingData["templates"] as? [String: Any])?["WSQ"] as? [[String: Any]],
//                        let firstWSQ = wsqArray.first {
//                         // Extract the "DEFAULT" value from the first WSQ dictionary
//                         rightRingJson["WSQ"] = firstWSQ["DEFAULT"] as? String
//                     }
//                     fingersDataJson["finger3"] = rightRingJson
//                 }
//                 if let rightLittleData = data["rightlittle"] as? [String: Any] {
//                     var rightLittleJson = [String: Any]()
//                     rightLittleJson["hand"] = hand
//                     rightLittleJson["finger"] = "little"
// //                    if let wsq = (rightLittleData["templates"] as? [String: Any])?["WSQ"] as? [String: String] {
// //                        rightLittleJson["WSQ"] = wsq["DEFAULT"]
// //                    }
//                     if let wsqArray = (rightLittleData["templates"] as? [String: Any])?["WSQ"] as? [[String: Any]],
//                        let firstWSQ = wsqArray.first {
//                         // Extract the "DEFAULT" value from the first WSQ dictionary
//                         rightLittleJson["WSQ"] = firstWSQ["DEFAULT"] as? String
//                     }
//                     fingersDataJson["finger4"] = rightLittleJson
//                 }
//             }
//             formattedJSON["data"] = fingersDataJson
//             formattedJSON["hand_type"] = hand
        
//             return formattedJSON
// //            if let jsonData = try? JSONSerialization.data(withJSONObject: formattedJSON, options: .prettyPrinted),
// //               let jsonString = String(data: jsonData, encoding: .utf8) {
// //              let  jsonString2 = jsonString.replacingOccurrences(of: "\n", with: "")
// //              let  jsonString3 = jsonString.replacingOccurrences(of: " ", with: "")
// //                return jsonString3
// //            }
//         }
        
//         return jsonDict
//     }

    
    
    
    
//     ///////////////
    
    
    
//     // UITextFieldDelegate method to restrict invalid characters (allow only alphanumeric)
//         func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
//             // Allow only alphanumeric characters and dashes
//             let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-"))
//             let characterSet = CharacterSet(charactersIn: string)
            
//             // Prevent pasting beyond max length
//             let maxLength = 23 // Length for XXXXXXXX-XXXXX-XXXXX-XX format
//             let currentString = (textField.text ?? "") as NSString
//             let newString = currentString.replacingCharacters(in: range, with: string)
            
//             return allowedCharacters.isSuperset(of: characterSet) && newString.count <= maxLength
//         }
        
//         // Action to format text as the user types
//         @objc func textFieldEditingChanged(_ textField: UITextField) {
//             guard let currentText = textField.text else { return }
//             textField.text = applyFormatting(to: currentText)
//         }
        
//         // Function to apply the custom format XXXXXXXX-XXXXX-XXXXX-XX
//         func applyFormatting(to string: String) -> String {
//             // Remove any dashes before formatting
//             let rawString = string.replacingOccurrences(of: "-", with: "")
            
//             var formattedString = ""
//             let mask = "XXXXXXXX-XXXXX-XXXXX-XX"
//             var index = rawString.startIndex
            
//             for ch in mask {
//                 if index == rawString.endIndex {
//                     break
//                 }
//                 if ch == "-" {
//                     formattedString.append("-")
//                 } else {
//                     formattedString.append(rawString[index])
//                     index = rawString.index(after: index)
//                 }
//             }
            
//             return formattedString
//         }
    
   
// }
// struct RequestBody: Codable {
  
//     let document_id: String
//     let nida_number: String
//     let user_id: String
//     let device_token: String
//     let device_type: String
//     let language_code: String
//     let lat: String
//     let lng: String
//     let int_udid: String
//     let device_brand: String
//     let device_name: String
//     let app_version: String
//     let finger_data: String
    
   
// }

// extension InitialViewController: GetSelectedFingerDelegate {
//     func getSelectedFinger(fingerArray: [HandScanType]) {
//         self.leftMissingArray.removeAll()
//         self.rightMissingArray.removeAll()
//         self.leftMissingFingerCount = 0
//         self.rightMissingFingerCount = 0
//         for fingerType in fingerArray {
//             switch fingerType {
//             case .leftIndex:
//                 self.leftMissingFingerCount += 1
//                 self.leftMissingArray.append(HandScanType.leftIndex.rawValue)
//                 break
//             case .leftMiddle:
//                 self.leftMissingFingerCount += 1
//                 self.leftMissingArray.append(HandScanType.leftMiddle.rawValue)
//                 break
//             case .leftRing:
//                 self.leftMissingFingerCount += 1
//                 self.leftMissingArray.append(HandScanType.leftRing.rawValue)
//                 break
//             case .leftLittle:
//                 self.leftMissingFingerCount += 1
//                 self.leftMissingArray.append(HandScanType.leftLittle.rawValue)
//                 break
//             case .rightIndex:
//                 self.rightMissingFingerCount += 1
//                 self.rightMissingArray.append(HandScanType.rightIndex.rawValue)
//                 break
//             case .rightMiddle:
//                 self.rightMissingFingerCount += 1
//                 self.rightMissingArray.append(HandScanType.rightMiddle.rawValue)
//                 break
//             case .rightRing:
//                 self.rightMissingFingerCount += 1
//                 self.rightMissingArray.append(HandScanType.rightRing.rawValue)
//                 break
//             case .rightLittle:
//                 self.rightMissingFingerCount += 1
//                 self.rightMissingArray.append(HandScanType.rightLittle.rawValue)
//                 break
//             default:
//                 break
//             }
//         }
//         UserDefaults.standard.set(self.leftMissingArray.description, forKey: "LeftMissingArray")
//         UserDefaults.standard.set(self.rightMissingArray.description, forKey: "RightMissingArray")
//         self.missingFingerValidation()
//         self.leftHandCheckBox.isSelected = false
//         self.rightHandCheckBox.isSelected = false
//     }
// }

