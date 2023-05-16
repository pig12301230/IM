//
//  SetupNewPasswordViewControllerVM.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/4/23.
//

import Foundation
import RxSwift
import RxCocoa

class SetupNewPasswordViewControllerVM: ReachableViewControllerVM {
    var disposeBag = DisposeBag()
    
    let submitEnable: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    let alertMessage = PublishSubject<String>()
    let shouldReload = PublishSubject<Void>()
    /**
     呼叫API時使用, 當收到 error and complete(next) 呼叫
     */
    let showLoading: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    
    let phoneNumber: String
    
    private(set) var passwordInputViewModel: MultipleRulesInputViewModel
    private(set) var confirmPasswordInputViewModel: MultipleRulesInputViewModel
    private let countryCode: String
    private let access: String
    
    init(phone: String, countryCode: String, access: String) {
        self.countryCode = countryCode
        self.access = access
        
        self.phoneNumber = Localizable.cellphoneNumbers + " " + phone
        
        self.passwordInputViewModel = MultipleRulesInputViewModel.init(title: Localizable.newPassword,
                                                                       needSecurity: true, showHint: true,
                                                                       rules: .alphabetAndDigit(min: 8, max: 16),
                                                                       .atLeastAlphabet(count: 1),
                                                                       .atLeastDigit(count: 1))
        self.passwordInputViewModel.maxInputLength = 16
        self.passwordInputViewModel.config.placeholder = Localizable.newPasswordInputPlaceholder
        self.passwordInputViewModel.config.keyboardType = .numbersAndPunctuation
        
        self.confirmPasswordInputViewModel = MultipleRulesInputViewModel.init(title: Localizable.confirmPassword,
                                                                              needSecurity: true,
                                                                              showHint: true,
                                                                              rules: .custom(message: Localizable.passwordConfirmValidationRule))
        self.confirmPasswordInputViewModel.maxInputLength = 16
        self.confirmPasswordInputViewModel.config.placeholder = Localizable.confirmNewPasswordInputPlaceholder
        self.confirmPasswordInputViewModel.config.keyboardType = .numbersAndPunctuation
        
        super.init()
        self.initBinding()
    }
    
    func resetPassword() {
        guard self.isReachable() else {
            return
        }
        
        guard let pwd = self.confirmPasswordInputViewModel.outputText.value else {
            return
        }
        
        self.showLoading.accept(true)
        ApiClient.resetUserPassword(password: pwd, oneTimeToken: self.access).subscribe(onNext: nil) { [unowned self] _ in
            self.showLoading.accept(false)
        } onCompleted: { [weak self] in
            guard let self = self else { return }
            self.showLoading.accept(false)
            self.shouldReload.onNext(())
            self.alertMessage.onNext((Localizable.resetPasswordSuccess))
        }.disposed(by: self.disposeBag)
    }
}

private extension SetupNewPasswordViewControllerVM {
    
    func initBinding() {
        Observable.combineLatest(self.confirmPasswordInputViewModel.outputText, self.passwordInputViewModel.outputText).subscribeSuccess { [unowned self] (confirm, original) in
            guard let confirm = confirm, confirm.count > 0, let original = original, confirm.count == original.count else {
                self.confirmPasswordInputViewModel.updateCustomRuleTo(false)
                return
            }
            
            self.confirmPasswordInputViewModel.updateCustomRuleTo(confirm == original)
        }.disposed(by: self.disposeBag)
        
        Observable.combineLatest(self.passwordInputViewModel.output.correct, self.confirmPasswordInputViewModel.output.correct).subscribeSuccess { [unowned self] (term1, term2) in
            self.submitEnable.accept(term1 && term2)
        }.disposed(by: self.disposeBag)
    }
}
