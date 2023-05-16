//
//  WellPayBindingViewController.swift
//  GuChat
//
//  Created by ERay_Peng on 2023/2/20.
//

import UIKit
import RxSwift

class WellPayBindingViewController: BaseVC {
    private lazy var stackView: UIStackView = {
        let sView = UIStackView()
        sView.alignment = .top
        sView.axis = .vertical
        return sView
    }()
    
    private lazy var walletTitleView: MultipleRulesInputView = {
        let inputView = MultipleRulesInputView.init(with: self.viewModel.walletTitleInputViewModel)
        inputView.isUserInteractionEnabled = false
        inputView.inputTextField.textAlignment = .right
        return inputView
    }()
    
    private lazy var walletAddressInput: MultipleRulesInputView = {
        let inputView = MultipleRulesInputView.init(with: self.viewModel.walletAddressInputViewModel)
        inputView.inputTextField.textAlignment = .left
        return inputView
    }()
    
    private lazy var securityPasswordInput: MultipleRulesInputView = {
        let inputView = MultipleRulesInputView.init(with: self.viewModel.securityPasswordInputViewModel)
        inputView.inputTextField.textAlignment = .left
        inputView.inputTextField.copyAndPasteDisable = true
        return inputView
    }()
    
    
    private lazy var btnSubmit: UIButton = {
        let btn = UIButton.init()
        btn.layer.cornerRadius = 4
        btn.theme_backgroundColor = Theme.c_07_neutral_200.rawValue
        btn.theme_setTitleColor(Theme.c_09_white_66.rawValue, forState: .disabled)
        btn.theme_setTitleColor(Theme.c_09_white.rawValue, forState: .normal)
        btn.setBackgroundColor(color: Theme.c_01_primary_400.rawValue.toColor(), forState: .normal)
        btn.setBackgroundColor(color: Theme.c_07_neutral_200.rawValue.toColor(), forState: .disabled)
        btn.setTitle(Localizable.confirmAdd, for: .normal)
        btn.titleLabel?.font = .boldParagraphMediumLeft
        return btn
    }()
    
    private lazy var btnCancel: UIButton = {
        let btn = UIButton.init()
        btn.layer.cornerRadius = 4
        btn.theme_setTitleColor(Theme.c_07_neutral_400.rawValue, forState: .normal)
        btn.setTitle(Localizable.cancel, for: .normal)
        btn.titleLabel?.font = .boldParagraphMediumLeft
        btn.layer.borderColor = Theme.c_07_neutral_500.rawValue.toCGColor()
        btn.layer.borderWidth = 1
        return btn
    }()
    
    var viewModel: WellPayBindingViewControllerVM!
    
    static func initVC(with vm: WellPayBindingViewControllerVM) -> WellPayBindingViewController {
        let vc = WellPayBindingViewController.init()
        vc.viewModel = vm
        vc.backTitle = .custom("")
        vc.title = Localizable.bind
        return vc
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let kern = self.securityPasswordInput.inputTextField.frame.width / 7
        let string = NSMutableAttributedString(string: "000000")
        string.addAttribute(NSAttributedString.Key.kern, value: kern, range: NSRange(location: 0, length: string.length - 1))
        self.securityPasswordInput.inputTextField.attributedPlaceholder = string
    }
    
    override func setupViews() {
        super.setupViews()
        self.view.theme_backgroundColor = Theme.c_07_neutral_50.rawValue
        
        view.addSubviews([stackView, btnSubmit, btnCancel])
        
        stackView.addArrangedSubviews([walletTitleView, walletAddressInput, securityPasswordInput])
        
        stackView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalToSuperview()
        }
        
        btnSubmit.snp.makeConstraints { make in
            make.top.equalTo(stackView.snp.bottom).offset(32)
            make.leading.trailing.equalTo(stackView)
            make.height.equalTo(48)
        }
        
        btnCancel.snp.makeConstraints { make in
            make.top.equalTo(btnSubmit.snp.bottom).offset(16)
            make.leading.trailing.equalTo(stackView)
            make.height.equalTo(48)
        }
                
        for view in stackView.subviews {
            view.snp.makeConstraints { $0.leading.trailing.equalToSuperview() }
        }
    }
    
    override func initBinding() {
        super.initBinding()
        self.viewModel.output.submitEnable.bind(to: self.btnSubmit.rx.isEnabled).disposed(by: self.disposeBag)
        
        self.viewModel.output.alertType.observe(on: MainScheduler.instance).subscribeSuccess { [weak self] type in
            guard let self = self else { return }
            self.view.endEditing(true)
            self.showAlertNotice(with: type)
        }.disposed(by: self.disposeBag)
        
        self.viewModel.output.popToExchangeAndGoto.observe(on: MainScheduler.instance).subscribeSuccess { [weak self] scene in
            guard let self = self else { return }
            self.navigator.pop(sender: self, to: ExchangeViewController.self, andShow: scene)
        }.disposed(by: self.disposeBag)
        
        self.btnSubmit.rx.controlEvent(.touchUpInside).subscribeSuccess { [weak self] _ in
            guard let self = self else { return }
            self.viewModel.submit()
        }.disposed(by: self.disposeBag)
        
        self.btnCancel.rx.click.subscribeSuccess { [weak self] _ in
            guard let self = self else { return }
            self.navigator.pop(sender: self)
        }.disposed(by: self.disposeBag)
    }
    
    private func showAlertNotice(with type: WellPayBindAlertType) {
        showAlert(title: type.title, message: type.alertContent, cancelBtnTitle: type.cancelBtnTitle, comfirmBtnTitle: Localizable.sure, onConfirm: {
            switch type {
            case .securityCodeError:
                break
            case .firstTimeBind:
                self.viewModel.bindWellPayWallet()
            }
        })
    }
}
