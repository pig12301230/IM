//
//  RegisterBaseVC.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/5/11.
//

import UIKit

class RegisterBaseVC<T: RegisterBaseVM>: BaseVC {

    var viewModel: T!

    lazy var nextButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = .boldParagraphMediumLeft
        button.layer.cornerRadius = 4
        button.setTitle(Localizable.next, for: .normal)
        return button
    }()

    override func setupViews() {
        super.setupViews()

        self.title = Localizable.register
        self.view.theme_backgroundColor = Theme.c_07_neutral_50.rawValue

        self.view.addSubview(nextButton)
    }

    override func initBinding() {
        super.initBinding()

        self.viewModel.errorHappened.subscribeSuccess { [unowned self] error in
            guard let apiError = error as? ApiError else {
                self.showAlert(message: error.localizedDescription, comfirmBtnTitle: Localizable.sure)
                return
            }
            if apiError == .unreachable {
                self.showUnreachableAlert()
            } else {
                self.showAlert(message: apiError.localizedString, comfirmBtnTitle: Localizable.sure)
            }
        }.disposed(by: self.disposeBag)

        self.viewModel.nextEnable.bind(to: self.nextButton.rx.isEnabled).disposed(by: self.disposeBag)
        self.viewModel.nextEnable.distinctUntilChanged().subscribeSuccess { [unowned self] enable in
            self.updateNextButtonStyle(enable: enable)
        }.disposed(by: self.disposeBag)
        
        self.viewModel.showLoading.subscribeSuccess { show in
            show ? LoadingView.shared.show() : LoadingView.shared.hide()
        }.disposed(by: self.disposeBag)
    }
}

private extension RegisterBaseVC {
    func updateNextButtonStyle(enable: Bool) {
        let bgColor = enable ? Theme.c_01_primary_400.rawValue : Theme.c_07_neutral_200.rawValue
        let titleColor = enable ? Theme.c_09_white.rawValue : Theme.c_09_white_66.rawValue

        self.nextButton.theme_backgroundColor = bgColor
        self.nextButton.theme_setTitleColor(titleColor, forState: .normal)
    }

    func showUnreachableAlert() {
        self.showAlert(message: Localizable.checkNetworkSetting, cancelBtnTitle: Localizable.cancel, comfirmBtnTitle: Localizable.learnMore, onConfirm: {
            self.navigator.show(scene: .unreachableHint, sender: self, transition: .present(animated: true))
        })
    }
}
