//
//  SetupNewPasswordViewController.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/4/23.
//

import UIKit

class SetupNewPasswordViewController: ReachableViewController<SetupNewPasswordViewControllerVM> {
    
    private lazy var lblTitle: UILabel = {
        let lbl = UILabel.init()
        lbl.textAlignment = .left
        lbl.font = .boldParagraphGiantLeft
        return lbl
    }()
    
    private lazy var passwordInput: MultipleRulesInputView = {
        let lbl = MultipleRulesInputView.init(with: self.viewModel.passwordInputViewModel)
        return lbl
    }()
    
    private lazy var confirmPasswordInput: MultipleRulesInputView = {
        let lbl = MultipleRulesInputView.init(with: self.viewModel.confirmPasswordInputViewModel)
        return lbl
    }()
    
    private lazy var btnSubmin: UIButton = {
        let btn = UIButton.init()
        btn.layer.cornerRadius = 4
        btn.theme_backgroundColor = Theme.c_07_neutral_200.rawValue
        btn.theme_setTitleColor(Theme.c_09_white.rawValue, forState: .normal)
        btn.setTitle(Localizable.resetPassword, for: .normal)
        btn.titleLabel?.font = .boldParagraphMediumLeft
        return btn
    }()
    
    static func initVC(with vm: SetupNewPasswordViewControllerVM) -> SetupNewPasswordViewController {
        let vc = SetupNewPasswordViewController.init()
        vc.backTitle = .cancel
        vc.title = Localizable.forgetPassword
        vc.viewModel = vm
        return vc
    }
    
    @objc override func popViewController() {
        guard self.navigator.pop(sender: self, to: LoginViewController.self) else {
            super.popViewController()
            return
        }
    }
    
    override func setupViews() {
        super.setupViews()
        self.view.theme_backgroundColor = Theme.c_07_neutral_50.rawValue
        self.view.addSubview(self.lblTitle)
        self.view.addSubview(self.passwordInput)
        self.view.addSubview(self.confirmPasswordInput)
        self.view.addSubview(self.btnSubmin)
        
        self.lblTitle.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(16)
            make.leading.equalToSuperview().offset(16)
            make.height.equalTo(28)
        }
        
        self.passwordInput.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.top.equalTo(self.lblTitle.snp.bottom).offset(32)
        }
        
        self.confirmPasswordInput.snp.makeConstraints { (make) in
            make.leading.trailing.equalTo(self.passwordInput)
            make.top.equalTo(self.passwordInput.snp.bottom).offset(10)
        }
        
        self.btnSubmin.snp.makeConstraints { (make) in
            make.leading.trailing.equalTo(self.passwordInput)
            make.top.equalTo(self.confirmPasswordInput.snp.bottom).offset(32)
            make.height.equalTo(48)
        }
        
        self.lblTitle.text = self.viewModel.phoneNumber
    }
    
    override func initBinding() {
        super.initBinding()
        
        self.viewModel.submitEnable.bind(to: self.btnSubmin.rx.isEnabled).disposed(by: self.disposeBag)
        self.viewModel.submitEnable.distinctUntilChanged().subscribeSuccess { [unowned self] enable in
            self.btnSubmin.theme_backgroundColor = enable ? Theme.c_01_primary_400.rawValue : Theme.c_07_neutral_200.rawValue
        }.disposed(by: self.disposeBag)
        
        self.viewModel.alertMessage.subscribeSuccess { [unowned self] (message) in
            self.showAlertAndBackToLogin(message: message)
        }.disposed(by: self.disposeBag)
        
        self.btnSubmin.rx.controlEvent(.touchUpInside).subscribeSuccess { [unowned self] _ in
            self.viewModel.resetPassword()
        }.disposed(by: self.disposeBag)
        
        self.viewModel.showLoading.subscribeSuccess { show in
            show ? LoadingView.shared.show() : LoadingView.shared.hide()
        }.disposed(by: self.disposeBag)
    }
}

private extension SetupNewPasswordViewController {
    func showAlertAndBackToLogin(message: String) {
        self.showAlert(message: message, comfirmBtnTitle: Localizable.sure, onConfirm: {
            self.navigator.pop(sender: self, to: LoginViewController.self, animated: true)
        })
    }
    
    func showErrorAlert(message: String) {
        self.showAlert(message: message, comfirmBtnTitle: Localizable.sure)
    }
}
