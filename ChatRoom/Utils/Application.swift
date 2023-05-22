//
//  Application.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/4/14.
//

import Foundation
import IQKeyboardManagerSwift
import RealmSwift
import SwiftTheme
import Sentry

class Application {

    static let shared = Application()
    static let timeout: TimeInterval = 60
    static let uploadTimeout: TimeInterval = 1800
    private(set) var appVersion: String = ""
    
    var limitImageMB: Double {
        return 16.0
    }
    
    var maxInputLenght: Int {
        return 18
    }
    
    var minToastWidth: CGFloat {
        return 120
    }

    func setups() {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        appVersion = "\(version)(\(build))"
        setupSentry()
        setupUserData()
        setupKeyboard()
        setupTheme()
        setupNetworkListening()
        setupNavigationBar()
    }
}

// MARK: - Setup Library
private extension Application {
    func setupSentry() {
        SentrySDK.start { options in
            options.dsn = AppConfig.Info.sentryDSN
            options.debug = true
            options.environment = AppConfig.Info.environment
            options.enableAppHangTracking = true
//            options.enableFileIOTracking = true
//            options.enableCoreDataTracking = true

            options.enableUserInteractionTracing = true
            options.attachScreenshot = true
            options.attachViewHierarchy = true
        }
    }

    func setupKeyboard() {
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.shouldResignOnTouchOutside = true
        IQKeyboardManager.shared.keyboardDistanceFromTextField = 5
        IQKeyboardManager.shared.enableAutoToolbar = false
//        IQKeyboardManager.shared.toolbarDoneBarButtonItemText = Localizable.done
        IQKeyboardManager.shared.shouldShowToolbarPlaceholder = true
        IQKeyboardManager.shared.previousNextDisplayMode = .Default
//        IQKeyboardManager.shared.canGoPrevious = true
    }

    func setupTheme() {
        ThemeManager.setTheme(jsonName: AppConfig.Info.themeFileName, path: .mainBundle)
    }

    func setupNetworkListening() {
        NetworkManager.startListening()
    }
    
    func setupUserData() {
        _ = UserData.shared
    }
}

// MARK: - Setup Views
private extension Application {

    func setupNavigationBar() {
        let bar = UINavigationBar.appearance()
        bar.isTranslucent = false
        bar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: Theme.c_10_grand_1.rawValue.toColor(),
                                   NSAttributedString.Key.font: UIFont.boldParagraphLargeCenter]
        
        let backImage = UIImage(named: "iconArrowsChevronLeft")
        bar.backIndicatorImage = backImage
        bar.backIndicatorTransitionMaskImage = backImage
    }
}
