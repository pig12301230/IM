//
//  ToastView.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/5/19.
//

import UIKit
import RxSwift

class ToastView: BaseViewModelView<ToastViewVM> {
    
    private lazy var infoIcon: UIImageView = {
        let imgView = UIImageView()
        imgView.contentMode = .scaleAspectFit
        return imgView
    }()

    private lazy var hint: UILabel = {
        let label = UILabel()
        label.font = .regularParagraphMediumLeft
        label.theme_textColor = Theme.c_09_white.rawValue
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    override func setupViews() {
        self.theme_backgroundColor = Theme.c_08_black_75.rawValue
        self.layer.cornerRadius = 4
        self.clipsToBounds = true
        
        self.addSubview(hint)
    }

    override func bindViewModel() {
        super.bindViewModel()
        
        self.viewModel.toastType.observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] type in
            if type == .message {
                self.infoIcon.stopAnimating()
                self.setupViewOnlyMessage()
            } else {
                self.setupViewWithImage()
            }
        }.disposed(by: self.disposeBag)
        
        self.viewModel.iconImage.bind(to: self.infoIcon.rx.image).disposed(by: self.disposeBag)
        self.viewModel.iconGif.subscribeSuccess { [unowned self] images in
            self.infoIcon.animationImages = images
            self.infoIcon.startAnimating()
        }.disposed(by: self.disposeBag)
        self.viewModel.hint.bind(to: self.hint.rx.text).disposed(by: self.disposeBag)
    }
    
    private func setupViewOnlyMessage() {
        
        self.hint.snp.remakeConstraints { make in
            make.center.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(8)
            make.width.equalTo(self.viewModel.toastSize.width - 32)
            make.height.equalTo(self.viewModel.toastSize.height - 16)
        }
    }
    
    private func setupViewWithImage() {
        self.infoIcon.removeFromSuperview()
        self.addSubview(self.infoIcon)
        
        self.infoIcon.snp.remakeConstraints { make in
            make.top.greaterThanOrEqualTo(16)
            make.top.lessThanOrEqualTo(28)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(40)
        }

        self.hint.snp.remakeConstraints { make in
            make.top.equalTo(self.infoIcon.snp.bottom).offset(4)
            make.leading.equalToSuperview().offset(8)
            make.centerX.equalToSuperview()
            make.bottom.greaterThanOrEqualTo(-28)
            make.bottom.lessThanOrEqualTo(-16)
        }
    }
}
