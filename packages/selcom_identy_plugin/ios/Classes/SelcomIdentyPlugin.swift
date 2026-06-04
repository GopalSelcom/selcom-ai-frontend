import Flutter
import UIKit
import Identy

public class SelcomIdentyPlugin: NSObject, FlutterPlugin {
    
    var handScanTypeArray: [HandScanType] = []
    var menuModelObj = MenuModel()
    var leftHandCheckBox: Bool! = false
    var rightHandCheckBox: Bool! = true
    var rightMissingArray: [Int] = []
    var leftMissingArray: [Int] = []
    var isLeftMissingFingerSelected: Bool! = false
    var isRightMissingFingerSelected: Bool! = false
    var licenseFile: String! = ""
    var languageCode: String! = ""
    
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "selcom_identy_plugin", binaryMessenger: registrar.messenger())
        let instance = SelcomIdentyPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "enrollFinger":
            if let args = call.arguments as? [String: Any] {
                // Debug: Print the entire arguments dictionary
                print("Received arguments: \(args)")
                
                // Safely cast the arguments to the expected types
                let isleftHandSelected = args["leftHandSelected"] as? Bool ?? false
                let isrightHandSelected = args["rightHandSelected"] as? Bool ?? false
                let isLeftMissingFingerSelected = args["isLeftMissingFingerSelected"] as? Bool ?? false
                let isRightMissingFingerSelected = args["isRightMissingFingerSelected"] as? Bool ?? false
                let leftHandMissingArray = args["leftHandMissingArray"] as? [Int] ?? []
                let rightHandMissingArray = args["rightHandMissingArray"] as? [Int] ?? []
                let licFile = args["licenseFile"] as? String ?? ""
                let langCode = args["languageCode"] as? String ?? "en"
                self.leftHandCheckBox = isleftHandSelected
                self.rightHandCheckBox = isrightHandSelected
                self.isLeftMissingFingerSelected = isLeftMissingFingerSelected
                self.isRightMissingFingerSelected = isRightMissingFingerSelected
                self.leftMissingArray = leftHandMissingArray
                self.rightMissingArray = rightHandMissingArray
                self.licenseFile = licFile
                self.languageCode = langCode
                print("leftHandCheckBox 2: \(self.leftHandCheckBox ?? false)")
                print("rightHandCheckBox 2: \(self.rightHandCheckBox ?? false)")
                print("Left Missing Finger Selected: \( self.isLeftMissingFingerSelected ?? false)")
                print("Right Missing Finger Selected: \(self.isRightMissingFingerSelected ?? false)")
                print("leftMissingArray: \(self.leftMissingArray)")
                print("rightMissingArray: \(self.rightMissingArray)")
                print("licenseFile: \(self.licenseFile)")
                
                // Call your method with the values
                self.enrollFingerWithPath(result: result)
            } else {
                // Debug: If arguments are nil or invalid, print an error message
                print("Invalid arguments received: \(call.arguments ?? "nil")")
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid arguments", details: nil))
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func enrollFingerWithPath(result: @escaping FlutterResult) {
        
        //  Call the validation function before capturing the finger
        self.validateAndAssignSelection()
        
        print("handScanArray: \(handScanTypeArray)")
        print("menuModelObj: \(menuModelObj)")
        
        let instance = FingerSdk.setFingerUpInstance(handScanArray: handScanTypeArray, menuModelObj: menuModelObj,licenseFile:self.licenseFile, languageCode:self.languageCode)
        
        // Get the top view controller
        guard let viewController = self.topViewController() else {
            result(FlutterError(code: "UNAVAILABLE", message: "No view controller available", details: nil))
            return
        }
        instance.capture(viewcontrol: viewController, onResponse: { (response, transactionID, noOfAttempts) in
            var temp =  response?.toJson()
            result(temp)
            
        }, onErrorResponse: { (error, response, transid, noOfAttempts) in
            if(noOfAttempts == 5){
                result("500")
            }
            if  error == IdentyError.ACTIVITY_PAUSED_ON_BACK_PRESSED {
                print("error found on back pressed")
                result("")
            }else if error == IdentyError.TRANSACTION_TIMEOUT {
                 if self.languageCode == "en" {
                    result("IDENTY_ERROR : Scanning timed out. Please try again.")
                }else{
                    result("IDENTY_ERROR : Uchakataji wa skani umeisha muda. Tafadhali jaribu tena.")
                }
            }else{
                print("IDENTY_ERROR : \(error)")
                //                result("IDENTY_ERROR : \(error)")
            }
            //  else{
            //      result(FlutterError(code: "ERROR", message: "Enrollment failed", details: error))
            //  }
            //  print(error)
            //  result(FlutterError(code: "ERROR", message: "Enrollment failed", details: error))
            
        }, onAttempt: { (attempts) in
            guard let attempts_array = attempts else {
                return
            }
            for attempt in attempts_array {
                print("As level", attempt.getAsHighestSecurityLevelReached())
            }
        })
    }
    
    private func validateAndAssignSelection() {
        self.handScanTypeArray.removeAll()
        if self.leftHandCheckBox {
            if self.isLeftMissingFingerSelected {
                _ = self.leftMissingArray.map { (fingerValue) in
                    let fingerType = HandScanType.init(rawValue: fingerValue)!
                    self.handScanTypeArray.append(fingerType)
                }
            }else{
                self.handScanTypeArray.append(.l4f)
            }
        }
        if self.rightHandCheckBox {
            if self.isRightMissingFingerSelected {
                _ = self.rightMissingArray.map { (fingerValue) in
                    let fingerType = HandScanType.init(rawValue: fingerValue)!
                    self.handScanTypeArray.append(fingerType)
                }
            }else{
                self.handScanTypeArray.append(.r4f)
            }
        }
    }
    
    private func topViewController() -> UIViewController? {
        var topVC = UIApplication.shared.windows.first?.rootViewController
        
        while let presentedVC = topVC?.presentedViewController {
            topVC = presentedVC
        }
        
        return topVC
    }
}
