//
//  VerificationCodeInputView.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/4/22.
//

import UIKit
import RxSwift

class VerificationCodeInputView: TitleInputView<VerificationCodeInputViewModel> {
    
    override func setupViews() {
        self.btnStatus.titleLabel?.font = .boldParagraphSmallLeft
        self.addSubview(self.lblTitle)
        self.addSubview(self.inputTextField)
        self.addSubview(self.btnStatus)
        self.addSubview(self.separatorView)
        
        self.lblTitle.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(8)
            make.top.equalToSuperview().offset(12)
            make.height.equalTo(24)
            make.width.equalTo(96)
        }
        
        self.inputTextField.snp.makeConstraints { (make) in
            make.leading.equalTo(self.lblTitle.snp.trailing).offset(16)
            make.centerY.equalTo(self.lblTitle)
            make.width.equalTo(110)
        }
        
        self.btnStatus.snp.makeConstraints { (make) in
            make.leading.greaterThanOrEqualTo(self.inputTextField.snp.trailing)
            make.top.equalToSuperview().offset(-2)
            make.centerY.equalTo(self.inputTextField)
            make.trailing.equalToSuperview().offset(-8)
        }
        
        self.btnStatus.titleEdgeInsets = UIEdgeInsets.zero
        self.btnStatus.titleLabel?.textAlignment = .right
        
        self.setupSeparatorView()
        
        self.addGestureRecognizer(self.tapGesture)
    }
    
    override func bindViewModel() {
        super.bindViewModel()
        self.viewModel.btnTitle.subscribeSuccess { [unowned self] (text) in
            self.btnStatus.setTitle(text, for: .normal)
        }.disposed(by: self.disposeBag)
        
        self.viewModel.layoutStyleEnable.subscribeSuccess { [unowned self] enable in
            let color = enable ? Theme.c_01_primary_0_500.rawValue : Theme.c_07_neutral_400.rawValue
            self.btnStatus.theme_setTitleColor(color, forState: .normal)
        }.disposed(by: self.disposeBag)
        
        self.viewModel.isUserInteractionEnabled.bind(to: self.btnStatus.rx.isEnabled).disposed(by: self.disposeBag)
        
        self.btnStatus.rx.controlEvent(.touchUpInside).throttle(.seconds(2), scheduler: MainScheduler.instance).subscribeSuccess { [unowned self] _ in
            self.viewModel.doVerificationAction()
        }.disposed(by: self.disposeBag)
    }
    
    override func setupStatusImageView() {
        
    }
}
