//
//  UIStackView+util.swift
//  LotBase
//
//  Created by george_tseng on 2020/7/15.
//  Copyright © 2020 Paridise-Soft. All rights reserved.
//

import UIKit

extension UIStackView {
    func setBackground(color: UIColor, cornerRadius: CGFloat = 0) {
        let backgroundViewTag: Int = 1001001
        
        if #available(iOS 14.0, *) {
            self.layer.cornerRadius = cornerRadius
            self.backgroundColor = color
        } else {
            /*
             UIStackView is a non-drawing view, meaning that `drawRect()` is never called and its background color is ignored. If you desperately want a background color, consider placing the stack view inside another `UIView` and giving that view a background color
             */
            let subview: UIView
            if let bgView = self.viewWithTag(backgroundViewTag) {
                subview = bgView
            } else {
                subview = UIView(frame: bounds)
                subview.tag = backgroundViewTag
                subview.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                subview.clipsToBounds = true
                insertSubview(subview, at: 0)
            }
            
            subview.backgroundColor = color
            subview.layer.cornerRadius = cornerRadius
        }
    }
    
    func addArrangedSubviews(_ views: [UIView]) {
        views.forEach { (v) in
            self.addArrangedSubview(v)
        }
    }
    
    func removeAllArrangedSubviews() {
        self.arrangedSubviews.forEach { (v) in
            v.removeFromSuperview()
        }
    }
}
