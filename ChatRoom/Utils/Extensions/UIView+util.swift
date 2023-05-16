//
//  UIView+util.swift
//  LotBase
//
//  Created by george_tseng on 2020/6/15.
//  Copyright © 2020 Paridise-Soft. All rights reserved.
//

import UIKit

extension UIView {
    func addSubviews(_ views: [UIView]) {
        views.forEach { (v) in
            self.addSubview(v)
        }
    }
    
    func popAnimation() {
        self.alpha = 0
        self.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.3, initialSpringVelocity: 0.3, options: .curveEaseIn, animations: {
            self.transform = .identity
            self.alpha = 1.0
        })
    }
    
    func setShadow(offset: CGSize, radius: CGFloat, opacity: Float, color: CGColor = UIColor.black.cgColor) {
        self.layer.masksToBounds = false
        self.layer.shadowOpacity = opacity
        self.layer.shadowOffset = offset
        self.layer.shadowRadius = radius
        self.layer.shadowColor = color
    }

    func roundCorners(corners: CACornerMask, radius: CGFloat) {
        self.layer.cornerRadius = radius
        if #available(iOS 11.0, *) {
            self.layer.maskedCorners = corners
        }
    }
    
    func toImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
    
    func rotation(angle: CGFloat = CGFloat.pi, duration: TimeInterval = 0.25) {
        UIView.animate(withDuration: duration) {
            self.transform = self.transform.rotated(by: angle)
        }
    }
    
    func resetRotation(duration: TimeInterval = 0.25) {
        UIView.animate(withDuration: duration) {
            self.transform = CGAffineTransform.identity
        }
    }
}

extension UIView {
    
    enum GradientDirection: Int {
        case topToBottom
        case bottomToTop
        case leftToRight
        case rightToLeft
        
        var startPoint: CGPoint {
            switch self {
            case .bottomToTop:
                return CGPoint.init(x: 0, y: 1)
            case .topToBottom, .leftToRight:
                return CGPoint.init(x: 0, y: 0)
            case .rightToLeft:
                return CGPoint.init(x: 1, y: 0)
            }
        }
        
        var endPoint: CGPoint {
            switch self {
            case .bottomToTop, .rightToLeft:
                return CGPoint.init(x: 0, y: 0)
            case .topToBottom:
                return CGPoint.init(x: 0, y: 1)
            case .leftToRight:
                return CGPoint.init(x: 1, y: 0)
            }
        }
    }
    
    func setGradientLayer(colors: [Any], direction: GradientDirection = .topToBottom) {
        let gradient = self.getGradientLayer(colors: colors, direction: direction)
        self.layer.addSublayer(gradient)
    }
    
    private func getGradientLayer(colors: [Any], direction: GradientDirection = .topToBottom) -> CAGradientLayer {
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.startPoint = direction.startPoint
        gradient.endPoint = direction.endPoint
        gradient.frame = self.bounds
        gradient.colors = colors
        return gradient
    }
}
