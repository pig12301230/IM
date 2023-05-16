//
//  Bundle+util.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/4/9.
//

import Foundation
import UIKit

extension Bundle {
    
    func getPlistBy(key: String) -> String? {
        return infoDictionary?[key] as? String ?? ""
    }

    func getPropertyPlistBy(key: String) -> [String: String] {
        return infoDictionary?[key] as? [String: String] ?? [:]
    }

    func getURLFromPlist(key: String) -> String {
        return getPlistBy(key: key)?.replacingOccurrences(of: "\\", with: "") ?? ""
    }

    func getChatPropertyFromPlist(key: String) -> String {
        return getPropertyPlistBy(key: "Customized Property List")[key] ?? ""
    }

    // for showing App Icon on ActivityVC
    func getAppIcon() -> UIImage? {
        guard let icons = infoDictionary?["CFBundleIcons"] as? [String: Any],
              let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
              let files = primary["CFBundleIconFiles"] as? [String],
              let icon = files.last else {
            return nil
        }
        return UIImage(named: icon)
    }
}
