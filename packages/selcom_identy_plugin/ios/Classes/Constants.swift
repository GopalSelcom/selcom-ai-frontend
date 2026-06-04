//
//  Constants.swift
//  IdentyProject
//
//  Created by mac on 7/4/18.
//  Copyright © 2018 Identy. All rights reserved.
//

import Foundation
enum Menu: Int {
    case setAppMode = 0
    case setAppUI
    case enableAS
    case showCaptureTraining
    case showGuide
    case templateFormat
    case wsqCompression
    case missingFingers
    case selectlanguage
    public var menuNameString: String{
        switch self {
        case .setAppMode:
            return "Set App mode"
        case .setAppUI:
            return "Set App UI"
        case .enableAS:
            return "Enable AS"
        case .showCaptureTraining:
            return "Show capture training"
        case .showGuide:
            return "Show Guide"
        case .templateFormat:
            return "IDENTY Template Format"
        case .wsqCompression:
            return "WSQ Compression"
        case .missingFingers:
            return "Missing Fingers"
        case .selectlanguage:
            return "Select Language"

            
        }
    }
}
enum HTMLPage: Int {
    case terms
    case privacy
    public var urlString: String {
        switch self {
        case .terms:
            return "tc"
        case .privacy:
            return "privacy"
        }
    }
}
enum selectedType: Int {
    case fingers
    public var selectedTypeString: String {
        switch self {
        case .fingers:
            return "Fingers"
        }
    }
    public var selectedPathString : String {
        switch self {
        case .fingers:
            return "Identy"
        }
    }
    public var pathString : String {
        switch self {
        case .fingers:
            return "Fingers"
        }
    }
}
