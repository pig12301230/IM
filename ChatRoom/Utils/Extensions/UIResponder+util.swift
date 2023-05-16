//
//  UIResponder+util.swift
//  LotBase
//
//  Created by george_tseng on 2020/7/29.
//  Copyright © 2020 Paridise-Soft. All rights reserved.
//

import UIKit

extension UIResponder {
    var parentViewController: UIViewController? {
        return next as? UIViewController ?? next?.parentViewController
    }
}
