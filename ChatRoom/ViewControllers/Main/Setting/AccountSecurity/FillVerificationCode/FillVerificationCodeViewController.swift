//
//  FillVerificationCodeViewController.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/7/30.
//

import UIKit
import RxSwift

class FillVerificationCodeViewController: BaseVC {
    var viewModel: FillVerificationCodeViewControllerVM!
    
    private lazy var lblHint: UILabel = {
        let lbl = UILabel.init()
        lbl.text = Localizable.verificationCodeHint
        lbl.theme_textColor = Theme.c_07_neutral_400.rawValue
        lbl.font = .regularParagraphMediumLeft
        return lbl
    }()
    
    private lazy var phoneTitleView: TitleInputView = {
        let view = TitleInputView.init(with: self.viewModel.phoneTitleViewModel)
        return view
    }()
    
    private lazy var verificationCodeInput: MultipleRulesInputView = {
        let view = MultipleRulesInputView.init(with: self.viewModel.verificationCodeInputViewModel)
        return view
    }()
    
    private lazy var btnSubmin: UIButton = {
        let btn = UIButton.init()
        btn.layer.cornerRadius = 4
        btn.theme_backgroundColor = Theme.c_07_neutral_200.rawValue
        btn.theme_setTitleColor(Theme.c_09_white.rawValue, forState: .normal)
        btn.setTitle(Localizable.send, for: .normal)
        btn.titleLabel?.font = .boldParagraphMediumLeft
        return btn
    }()
    
    private lazy var btnNotReciveCode: UIButton = {
        let btn = UIButton.init()
        btn.setTitle(Localizable.canNotReceiveVerificationCode, for: .normal)
        btn.setTitleColor(Theme.c_03_tertiary_0_500.rawValue.toColor(), for: .normal)
        btn.titleLabel?.font = .regularParagraphLargeLeft
        return btn
    }()
    
    static func initVC(with vm: FillVerificationCodeViewControllerVM) -> FillVerificationCodeViewController {
        let vc = FillVerificationCodeViewController.init()
        vc.viewModel = vm
        vc.backTitle = .custom("")
        vc.title = Localizable.fillInVerificationCode
        return vc
    }
    
    override func setupViews() {
        super.setupViews()
        self.view.theme_backgroundColor = Theme.c_07_neutral_50.rawValue
        self.view.addSubview(self.lblHint)
        self.view.addSubview(self.phoneTitleView)
        self.view.addSubview(self.verificationCodeInput)
        self.view.addSubview(self.btnSubmin)
        self.view.addSubview(self.btnNotReciveCode)
        
        self.lblHint.snp.makeConstraints { make in
            make.leading.top.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        self.phoneTitleView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self.lblHint)
            make.top.equalTo(self.lblHint.snp.bottom)
            make.height.equalTo(56)
        }
        
        self.verificationCodeInput.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self.lblHint)
            make.top.equalTo(self.phoneTitleView.snp.bottom)
        }
        
        self.btnSubmin.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self.lblHint)
            make.top.equalTo(self.verificationCodeInput.snp.bottom).offset(32)
            make.height.equalTo(48)
        }
        
        self.btnNotReciveCode.snp.makeConstraints { make in
            make.leading.equalTo(self.lblHint)
            make.top.equalTo(self.btnSubmin.snp.bottom).offset(8)
        }
    }
    
    override func initBinding() {
        super.initBinding()
        
        self.viewModel.output.submitEnable.bind(to: self.btnSubmin.rx.isEnabled).disposed(by: self.disposeBag)
        self.viewModel.output.submitEnable.distinctUntilChanged().observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] (enable) in
            self.btnSubmin.theme_backgroundColor = enable ? Theme.c_01_primary_400.rawValue : Theme.c_07_neutral_200.rawValue
        }.disposed(by: self.disposeBag)
        
        self.viewModel.output.popToSecurityAndGoto.observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] scene in
            self.navigator.pop(sender: self, to: AccountSecurityViewController.self, andShow: scene, animated: false)
        }.disposed(by: self.disposeBag)
        
        self.btnNotReciveCode.rx.controlEvent(.touchUpInside).subscribeSuccess { [unowned self] in
            self.showResendSheet()
        }.disposed(by: self.disposeBag)
        
        self.btnSubmin.rx.controlEvent(.touchUpInside).bind(to: self.viewModel.input.submitAction).disposed(by: self.disposeBag)
    }
    
    override func popViewController() {
        let config = DisplayConfig(font: .regularParagraphLargeCenter, textColor: Theme.c_10_grand_1.rawValue.toColor(), text: Localizable.cancelVerificationCode)
        
        let cancleAction = UIAlertAction(title: Localizable.cancel, style: .default, handler: nil)
        let sureAction = UIAlertAction(title: Localizable.sure, style: .default) { _ in
            self.navigator.pop(sender: self)
        }
        
        showAlert(title: nil, message: config, actions: [cancleAction, sureAction])
    }
    
    private func showResendSheet() {
        let resend = UIAlertAction.init(title: Localizable.getVerificationCodeAgain, style: .default) { _ in
            self.viewModel.getVerifyCode()
        }
        
        showSheet(actions: resend, cancelBtnTitle: Localizable.cancel)
    }
}
