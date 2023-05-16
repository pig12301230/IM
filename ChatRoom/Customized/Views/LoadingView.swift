//
//  LoadingView.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/5/10.
//

import UIKit
import Lottie

class LoadingView: UIView {

    static let shared: LoadingView = {
        let view = LoadingView(frame: UIScreen.main.bounds)
        view.isHidden = true
        return view
    }()

    private lazy var animation: AnimationView = {
        let view = AnimationView(name: AppConfig.Info.loadingFileName)
        view.loopMode = .loop
        return view
    }()

    private var refCount = 0

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        self.frame = UIScreen.main.bounds
        self.theme_backgroundColor = Theme.c_08_black_25.rawValue
        self.isHidden = true

        self.addSubview(animation)

        animation.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.height.equalTo(96)
        }

        appDelegate?.window?.addSubview(self)
    }

    func show() {
        self.refCount += 1
        guard self.refCount <= 1 else {
            return
        }
        self.animation.play()
        self.isHidden = false
        appDelegate?.window?.bringSubviewToFront(self)
    }

    func hide() {
        self.refCount -= 1
        guard self.refCount <= 0 else {
            return
        }
        self.animation.stop()
        self.isHidden = true
        self.refCount = 0
    }
}
