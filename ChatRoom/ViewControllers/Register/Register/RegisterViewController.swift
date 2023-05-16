//
//  RegisterController.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/4/26.
//

import UIKit
import RxSwift

class RegisterController: RegisterBaseVC<RegisterControllerVM> {
    
    private lazy var infoStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.spacing = 0
        return stackView
    }()
    
    private lazy var accountInput: MultipleRulesInputView = {
        let lbl = MultipleRulesInputView(with: self.viewModel.accountInputVM)
        return lbl
    }()

    private lazy var passwordInput: MultipleRulesInputView = {
        let lbl = MultipleRulesInputView(with: self.viewModel.passwordInputVM)
        return lbl
    }()

    private lazy var confirmPwdInput: MultipleRulesInputView = {
        let lbl = MultipleRulesInputView(with: self.viewModel.confirmPwdInputVM)
        return lbl
    }()

    private lazy var nicknameInput: MultipleRulesInputView = {
        let lbl = MultipleRulesInputView(with: self.viewModel.nicknameInputVM)
        return lbl
    }()
    
    private lazy var socialAccountInput: MultipleRulesInputView = {
        let lbl = MultipleRulesInputView(with: self.viewModel.socialAccountInputVM)
        return lbl
    }()
    
    private lazy var inviteCodeInput: MultipleRulesInputView = {
        let lbl = MultipleRulesInputView(with: self.viewModel.inviteCodeInputVM)
        return lbl
    }()
    
    static func initVC(with vm: RegisterControllerVM) -> RegisterController {
        let vc = RegisterController()
        vc.backTitle = .cancel
        vc.title = Localizable.register
        vc.viewModel = vm
        return vc
    }

    override func setupViews() {
        super.setupViews()
        
        self.view.addSubview(self.infoStackView)
        self.infoStackView.addArrangedSubviews([accountInput, passwordInput, confirmPwdInput, nicknameInput, inviteCodeInput])

        self.infoStackView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(16)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        self.accountInput.snp.makeConstraints { (make) in
            make.height.greaterThanOrEqualTo(48)
        }

        self.passwordInput.snp.makeConstraints { (make) in
            make.height.greaterThanOrEqualTo(48)
        }

        self.confirmPwdInput.snp.makeConstraints { (make) in
            make.height.greaterThanOrEqualTo(48)
        }

        self.nicknameInput.snp.makeConstraints { (make) in
            make.height.greaterThanOrEqualTo(48)
        }

        self.inviteCodeInput.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(48)
        }
        
        self.nextButton.setTitle(Localizable.register, for: .normal)
        self.nextButton.snp.makeConstraints { (make) in
            make.top.equalTo(infoStackView.snp.bottom).offset(32)
            make.leading.trailing.equalTo(infoStackView)
            make.height.equalTo(48)
        }
    }

    override func initBinding() {
        super.initBinding()

        self.nextButton.rx.controlEvent(.touchUpInside).throttle(.seconds(2), scheduler: MainScheduler.instance).subscribeSuccess { [unowned self] in
            self.viewModel.checkAccount()
        }.disposed(by: self.disposeBag)
        
        self.viewModel.goSetProfile.subscribeSuccess { [unowned self] _ in
            let vm = SetAvatarViewControllerVM()
            self.navigator.show(scene: .setAvatar(vm: vm), sender: self, transition: .present(animated: false, style: .fullScreen))
        }.disposed(by: self.disposeBag)
        
        self.viewModel.showSocialAccount.subscribeSuccess { [unowned self] needShow in
            if needShow {
                self.socialAccountInput.snp.makeConstraints { make in
                    make.height.greaterThanOrEqualTo(48)
                }
                infoStackView.insertArrangedSubview(socialAccountInput, at: self.infoStackView.subviews.count - 1)
            }
        }.disposed(by: disposeBag)
        
        self.viewModel.showError
            .bind { [weak self] errorMsg in
                self?.showAlert(title: "", message: errorMsg, comfirmBtnTitle: Localizable.sure)
            }.disposed(by: disposeBag)
    }

    @objc override func popViewController() {
        self.navigationController?.popBack(toControllerType: PhoneVerifyViewController.self)
    }
}
