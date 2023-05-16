//
//  Navigator.swift
//  LotBase
//
//  Created by george_tseng on 2020/5/29.
//  Copyright © 2020 Paridise-Soft. All rights reserved.
//

import UIKit

class Navigator {
    static var `default` = Navigator()

    enum TransitionType {
        case root(in: UIWindow, duration: Double = 0.0)
        case push(animated: Bool)
        case present(animated: Bool, style: UIModalPresentationStyle = .fullScreen)
        case custom(animated: Bool)
        case toTabRoot(tab: MainBarKind)
    }
}
