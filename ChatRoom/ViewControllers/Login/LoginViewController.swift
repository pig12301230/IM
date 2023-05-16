//
//  LoginViewController.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/4/15.
//

import UIKit

class LoginViewController: ReachableViewController<LoginViewControllerVM> {
    
    private lazy var lblTitle: UILabel = {
        let lbl = UILabel.init()
        lbl.textAlignment = .left
        lbl.font = .boldParagraphGiantLeft
        lbl.text = Localizable.loginWithCellphoneNumbers
        return lbl
    }()
    
    private lazy var phoneNumberInput: PhoneInputView = {
        let lbl = PhoneInputView.init(with: self.viewModel.phoneInputViewModel)
        return lbl
    }()
    
    private lazy var passwordInput: MultipleRulesInputView = {
        let lbl = MultipleRulesInputView.init(with: self.viewModel.passwordInputViewModel)
        return lbl
    }()

    private lazy var regionInput: TitleInputView = {
        let view = TitleInputView.init(with: self.viewModel.regionInputViewModel)
        return view
    }()
    
    private lazy var btnRemember: UIButton = {
        let btn = UIButton.init(type: .custom)
        btn.theme_setTitleColor(Theme.c_10_grand_2.rawValue, forState: .normal)
        btn.setTitle(Localizable.rememberAccount, for: .normal)
        btn.titleLabel?.font = .regularParagraphLargeLeft
        btn.titleEdgeInsets = UIEdgeInsets.init(top: 0, left: 8, bottom: 0, right: 0)
        return btn
    }()
    
    private lazy var btnSubmin: UIButton = {
        let btn = UIButton.init()
        btn.layer.cornerRadius = 4
        btn.theme_backgroundColor = Theme.c_07_neutral_200.rawValue
        btn.theme_setTitleColor(Theme.c_09_white.rawValue, forState: .normal)
        btn.setTitle(Localizable.login, for: .normal)
        btn.titleLabel?.font = .boldParagraphMediumLeft
        return btn
    }()
    
    private lazy var btnForgotPassword: UIButton = {
        let btn = UIButton.init()
        btn.theme_setTitleColor(Theme.c_01_primary_0_500.rawValue, forState: .normal)
        btn.setTitle(Localizable.forgetPassword, for: .normal)
        btn.titleLabel?.font = .boldParagraphSmallLeft
        return btn
    }()
    
    static func initVC(with vm: LoginViewControllerVM) -> LoginViewController {
        let vc = LoginViewController.init()
        vc.backTitle = .cancel
        vc.title = Localizable.login
        vc.viewModel = vm
        return vc
    }
    
    override func initBinding() {
        super.initBinding()
        
        self.viewModel.regionInputViewModel.touchInputAction.subscribeSuccess { [unowned self] _ in
            self.navigator.show(scene: .selectRegion(vm: self.viewModel.regionSelectVM), sender: self)
        }.disposed(by: self.disposeBag)
        
        self.viewModel.submitEnable.bind(to: self.btnSubmin.rx.isEnabled).disposed(by: self.disposeBag)
        self.viewModel.submitEnable.distinctUntilChanged().subscribeSuccess { (enable) in
            self.btnSubmin.theme_backgroundColor = enable ? Theme.c_01_primary_400.rawValue : Theme.c_07_neutral_200.rawValue
        }.disposed(by: self.disposeBag)
        
        self.viewModel.loginSuccess.subscribeSuccess { [unowned self] in
            guard let window = appDelegate?.window else { return }
            let mainVM = MainTabBarControllerVM.init(withStock: true)
            self.navigator.show(scene: .mainTabBar(vm: mainVM), sender: self, transition: .root(in: window, duration: 0))
            PushManager.shared.registerPushNotification()
        }.disposed(by: self.disposeBag)
        
        self.viewModel.rememberButtonImage.bind(to: self.btnRemember.rx.image()).disposed(by: self.disposeBag)
        
        self.btnSubmin.rx.controlEvent(.touchUpInside).bind(to: self.viewModel.submitLogin).disposed(by: self.disposeBag)
        
        self.btnForgotPassword.rx.controlEvent(.touchUpInside).subscribeSuccess { [unowned self] _ in
            let vm = ForgotPasswordViewControllerVM.init()
            vm.shouldReload.bind { self.viewModel.resetCountryInfo() }.disposed(by: disposeBag)
            self.navigator.show(scene: .forgotPassword(vm: vm), sender: self)
        }.disposed(by: self.disposeBag)
        
        self.btnRemember.rx.controlEvent(.touchUpInside).subscribeSuccess { [unowned self] _ in
            self.viewModel.changeRememberStatus()
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
        self.view.addSubview(self.passwordInput)
        self.view.addSubview(self.btnRemember)
        self.view.addSubview(self.btnSubmin)
        self.view.addSubview(self.btnForgotPassword)
        
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
        
        self.passwordInput.snp.makeConstraints { (make) in
            make.leading.trailing.equalTo(self.phoneNumberInput)
            make.top.equalTo(self.phoneNumberInput.snp.bottom).offset(10)
        }
        
        self.btnRemember.snp.makeConstraints { (make) in
            make.top.equalTo(self.passwordInput.snp.bottom).offset(16)
            make.leading.equalTo(self.passwordInput)
            make.width.equalTo(96)
            make.height.equalTo(24)
        }
        
        self.btnSubmin.snp.makeConstraints { (make) in
            make.top.equalTo(self.btnRemember.snp.bottom).offset(32)
            make.leading.trailing.equalTo(self.regionInput)
            make.height.equalTo(48)
        }
        
        self.setupForgotPassword()
    }
    
    func setupForgotPassword() {
        var bottomSafeArea: CGFloat = 16
        
        if let root = appDelegate?.window?.rootViewController {
            if #available(iOS 11.0, *) {
                bottomSafeArea += root.view.safeAreaInsets.bottom
            } else {
                bottomSafeArea += root.bottomLayoutGuide.length
            }
        }
        
        self.btnForgotPassword.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-bottomSafeArea)
        }
    }
}
