// //
// //  ConfigureIdenty.swift
// //  Runner
// //
// //  Created by Fintosa Mac on 08/10/24.
// //

// import Foundation
// import Identy

// class ConfigureIdentyViewController:  UIViewController {
    
//     var handScanTypeArray: [HandScanType] = []
//     var menuModelObj = MenuModel()

    
//     var leftHandCheckBox: Bool! = false
//     var rightHandCheckBox: Bool! = false
//     var rightMissingArray: [Int] = []
//     var leftMissingArray: [Int] = []
//     var isLeftMissingFingerSelected: Bool! = false
//     var isRightMissingFingerSelected: Bool! = false
    
//     func enrollFingerWithPath(){
//         self.menuModelObj.needPng = false
//         self.menuModelObj.isWSQSelected = true
//         self.menuModelObj.isTorch = false
//         let instance = FingerSdk.setFingerUpInstance(handScanArray: handScanTypeArray, menuModelObj: menuModelObj)
//         self.validateAndAssignSelection()
        
//         instance.capture(viewcontrol: self, onResponse: { (response,transactionID, noOfAttempts) in
            
//             debugPrint(response)
//             self.dismiss(animated: true, completion: nil)

// //            if let json = response?.toJson(){

// //                self.postApiCall(json: json)
// //                
// //                self.saveStringToDocumentDirectory(json, withFileName: "enroll_finger_6.1.0.json")
// //            }
// //            if let response = response?.responseDictionary{
// //                FingerSdk.parseResponse(from:response, isEnroll: true)
            
// //            }
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
//     }
    
    
    
//     func validateAndAssignSelection(){
//         self.handScanTypeArray.removeAll()
//         if self.leftHandCheckBox {
//             if self.isLeftMissingFingerSelected {
//                 _ = self.leftMissingArray.map { (fingerValue) in
//                     let fingerType = HandScanType.init(rawValue: fingerValue)!
//                     self.handScanTypeArray.append(fingerType)
//                     self.handScanTypeArray.append(fingerType)
//                 }
//             }else{
//                 self.handScanTypeArray.append(.l4f)
//             }
//         }
//         if self.rightHandCheckBox {
//             if self.isRightMissingFingerSelected {
//                 _ = self.rightMissingArray.map { (fingerValue) in
//                     let fingerType = HandScanType.init(rawValue: fingerValue)!
//                     self.handScanTypeArray.append(fingerType)
//                 }
//             }else{
//                 self.handScanTypeArray.append(.r4f)
//             }
//         }
//     }
// }

