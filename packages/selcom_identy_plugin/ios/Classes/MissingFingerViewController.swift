//
//  MissingFingerViewController.swift
//  IdentyProject
//
//  Created by mac on 7/4/18.
//  Copyright © 2018 Identy. All rights reserved.
//

import UIKit
import Identy
protocol GetSelectedFingerDelegate {
    func getSelectedFinger(fingerArray: [HandScanType])
}
class MissingFingerViewController: UIViewController {
    var leftSelectedHandScanTypeArray: [HandScanType] = []
    var rightSelectedHandScanTypeArray: [HandScanType] = []
    var delegate: GetSelectedFingerDelegate?
    @IBOutlet weak var leftFingerStackView: UIStackView!
    @IBOutlet weak var rightFingerStackView: UIStackView!
    override func viewDidLoad() {
        super.viewDidLoad()
        if self.leftSelectedHandScanTypeArray.count != 0 {
            for sView in self.leftFingerStackView.subviews {
                if sView.isKind(of: UIButton.self) {
                    let button = sView as! UIButton
                    button.isSelected = false
                }
            }
        }
        if self.rightSelectedHandScanTypeArray.count != 0 {
            for sView in self.rightFingerStackView.subviews {
                if sView.isKind(of: UIButton.self) {
                    let button = sView as! UIButton
                    button.isSelected = false
                }
            }
        }
        for scanFinger in leftSelectedHandScanTypeArray {
            let button = self.leftFingerStackView.viewWithTag(scanFinger.rawValue) as! UIButton
            button.isSelected = true
        }
        for scanFinger in rightSelectedHandScanTypeArray {
            let button = self.rightFingerStackView.viewWithTag(scanFinger.rawValue) as! UIButton
            button.isSelected = true
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func fingerButtonAction(_ sender: UIButton) {
        let fingerName = HandScanType(rawValue: sender.tag)
        sender.isSelected = !sender.isSelected
    }
    @IBAction func okButtonAction(_ sender: Any) {
        self.leftSelectedHandScanTypeArray.removeAll()
        self.rightSelectedHandScanTypeArray.removeAll()
        for v in self.leftFingerStackView.subviews {
            if v.isKind(of: UIButton.self) {
                let button = v as! UIButton
                if button.isSelected {
                    let fingerName = HandScanType(rawValue: button.tag)
                    self.leftSelectedHandScanTypeArray.append(fingerName!)
                }
            }
        }
        for v in self.rightFingerStackView.subviews {
            if v.isKind(of: UIButton.self) {
                let button = v as! UIButton
                if button.isSelected {
                    let fingerName = HandScanType(rawValue: button.tag)
                    self.rightSelectedHandScanTypeArray.append(fingerName!)
                }
            }
        }
        guard let fingerDelegate = self.delegate else { return }
        fingerDelegate.getSelectedFinger(fingerArray: self.leftSelectedHandScanTypeArray + self.rightSelectedHandScanTypeArray)
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func closeButtonAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
