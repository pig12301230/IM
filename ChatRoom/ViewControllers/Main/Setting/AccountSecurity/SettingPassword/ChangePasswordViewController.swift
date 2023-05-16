//
//  ChangePasswordViewController.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/7/29.
//

import UIKit
import RxSwift

class ChangePasswordViewController: BaseVC {
    
    private lazy var idTitleView: TitleInputView = {
        let view = TitleInputView.init(with: self.viewModel.userIDTitleViewModel)
        return view
    }()
    
    private lazy var originalPasswordInput: MultipleRulesInputView = {
        let lbl = MultipleRulesInputView.init(with: self.viewModel.originalInputViewModel)
        return lbl
    }()
    
    private lazy var newPasswordInput: MultipleRulesInputView = {
        let lbl = MultipleRulesInputView.init(with: self.viewModel.newPasswordInputViewModel)
        return lbl
    }()
    
    private lazy var confirmPasswordInput: MultipleRulesInputView = {
        let lbl = MultipleRulesInputView.init(with: self.viewModel.confirmPasswordInputViewModel)
        return lbl
    }()
    
    private lazy var lblHint: UILabel = {
        let lbl = UILabel.init()
        lbl.text = Localizable.resetPasswordHint
        lbl.theme_textColor = Theme.c_07_neutral_400.rawValue
        lbl.font = .regularParagraphMediumLeft
        lbl.numberOfLines = 0
        return lbl
    }()
    
    private lazy var btnForgetPassword: UIButton = {
        let btn = UIButton.init()
        btn.setTitle(Localizable.forgotOldPassword, for: .normal)
        btn.setTitleColor(Theme.c_03_tertiary_0_500.rawValue.toColor(), for: .normal)
        btn.titleLabel?.font = .regularParagraphLargeLeft
        return btn
    }()
    
    private lazy var btnSubmin: UIButton = {
        let btn = UIButton.init()
        btn.layer.cornerRadius = 4
        btn.theme_backgroundColor = Theme.c_07_neutral_200.rawValue
        btn.theme_setTitleColor(Theme.c_09_white_66.rawValue, forState: .disabled)
        btn.theme_setTitleColor(Theme.c_09_white.rawValue, forState: .normal)
        btn.setBackgroundColor(color: Theme.c_01_primary_400.rawValue.toColor(), forState: .normal)
        btn.setBackgroundColor(color: Theme.c_07_neutral_200.rawValue.toColor(), forState: .disabled)
        btn.setTitle(self.viewModel.changePasswordType.submitTitle, for: .normal)
        btn.titleLabel?.font = .boldParagraphMediumLeft
        return btn
    }()
    
    var viewModel: ChangePasswordViewControllerVM!
    
    static func initVC(with vm: ChangePasswordViewControllerVM) -> ChangePasswordViewController {
        let vc = ChangePasswordViewController.init()
        vc.viewModel = vm
        vc.backTitle = .custom("")
        vc.title = Localizable.settingGuPassword
        return vc
    }
    
    override func setupBackTitle(text: String) {
        switch self.viewModel.changePasswordType {
        case .withOldPassword:
            super.setupBackTitle(text: text)
        default:
            self.navigationItem.hidesBackButton = true
        }
    }
    
    override func setupViews() {
        super.setupViews()
        self.view.theme_backgroundColor = Theme.c_07_neutral_50.rawValue
        self.view.addSubview(self.idTitleView)
        self.view.addSubview(self.newPasswordInput)
        self.view.addSubview(self.confirmPasswordInput)
        self.view.addSubview(self.lblHint)
        self.view.addSubview(self.btnSubmin)
        
        switch self.viewModel.changePasswordType {
        case .withOldPassword:
            self.setupViewsWithOldPassword()
        case .withoutOldPassword:
            self.setupViewsWithoutOldPassword()
        }
    }
    
    override func initBinding() {
        super.initBinding()
        self.viewModel.output.submitEnable.bind(to: self.btnSubmin.rx.isEnabled).disposed(by: self.disposeBag)
        
        self.btnSubmin.rx.controlEvent(.touchUpInside).bind(to: self.viewModel.input.resetAction).disposed(by: self.disposeBag)
        self.btnForgetPassword.rx.controlEvent(.touchUpInside).bind(to: self.viewModel.input.forgotAction).disposed(by: self.disposeBag)
        
        self.viewModel.output.alertType.observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] noticeType in
            self.view.endEditing(true)
            self.showAlertNotice(with: noticeType)
        }.disposed(by: self.disposeBag)
        
        self.viewModel.output.gotoScene.observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] scene in
            switch scene {
            case .login:
                self.gotoViewController(locate: .login)
            default:
                self.navigator.show(scene: scene, sender: self)
            }
        }.disposed(by: self.disposeBag)
    }
    
    func showAlertNotice(with type: AlertNoticeType) {
        let config = DisplayConfig(font: .regularParagraphLargeCenter, textColor: Theme.c_10_grand_1.rawValue.toColor(), text: type.message)
        
        var actions = [UIAlertAction]()
        let dissmissAction = UIAlertAction(title: type.dismissActionName, style: .default) { _ in
            guard type.goBackAferDismiss else {
                return
            }
            
            self.navigator.pop(sender: self)
        }
        
        actions.append(dissmissAction)
        if let next = type.nextActionName {
            let nextAction = UIAlertAction(title: next, style: .default) { _ in
                self.viewModel.input.doAlertNextAction.onNext(type)
            }
            actions.append(nextAction)
        }
        
        showAlert(title: nil, message: config, actions: actions)
    }
}

private extension ChangePasswordViewController {
    func setupViewsWithOldPassword() {
        self.view.addSubview(self.btnForgetPassword)
        self.view.addSubview(self.originalPasswordInput)
        
        self.idTitleView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(56)
            make.top.equalToSuperview()
        }
        
        self.originalPasswordInput.snp.makeConstraints { make in
            make.top.equalTo(self.idTitleView.snp.bottom)
            make.leading.trailing.equalTo(self.idTitleView)
        }
        
        self.newPasswordInput.snp.makeConstraints { make in
            make.top.equalTo(self.originalPasswordInput.snp.bottom)
            make.leading.trailing.equalTo(self.idTitleView)
        }
        
        self.confirmPasswordInput.snp.makeConstraints { make in
            make.top.equalTo(self.newPasswordInput.snp.bottom)
            make.leading.trailing.equalTo(self.idTitleView)
        }
        
        self.lblHint.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self.idTitleView)
            make.top.equalTo(self.confirmPasswordInput.snp.bottom).offset(16)
        }
        
        self.btnForgetPassword.snp.makeConstraints { make in
            make.leading.equalTo(self.idTitleView)
            make.top.equalTo(self.lblHint.snp.bottom).offset(8)
        }
        
        self.btnSubmin.snp.makeConstraints { (make) in
            make.leading.trailing.equalTo(self.idTitleView)
            make.top.equalTo(self.btnForgetPassword.snp.bottom).offset(32)
            make.height.equalTo(48)
        }
    }
    
    func setupViewsWithoutOldPassword() {
        self.idTitleView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(56)
            make.top.equalToSuperview()
        }
        
        self.newPasswordInput.snp.makeConstraints { make in
            make.top.equalTo(self.idTitleView.snp.bottom)
            make.leading.trailing.equalTo(self.idTitleView)
        }
        
        self.confirmPasswordInput.snp.makeConstraints { make in
            make.top.equalTo(self.newPasswordInput.snp.bottom)
            make.leading.trailing.equalTo(self.idTitleView)
        }
        
        self.lblHint.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self.idTitleView)
            make.top.equalTo(self.confirmPasswordInput.snp.bottom).offset(16)
        }
        
        self.btnSubmin.snp.makeConstraints { (make) in
            make.leading.trailing.equalTo(self.idTitleView)
            make.top.equalTo(self.lblHint.snp.bottom).offset(32)
            make.height.equalTo(48)
        }
    }
}
