//
//  NSMutableAttributedString+util.swift
//  LotBase
//
//  Created by george_tseng on 2020/6/24.
//  Copyright © 2020 Paridise-Soft. All rights reserved.
//

import Foundation
import UIKit

// An attributed string extension to achieve colors on text.
extension NSMutableAttributedString {
    // MARK: - Color
    func setColorToAllRange(color: UIColor, forText stringValue: String, options: NSString.CompareOptions = .caseInsensitive) {
        let ranges = self.string.ranges(of: stringValue, options: options).compactMap { self.string.nsRange(from: $0) }
        ranges.forEach {
            self.setColor(color: color, range: $0)
        }
    }
    
    func setColor(color: UIColor, forText stringValue: String, options: NSString.CompareOptions = .caseInsensitive) {
        let range: NSRange = self.mutableString.range(of: stringValue, options: options)
        self.setColor(color: color, range: range)
    }
    
    func recoverColor(to color: UIColor) {
        self.setColor(color: color, forText: self.string)
    }

    func setColor(color: UIColor, range: NSRange) {
        self.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: range)
    }

    // MARK: - Font
    func setFont(font: UIFont, for range: NSRange) {
        self.addAttribute(.font, value: font, range: range)
    }

    func setFont(font: UIFont, forText stringValue: String) {
        let range: NSRange = self.mutableString.range(of: stringValue, options: .forcedOrdering)
        self.setFont(font: font, for: range)
    }

    func recoverFont(to font: UIFont) {
        self.setFont(font: font, forText: self.string)
    }

    // MARK: - Background Color
    func setBackgroundColor(color: UIColor, for range: NSRange) {
        self.addAttribute(.backgroundColor, value: color, range: range)
    }

    func setBackgroundColor(color: UIColor, forText stringValue: String) {
        let range: NSRange = self.mutableString.range(of: stringValue, options: .forcedOrdering)
        self.setBackgroundColor(color: color, for: range)
    }

    func recoverBackgroundColor(to color: UIColor) {
        self.setBackgroundColor(color: color, forText: self.string)
    }

    // MARK: - Link
    func setUnderLine(style: NSUnderlineStyle, for range: NSRange) {
        self.addAttribute(.underlineStyle, value: style.rawValue, range: range)
    }

    func setLink(url: URL, for range: NSRange) {
        self.addAttribute(.link, value: url, range: range)
    }
}
