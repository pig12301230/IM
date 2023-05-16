//
//  Toast.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/5/19.
//

import UIKit

class ToastManager {

    private var toast: Toast?

    /**
     顯示Toast

     - Parameters:
        - iconName: Toast上的icon(圖片)
        - hint: Toast上的文字
        - config: Toast顯示設定
     */
    func showToast(iconName: String, hint: String, config: Toast.ToastConfig = Toast.ToastConfig(), completion: (() -> Void)? = nil) {
        guard let image = UIImage.init(named: iconName) else {
            return
        }
        
        if self.toast == nil {
            self.toast = Toast(icon: image, hint: hint, config: config)
            self.toast?.show()
        } else {
            self.toast?.update(icon: image, hint: hint, config: config)
        }
        self.toast?.finished = { [weak self] in
            completion?()
            self?.toast = nil
        }
    }
    
    /**
     顯示Toast

     - Parameters:
        - icon: Toast上的icon(圖片)
        - hint: Toast上的文字
        - config: Toast顯示設定
        - completion: 完成後事件
     */
    func showToast(icon: UIImage, hint: String, config: Toast.ToastConfig = Toast.ToastConfig(), completion: (() -> Void)? = nil) {
        if self.toast == nil {
            self.toast = Toast(icon: icon, hint: hint, config: config)
            self.toast?.show()
        } else {
            self.toast?.update(icon: icon, hint: hint, config: config)
        }
        self.toast?.finished = { [weak self] in
            completion?()
            self?.toast = nil
        }
    }

    /**
     顯示Toast

     - Parameters:
        - icons: Toast上的icon(GIF動畫)
        - hint: Toast上的文字
        - config: Toast顯示設定
     */
    func showToast(icons: [UIImage], hint: String, config: Toast.ToastConfig = Toast.ToastConfig(), completion: (() -> Void)? = nil) {
        if self.toast == nil {
            self.toast = Toast(icons: icons, hint: hint, config: config)
            self.toast?.show()
        } else {
            self.toast?.update(icons: icons, hint: hint, config: config)
        }
        self.toast?.finished = { [weak self] in
            completion?()
            self?.toast = nil
        }
    }
    
    /**
     顯示純文字Toast

     - Parameters:
        - hint: Toast上的文字
        - config: Toast顯示設定
     */
    func showToast(hint: String, config: Toast.ToastConfig = Toast.ToastConfig(), completion: (() -> Void)? = nil) {
        if self.toast == nil {
            self.toast = Toast(hint: hint, config: config)
            self.toast?.show()
        } else {
            self.toast?.update(hint: hint, config: config)
        }
        self.toast?.finished = { [weak self] in
            completion?()
            self?.toast = nil
        }
    }

    func showToast(message: String, config: Toast.ToastConfig = Toast.ToastConfig(), completion: (() -> Void)? = nil) {
        if self.toast == nil {
            self.toast = Toast(message: message, config: config)
            self.toast?.showMessageToast(message: message)
        } else {
            self.toast?.update(message: message, config: config)
        }
        self.toast?.finished = { [weak self] in
            completion?()
            self?.toast = nil
        }
    }
    
    /**
     隱藏Toast

     - Parameters:
        - afterDelay: 是否要等delay之後再hide Toast
        - hideDuration: 設置隱藏動畫duration
     */
    func hideToast(afterDelay: Bool, hideDuration: TimeInterval) {
        guard self.toast != nil else {
            return
        }
        self.toast?.config.hideDuration = hideDuration
        afterDelay ? self.toast?.delayThenHide() : self.toast?.hide()
        self.toast?.finished = { [weak self] in
            self?.toast = nil
        }
    }
}

class Toast {

    enum DismissMode {
        case none, auto
    }

    struct ToastConfig {
        var delayTime: TimeInterval = 1.0
        var showDuration: TimeInterval = 0.2
        var hideDuration: TimeInterval = 0.5
        var dismissMode: DismissMode = .auto
    }

    var config = ToastConfig()
    var finished: (() -> Void)?

    private var toastView: ToastView?
    private var delayTimer: Timer?

    init(icon: UIImage, hint: String, config: ToastConfig = ToastConfig()) {
        let vm = ToastViewVM(size: CGSize.init(width: AppConfig.Screen.screenWidth - 64, height: AppConfig.Screen.screenHeight - 32), icon: icon, hint: hint)
        let toastView = ToastView(with: vm)
        toastView.alpha = 0
        self.toastView = toastView
        self.config = config
    }

    init(icons: [UIImage], hint: String, config: ToastConfig = ToastConfig()) {
        let vm = ToastViewVM(size: CGSize.init(width: AppConfig.Screen.screenWidth - 64, height: AppConfig.Screen.screenHeight - 32), icons: icons, hint: hint)
        let toastView = ToastView(with: vm)
        toastView.alpha = 0
        self.toastView = toastView
        self.config = config
    }
    
    init(hint: String, config: ToastConfig = ToastConfig()) {
        let vm = ToastViewVM(size: CGSize.init(width: AppConfig.Screen.mainFrameWidth - 64, height: AppConfig.Screen.mainFrameHeight - 32), hint: hint)
        let toastView = ToastView(with: vm)
        toastView.alpha = 0
        self.toastView = toastView
        self.config = config
    }

    init(message: String, config: ToastConfig = ToastConfig()) {
        let vm = ToastViewVM(message: message)
        let toastView = MessageToastView(with: vm)
        toastView.alpha = 0
        self.toastView = toastView
        self.config = config
    }
    
    func update(icon: UIImage, hint: String, config: ToastConfig = ToastConfig()) {
        self.toastView?.viewModel.updateView(icon: icon, hint: hint)
        self.config = config
        self.updateToastViewLayout()
        self.delayThenHide()
    }

    func update(icons: [UIImage], hint: String, config: ToastConfig = ToastConfig()) {
        self.toastView?.viewModel.updateView(icons: icons, hint: hint)
        self.config = config
        self.updateToastViewLayout()
        self.delayThenHide()
    }
    
    func update(hint: String, config: ToastConfig = ToastConfig()) {
        self.toastView?.layer.removeAllAnimations()
        self.toastView?.viewModel.updateView(hint: hint)
        self.config = config
        self.updateToastViewLayout()
        self.delayThenHide()
    }
    
    func update(message: String, config: ToastConfig = ToastConfig()) {
        self.toastView?.viewModel.updateView(message: message)
        self.config = config
        
        self.delayThenHide()
    }

    private func resetTimer() {
        self.delayTimer?.invalidate()
        self.delayTimer = nil
    }

    func show(completion: (() -> Void)? = nil) {
        guard let superView = appDelegate?.window, let toast = self.toastView else {
            return
        }
        
        superView.addSubview(toast)
        self.updateToastViewLayout()

        UIView.animate(withDuration: self.config.showDuration, delay: 0, options: .curveEaseIn) {
            toast.alpha = 1
        } completion: { [weak self] _ in
            guard self?.config.dismissMode == .auto else {
                return
            }
            self?.delayThenHide()
        }
    }
    
    private func updateToastViewLayout() {
        guard let toast = self.toastView else {
            return
        }
        
        toast.snp.remakeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(toast.viewModel.toastSize.width)
            make.height.equalTo(toast.viewModel.toastSize.height)
        }
    }
    
    func showMessageToast(message: String, completion: (() -> Void)? = nil) {
        guard let superView = appDelegate?.window, let toast = self.toastView else { return }
        superView.addSubview(toast)
        
        toast.snp.makeConstraints {
            $0.center.equalToSuperview()
            var width = min(message.width(height: 20,
                                          font: .regularParagraphMediumLeft) + 32, // 32: padding
                            AppConfig.Screen.mainFrameWidth)
            width = max(120, width) // 最小寬度120
            $0.width.equalTo(width)
            $0.height.equalTo(message.height(width: width,
                                             font: .regularParagraphMediumLeft) + 16) // 16: padding
        }
        
        UIView.animate(withDuration: self.config.showDuration,
                       delay: 0,
                       options: .curveEaseIn) {
            toast.alpha = 1
        } completion: { [weak self] _ in
            guard self?.config.dismissMode == .auto else {
                return
            }
            self?.delayThenHide()
        }
    }

    func delayThenHide() {
        self.resetTimer()

        let timer = Timer(timeInterval: self.config.delayTime, target: self, selector: #selector(self.hide), userInfo: nil, repeats: false)
        RunLoop.main.add(timer, forMode: .common)
        self.delayTimer = timer
    }

    @objc func hide() {
        guard let toast = self.toastView else {
            return
        }

        UIView.animate(withDuration: self.config.hideDuration) {
            toast.alpha = 0
        } completion: { [weak self] _ in
            guard let self = self else { return }
            toast.removeFromSuperview()
            self.toastView = nil
            self.resetTimer()
            self.finished?()
        }
    }
}
