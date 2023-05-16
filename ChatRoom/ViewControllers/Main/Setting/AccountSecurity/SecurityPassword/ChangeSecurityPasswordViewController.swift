//
//  ChangeSecurityPasswordViewController.swift
//  GuChat
//
//  Created by ERay_Peng on 2023/2/13.
//

import UIKit
import RxSwift

class ChangeSecurityPasswordViewController: BaseVC {
    
    private lazy var stackView: UIStackView = {
        let sView = UIStackView()
        sView.alignment = .top
        sView.axis = .vertical
        return sView
    }()
    
    private lazy var originalSecurityPasswordInput: MultipleRulesInputView = {
        let inputView = MultipleRulesInputView.init(with: self.viewModel.originalSecurityPasswordInputViewModel)
        inputView.inputTextField.copyAndPasteDisable = true
        return inputView
    }()
    
    private lazy var newSecurityPasswordInput: MultipleRulesInputView = {
        let inputView = MultipleRulesInputView.init(with: self.viewModel.newSecurityPasswordInputViewModel)
        inputView.inputTextField.copyAndPasteDisable = true
        return inputView
    }()
    
    private lazy var confirmSecurityPasswordInput: MultipleRulesInputView = {
        let inputView = MultipleRulesInputView.init(with: self.viewModel.confirmSecurityPasswordInputViewModel)
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
        btn.setTitle(Localizable.done, for: .normal)
        btn.titleLabel?.font = .boldParagraphMediumLeft
        return btn
    }()
    
    var viewModel: ChangeSecurityPasswordViewControllerVM!
    
    static func initVC(with vm: ChangeSecurityPasswordViewControllerVM) -> ChangeSecurityPasswordViewController {
        let vc = ChangeSecurityPasswordViewController.init()
        vc.viewModel = vm
        vc.backTitle = .custom("")
        vc.title = Localizable.settingSecurityPassword
        return vc
    }
    
    override func setupViews() {
        super.setupViews()
        self.view.theme_backgroundColor = Theme.c_07_neutral_50.rawValue
        self.view.addSubview(stackView)
        
        stackView.addArrangedSubviews([originalSecurityPasswordInput, newSecurityPasswordInput, confirmSecurityPasswordInput, btnSubmit])
        
        stackView.setCustomSpacing(32, after: confirmSecurityPasswordInput)
        
        
        stackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.top.equalToSuperview()
        }
                
        for (index, view) in stackView.subviews.enumerated() {
            view.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview()
                let isLastView = index == (stackView.subviews.count - 1)
                if isLastView {
                    make.height.equalTo(48)
                }
            }
        }
        
        originalSecurityPasswordInput.isHidden = viewModel.changeSecurityPasswordType == .withoutOldSecurityPassword
    }
    
    override func initBinding() {
        super.initBinding()
        self.viewModel.output.submitEnable.bind(to: self.btnSubmit.rx.isEnabled).disposed(by: self.disposeBag)
        
        self.btnSubmit.rx.controlEvent(.touchUpInside).bind(to: self.viewModel.input.resetAction).disposed(by: self.disposeBag)
        
        self.viewModel.output.alertTypeAndGotoScene.observe(on: MainScheduler.instance).subscribeSuccess { [weak self] noticeType, scene in
            guard let self = self else { return }
            self.view.endEditing(true)
            self.showAlertNotice(with: noticeType, gotoScene: scene)
        }.disposed(by: self.disposeBag)
    }
}

private extension ChangeSecurityPasswordViewController {
    func showAlertNotice(with type: SecurityAlertType, gotoScene: Navigator.Scene?) {
        let config = DisplayConfig(font: .regularParagraphLargeCenter, textColor: Theme.c_10_grand_1.rawValue.toColor(), text: type.message)
        
        let dissmissAction = UIAlertAction(title: Localizable.sure, style: .default) { _ in
            guard case .resetSuccess = type else {
                return
            }
            
            if self.viewModel.isFromCheckBinding {
                guard let scene = gotoScene else { return }
                self.navigator.pop(sender: self, to: CreditViewController.self, andShow: scene)
            } else {
                self.navigator.pop(sender: self)
            }
        }
        
        showAlert(title: nil, message: config, actions: [dissmissAction])
    }
}
