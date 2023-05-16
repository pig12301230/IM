//
//  UIFont+util.swift
//  LotBase
//
//  Created by george_tseng on 2020/6/1.
//  Copyright © 2020 Paridise-Soft. All rights reserved.
//

import UIKit

extension UIFont {
    
    static func systemFont(_ size: CGFloat) -> UIFont { .systemFont(ofSize: size) }
    
    static func italic(_ size: CGFloat) -> UIFont {
        return UIFont.italicSystemFont(ofSize: size)
    }

    static func ultraLight(_ size: CGFloat) -> UIFont {
        return UIFont(name: "PingFangSC-Ultralight", size: size) ?? systemFont(size)
    }

    static func thin(_ size: CGFloat) -> UIFont {
        return UIFont(name: "PingFangSC-Thin", size: size) ?? systemFont(size)
    }

    static func light(_ size: CGFloat) -> UIFont {
        return UIFont(name: "PingFangSC-Light", size: size) ?? systemFont(size)
    }

    static func regular(_ size: CGFloat) -> UIFont {
        return UIFont(name: "PingFangSC-Regular", size: size) ?? systemFont(size)
    }

    static func medium(_ size: CGFloat) -> UIFont {
        return UIFont(name: "PingFangSC-Medium", size: size) ?? systemFont(size)
    }

    static func semibold(_ size: CGFloat) -> UIFont {
        return UIFont(name: "PingFangSC-Semibold", size: size) ?? systemFont(size)
    }
}

extension UIFont {
    func size(OfString string: String, constrainedToWidth width: CGFloat) -> CGSize {
        return NSString(string: string).boundingRect(with: CGSize(width: width, height: .greatestFiniteMagnitude),
                                                     options: .usesLineFragmentOrigin,
                                                     attributes: [.font: self],
                                                     context: nil).size
    }
}
