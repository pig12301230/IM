//
//  PhoneVerifyViewController.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/4/21.
//

import UIKit

class PhoneVerifyViewController: RegisterBaseVC<PhoneVerifyViewControllerVM> {

    private lazy var lblTitle: UILabel = {
        let lbl = UILabel()
        lbl.textAlignment = .left
        lbl.font = .boldParagraphGiantLeft
        lbl.theme_textColor = Theme.c_10_grand_1.rawValue
        lbl.text = Localizable.inputMobileNumber
        return lbl
    }()

    private lazy var regionInput: TitleInputView = {
        let view = TitleInputView(with: self.viewModel.regionInputVM)
        return view
    }()

    private lazy var phoneInput: PhoneInputView = {
        let view = PhoneInputView(with: self.viewModel.phoneInputVM)
        return view
    }()

    private lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.distribution = .fill
        view.spacing = 8
        return view
    }()

    private lazy var btnCheck: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(named: "checkboxActiveImage"), for: .normal)
        btn.setImage(UIImage(named: "checkboxCheckedImage"), for: .selected)
        return btn
    }()

    private lazy var serviceAgreement: UILabel = {
        let lbl = UILabel()
        lbl.isUserInteractionEnabled = true

        let totalText = Localizable.serviceAgreement
        let linkText = Localizable.templateSrvAgreement
        let attrString = NSMutableAttributedString(string: totalText,
                                                   attributes: [.font: UIFont.regular(16),
                                                                .foregroundColor: Theme.c_10_grand_2.rawValue.toColor()])
        if let text = linkText.first, let linkLocation = totalText.index(of: text) {
            attrString.addAttributes([.font: UIFont.regular(16), .foregroundColor: Theme.c_03_tertiary_0_500.rawValue.toColor()],
                                     range: NSRange(location: linkLocation, length: Localizable.templateSrvAgreement.count))
        }
        lbl.attributedText = attrString
        return lbl
    }()

    private let tapServiceGesture = UITapGestureRecognizer()

    static func initVC(with vm: PhoneVerifyViewControllerVM) -> PhoneVerifyViewController {
        let vc = PhoneVerifyViewController()
        vc.backTitle = .cancel
        vc.title = Localizable.register
        vc.viewModel = vm
        return vc
    }

    override func setupViews() {
        super.setupViews()

        self.view.addSubview(lblTitle)
        self.view.addSubview(regionInput)
        self.view.addSubview(phoneInput)
        self.view.addSubview(stackView)

        self.lblTitle.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(16)
            make.leading.equalToSuperview().offset(16)
            make.height.equalTo(28)
        }

        self.regionInput.snp.makeConstraints { make in
            make.top.equalTo(lblTitle.snp.bottom).offset(32)
            make.leading.equalTo(lblTitle)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(48)
        }

        self.phoneInput.snp.makeConstraints { make in
            make.top.equalTo(regionInput.snp.bottom)
            make.leading.trailing.equalTo(regionInput)
            make.height.greaterThanOrEqualTo(48)
        }

        self.stackView.snp.makeConstraints { make in
            make.top.equalTo(phoneInput.snp.bottom).offset(16)
            make.leading.trailing.equalTo(phoneInput)
            make.height.equalTo(24)
        }

        self.nextButton.snp.makeConstraints { make in
            make.top.equalTo(stackView.snp.bottom).offset(32)
            make.leading.trailing.equalTo(stackView)
            make.height.equalTo(48)
        }

        self.stackView.addArrangedSubview(btnCheck)
        self.stackView.addArrangedSubview(serviceAgreement)

        self.serviceAgreement.addGestureRecognizer(self.tapServiceGesture)
    }

    override func initBinding() {
        super.initBinding()

        self.viewModel.regionInputVM.touchInputAction.subscribeSuccess { [unowned self] in
            self.navigator.show(scene: .selectRegion(vm: self.viewModel.regionSelectVM), sender: self)
        }.disposed(by: self.disposeBag)

        self.tapServiceGesture.rx.event.subscribeSuccess { [unowned self] gesture in
            if gesture.didTapAttributedString(Localizable.templateSrvAgreement, in: self.serviceAgreement) {
                let vm = TermsViewControllerVM(title: AboutOption.provision.title, url: AboutOption.provision.url)
                self.navigator.show(scene: .termsHint(vm: vm), sender: self, transition: .present(animated: true))
            } else {
                self.viewModel.agreementRead.accept(!self.btnCheck.isSelected)
            }
        }.disposed(by: self.disposeBag)

        self.viewModel.agreementRead.bind(to: self.btnCheck.rx.isSelected).disposed(by: self.disposeBag)
        self.btnCheck.rx.controlEvent(.touchUpInside).subscribeSuccess { [unowned self] in
            self.viewModel.agreementRead.accept(!self.btnCheck.isSelected)
        }.disposed(by: self.disposeBag)

        self.nextButton.rx.controlEvent(.touchUpInside).subscribeSuccess { [unowned self] in
            self.viewModel.checkPhone()
        }.disposed(by: self.disposeBag)

        self.viewModel.verifyCompleted.subscribeSuccess { [unowned self] verified, info in
            switch verified {
            case .notVerified:
                let vm = CodeVerifyViewControllerVM()
                vm.registerInfo = info
                self.navigator.show(scene: .codeVerify(vm: vm), sender: self)
            case .verified:
                let vm = RegisterControllerVM()
                vm.registerInfo = info
                self.navigator.show(scene: .register(vm: vm), sender: self, transition: .push(animated: true))
            }
        }.disposed(by: self.disposeBag)
    }
}
