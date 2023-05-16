//
//  ForgotPasswordViewController.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/4/22.
//

import UIKit

class ForgotPasswordViewController: ReachableViewController<ForgotPasswordViewControllerVM> {
    
    private lazy var lblTitle: UILabel = {
        let lbl = UILabel.init()
        lbl.textAlignment = .left
        lbl.font = .boldParagraphGiantLeft
        lbl.text = Localizable.inputRegisterPhoneNumber
        return lbl
    }()
    
    private lazy var regionInput: TitleInputView = {
        let view = TitleInputView.init(with: self.viewModel.regionInputViewModel)
        return view
    }()
    
    private lazy var phoneNumberInput: PhoneInputView = {
        let lbl = PhoneInputView.init(with: self.viewModel.phoneInputViewModel)
        return lbl
    }()
    
    private lazy var verificationCodeInput: VerificationCodeInputView = {
        let lbl = VerificationCodeInputView.init(with: self.viewModel.verificationCodeInputViewModel)
        return lbl
    }()
    
    private lazy var lblHint: UILabel = {
        let lbl = UILabel.init()
        lbl.font = .regularParagraphMediumLeft
        lbl.theme_textColor = Theme.c_07_neutral_400.rawValue
        lbl.numberOfLines = 0
        lbl.text = Localizable.forgetPasswordHint
        return lbl
    }()
    
    private lazy var btnSubmin: UIButton = {
        let btn = UIButton.init()
        btn.layer.cornerRadius = 4
        btn.theme_backgroundColor = Theme.c_07_neutral_200.rawValue
        btn.theme_setTitleColor(Theme.c_09_white.rawValue, forState: .normal)
        btn.setTitle(Localizable.next, for: .normal)
        btn.titleLabel?.font = .boldParagraphMediumLeft
        return btn
    }()
    
    static func initVC(with vm: ForgotPasswordViewControllerVM) -> ForgotPasswordViewController {
        let vc = ForgotPasswordViewController.init()
        vc.backTitle = .cancel
        vc.title = Localizable.forgetPassword
        vc.viewModel = vm
        return vc
    }
    
    override func initBinding() {
        super.initBinding()
        
        self.btnSubmin.rx.controlEvent(.touchUpInside).subscribeSuccess { [unowned self] _ in
            self.viewModel.recoveryAccount()
        }.disposed(by: self.disposeBag)
        
        self.viewModel.regionInputViewModel.touchInputAction.subscribeSuccess { [unowned self] _ in
            self.navigator.show(scene: .selectRegion(vm: self.viewModel.regionSelectVM), sender: self)
        }.disposed(by: self.disposeBag)
        
        self.viewModel.submitEnable.bind(to: self.btnSubmin.rx.isEnabled).disposed(by: self.disposeBag)
        self.viewModel.submitEnable.distinctUntilChanged().subscribeSuccess { [unowned self] enable in
            self.btnSubmin.theme_backgroundColor = enable ? Theme.c_01_primary_400.rawValue : Theme.c_07_neutral_200.rawValue
        }.disposed(by: self.disposeBag)
        
        self.viewModel.phoneInputViewModel.output.correct.distinctUntilChanged().bind(to: self.verificationCodeInput.rx.isUserInteractionEnabled).disposed(by: self.disposeBag)
        self.viewModel.errorMessage.subscribeSuccess { [unowned self] (message) in
            self.showAlert(message: message, comfirmBtnTitle: Localizable.sure)
        }.disposed(by: self.disposeBag)
        
        self.viewModel.resetBy.subscribeSuccess { [unowned self] token in
            let vm = SetupNewPasswordViewControllerVM.init(phone: self.viewModel.getPhoneTitle(),
                                                           countryCode: self.viewModel.getCurrentCountryCode(),
                                                           access: token)
            vm.shouldReload.bind(to: viewModel.shouldReload).disposed(by: disposeBag)
            self.navigator.show(scene: .setupPassword(vm: vm), sender: self)
        }.disposed(by: self.disposeBag)
        
        self.viewModel.showLoading.subscribeSuccess { show in
            show ? LoadingView.shared.show() : LoadingView.shared.hide()
        }.disposed(by: self.disposeBag)
    }
    
    override func setupViews() {
        super.setupViews()
        self.view.theme_backgroundColor = Theme.c_07_neutral_50.rawValue
        
        self.view.addSubview(self.lblTitle)
        self.view.addSubview(self.regionInput)
        self.view.addSubview(self.phoneNumberInput)
        self.view.addSubview(self.verificationCodeInput)
        self.view.addSubview(self.lblHint)
        self.view.addSubview(self.btnSubmin)
        
        self.lblTitle.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(16)
            make.leading.equalToSuperview().offset(16)
            make.height.equalTo(28)
        }
        
        self.regionInput.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.top.equalTo(self.lblTitle.snp.bottom).offset(32)
        }
        
        self.phoneNumberInput.snp.makeConstraints { (make) in
            make.leading.trailing.equalTo(self.regionInput)
            make.top.equalTo(self.regionInput.snp.bottom).offset(10)
        }
        
        self.verificationCodeInput.snp.makeConstraints { (make) in
            make.leading.trailing.equalTo(self.regionInput)
            make.top.equalTo(self.phoneNumberInput.snp.bottom).offset(10)
        }
        
        self.lblHint.snp.makeConstraints { (make) in
            make.leading.trailing.equalTo(self.regionInput)
            make.top.equalTo(self.verificationCodeInput.snp.bottom).offset(16)
        }
        
        self.btnSubmin.snp.makeConstraints { (make) in
            make.leading.trailing.equalTo(self.regionInput)
            make.top.equalTo(self.lblHint.snp.bottom).offset(32)
            make.height.equalTo(48)
        }
    }
}
