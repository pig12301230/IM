//
//  SecurityInputView.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/4/16.
//

import UIKit

class SecurityInputView: FormInputView<SecurityInputViewModel> {
    private lazy var btnSecurity: UIButton = {
        let btn = UIButton.init()
        // TODO: setup for test
        btn.backgroundColor = .red
        return btn
    }()
    
    override func bindViewModel() {
        super.bindViewModel()
        
        self.viewModel.securityImage.bind(to: self.btnSecurity.rx.backgroundImage()).disposed(by: self.disposeBag)
        self.viewModel.isSecurity.bind(to: self.inputTextField.rx.isSecureTextEntry).disposed(by: self.disposeBag)
        
        self.btnSecurity.rx.controlEvent(.touchUpInside).bind(to: self.viewModel.changeSecurity).disposed(by: self.disposeBag)
    }
    
    override func updateViews() {
        super.updateViews()
        
        self.addSubview(self.btnSecurity)
        
        self.btnSecurity.snp.makeConstraints { (make) in
            make.height.width.equalTo(25)
            make.centerY.trailing.equalTo(self.inputTextField)
        }
    }
}
