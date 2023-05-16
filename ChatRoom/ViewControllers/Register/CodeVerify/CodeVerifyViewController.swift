//
//  CodeVerifyViewController.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/4/26.
//

import UIKit

class CodeVerifyViewController: RegisterBaseVC<CodeVerifyViewControllerVM> {

    private lazy var lblTitle: UILabel = {
        let lbl = UILabel()
        lbl.textAlignment = .left
        lbl.font = .boldParagraphGiantLeft
        lbl.theme_textColor = Theme.c_10_grand_1.rawValue
        lbl.text = Localizable.inputSMSVerificationCode
        return lbl
    }()

    private lazy var verifyCodeInput: VerificationCodeInputView = {
        let view = VerificationCodeInputView(with: self.viewModel.verifyCodeInputVM)
        return view
    }()

    static func initVC(with vm: CodeVerifyViewControllerVM) -> CodeVerifyViewController {
        let vc = CodeVerifyViewController()
        vc.backTitle = .cancel
        vc.title = Localizable.register
        vc.viewModel = vm
        return vc
    }

    override func setupViews() {
        super.setupViews()

        self.view.addSubview(lblTitle)
        self.view.addSubview(verifyCodeInput)

        self.lblTitle.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(16)
            make.leading.equalToSuperview().offset(16)
            make.height.equalTo(28)
        }

        self.verifyCodeInput.snp.makeConstraints { make in
            make.top.equalTo(lblTitle.snp.bottom).offset(32)
            make.leading.equalTo(lblTitle)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(48)
        }

        self.nextButton.snp.makeConstraints { make in
            make.top.equalTo(verifyCodeInput.snp.bottom).offset(32)
            make.leading.trailing.equalTo(verifyCodeInput)
            make.height.equalTo(48)
        }
    }

    override func initBinding() {
        super.initBinding()

        self.nextButton.rx.controlEvent(.touchUpInside).subscribeSuccess { [unowned self] in
            self.viewModel.checkVerifyCode()
        }.disposed(by: self.disposeBag)

        self.viewModel.goCreateAccount.subscribeSuccess { [unowned self] info in
            let vm = RegisterControllerVM()
            vm.registerInfo = info
            self.navigator.show(scene: .register(vm: vm), sender: self, transition: .push(animated: true))
        }.disposed(by: self.disposeBag)
        
        self.viewModel.showError
            .bind { [weak self] errorMsg in
                self?.showAlert(title: "", message: errorMsg, comfirmBtnTitle: Localizable.sure)
            }.disposed(by: disposeBag)
    }
}
