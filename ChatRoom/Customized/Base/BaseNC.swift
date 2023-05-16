//
//  BaseNC.swift
//  LotBase
//
//  Created by george_tseng on 2020/6/8.
//  Copyright © 2020 Paridise-Soft. All rights reserved.
//

import UIKit

open class BaseNC: UINavigationController {
    var dataObject: [String: Any] = [:]
    let navigator = Navigator.default
    
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        if let vc = UIApplication.topViewController() {
            return vc.preferredStatusBarStyle
        }
        return .default
    }
}
