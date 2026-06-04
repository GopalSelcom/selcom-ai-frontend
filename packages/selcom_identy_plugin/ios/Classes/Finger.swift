//
//  Finger.swift
//  IdentyProject
//
//  Created by Jijosh B on 11/06/24.
//  Copyright © 2024 Identy. All rights reserved.
//

import Foundation
import Identy
import UIKit
import CryptoSwift

class FingerSdk{
    
    static func setFingerUpInstance(handScanArray:[HandScanType],menuModelObj:MenuModel, licenseFile:String, languageCode:String) ->IdentyFramework{
        let instance = IdentyFramework.init(with: Bundle.main.path(forResource: licenseFile, ofType: "lic")!, localizablePath: Bundle.main.path(forResource: languageCode, ofType: "lproj"), table: "Main")

        instance.setDetectionMode(detections: handScanArray)
        instance.setWSQCompression(compression: menuModelObj.selectedCompression)
        if UserDefaults.standard.bool(forKey: Keys.isNeedShowTraining){
            instance.enableTraining()
        }else{
            instance.disableTraining()
        }
        if menuModelObj.selectedAppMode == .demo{
            instance.enableDemoMode()
        }
        //        instance.enableGImage(format: .PNG)
        //        instance.enablesd(gyro: true, accel: true, duration: 500)
        instance.setAsSecMode(.HIGH)
        instance.setMatchSecLevel(mode: .HIGH)
        instance.setDisplayResult(displayResult: false)
        if !UserDefaults.standard.bool(forKey: Keys.isShowGuide){
            instance.disableGuide()
        }
        instance.isTorch = UserDefaults.standard.bool(forKey: "false")
        //        instance.disableMoveNextDetectionDialog()
        instance.setOutputSize(width: 512, height: 512)
        
        //        instance.setBoxImage = UIImage.init(named:  "finger_print.png")!
        //        instance.introScreenStartColor = UIColor.blue
        //        instance.introScreenMiddleColor = UIColor.red
        //        instance.introScreenEndColor = UIColor.green
        //        instance.scanningBarColor = .white
        //        instance.setBase64EncodingFlag(val: base64encoding.NO_WRAP.base64Value)
        //        let path = Bundle.main.path(forResource: "thumb_animation", ofType: "gif")!
        //        let gif4FData = try! Data(contentsOf: URL(fileURLWithPath: path))
        //        instance.gif4FData = gif4FData
        //        instance.gifThumbData = gif4FData
        //        instance.middleColor = .yellow
        //        instance.endColor = .red
        //        instance.plainSolidColor = UIColor(argb: 0xffFEE5EC)
        //        instance.boxesColor = UIColor(argb: 0x80FFFFFF)
        //        instance.startColor = .green
        //        instance.boxes_transparent = .red
        //        instance.headerTextColor = .black
        //        instance.boxes_transparent = UIColor(argb: 0xffFEE5EC)
        //        instance.boxes_transparent_innerborder = UIColor(argb: 0xffFFFFFF)
        
        instance.plainSolidColor = UIColor(argb: 0xffE3F3E4)
        instance.boxesColor = UIColor(argb: 0xff5CB75E)
        instance.startColor = .green
        instance.boxes_transparent = .red
        instance.headerTextColor = .black
        instance.boxes_transparent = UIColor(argb: 0xffE3F3E4)
        instance.boxes_transparent_innerborder = UIColor(argb: 0xff5CB75E)
        instance.backImage = UIImage(named: "left-arrow.png")
        instance.setHandIcons(leftHandIcon: nil, rightHandIcon: nil,showIcons: false)
        instance.setUiOption(option: menuModelObj.selectedAppUI)
        //        instance.disableDisplayBackButtonAlert()
        instance.setTransactionUiType(uitype: .ALERT)
        instance.disableDisplayTransactionAlerts()
        
        // header and footer customization
        let customUI = IdentyFingerCustomUI()
        customUI.addHeaderView = { (headerView, viewController) in
            
            // Custom back button
            let BackButton = UIButton(type: .system)
            BackButton.setImage(UIImage(systemName: "chevron.left")!.withRenderingMode(.alwaysOriginal).withTintColor(.black), for: .normal)
            BackButton.tag = 1050
            BackButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
            
            let buttonWidth: CGFloat = 30
            let buttonHeight: CGFloat = 30
            BackButton.frame = CGRect(
                x: 0,
                y: (headerView.frame.height - buttonHeight) / 2,
                width: buttonWidth,
                height: buttonHeight
            )
            headerView.addSubview(BackButton)
            
            // Fetching multiple localized strings
            let customBundle = Bundle(path: Bundle.main.path(forResource: languageCode, ofType: "lproj")!)
            let footerText1 = NSLocalizedString("selcom_how_to_scan", tableName: "Main", bundle: customBundle!, value: "", comment: "First line of footer text")
            let footerText2 = NSLocalizedString("selcom_how_to_scan_one", tableName: "Main", bundle: customBundle!, value: "", comment: "Second line of footer text")
            let footerText3 = NSLocalizedString("selcom_how_to_scan_two", tableName: "Main", bundle: customBundle!, value: "", comment: "Third line of footer text")
            
            // Screen dimensions
            let screenWidth = viewController.view.frame.width
            let screenHeight = viewController.view.frame.height
            let bottomPadding: CGFloat = 40
            
            // First line: Center-aligned with dynamic height
            let footerLabel1 = UILabel()
            footerLabel1.text = footerText1
            footerLabel1.textColor = .black
            footerLabel1.font = UIFont.systemFont(ofSize: 16, weight: .bold)
            footerLabel1.textAlignment = .center
            footerLabel1.numberOfLines = 0 // Allow multiline text
            
            // Calculate dynamic size
            let label1Width = screenWidth - 32
            let label1Size = footerLabel1.sizeThatFits(CGSize(width: label1Width, height: CGFloat.greatestFiniteMagnitude))
            footerLabel1.frame = CGRect(
                x: 16,
                y: screenHeight - label1Size.height - 100 - bottomPadding,
                width: label1Width,
                height: label1Size.height
            )
            viewController.view.addSubview(footerLabel1)
            
            // First, create a paragraph style to adjust line height
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 8 // Set the line spacing to whatever value you prefer
            
            // Remaining lines: Left-aligned with dynamic height
            let footerLabel2 = UILabel()
            footerLabel2.text = "\(footerText2)\n\(footerText3)"
            footerLabel2.textColor = .black
            footerLabel2.font = UIFont.systemFont(ofSize: 14, weight: .regular)
            footerLabel2.textAlignment = .left
            footerLabel2.numberOfLines = 0 // Allow multiline text
            
            // Apply the paragraph style to the label text
            let attributes: [NSAttributedString.Key: Any] = [
                .paragraphStyle: paragraphStyle
            ]
            let attributedText = NSAttributedString(string: footerLabel2.text ?? "", attributes: attributes)
            footerLabel2.attributedText = attributedText
            
            // Calculate dynamic size
            let label2Width = screenWidth - 32
            let label2Size = footerLabel2.sizeThatFits(CGSize(width: label2Width, height: CGFloat.greatestFiniteMagnitude))
            footerLabel2.frame = CGRect(
                x: 16,
                y: footerLabel1.frame.maxY + 10, // Position below footerLabel1 with some padding
                width: label2Width,
                height: label2Size.height
            )
            viewController.view.addSubview(footerLabel2)
            
            
        }
        instance.setCustomUI(customUI)
        
        // MARK: - Check CustomViewController.swift for Customisation
        // MARK: - CustomSpoofScreen (v6.3.0 NEW)
        instance.isCustomSpoofScreen = true
        let svc  = CustomSpoofViewController(languageCode: languageCode) // Pass language code
        svc.retakeResult = {
            guard let openCam = instance.retakeAction else { return }
            openCam()
        }
        instance.customSpoofViewController = svc
        
        // MARK: - CustomQualityScreen (v6.3.0 NEW)
        instance.isCustomQualityScreen = true
        let qvc  = CustomQualityViewController(languageCode: languageCode)
        qvc.retakeResult = {
            guard let openCam = instance.retakeAction else { return }
            openCam()
        }
        instance.customQualityViewController = qvc
        
        // MARK: enableRetries (v6.3.0 NEW)
        //                do{
        //                    try instance.enableRetries(minqualityRetries: 0, maxqualityRetries: 0, minspoofRetries: 1, maxspoofRetries: 2)
        //                } catch {
        //                    print("None")
        //                }
        
        var templates = Dictionary<AppTemplateFormat, Dictionary<FingerType, [TemplateSize]>>()
        var fingerDict : [FingerType : [TemplateSize]] = [:]
        fingerDict.updateValue([.DEFAULT], forKey: .index)
        fingerDict.updateValue([.DEFAULT], forKey: .middle)
        fingerDict.updateValue([.DEFAULT], forKey: .ring)
        fingerDict.updateValue([.DEFAULT], forKey: .little)
        fingerDict.updateValue([.DEFAULT], forKey: .thumb)
        
        if menuModelObj.needWSQ {
            templates.updateValue(fingerDict, forKey: AppTemplateFormat.WSQ)
        }
        if menuModelObj.needRaw {
            templates.updateValue(fingerDict, forKey: AppTemplateFormat.RAW)
        }
        if menuModelObj.needPng{
            templates.updateValue(fingerDict, forKey: AppTemplateFormat.PNG)
        }
        if menuModelObj.needISO4{
            templates.updateValue(fingerDict, forKey: AppTemplateFormat.ISO_19794_4)
        }
        if menuModelObj.needISO2{
            templates.updateValue(fingerDict, forKey: AppTemplateFormat.ISO_19794_2)
        }
        if menuModelObj.needANSI_INCITS{
            templates.updateValue(fingerDict, forKey: AppTemplateFormat.ANSI_378_2004)
        }
        instance.setRequiredTemplates(templates: templates)
        // do {
        //     try instance.setAttemptsTimeout(allowedAttempts: 3, allowedTimeLimit: 20)
        // }
        // catch{
        // }
        //        instance.setHandChangeImage = UIImage.init(named: "finger_print.png")
        
        //        instance.isCustomResultScreen = false
        //        instance.isCustomQualityScreen = false
        //        instance.isCustomIntroScreen = false
        //        let introViewControl = self.storyboard?.instantiateViewController(withIdentifier: "CustomIntroViewController") as! CustomIntroViewController
        //        instance.isCustomIntroScreen = false
        //        introViewControl.moveToCamera = {
        //            guard let openCam = instance.moveToCamera else { return }
        //            openCam()
        //
        //        }
        //        instance.customIntroViewController = introViewControl
        //
        //        // Result
        //
        //        let resultViewControl = self.storyboard?.instantiateViewController(withIdentifier: "CustomResultViewController") as! CustomResultViewController
        //        instance.isCustomResultScreen = false
        //        resultViewControl.closeResult = {
        //            guard let closeResult = instance.closeAction else { return }
        //            closeResult()
        //
        //        }
        //        resultViewControl.captureResult = {
        //            guard let captureResult = instance.captureResult else { return ""}
        //            return captureResult()
        //        }
        //        instance.customResultViewController = resultViewControl
        //
        //        // Quality
        //
        //        let qualityViewControl = self.storyboard?.instantiateViewController(withIdentifier: "CustomQualityViewController") as! CustomQualityViewController
        //
        //        instance.isCustomQualityScreen = true
        //        qualityViewControl.moveToCamera = {
        //            guard let openCam = instance.moveToCamera else { return }
        //            openCam()
        //
        //        }
        //        instance.customQualityViewController = qualityViewControl
        
        //Encryption
        //        let publicKey = """
        //  MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEApwni+ErA4h6wyqAYz39p
        //  f3dOlvgRX8I1npz2Cx3Y1ASNl0zfhCK+9r48FisEuRb36iEz8OPk4O7hZIWb2cHg
        //  7wNXwUL09jO0rdSquGyPiJXNM/v04CTZo61r5iZ1cLSnLSw0NU4BOedK2mZaFqJh
        //  FJDeu44TGmz/x+8l50JAgD3XGk/NlTyYgRGwqpu8TFcCT8XoxEYq2QScfxq+2FnG
        //  NFX6bVi1zDSj0yBv90uelsM226zwzdGO0MZnls4AqwfzayTL4zQlI/2CFajnf4no
        //  agjbkR8jdFk4je5kLa58smRKA+ce1cb6UHfPQJD6+lVgSLU2uHmoj2KGmPDHtCDE
        //  twIDAQAB
        //  """
        //
        //        do{
        //            try instance.setEncryption(type: .RSA_AES, key: publicKey)
        //        }catch{
        //            print("")
        //        }
        return instance
    }
    static func parseResponse(from response:[String:Any],isEnroll:Bool){
        if let verifyResponse = response["verify_result"]  as? [String:Any]{
            print(verifyResponse)
        }
        
        guard let datadict :  Dictionary<String,Any> = response["data"] as? [String:Any] else {return}
        for (key,val) in datadict{
            guard let fingerDict = val as? [String:Any] else {return}
            if let templatedict  = fingerDict["templates"] as? Dictionary<String,[[String : String]]>{
                for (template, value) in templatedict {
                    for tempValue in value  {
                        for (tempSize,tempString) in tempValue{
                            let value = tempString
                            let tempData = value.data(using: .utf8)
                            let data = Data(base64Encoded: tempData!)
                            self.generateTemplates(filename: key, tempSize: tempSize, data: data, type: isEnroll ? "Enroll":"Verify", fileExtension: template.lowercased())
                        }
                    }
                }
            }else{
                if let  templatedict  = fingerDict["encryptedTemplates"] as? Dictionary<String,[[String : [String:Any]]]>{
                    for (template, value) in templatedict {
                        for tempValue in value  {
                            for (_,temps) in tempValue{
                                if template == "PNG"{
                                    let iv = temps["key1"] as! String
                                    let aes = temps["key2"] as! String
                                    let template = temps["data"] as! String
                                    if let pkey = self.importPrivateKey() {
                                        do{
                                            let aesKeyData = Data(base64Encoded: aes.data(using: .utf8)!)!
                                            let dec = try decryptWithRSA(data: aesKeyData, privateKey: pkey)
                                            let decTemplate  = try AesDecrypt(key: dec.base64EncodedString(), iv: Data(base64Encoded: iv.data(using: .utf8)!)!, data: Data(base64Encoded: template.data(using: .utf8)!)!)
                                            let pngData = decTemplate.base64EncodedString().data(using: .utf8)
                                            let pData = Data(base64Encoded: pngData!)
                                            let image = UIImage(data: pData!)
                                            print(image?.size)
                                            
                                        }catch{
                                            print(error)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    static func AesDecrypt(key:String,iv:Data,data:Data)throws->Data{
        let iv = [UInt8](iv)
        let gcm = GCM(iv: iv, mode: GCM.Mode.combined)
        let keyBytes = [UInt8](Data(base64Encoded: key, options: .ignoreUnknownCharacters)!)
        let aes = try AES(key: keyBytes, blockMode: gcm, padding: .noPadding)
        let decrypted = try aes.decrypt([UInt8](data))
        return Data(decrypted)
    }
    
    static func decryptWithRSA(data: Data, privateKey: SecKey) throws -> Data {
        var error: Unmanaged<CFError>?
        guard let decryptedData = SecKeyCreateDecryptedData(privateKey, .rsaEncryptionOAEPSHA1, data as CFData, &error) as Data? else {
            throw error!.takeRetainedValue() as Error
        }
        return decryptedData
    }
    private static func importPrivateKey() -> SecKey? {
        
        // For decrypting the captured face you must have to evter your private key here.
        // For Multi-line string use """ on both ends of the key.
        
        let privateKey = """
MIIEowIBAAKCAQEApwni+ErA4h6wyqAYz39pf3dOlvgRX8I1npz2Cx3Y1ASNl0zf
hCK+9r48FisEuRb36iEz8OPk4O7hZIWb2cHg7wNXwUL09jO0rdSquGyPiJXNM/v0
4CTZo61r5iZ1cLSnLSw0NU4BOedK2mZaFqJhFJDeu44TGmz/x+8l50JAgD3XGk/N
lTyYgRGwqpu8TFcCT8XoxEYq2QScfxq+2FnGNFX6bVi1zDSj0yBv90uelsM226zw
zdGO0MZnls4AqwfzayTL4zQlI/2CFajnf4noagjbkR8jdFk4je5kLa58smRKA+ce
1cb6UHfPQJD6+lVgSLU2uHmoj2KGmPDHtCDEtwIDAQABAoIBABDyJyflUuLIa6Bt
ftbeKDJu73bQEoMnzWTFVmNo/cGp90CtjdIhQZpVUPyMFLM/qfBYufpARHdar1xm
qZmn2k1P24FBwl7lKU6mpUMx0EXyXJpff0eWCsuuIPonq1ZpyA6vI1odCxwiuNdQ
oZHA8MmzVhqqSTSEcQE0OSDYTyQzTTrwX+3g41WRHH24uN479DWQfIVcPX7u3k8U
jfgwtD3TYLQ2kiOawQ5WbxOPtLMPsa8GA8/PDNit9DSaDQuTv4mATnwuJMp2FeUa
9m3M/bcaEgTiEHq77kJZ8srJF/r+OwKbrxPE3eeSPEfuP+wkg5AgOjhLnrdzwVRU
DFGWvOECgYEAyIk7F0S0AGn2aryhw9CihDfimigCxEmtIO5q7mnItCfeQwYPsX72
1fLpJNgfPc9DDfhAZ2hLSsBlAPLUOa0Cuny9PCBWVuxi1WjLVaeZCV2bF11mAgW2
fjLkAXT34IX+HZl60VoetSWq9ibfkJHeCAPnh/yjdB3Vs+2wxNkU8m8CgYEA1Tzm
mjJq7M6f+zMo7DpRwFazGMmrLKFmHiGBY6sEg7EmoeH2CkAQePIGQw/Rk16gWJR6
DtUZ9666sjCH6/79rx2xg+9AB76XTFFzIxOk9cm49cIosDMk4mogSfK0Zg8nVbyW
5nEb//9JCrZ18g4lD3IrT5VJoF4MhfdBUjAS1jkCgYB+RDIpv3+bNx0KLgWpFwgN
Omb667B6SW2ya4x227KdBPFkwD9HYosnQZDdOxvIvmUZObPLqJan1aaDR2Krgi1S
oNJCNpZGmwbMGvTU1Pd+Nys9NfjR0ykKIx7/b9fXzman2ojDovvs0W/pF6bzD3V/
FH5HWKLOrS5u4X3JJGqVDwKBgQCd953FwW/gujld+EpqpdGGMTRAOrXqPC7QR3X5
Beo0PPonlqOUeF07m9/zsjZJfCJBPM0nS8sO54w7ESTAOYhpQBAPcx/2HMUsrnIj
HBxqUOQKe6l0zo6WhJQi8/+cU8GKDEmlsUlS3iWYIA9EICJoTOW08R04BjQ00jS7
1A1AUQKBgHlHrV/6S/4hjvMp+30hX5DpZviUDiwcGOGasmIYXAgwXepJUq0xN6aa
lnT+ykLGSMMY/LABQiNZALZQtwK35KTshnThK6zB4e9p8JUCVrFpssJ2NCrMY3SU
qw87K1W6engeDrmunkJ/PmvSDLYeGiYWmEKQbLQchTxx1IEddXkK
"""
        
        guard let pemData = privateKey.data(using: .utf8) else {
            return nil
        }
        
        // Will remove if pem header exists
        let strippedKey = privateKey
            .replacingOccurrences(of: "-----BEGIN PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: " ", with: "")
        
        // Convert base64-encoded data
        guard let base64Data = Data(base64Encoded: strippedKey) else {
            return nil
        }
        // Create a dictionary to specify the key type and class
        let keyAttributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
        ]
        // Create a SecKey using SecKeyCreateWithData
        var error: Unmanaged<CFError>?
        guard let secKey = SecKeyCreateWithData(base64Data as CFData, keyAttributes as CFDictionary, &error) else {
            return nil
        }
        return secKey
    }
    
    private static func generateTemplates(filename:String, tempSize:String, data:Data?, type:String, fileExtension:String){
        var name:String! = ""
        
        if filename == "leftindex"{
            name = "07";
        } else if filename == "leftmiddle"{
            name = "08";
        } else if filename == "leftring" {
            name = "09";
        } else if filename == "leftlittle" {
            name = "10";
        } else if filename == "leftthumb" {
            name = "12";
        } else if filename == "rightindex" {
            name = "02";
        }else if filename == "rightmiddle" {
            name = "03";
        }else if filename == "rightring" {
            name = "04";
        }else if filename == "rightlittle" {
            name = "05";
        }else if filename == "rightthumb" {
            name = "11";
        }
        let defaults = UserDefaults.standard
        let token = defaults.integer(forKey: "FileCount")
        let path = "Template/\(type)_\(token.description)/\(tempSize)"
        let doumentDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        self.createFolder(foldername: path)
        if let data = data {
            let filename = doumentDirectoryPath.appendingPathComponent("/\(selectedType.fingers.selectedPathString)/\(path.description)/\(name.description).\(fileExtension.description)")
            let fileurl = URL.init(fileURLWithPath: filename)
            try? data.write(to: fileurl)
            
        }
    }
    private static func createFolder(foldername:String){
        let fileManager = FileManager.default
        if let tDocumentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let dirPath =  tDocumentDirectory.appendingPathComponent("/Identy")
            
            let filePath =  dirPath.appendingPathComponent("\(foldername)")
            if !fileManager.fileExists(atPath: filePath.path) {
                do {
                    try fileManager.createDirectory(atPath: filePath.path, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    NSLog("Couldn't create document directory")
                }
            }
            NSLog("Document directory is \(filePath)")
        }
    }
}


class CustomSpoofViewController: UIViewController {
    
    var retakeResult: (() -> Void)?
    
    var languageCode: String
    
    init(languageCode: String) {
        self.languageCode = languageCode
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Fetching multiple localized strings
        let customBundle = Bundle(path: Bundle.main.path(forResource: languageCode, ofType: "lproj")!)
        let spoofTitle = NSLocalizedString("spoof_title", tableName: "Main", bundle: customBundle!, value: "", comment: "First line of footer text")
        let spoofDescription = NSLocalizedString("spoof_description", tableName: "Main", bundle: customBundle!, value: "", comment: "Second line of footer text")
        let spoofPointOne = NSLocalizedString("spoof_point_one", tableName: "Main", bundle: customBundle!, value: "", comment: "Third line of footer text")
        let spoofPointTwo = NSLocalizedString("spoof_point_two", tableName: "Main", bundle: customBundle!, value: "", comment: "Third line of footer text")
        let spoofPointThree = NSLocalizedString("spoof_point_three", tableName: "Main", bundle: customBundle!, value: "", comment: "Third line of footer text")
        let retakeLabel = NSLocalizedString("id_try_again_btn", tableName: "Main", bundle: customBundle!, value: "", comment: "Third line of footer text")
        
        // Set background color
        self.view.backgroundColor = UIColor(argb: 0xffE3F3E4)
        
        // Create Image View
        let imageView = UIImageView(image: UIImage(named: "biometric_spoof"))
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Title Label
        let titleLabel = UILabel()
        titleLabel.text = spoofTitle
        titleLabel.textColor = .black
        titleLabel.font = UIFont.boldSystemFont(ofSize: 22)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Description Label
        let descriptionLabel = UILabel()
        descriptionLabel.text = spoofDescription
        descriptionLabel.textColor = .black
        descriptionLabel.font = UIFont.systemFont(ofSize: 16)
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Tips Section
        let tipsStackView = UIStackView()
        tipsStackView.axis = .vertical
        tipsStackView.spacing = 8
        tipsStackView.alignment = .leading
        tipsStackView.translatesAutoresizingMaskIntoConstraints = false
        
        let tips = [
            spoofPointOne,
            spoofPointTwo,
            spoofPointThree
        ]
        
        for tip in tips {
            let tipLabel = UILabel()
            tipLabel.text = "• \(tip)"
            tipLabel.textColor = .black
            tipLabel.font = UIFont.systemFont(ofSize: 14)
            tipsStackView.addArrangedSubview(tipLabel)
        }
        
        // Retake Button
        let button = UIButton(type: .system)
        button.setTitle(retakeLabel, for: .normal)
        button.backgroundColor = UIColor(argb: 0xff5CB75E)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 15
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(cameraAction(_:)), for: .touchUpInside)
        
        // Add views to the main view
        view.addSubview(imageView)
        view.addSubview(titleLabel)
        view.addSubview(descriptionLabel)
        view.addSubview(tipsStackView)
        view.addSubview(button)
        
        // Auto Layout Constraints
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 150),
            imageView.heightAnchor.constraint(equalToConstant: 150),
            
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            descriptionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            tipsStackView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 40),
            tipsStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            // Retake Button (Pinned to Bottom with Padding)
            button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            button.heightAnchor.constraint(equalToConstant: 55)
        ])
    }
    
    @IBAction func cameraAction(_ sender: Any) {
        guard let retake = self.retakeResult else { return }
        self.dismiss(animated: true, completion: nil)
        retake()
    }
}

class CustomQualityViewController: UIViewController {
    
    var retakeResult: (() -> Void)?
    
    var languageCode: String
    
    init(languageCode: String) {
        self.languageCode = languageCode
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Fetching multiple localized strings
        let customBundle = Bundle(path: Bundle.main.path(forResource: languageCode, ofType: "lproj")!)
        let qualityTitle = NSLocalizedString("quality_title", tableName: "Main", bundle: customBundle!, value: "", comment: "First line of footer text")
        let qualityDescription = NSLocalizedString("quality_description", tableName: "Main", bundle: customBundle!, value: "", comment: "Second line of footer text")
        let qualityPointOne = NSLocalizedString("quality_point_one", tableName: "Main", bundle: customBundle!, value: "", comment: "Third line of footer text")
        let qualityPointTwo = NSLocalizedString("quality_point_two", tableName: "Main", bundle: customBundle!, value: "", comment: "Third line of footer text")
        let qualityPointThree = NSLocalizedString("quality_point_three", tableName: "Main", bundle: customBundle!, value: "", comment: "Third line of footer text")
        let retakeLabel = NSLocalizedString("id_try_again_btn", tableName: "Main", bundle: customBundle!, value: "", comment: "Third line of footer text")
        
        // Set background color
        self.view.backgroundColor = UIColor(argb: 0xffE3F3E4)
        
        // Create Image View
        let imageView = UIImageView(image: UIImage(named: "biometric_quality"))
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Title Label
        let titleLabel = UILabel()
        titleLabel.text = qualityTitle
        titleLabel.textColor = .black
        titleLabel.font = UIFont.boldSystemFont(ofSize: 22)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Description Label
        let descriptionLabel = UILabel()
        descriptionLabel.text = qualityDescription
        descriptionLabel.textColor = .black
        descriptionLabel.font = UIFont.systemFont(ofSize: 16)
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Tips Section
        let tipsStackView = UIStackView()
        tipsStackView.axis = .vertical
        tipsStackView.spacing = 8
        tipsStackView.alignment = .leading
        tipsStackView.translatesAutoresizingMaskIntoConstraints = false
        
        let tips = [
            qualityPointOne,
            qualityPointTwo,
            qualityPointThree
        ]
        
        for tip in tips {
            let tipLabel = UILabel()
            tipLabel.text = "• \(tip)"
            tipLabel.textColor = .black
            tipLabel.font = UIFont.systemFont(ofSize: 14)
            tipsStackView.addArrangedSubview(tipLabel)
        }
        
        // Retake Button
        let button = UIButton(type: .system)
        button.setTitle(retakeLabel, for: .normal)
        button.backgroundColor = UIColor(argb: 0xff5CB75E)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 15
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(cameraAction(_:)), for: .touchUpInside)
        
        // Add views to the main view
        view.addSubview(imageView)
        view.addSubview(titleLabel)
        view.addSubview(descriptionLabel)
        view.addSubview(tipsStackView)
        view.addSubview(button)
        
        // Auto Layout Constraints
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 150),
            imageView.heightAnchor.constraint(equalToConstant: 150),
            
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            descriptionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            tipsStackView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 40),
            tipsStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            // Retake Button (Pinned to Bottom with Padding)
            button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            button.heightAnchor.constraint(equalToConstant: 55)
        ])
    }
    
    @IBAction func cameraAction(_ sender: Any) {
        guard let retake = self.retakeResult else { return }
        self.dismiss(animated: true, completion: nil)
        retake()
    }
}

extension UIColor {
    convenience init(argb: UInt32) {
        let alpha = CGFloat((argb >> 24) & 0xFF) / 255.0
        let red = CGFloat((argb >> 16) & 0xFF) / 255.0
        let green = CGFloat((argb >> 8) & 0xFF) / 255.0
        let blue = CGFloat(argb & 0xFF) / 255.0
        
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
