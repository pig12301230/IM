//
//  UIColor+util.swift
//  LotBase
//
//  Created by george_tseng on 2020/6/1.
//  Copyright © 2020 Paridise-Soft. All rights reserved.
//

import UIKit

extension UIColor {
    convenience init(_ hex: Int, alpha: Double = 1.0) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255.0, green: CGFloat((hex >> 8) & 0xFF) / 255.0, blue: CGFloat((hex) & 0xFF) / 255.0, alpha: CGFloat(255 * alpha) / 255)
    }

    convenience init(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat = 1) {
        self.init(red: (r / 255), green: (g / 255), blue: (b / 255), alpha: a)
    }

    convenience init(_ hex: String) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 1

        let hexColor = hex.replacingOccurrences(of: "#", with: "")
        let scanner = Scanner(string: hexColor)
        var hexNumber: UInt64 = 0

        if scanner.scanHexInt64(&hexNumber) {
            if hexColor.count == 8 {
                r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
                g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
                a = CGFloat(hexNumber & 0x000000ff) / 255
            } else if hexColor.count == 6 {
                r = CGFloat((hexNumber & 0xff0000) >> 16) / 255
                g = CGFloat((hexNumber & 0x00ff00) >> 8) / 255
                b = CGFloat(hexNumber & 0x0000ff) / 255
            }
        }
        self.init(red: r, green: g, blue: b, alpha: a)
    }
}
