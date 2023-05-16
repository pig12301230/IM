//
//  UIApplication+util.swift
//  LotBase
//
//  Created by george_tseng on 2020/5/29.
//  Copyright © 2020 Paridise-Soft. All rights reserved.
//

import UIKit

extension UIApplication {
    
    class func topViewController(_ base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            if let selected = tab.selectedViewController {
                return topViewController(selected)
            }
        }
        if let alert = base as? UIAlertController {
            return alert
        }
        if let presented = base?.presentedViewController {
            return topViewController(presented)
        }
        return base
    }
}
