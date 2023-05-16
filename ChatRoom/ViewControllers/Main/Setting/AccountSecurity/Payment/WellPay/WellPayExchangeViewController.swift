//
//  WellPayExchangeViewController.swift
//  ChatRoom
//
//  Created by ERay_Peng on 2023/2/23.
//

import UIKit
import RxSwift

class WellPayExchangeViewController: BaseVC {
    private var isRotating: Bool = false {
        didSet {
            if isRotating {
                self.btnRefrech.isUserInteractionEnabled = false
                self.btnRefrech.layer.add(rotateAnimation, forKey: "rotationAnimation")
                return
            }
            self.btnRefrech.isUserInteractionEnabled = true
            self.btnRefrech.layer.removeAllAnimations()
        }
    }
    
    private lazy var inputStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .top
        return stackView
    }()
    
    private lazy var walletTitleView: TitleInputView = {
        let inputView = TitleInputView.init(with: self.viewModel.walletTitleViewModel)
        inputView.inputTextField.textAlignment = .left
        inputView.isUserInteractionEnabled = false
        return inputView
    }()
    
    private lazy var exchangeInputView: MultipleRulesInputView = {
        let inputView = MultipleRulesInputView.init(with: self.viewModel.exchangeInputViewModel)
        inputView.inputTextField.textAlignment = .left
        inputView.inputTextField.copyAndPasteDisable = true
        return inputView
    }()
    
    private lazy var securityPwdInputView: MultipleRulesInputView = {
        let inputView = MultipleRulesInputView.init(with: self.viewModel.securityPasswordInputViewModel)
        inputView.inputTextField.textAlignment = .left
        inputView.inputTextField.copyAndPasteDisable = true
        return inputView
    }()
    
    private lazy var insufficientStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .leading
        return stackView
    }()
    
    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "iconPopint")?.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = Theme.c_01_primary_0_500.rawValue.toColor()
        imageView.roundSelf()
        return imageView
    }()
    
    private lazy var lblBalance: UILabel = {
        let lbl = UILabel()
        return lbl
    }()
    
    private lazy var btnRefrech: UIButton = {
        let btn = UIButton.init()
        btn.setImage(UIImage(named: "iconIconReload2")?.withRenderingMode(.alwaysTemplate), for: .normal)
        btn.tintColor = Theme.c_01_primary_0_500.rawValue.toColor()
        return btn
    }()
    
    private lazy var lblCustomExchangeHint: UILabel = {
        let lbl = UILabel()
        lbl.theme_textColor = Theme.c_05_warning_700.rawValue
        lbl.text = Localizable.exchangeAmountOver
        lbl.textAlignment = .left
        lbl.font = .boldParagraphMediumRight
        lbl.isHidden = true
        return lbl
    }()
    
    private lazy var lblCustomSecurityHint: UILabel = {
        let lbl = UILabel()
        lbl.theme_textColor = Theme.c_05_warning_700.rawValue
        lbl.text = Localizable.securityCodeError
        lbl.textAlignment = .left
        lbl.font = .boldParagraphMediumRight
        lbl.isHidden = true
        return lbl
    }()
    
    private lazy var btnSubmit: UIButton = {
        let btn = UIButton.init()
        btn.layer.cornerRadius = 4
        btn.theme_backgroundColor = Theme.c_07_neutral_200.rawValue
        btn.theme_setTitleColor(Theme.c_09_white_66.rawValue, forState: .disabled)
        btn.theme_setTitleColor(Theme.c_09_white.rawValue, forState: .normal)
        btn.setBackgroundColor(color: Theme.c_01_primary_400.rawValue.toColor(), forState: .normal)
        btn.setBackgroundColor(color: Theme.c_07_neutral_200.rawValue.toColor(), forState: .disabled)
        btn.setTitle(Localizable.confirmSubmission, for: .normal)
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
    
    private lazy var rotateAnimation: CABasicAnimation = {
        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.toValue = NSNumber(value: Double.pi * 3)
        animation.duration = 3.0
        animation.repeatCount = 1
        return animation
    }()
    
    var viewModel: WellPayExchangeViewControllerVM!
    
    static func initVC(with vm: WellPayExchangeViewControllerVM) -> WellPayExchangeViewController {
        let vc = WellPayExchangeViewController.init()
        vc.viewModel = vm
        vc.backTitle = .custom("")
        vc.title = Localizable.wellPayExchange
        return vc
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let kern = self.securityPwdInputView.inputTextField.frame.width / 7
        let string = NSMutableAttributedString(string: "000000")
        string.addAttribute(NSAttributedString.Key.kern, value: kern, range: NSRange(location: 0, length: string.length - 1))
        self.securityPwdInputView.inputTextField.attributedPlaceholder = string
    }
    
    override func setupViews() {
        super.setupViews()
        self.view.theme_backgroundColor = Theme.c_07_neutral_50.rawValue
        
        self.view.addSubviews([inputStackView,
                               btnSubmit,
                               btnCancel,
                               insufficientStackView])
        
        self.setUpInputStackView()
        self.setUpInsufficientStackView()
        
        self.inputStackView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        self.insufficientStackView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(self.securityPwdInputView.snp.bottom).offset(40)
        }
        
        self.btnSubmit.snp.makeConstraints { (make) in
            make.leading.trailing.equalTo(self.walletTitleView)
            make.top.equalTo(self.insufficientStackView.snp.bottom).offset(16)
            make.height.equalTo(48)
        }
        
        self.btnCancel.snp.makeConstraints { (make) in
            make.leading.trailing.equalTo(self.walletTitleView)
            make.top.equalTo(self.btnSubmit.snp.bottom).offset(16)
            make.height.equalTo(48)
        }
    }
    
    override func initBinding() {
        super.initBinding()
        self.viewModel.output.submitEnable.bind(to: self.btnSubmit.rx.isEnabled).disposed(by: self.disposeBag)
        
        self.viewModel.output.showToast.subscribeSuccess { [weak self] message in
            guard let self = self else { return }
            self.toastManager.showToast(hint: message) {
                _ = self.navigator.pop(sender: self, to: CreditViewController.self)
            }
        }.disposed(by: self.disposeBag)
        
        self.viewModel.output.wellPayExchangeAlert.observe(on: MainScheduler.instance).subscribeSuccess { [weak self] errorType in
            guard let self = self else { return }
            self.view.endEditing(true)
            self.showAlert(errorType)
        }.disposed(by: self.disposeBag)
        
        self.viewModel.output.gotoScene.observe(on: MainScheduler.instance).subscribeSuccess { [weak self] scene in
            guard let self = self else { return }
            self.navigator.show(scene: scene, sender: self)
        }.disposed(by: self.disposeBag)
        
        self.btnRefrech.rx.click.subscribeSuccess { [weak self] _ in
            guard let self = self else { return }
            self.fetchBalanceAndRotateBtnRefresh()
        }.disposed(by: self.disposeBag)
        
        self.btnSubmit.rx.click.subscribeSuccess { [weak self] _ in
            guard let self = self else { return }
            self.viewModel.submit()
        }.disposed(by: self.disposeBag)
        
        self.btnCancel.rx.click.subscribeSuccess { [weak self] _ in
            guard let self = self else { return }
            self.navigator.pop(sender: self)
        }.disposed(by: self.disposeBag)
        
        self.viewModel.output.balance.subscribeSuccess { [weak self] balance in
            guard let self = self else { return }
            self.lblBalance.text = String(format: Localizable.insufficientPoints, balance ?? "0.0")
        }.disposed(by: self.disposeBag)
        
        self.viewModel.output.isHiddenExchangeAlert.subscribeSuccess { [weak self] valid in
            guard let self = self else { return }
            self.lblCustomExchangeHint.isHidden = valid
        }.disposed(by: self.disposeBag)
        
        self.viewModel.output.isHiddenSecurityAlert.subscribeSuccess { [weak self] valid in
            guard let self = self else { return }
            self.lblCustomSecurityHint.isHidden = valid
        }.disposed(by: self.disposeBag)
        
        self.viewModel.output.isUserInteractionEnabled.distinctUntilChanged().subscribeSuccess { [weak self] isUserInteractionEnabled in
            guard let self = self else { return }
            self.view.isUserInteractionEnabled = isUserInteractionEnabled
        }.disposed(by: disposeBag)
    }
    
    func showAlert(_ errorType: WellPayExchangeAlertType) {
        self.showAlert(message: errorType.description, comfirmBtnTitle: Localizable.sure, onConfirm: {
            if case .mediumFailed = errorType {
                _ = self.navigator.pop(sender: self, to: ExchangeViewController.self)
            }
            self.viewModel.output.isUserInteractionEnabled.accept(true)
        })
    }
}

private extension WellPayExchangeViewController {
    func setUpInputStackView() {
        self.inputStackView.addArrangedSubviews([walletTitleView,
                                                 exchangeInputView,
                                                 lblCustomExchangeHint,
                                                 securityPwdInputView,
                                                 lblCustomSecurityHint])
        self.inputStackView.setCustomSpacing(5, after: exchangeInputView)
        self.inputStackView.setCustomSpacing(5, after: securityPwdInputView)
        
        for (index, view) in inputStackView.subviews.enumerated() {
            view.snp.makeConstraints { make in
                make.width.equalToSuperview()
                if index == 2, index == 4 {
                    // hintView
                    make.height.equalTo(20)
                }
            }
        }
    }
    
    func setUpInsufficientStackView() {
        let insufficientStackViewHeight = 24
        self.insufficientStackView.addArrangedSubviews([iconImageView, lblBalance, btnRefrech])
        self.insufficientStackView.setCustomSpacing(8, after: iconImageView)
        self.insufficientStackView.setCustomSpacing(12, after: lblBalance)
        
        self.iconImageView.snp.makeConstraints({ $0.width.height.equalTo(insufficientStackViewHeight) })
        
        self.lblBalance.snp.makeConstraints({ $0.height.equalTo(insufficientStackViewHeight) })
        
        self.btnRefrech.snp.makeConstraints({ $0.width.height.equalTo(insufficientStackViewHeight) })
    }
    
    func fetchBalanceAndRotateBtnRefresh() {
        guard !self.isRotating else { return }
        self.viewModel.fetchBalance()
        self.isRotating = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.isRotating = false
        }
    }
}
