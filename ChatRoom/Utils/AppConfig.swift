//
//  PFUtil.swift
//  LotBase
//
//  Created by george_tseng on 2020/5/27.
//  Copyright © 2020 Paridise-Soft. All rights reserved.
//

import UIKit

struct AppConfig {
    static var bundle = Bundle.main
    static let maxPhotoLimit: Int = 10
    static let imgDomainRefreshTime: Double = 1800 // 30 min
    
    struct Device {
        static let uuid = UIDevice.current.identifierForVendor?.uuidString ?? ""
        static let iOSVersion = "iOS \(UIDevice.current.systemVersion)"
        static var modelIdentifier: String {
            guard let simulatorModelIdentifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] else {
                return UIDevice.modelName
            }
            return simulatorModelIdentifier
        }
        static var language: String {
            let preferredLang = NSLocale.preferredLanguages[0]
            if preferredLang.contains("en") {
                return "en_us"
            } else {
                return "zh_cn"
            }
        }
        static var keyboardMaxHeight: CGFloat = .zero
        static let localImageFilePath: URL = FileManager.default.getLocalImagesFolderUrl() ?? URL(fileURLWithPath: "")
    }

    struct Screen {
        static let screenWidth = Int(UIScreen.main.nativeBounds.width)
        static let screenHeight = Int(UIScreen.main.nativeBounds.height)
        static let resolution = "\(screenWidth)x\(screenHeight)"

        static let screenRect = UIScreen.main.bounds
        static let mainFrameWidth = screenRect.size.width
        static let mainFrameHeight = screenRect.size.height

        static let tabBarHeight: CGFloat = mainFrameHeight >= 812 ? 83 : 49
        static let statusBarHeight: CGFloat = UIApplication.shared.statusBarFrame.height
        static var isSmallScreen: Bool = {
            return mainFrameWidth == 320
        }()
    }
    
    struct GlobalProperty {
        static let sectionNumberSign = "#"
    }

    // Associated Domains
    struct UniversalLink {
        static let dev = "applinks:ttmj-web-dev.paradise-soft.com.tw/app-ul"
        static let uat = "applinks:ttmj-web-uat.paradise-soft.com.tw/app-ul"
    }
    
    enum ImageParallelCDN: String, CaseIterable {
        case CDNA
        case CDNB
        case CDNC
        case CDND
        
        var line: String {
            switch self {
            case .CDNA:
                return "fs1.cdn800.com"
            case .CDNB:
                return "fs2.cdn800.com"
            case .CDNC:
                return "fs3.cdn800.com"
            case .CDND:
                return "fs4.cdn800.com"
            }
        }
    }
    
    struct CurrentDomain {
        static var imageDomain = "fs1.cdn800.com"
    }

    struct Info {
        static let brand = bundle.getChatPropertyFromPlist(key: "Brand")

        static let bundleID: String = bundle.getPlistBy(key: "CFBundleIdentifier") ?? ""
        static let appVersion = bundle.getPlistBy(key: "CFBundleShortVersionString")
        static let buildVersion = bundle.getPlistBy(key: "CFBundleVersion")
        static let bundleName = bundle.getPlistBy(key: "CFBundleName")
        static let appName = bundle.getPlistBy(key: kCFBundleNameKey as String) ?? ""
        static let targetName = bundle.getPlistBy(key: "CFBundleExecutable")
        static let environment = bundle.getChatPropertyFromPlist(key: "Sentry_Environment")
        static let sentryDSN = bundle.getChatPropertyFromPlist(key: "Sentry_DSN")
        static var isMaintaining: Bool = false
        static var themeFileName = bundle.getChatPropertyFromPlist(key: "ThemeFileName")
        static var loadingFileName = bundle.getChatPropertyFromPlist(key: "LoadingFile")
        static var localizableFileName = bundle.getChatPropertyFromPlist(key: "LocalizableFile")
        static var servicePolicy = bundle.getChatPropertyFromPlist(key: "Service_URL")
        static var privacyPolicy = bundle.getChatPropertyFromPlist(key: "Privacy_URL")
    }

    struct Database {
        /**
         1: 初始化
         2: 聊天、好友列表相關schema調整
         */
        static let schemaVersion: UInt64 = 13
    }

}
