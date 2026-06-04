//
//  MenuListViewController.swift
//  Identy1
//
//  Created by mac on 6/9/18.
//  Copyright © 2018 Sumuga. All rights reserved.
//

import UIKit
import Identy

class MenuModel: NSObject {
    var isEnabledAS: Bool = true
    var isShowTraining: Bool = false
    var isMissingFinger: Bool = false
    var needWSQ: Bool = true
    var needRaw: Bool = false
    var needPng: Bool = false
    var needISO4: Bool = false
    var needISO2:Bool = false
    var needISO5: Bool = false
    var needANSI_INCITS: Bool = false
    var needNIST: Bool = false
    var needEnhancement: Bool = true
    var selectedAppMode: AppMode! = .demo
    var selectedAppUI: AppUI! = .boxes
    var selectedCompression: WSQCompressionType! = .WSQ_10_1
    var isSetAppModeSelected: Bool = false
    var isSetAppUISelected: Bool = false
    var isTempleteSelected: Bool = false
    var isWSQSelected: Bool = true
    var isTorch:Bool = false

}
class MenuListViewController: UIViewController {
    @IBOutlet weak var menuTableView: UITableView!
    var menuModel: MenuModel!
    var selectedType : selectedType = .fingers
    var menuArray = [Menu.setAppMode, Menu.setAppUI, Menu.enableAS, Menu.showCaptureTraining, Menu.showGuide, Menu.templateFormat, Menu.wsqCompression, Menu.missingFingers]
    var fingerAppModeArray = [AppMode.demo, AppMode.commercial]
    var fingerAppUIArray = [AppUI.scanningBar, AppUI.boxes ,AppUI.image]
    var fingerTemplateArray = [AppTemplateFormat.RAW, AppTemplateFormat.WSQ, AppTemplateFormat.PNG,AppTemplateFormat.ISO_19794_4 ,AppTemplateFormat.ISO_19794_2,AppTemplateFormat.ANSI_378_2004]
    var compressionArray = [WSQCompressionType.WSQ_5_1, WSQCompressionType.WSQ_10_1, WSQCompressionType.WSQ_15_1]
    var missingFingerClosure: (()-> Void)?
    var menuList : [Menu] = []
    var templateArray : [Any] = []
    var appUIArray : [Any] = []
    var appModeArray : [Any] = []
    var documentInteractionController : UIDocumentInteractionController!
//    var appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        menuList = self.menuArray
        templateArray = self.fingerTemplateArray
        appModeArray = self.fingerAppModeArray
        appUIArray = self.fingerAppUIArray
        self.menuTableView.register(MenuTableViewCell.nib, forCellReuseIdentifier: MenuTableViewCell.identifier)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if #available(iOS 12.0, *) {
            if self.traitCollection.userInterfaceStyle == .dark{
                self.menuTableView.backgroundColor = .white
            }
        }
        self.tableShowAnimation()
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.hideTableAnimation()
    }
    
    private func tableShowAnimation(){
        self.menuTableView.frame = CGRect(x: UIScreen.main.bounds.width - 20 , y: 40, width: 0, height: 0)
        self.menuTableView.alpha = 0.0
        UIView.transition(with: self.view, duration: 0.25, options: .transitionCrossDissolve, animations: {() -> Void in
            self.menuTableView.alpha = 1.0
            self.menuTableView.frame = CGRect(x: UIScreen.main.bounds.width - 220 - 20, y: 40, width: 220, height: CGFloat(self.menuList.count * 44 + 10))
            
        }, completion: { _ in })
    }
    open func hideTableAnimation(){
        self.menuModel.isWSQSelected = false
        self.menuModel.isTempleteSelected = false
        self.menuModel.isSetAppUISelected = false
        self.menuModel.isSetAppModeSelected = false
        UIView.transition(with: self.view, duration: 0.25, options: .transitionCrossDissolve, animations: {() -> Void in
            self.menuTableView.frame = CGRect(x: UIScreen.main.bounds.width - 30 , y: 40, width: 0, height: 0)
            self.menuTableView.alpha = 0.0
            self.view.alpha = 0.0;
        }, completion: { _ in
            self.dismiss(animated: true, completion: nil)
        })
    }
    open func updateTableViewAnimation(array: Array<Any>){
        UIView.transition(with: self.view, duration: 0.25, options: .transitionCrossDissolve, animations: {() -> Void in
            self.menuTableView.alpha = 1.0
            self.menuTableView.frame = CGRect(x: UIScreen.main.bounds.width - 220 - 20, y: 40, width: 220, height: CGFloat(array.count * 44 + 30))
        }, completion: { _ in })
        
    }
    func createFolder(foldername:String){
        let fileManager = FileManager.default
        if let tDocumentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let filePath =  tDocumentDirectory.appendingPathComponent("\(foldername)")
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

extension MenuListViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if menuModel.isSetAppUISelected {
            return self.appUIArray.count
        }
        if menuModel.isSetAppModeSelected {
            return self.appModeArray.count
        }
        if menuModel.isTempleteSelected {
            return self.templateArray.count
        }
        if menuModel.isWSQSelected {
            return self.compressionArray.count
        }
        return menuList.count
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if menuModel.isWSQSelected {
            return Menu.wsqCompression.menuNameString
        }
        if menuModel.isSetAppUISelected {
            return Menu.setAppUI.menuNameString
        }
        if menuModel.isSetAppModeSelected {
            return Menu.setAppMode.menuNameString
        }
        if menuModel.isTempleteSelected {
            return Menu.templateFormat.menuNameString
        }
        return ""
    }
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if #available(iOS 12.0, *) {
            if self.traitCollection.userInterfaceStyle == .dark{
                view.tintColor = .lightGray
            }
        }
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if menuModel.isWSQSelected {
            let cell = tableView.dequeueReusableCell(withIdentifier: MenuTableViewCell.identifier) as! MenuTableViewCell
            cell.accessoryType = .none
            cell.checkBoxButton.isHidden = false
            let menuItem = self.compressionArray[indexPath.row]
            cell.checkBoxButton.isSelected = (self.menuModel.selectedCompression == menuItem) ? true : false
            cell.nameLabel.text = menuItem.compressionName
            return cell
        }else if menuModel.isSetAppUISelected {
            let cell = tableView.dequeueReusableCell(withIdentifier: MenuTableViewCell.identifier) as! MenuTableViewCell
            cell.accessoryType = .none
            cell.checkBoxButton.isHidden = false
            let menuItem = self.appUIArray[indexPath.row] as! AppUI
            cell.checkBoxButton.isSelected = (self.menuModel.selectedAppUI == menuItem) ? true : false
            cell.nameLabel.text = menuItem.appUIName
            return cell
        }else if menuModel.isSetAppModeSelected {
            let cell = tableView.dequeueReusableCell(withIdentifier: MenuTableViewCell.identifier) as! MenuTableViewCell
            cell.accessoryType = .none
            cell.checkBoxButton.isHidden = false
            let menuItem = self.appModeArray[indexPath.row] as! AppMode
            cell.checkBoxButton.isSelected = (self.menuModel.selectedAppMode == menuItem) ? true : false
            cell.nameLabel.text = menuItem.appModeName
            return cell
        }else if menuModel.isTempleteSelected {
            let cell = tableView.dequeueReusableCell(withIdentifier: MenuTableViewCell.identifier) as! MenuTableViewCell
            cell.accessoryType = .none
            cell.checkBoxButton.isHidden = false
            let menuItem = self.templateArray[indexPath.row] as! AppTemplateFormat
            switch menuItem{
            case .RAW:
                cell.checkBoxButton.isSelected = (self.menuModel.needRaw == true) ? true : false
                break
            case .WSQ:
                cell.checkBoxButton.isSelected = (self.menuModel.needWSQ == true) ? true : false
                break
            case .PNG:
                cell.checkBoxButton.isSelected = (self.menuModel.needPng == true) ? true : false
                break
            case .ISO_19794_4:
                cell.checkBoxButton.isSelected = (self.menuModel.needISO4 == true) ? true : false
                break
            case .ISO_19794_2:
                cell.checkBoxButton.isSelected = (self.menuModel.needISO2 == true) ? true : false
                break
            case .ANSI_378_2004:
                cell.checkBoxButton.isSelected = (self.menuModel.needANSI_INCITS == true) ? true : false
                break
            default:break
            }
            cell.nameLabel.text = menuItem.getTemplateName()
            return cell
        }
        else{
            let cell = tableView.dequeueReusableCell(withIdentifier: MenuTableViewCell.identifier) as! MenuTableViewCell
            if #available(iOS 12.0, *) {
                if self.traitCollection.userInterfaceStyle == .dark{
                    cell.backgroundColor = .white
                }
            }
            let menuItem = menuList[indexPath.row]
            var name = ""
            switch menuItem {
            case .setAppMode:
                name = menuItem.menuNameString
                cell.accessoryType = .disclosureIndicator
                cell.checkBoxButton.isHidden = true
                break
            case .setAppUI:
                name = menuItem.menuNameString
                cell.accessoryType = .disclosureIndicator
                cell.checkBoxButton.isHidden = true
                break
            case .enableAS:
                name = menuItem.menuNameString
                cell.accessoryType = .none
                cell.checkBoxButton.isHidden = false
                cell.checkBoxButton.isSelected = UserDefaults.standard.bool(forKey: Keys.isAntiSpoof) ? true : false//self.menuModel.isEnabledAS ? true : false//
                break
            case .showCaptureTraining:
                name = menuItem.menuNameString
                cell.accessoryType = .none
                cell.checkBoxButton.isHidden = false
                cell.checkBoxButton.isSelected = UserDefaults.standard.bool(forKey: Keys.isNeedShowTraining) ? true : false//self.menuModel.isShowTraining ? true : false//
                break
            case .showGuide:
                name = menuItem.menuNameString
                cell.accessoryType = .none
                cell.checkBoxButton.isHidden = false
                cell.checkBoxButton.isSelected = UserDefaults.standard.bool(forKey: Keys.isShowGuide) ? true : false
                break

            case .templateFormat:
                name = menuItem.menuNameString
                cell.accessoryType = .disclosureIndicator
                cell.checkBoxButton.isHidden = true
                break
            case .wsqCompression:
                name = menuItem.menuNameString
                cell.accessoryType = .disclosureIndicator
                cell.checkBoxButton.isHidden = true
                break
            case .missingFingers:
                name = menuItem.menuNameString
                cell.accessoryType = .none
                cell.checkBoxButton.isHidden = false
                cell.checkBoxButton.isSelected = UserDefaults.standard.bool(forKey: Keys.isMissingFinger) ? true : false
                break
            case .selectlanguage:
                name = menuItem.menuNameString
                cell.accessoryType = .none
                cell.checkBoxButton.isHidden = true
                break
            }
            cell.nameLabel.text = name
            return cell
        }
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if menuModel.isWSQSelected {
            let menuItem = self.compressionArray[indexPath.row]
            self.menuModel.selectedCompression = menuItem
            menuTableView.reloadData()
            self.hideTableAnimation()
        }else if menuModel.isSetAppUISelected {
            let menuItem = self.appUIArray[indexPath.row]
            self.menuModel.selectedAppUI = menuItem as? AppUI
            menuTableView.reloadData()
            self.hideTableAnimation()
        }else if menuModel.isSetAppModeSelected {
            let menuItem = self.appModeArray[indexPath.row]
            self.menuModel.selectedAppMode = menuItem as? AppMode
            menuTableView.reloadData()
            self.hideTableAnimation()
            
        }else if menuModel.isTempleteSelected {
            let menuItem = self.templateArray[indexPath.row] as! AppTemplateFormat
            switch menuItem{
            case .RAW:
                self.menuModel.needRaw = !self.menuModel.needRaw
                break
            case .WSQ:
                self.menuModel.needWSQ = !self.menuModel.needWSQ
                break
            case .PNG:
                self.menuModel.needPng = !self.menuModel.needPng
                break
            case .ISO_19794_4:
                self.menuModel.needISO4 = !self.menuModel.needISO4
                break
            case .ISO_19794_2:
                self.menuModel.needISO2 = !self.menuModel.needISO2
                break
            case .ANSI_378_2004:
                self.menuModel.needANSI_INCITS = !self.menuModel.needANSI_INCITS
                break
            default:break
            }
            menuTableView.reloadData()
            self.hideTableAnimation()
        }
        else{
            let menuItem = self.menuList[indexPath.row]
            switch menuItem {
            case .setAppMode:
                menuModel.isSetAppModeSelected = true
                self.updateTableViewAnimation(array: self.appModeArray)
                menuTableView.reloadData()
                break
            case .setAppUI:
                menuModel.isSetAppUISelected = true
                self.updateTableViewAnimation(array: self.appUIArray)
                menuTableView.reloadData()
                break
            case .enableAS:
                let isAntiSpoof = UserDefaults.standard.bool(forKey: Keys.isAntiSpoof)
                UserDefaults.standard.set(!isAntiSpoof, forKey: Keys.isAntiSpoof)
                //                menuModel.isEnabledAS = !menuModel.isEnabledAS
                menuTableView.reloadData()
                self.hideTableAnimation()
                break
            case .showCaptureTraining:
                let isShow = UserDefaults.standard.bool(forKey: Keys.isNeedShowTraining)
                UserDefaults.standard.set(!isShow, forKey: Keys.isNeedShowTraining)
                //                menuModel.isShowTraining = !menuModel.isShowTraining
                menuTableView.reloadData()
                self.hideTableAnimation()
                
                break
            case .showGuide:
                let isShow = UserDefaults.standard.bool(forKey: Keys.isShowGuide)
                UserDefaults.standard.set(!isShow, forKey: Keys.isShowGuide)
                menuTableView.reloadData()
                self.hideTableAnimation()
                break

            case .templateFormat:
                menuModel.isTempleteSelected = true
                self.updateTableViewAnimation(array: self.templateArray)
                menuTableView.reloadData()
                break
            case .wsqCompression:
                menuModel.isWSQSelected = true
                self.updateTableViewAnimation(array: self.compressionArray)
                menuTableView.reloadData()
                break
            case .missingFingers:
                let isShow = UserDefaults.standard.bool(forKey: Keys.isMissingFinger)
                UserDefaults.standard.set(!isShow, forKey: Keys.isMissingFinger)
                self.hideTableAnimation()
                guard let tapMissingFinger = self.missingFingerClosure else {return}
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    tapMissingFinger()
                }
                break
            case .selectlanguage:
                let actionSheetController: UIAlertController = UIAlertController(title: "Choose Language", message: nil, preferredStyle: .actionSheet)
                let firstAction: UIAlertAction = UIAlertAction(title: "English", style: .default) { action -> Void in
                    Singleton.sharedInstance.currentLanguage = "en"
                    actionSheetController.dismiss(animated: false, completion: nil)
                }
                let secondAction: UIAlertAction = UIAlertAction(title: "Spanish", style: .default) { action -> Void in
                    Singleton.sharedInstance.currentLanguage = "es-MX"
                    actionSheetController.dismiss(animated: false, completion: nil)
                }
                let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
                    actionSheetController.dismiss(animated: false, completion: nil)
                }
                actionSheetController.addAction(firstAction)
                actionSheetController.addAction(secondAction)
                actionSheetController.addAction(cancelAction)
                present(actionSheetController, animated: false, completion: {
                    //                    self.menuTableView.reloadData()
                    //                    self.hideTableAnimation()
                })
                break

            }
        }
        
        
    }
}
    
extension MenuListViewController  {
    /// This function will set all the required properties, and then provide a preview for the document
    func share(url: URL) {
        let appearance = UIBarButtonItem.appearance(whenContainedInInstancesOf: [UINavigationBar.self])
        appearance.setTitleTextAttributes([NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 16.0), NSAttributedString.Key.foregroundColor : UIColor.init(red: 71/255, green: 187/255, blue: 233/255, alpha: 1.0)], for: .normal)
        documentInteractionController.delegate = self
        documentInteractionController.url = url
        documentInteractionController.uti = url.typeIdentifier ?? "public.data, public.content"
        documentInteractionController.name = url.localizedName ?? url.lastPathComponent
        documentInteractionController.presentPreview(animated: false)
    }
    
    /// This function will store your document to some temporary URL and then provide sharing, copying, printing, saving options to the user
    func storeAndShare(withURLString: String) {
        guard let url = URL(string: withURLString) else { return }
        /// START YOUR ACTIVITY INDICATOR HERE
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else { return }
            let tmpURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(response?.suggestedFilename ?? "fileName.png")
            do {
                try data.write(to: tmpURL)
            } catch {
//                DLog("",error)
            }
            DispatchQueue.main.async {
                /// STOP YOUR ACTIVITY INDICATOR HERE
                self.share(url: tmpURL)
            }
        }.resume()
    }
   
}

extension MenuListViewController: UIDocumentInteractionControllerDelegate{
    /// If presenting atop a navigation stack, provide the navigation controller in order to animate in a manner consistent with the rest of the platform
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        guard let navVC = self.navigationController else {
        return self
        }
        return navVC
    }
    func documentInteractionControllerDidEndPreview(_ controller: UIDocumentInteractionController) {
        documentInteractionController.dismissPreview(animated: false)
        documentInteractionController = nil
    }
}
extension URL {
    var typeIdentifier: String? {
        return (try? resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier
    }
    var localizedName: String? {
        return (try? resourceValues(forKeys: [.localizedNameKey]))?.localizedName
    }
}
