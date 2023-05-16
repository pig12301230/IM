//
//  PlatformExchangeViewController.swift
//  ChatRoom
//
//  Created by ERay_Peng on 2023/2/17.
//

import UIKit
import RxSwift

class PlatformExchangeViewController: BaseVC {
    
    private lazy var addressInput: UserInteractiveStatusInputView = {
        let inputView = UserInteractiveStatusInputView.init(with: self.viewModel.addressInputViewModel)
        inputView.inputTextField.textAlignment = .left
        return inputView
    }()
    
    private lazy var securityPasswordInput: MultipleRulesInputView = {
        let inputView = MultipleRulesInputView.init(with: self.viewModel.securityPasswordInputViewModel)
        inputView.inputTextField.textAlignment = .left
        inputView.inputTextField.copyAndPasteDisable = true
        return inputView
    }()
    
    private lazy var btnExchange: UIButton = {
        let btn = UIButton.init()
        btn.layer.cornerRadius = 4
        btn.theme_backgroundColor = Theme.c_07_neutral_200.rawValue
        btn.theme_setTitleColor(Theme.c_09_white_66.rawValue, forState: .disabled)
        btn.theme_setTitleColor(Theme.c_09_white.rawValue, forState: .normal)
        btn.setBackgroundColor(color: Theme.c_01_primary_400.rawValue.toColor(), forState: .normal)
        btn.setBackgroundColor(color: Theme.c_07_neutral_200.rawValue.toColor(), forState: .disabled)
        btn.setTitle(Localizable.exchange, for: .normal)
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
    
    var viewModel: PlatformExchangeViewControllerVM!
    
    static func initVC(with vm: PlatformExchangeViewControllerVM) -> PlatformExchangeViewController {
        let vc = PlatformExchangeViewController.init()
        vc.viewModel = vm
        vc.backTitle = .custom("")
        vc.title = Localizable.brandPointsExchange
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
        self.view.addSubview(self.addressInput)
        self.view.addSubview(self.securityPasswordInput)
        self.view.addSubview(self.btnExchange)
        self.view.addSubview(self.btnCancel)
        
        
        self.addressInput.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(56)
            make.top.equalToSuperview()
        }
        
        self.securityPasswordInput.snp.makeConstraints { make in
            make.top.equalTo(self.addressInput.snp.bottom)
            make.leading.trailing.equalTo(self.addressInput)
        }
        
        self.btnExchange.snp.makeConstraints { (make) in
            make.leading.trailing.equalTo(self.addressInput)
            make.top.equalTo(self.securityPasswordInput.snp.bottom).offset(32)
            make.height.equalTo(48)
        }
        
        self.btnCancel.snp.makeConstraints { (make) in
            make.leading.trailing.equalTo(self.addressInput)
            make.top.equalTo(self.btnExchange.snp.bottom).offset(32)
            make.height.equalTo(48)
        }
    }
    
    override func initBinding() {
        super.initBinding()
        self.viewModel.output.exchangeEnable.bind(to: self.btnExchange.rx.isEnabled).disposed(by: self.disposeBag)
        
        self.btnExchange.rx.controlEvent(.touchUpInside).bind(to: self.viewModel.input.exchangeAction).disposed(by: self.disposeBag)
        
        self.btnCancel.rx.controlEvent(.touchUpInside).observe(on: MainScheduler.instance).subscribeSuccess { [weak self] _ in
            guard let self = self else { return }
            self.navigator.pop(sender: self)
        }.disposed(by: self.disposeBag)
        
        self.viewModel.output.gotoScene.observe(on: MainScheduler.instance).subscribeSuccess { [weak self] scene in
            guard let self = self else { return }
            self.navigator.show(scene: scene, sender: self, transition: .push(animated: false))
        }.disposed(by: self.disposeBag)
        
        self.viewModel.output.addressInpuText.observe(on: MainScheduler.instance).subscribeSuccess { [weak self] txt in
            guard let self = self else { return }
            self.addressInput.inputTextField.text = txt
        }.disposed(by: self.disposeBag)
        
        self.viewModel.output.showToast.observe(on: MainScheduler.instance).subscribeSuccess { [weak self] txt in
            guard let self = self else { return }
            self.toastManager.showToast(hint: txt)
        }.disposed(by: disposeBag)
        
        self.viewModel.output.alert.observe(on: MainScheduler.instance).subscribeSuccess { [weak self] _ in
            guard let self = self else { return }
            self.showAlert(title: Localizable.pleaseAttention, message: Localizable.firstTimeExchangeHint, cancelBtnTitle: Localizable.cancel, comfirmBtnTitle: Localizable.sure, onConfirm: {
                self.viewModel.goToLoading()
            })
        }.disposed(by: disposeBag)
    }
    
    func showAlertNotice(with type: SecurityAlertType) {
        let config = DisplayConfig(font: .regularParagraphLargeCenter, textColor: Theme.c_10_grand_1.rawValue.toColor(), text: type.message)
        
        let dissmissAction = UIAlertAction(title: Localizable.sure, style: .default) { _ in
            self.navigator.pop(sender: self)
        }
        
        showAlert(title: nil, message: config, actions: [dissmissAction])
    }
}
