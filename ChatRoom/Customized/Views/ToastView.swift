//
//  ToastView.swift
//  LibPlatform
//
//  Created by ZoeLin on 2021/3/2.
//

import UIKit

#warning("Has to modify as Chat style")
public class ToastView {

    static func showSuccessToast(message: String = "", duration: TimeInterval = 1.0, completion: (() -> Void)? = nil) {
        guard let superView = UIApplication.shared.keyWindow else {
            return
        }
        let bgView = UIView()
        bgView.backgroundColor = .clear
        superView.addSubview(bgView)
        bgView.snp.makeConstraints { (maker) in
            maker.top.bottom.left.right.equalTo(superView)
        }

        let toastView = UIView()
        toastView.layer.cornerRadius = 8
//        toastView.backgroundColor = .brandColorNormalBlack_80
        bgView.addSubview(toastView)
        toastView.snp.makeConstraints { (maker) in
            maker.width.height.equalTo(140)
            maker.centerX.equalTo(superView)
            maker.top.equalTo(superView).offset(superView.frame.height / 667 * 208)
        }

        let imageView = UIImageView()
//        imageView.image = UIImage(name: "icon_exclamation")
//        imageView.tintColor = .brandColorNormalWhite
        toastView.addSubview(imageView)
        imageView.snp.makeConstraints { (maker) in
            maker.width.height.equalTo(45)
            maker.centerX.equalTo(toastView)
            maker.top.equalTo(toastView).offset(32)
        }

        let label = UILabel()
        label.text = message
//        label.font = .cRegularSize13Center
//        label.textColor = .brandColorNormalWhite
        toastView.addSubview(label)
        label.snp.makeConstraints { (maker) in
            maker.height.equalTo(13)
            maker.centerX.equalTo(toastView)
            maker.bottom.equalTo(toastView).offset(-31)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            UIView.animate(withDuration: 0.5, animations: { toastView.alpha = 0 }, completion: { _ in
                bgView.removeFromSuperview()
                completion?()
            })
        }
    }

    static func showWarningToast(message: String = "", duration: TimeInterval = 1.0, completion: (() -> Void)? = nil) {
        guard let superView = UIApplication.shared.keyWindow else {
            return
        }
        let bgView = UIView()
        bgView.backgroundColor = .clear
        superView.addSubview(bgView)
        bgView.snp.makeConstraints { (maker) in
            maker.top.bottom.left.right.equalTo(superView)
        }

        let toastView = UIView()
        toastView.layer.cornerRadius = 8
//        toastView.backgroundColor = .brandColorNormalBlack_80
        bgView.addSubview(toastView)
        toastView.snp.makeConstraints { (maker) in
            maker.width.height.equalTo(140)
            maker.centerX.equalTo(superView)
            maker.top.equalTo(superView).offset(superView.frame.height / 667 * 208)
        }

        let imageView = UIImageView()
//        imageView.image = UIImage(name: "icon_exclamation_1")
//        imageView.tintColor = .brandColorNormalWhite
        toastView.addSubview(imageView)
        imageView.snp.makeConstraints { (maker) in
            maker.width.height.equalTo(60)
            maker.centerX.equalTo(toastView)
            maker.top.equalTo(toastView).offset(24)
        }

        let label = UILabel()
        label.text = message
//        label.font = .cRegularSize13Center
//        label.textColor = .brandColorNormalWhite
        toastView.addSubview(label)
        label.snp.makeConstraints { (maker) in
            maker.height.equalTo(20)
            maker.centerX.equalTo(toastView)
            maker.bottom.equalTo(toastView).offset(-24)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            UIView.animate(withDuration: 0.5, animations: { toastView.alpha = 0 }, completion: {_ in 
                bgView.removeFromSuperview()
                completion?()
            })
        }
    }
}
