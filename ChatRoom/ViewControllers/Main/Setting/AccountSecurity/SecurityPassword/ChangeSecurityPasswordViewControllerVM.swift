//
//  ChangeSecurityPasswordViewControllerVM.swift
//  GuChat
//
//  Created by ERay_Peng on 2023/2/13.
//

import Foundation
import RxSwift
import RxCocoa

enum SecurityAlertType {
    case resetSuccess
    case oldPasswordError
    
    var message: String {
        switch self {
        case .resetSuccess:
            return Localizable.setSecurityPasswordSuccess
        case .oldPasswordError:
            return Localizable.oldSecurityPasswordErrorRefill
        }
    }
}

class ChangeSecurityPasswordViewControllerVM: BaseViewModel {
    enum ChangeSecurityPasswordType {
        case withOldSecurityPassword
        case withoutOldSecurityPassword
        
        var showBackButton: Bool {
            switch self {
            case .withOldSecurityPassword:
                return true
            case .withoutOldSecurityPassword:
                return false
            }
        }
    }
    
    struct Output {
        let submitEnable: BehaviorRelay<Bool> = BehaviorRelay(value: false)
        let alertTypeAndGotoScene = PublishSubject<(SecurityAlertType, Navigator.Scene?)>()
    }
    
    struct Input {
        let resetAction = PublishSubject<Void>()
    }
    
    var disposeBag = DisposeBag()
    
    private(set) var originalSecurityPasswordInputViewModel: MultipleRulesInputViewModel
    private(set) var newSecurityPasswordInputViewModel: MultipleRulesInputViewModel
    private(set) var confirmSecurityPasswordInputViewModel: MultipleRulesInputViewModel
    private(set) var isFromCheckBinding: Bool
    let changeSecurityPasswordType: ChangeSecurityPasswordType
    let input = Input()
    let output = Output()
    
    // isFromCheckBinding為是否在兌換流程中確認是否設置安全碼
    init(type: ChangeSecurityPasswordType, isFromCheckBinding: Bool = false) {
        self.isFromCheckBinding = isFromCheckBinding
        self.changeSecurityPasswordType = type
        
        self.originalSecurityPasswordInputViewModel = MultipleRulesInputViewModel.init(title: Localizable.oldSecurityPassword,
                                                                                       needSecurity: true,
                                                                                       showHint: false,
                                                                                       check: false,
                                                                                       rules: .specifyNumber(count: 6))
        self.originalSecurityPasswordInputViewModel.maxInputLength = 6
        self.originalSecurityPasswordInputViewModel.config.placeholder = Localizable.oldSecurityPasswordPlaceholder
        self.originalSecurityPasswordInputViewModel.config.keyboardType = .numberPad
        
        let newPasswordTitle = type == .withOldSecurityPassword ? Localizable.newSecurityPassword : Localizable.settingSecurityPassword
        self.newSecurityPasswordInputViewModel = MultipleRulesInputViewModel.init(title: newPasswordTitle,
                                                                                  needSecurity: true,
                                                                                  showHint: true,
                                                                                  check: false,
                                                                                  rules: .specifyNumber(count: 6))
        self.newSecurityPasswordInputViewModel.maxInputLength = 6
        self.newSecurityPasswordInputViewModel.config.placeholder = Localizable.newSecurityPasswordPlaceholder
        self.newSecurityPasswordInputViewModel.config.keyboardType = .numberPad
        
        self.confirmSecurityPasswordInputViewModel = MultipleRulesInputViewModel.init(title: Localizable.confirmSecurityPassword,
                                                                                      needSecurity: true,
                                                                                      showHint: true,
                                                                                      check: false,
                                                                                      rules: .custom(message: Localizable.securityPasswordConfirmValidationRule))
        self.confirmSecurityPasswordInputViewModel.maxInputLength = 6
        self.confirmSecurityPasswordInputViewModel.config.placeholder = Localizable.newSecurityPasswordConfirmPlaceholder
        self.confirmSecurityPasswordInputViewModel.config.keyboardType = .numberPad
        
        super.init()
        self.initBinding()
    }
    
    func initBinding() {
        Observable.combineLatest(self.confirmSecurityPasswordInputViewModel.outputText,
                                 self.newSecurityPasswordInputViewModel.outputText)
        .subscribeSuccess { [weak self] (confirm, original) in
            guard let self = self else { return }
            guard let confirm = confirm, !confirm.isEmpty, let original = original else { return }
            self.confirmSecurityPasswordInputViewModel.updateCustomRuleTo(confirm == original)
        }.disposed(by: self.disposeBag)
        
        if self.changeSecurityPasswordType == .withOldSecurityPassword {
            Observable.combineLatest(self.originalSecurityPasswordInputViewModel.output.correct,
                                     self.newSecurityPasswordInputViewModel.output.correct,
                                     self.confirmSecurityPasswordInputViewModel.output.correct)
            .subscribeSuccess { [weak self] (term1, term2, term3) in
                guard let self = self else { return }
                let enable = term1 && term2 && term3
                self.output.submitEnable.accept(enable)
            }.disposed(by: self.disposeBag)
        } else {
            Observable.combineLatest(self.newSecurityPasswordInputViewModel.output.correct,
                                     self.confirmSecurityPasswordInputViewModel.output.correct)
            .subscribeSuccess { [weak self] (term1, term2) in
                guard let self = self else { return }
                let enable = term1 && term2
                self.output.submitEnable.accept(enable)
            }.disposed(by: self.disposeBag)
        }
        
        self.input.resetAction.subscribeSuccess { [weak self] _ in
            guard let self = self else { return }
//            LogHelper.print(.debug, item: "reset action")
            self.resetPassword()
        }.disposed(by: self.disposeBag)
    }
}

private extension ChangeSecurityPasswordViewControllerVM {
    
    func resetPassword() {
        switch self.changeSecurityPasswordType {
        case .withOldSecurityPassword:
            self.resetWithOldSecurityPassword()
        case .withoutOldSecurityPassword:
            self.resetWithoutOldSecurityPassword()
        }
    }
    
    func resetWithOldSecurityPassword() {
        guard let oldPassword = self.originalSecurityPasswordInputViewModel.outputText.value, let newPassword = self.newSecurityPasswordInputViewModel.outputText.value else {
            return
        }
        
        DataAccess.shared.setSecurityCode(from: oldPassword, to: newPassword)
            .subscribe { _ in
                let vm = ExchangeViewControllerVM()
                self.output.alertTypeAndGotoScene.onNext((.resetSuccess, .exchange(vm: vm)))
            } onError: { error in
                if let err = error as? ApiError, (err == .invalidAccess || err == .noAccess) {
                    // 強登處理
                } else {
                    self.output.alertTypeAndGotoScene.onNext((.oldPasswordError, nil))
                }
            }.disposed(by: self.disposeBag)
    }
    
    func resetWithoutOldSecurityPassword() {
        guard let newPassword = self.newSecurityPasswordInputViewModel.outputText.value else {
            return
        }
        
        DataAccess.shared.setSecurityCode(to: newPassword)
            .subscribeSuccess { _ in
                UserData.shared.setHasSetSecurityCode(true)
                let vm = ExchangeViewControllerVM()
                self.output.alertTypeAndGotoScene.onNext((.resetSuccess, .exchange(vm: vm)))
            }.disposed(by: self.disposeBag)
    }
}
