//
//  UISegmentedControl+util.swift
//  LotBase
//
//  Created by saffi_peng on 2020/10/8.
//  Copyright © 2020 Paridise-Soft. All rights reserved.
//

import UIKit

extension UISegmentedControl {

    func setColors(backgroundColor: UIColor, tintColor: UIColor, normalTextColor: UIColor, selectedTextColor: UIColor) {
        self.backgroundColor = .clear

        let normalBg = UIImage(color: backgroundColor)
        let selectedBg = UIImage(color: tintColor)
        setBackgroundImage(normalBg, for: .normal, barMetrics: .default)
        setBackgroundImage(selectedBg, for: .selected, barMetrics: .default)
        setBackgroundImage(selectedBg, for: .highlighted, barMetrics: .default)

        let dividerImage = UIImage(color: tintColor, size: CGSize(width: 0.3, height: self.bounds.height))
        setDividerImage(dividerImage, forLeftSegmentState: .normal, rightSegmentState: .normal, barMetrics: .default)

        let attributeNormalText = [NSAttributedString.Key.foregroundColor: normalTextColor,
                                   NSAttributedString.Key.font: UIFont.medium(14)]
        self.setTitleTextAttributes(attributeNormalText, for: .normal)

        let attributeSelectedText = [NSAttributedString.Key.foregroundColor: selectedTextColor,
                                     NSAttributedString.Key.font: UIFont.medium(14)]
        self.setTitleTextAttributes(attributeSelectedText, for: .selected)
        self.setTitleTextAttributes(attributeSelectedText, for: .highlighted)
    }
}
