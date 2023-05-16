//
//  ProgressCancelButton.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/6/22.
//

import UIKit
import QuartzCore

struct ProgressConfig {
    let progressLineColor: CGColor = Theme.c_09_white.rawValue.toCGColor()
    let cancelImageName: String = "iconIconCross"
    let backgroundImageName: String = "background"
    let size = CGSize.init(width: 48, height: 48)
    let radius: CGFloat = 24
    let duration: Double = 0.25
}

class ProgressCancelButton: UIButton {
    
    private(set) var fraction: Double = 0.0
    private(set) var config: ProgressConfig
    private let progressLayer = CAShapeLayer()
    
    init(config: ProgressConfig = ProgressConfig()) {
        self.config = config
        super.init(frame: CGRect.init(origin: .zero, size: config.size))
        
        self.backgroundColor = .clear
        self.layer.cornerRadius = config.radius
        self.clipsToBounds = true
        self.setBackgroundImage(UIImage.init(named: config.backgroundImageName), for: .normal)
        self.setImage(UIImage.init(named: config.cancelImageName), for: .normal)
        self.imageView?.theme_tintColor = Theme.c_09_white.rawValue
        self.initProgressLayer()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /**
     更新 progress fraction from self.fraction to fractionCompleted (0~1)
     - Parameter fractionCompleted: 已完成上傳的進度 (0.0~1.0)
     */
    func updateFractionCompleted(_ fractionCompleted: Double?) {
        guard let fractionCompleted = fractionCompleted else {
            return
        }
        self.isHidden = false
        self.setProgress(fractionCompleted, animated: true) {
            self.isHidden = true
        }
    }
    
    /**
     重設 fractionCompleted to zero
     */
    func resetFractionCompleted() {
        self.isHidden = true
        self.fraction = 0
        self.setProgress(0, animated: false)
    }

    /**
     設定 progress from self.fraction to 1.0 (finished)
     */
    func fractionCompleted(completion: (() -> Void)?) {
        fraction = 1.0
        self.setProgress(1.0, animated: true) {
            self.isHidden = true
            completion?()
        }
    }
    
}

private extension ProgressCancelButton {
    
    func initProgressLayer() {
        let aDegree = CGFloat.pi / 180
        let lineWidth: CGFloat = 2
        let startDegree: CGFloat = 270
        let radius: CGFloat = self.config.radius - 1
        let path = UIBezierPath(arcCenter: CGPoint(x: bounds.midX, y: bounds.midY),
                                radius: radius,
                                startAngle: aDegree * startDegree,
                                endAngle: aDegree * (startDegree + 360),
                                clockwise: true)

        self.progressLayer.frame = bounds
        self.progressLayer.fillColor = UIColor.clear.cgColor
        self.progressLayer.strokeColor = self.config.progressLineColor
        self.progressLayer.lineWidth = lineWidth
        self.progressLayer.path = path.cgPath
        self.progressLayer.strokeStart = 0
        self.progressLayer.strokeEnd = 0
        layer.addSublayer(self.progressLayer)
    }
    
    func setProgress(_ fraction: Double, animated: Bool, completion: (() -> Void)? = nil) {
        let duration: Double = (1.0 - fraction) * 3.0
        self.fraction = fraction
        self.setProgress(fraction, animated: animated, withDuration: duration) {
            completion?()
        }
    }
    
    func setProgress(_ fraction: CGFloat, animated: Bool, withDuration duration: Double, completion: (() -> Void)?) {
        CATransaction.begin()
        CATransaction.setDisableActions(!animated)
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.duration = duration
        animation.fromValue = fraction
        animation.toValue = 1
        self.progressLayer.strokeEnd = 1.0
        CATransaction.setCompletionBlock {
            completion?()
        }
        self.progressLayer.add(animation, forKey: "animateCircle")
        CATransaction.commit()
    }
}
