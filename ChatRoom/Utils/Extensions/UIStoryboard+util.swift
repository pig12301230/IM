//
//  PFUIStoryboard+util.swift
//  LibPlatform
//
//  Created by ZoeLin on 2021/3/5.
//

import UIKit

extension UIStoryboard {
    class func by(name: String) -> UIStoryboard {
        return UIStoryboard(name: name, bundle: Bundle(for: self))
    }
}
