//
//  RegisterControllerVM.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/4/26.
//

import Foundation
import RxSwift
import RxCocoa

class RegisterControllerVM: RegisterBaseVM {
    
    var disposeBag = DisposeBag()

    let goSetProfile = PublishRelay<Any>()
    let showError = PublishSubject<String>()
    
    private(set) var accountInputVM: MultipleRulesInputViewModel
    private(set) var passwordInputVM: MultipleRulesInputViewModel
    private(set) var confirmPwdInputVM: MultipleRulesInputViewModel
    private(set) var nicknameInputVM: MultipleRulesInputViewModel
    private(set) var socialAccountInputVM: MultipleRulesInputViewModel!
    private(set) var inviteCodeInputVM: MultipleRulesInputViewModel
    private var inputValidation: Observable<Bool> = .empty()
    
    let showSocialAccount: PublishSubject<Bool> = .init()
    
    override init() {
        self.accountInputVM = MultipleRulesInputViewModel(title: Localizable.accountID, showHint: true,
                                                          rules: .alphabetAndDigit(min: 6, max: 12),
                                                                 .atLeastAlphabet(count: 1),
                                                                 .atLeastDigit(count: 1))
        self.accountInputVM.maxInputLength = 12
        self.accountInputVM.config.placeholder = Localizable.accountIDInputPlaceholder
        self.accountInputVM.config.keyboardType = .numbersAndPunctuation

        self.passwordInputVM = MultipleRulesInputViewModel(title: Localizable.passwordSetting, needSecurity: true, showHint: true,
                                                           rules: .alphabetAndDigit(min: 8, max: 16),
                                                                  .atLeastAlphabet(count: 1),
                                                                  .atLeastDigit(count: 1))
        self.passwordInputVM.maxInputLength = 16
        self.passwordInputVM.config.placeholder = Localizable.passwordInputPlaceholder
        self.passwordInputVM.config.keyboardType = .numbersAndPunctuation

        self.confirmPwdInputVM = MultipleRulesInputViewModel(title: Localizable.confirmPassword, needSecurity: true, showHint: true,
                                                             rules: .custom(message: Localizable.passwordConfirmValidationRule))
        self.confirmPwdInputVM.maxInputLength = 16
        self.confirmPwdInputVM.config.placeholder = Localizable.inputPasswordAgain
        self.confirmPwdInputVM.config.keyboardType = .numbersAndPunctuation

        self.nicknameInputVM = MultipleRulesInputViewModel(title: Localizable.nickname, showHint: true,
                                                           rules: .custom(message: Localizable.nicknameValidateRule))
        self.nicknameInputVM.maxInputLength = 12
        self.nicknameInputVM.config.placeholder = Localizable.nicknameInputPlaceholder

        self.inviteCodeInputVM = MultipleRulesInputViewModel(title: Localizable.inviteCode,
                                                             isOptional: true,
                                                             showHint: true,
                                                             rules: .custom(message: Localizable.verificationCodeLengthValidationRule))
        self.inviteCodeInputVM.maxInputLength = 6
        let pasteboardString: String? = UIPasteboard.general.string
        if let clipboardString = pasteboardString, clipboardString.hasPrefix("gu-") {
            self.inviteCodeInputVM.config.defaultString = clipboardString
        }
        self.inviteCodeInputVM.config.placeholder = Localizable.inviteCodeInputPlaceholder
        self.accountInputVM.config.keyboardType = .numbersAndPunctuation

        super.init()
        self.initBinding()
        self.getRegisterInfo()
    }

    func checkAccount() {
        guard NetworkManager.reachability() else {
            self.errorHappened.accept(ApiError.unreachable)
            return
        }
        guard let phone = self.registerInfo.phone, let account = self.accountInputVM.outputText.value else {
            return
        }
        
        self.showLoading.accept(true)
        ApiClient.checkAccount(phone: phone, account: account)
            .subscribe(onNext: nil) { [unowned self] _ in
                self.showLoading.accept(false)
            } onCompleted: { [unowned self] in
                self.showLoading.accept(false)
                self.register()
            }.disposed(by: self.disposeBag)
    }

    private func register() {
        guard let country = self.registerInfo.country,
              let phone = self.registerInfo.phone,
              let deviceID = self.registerInfo.deviceID,
              let password = self.passwordInputVM.outputText.value,
              let account = self.accountInputVM.outputText.value,
              let nickname = self.nicknameInputVM.outputText.value,
              let number = self.registerInfo.number else {
            return
        }
        
        let inviteCode = self.inviteCodeInputVM.outputText.value ?? ""
        var socialAccount = ""
        if let vm = self.socialAccountInputVM {
            socialAccount = vm.outputText.value ?? ""
        }
        let request = ApiClient.RegisterRequset(country: country,
                                                phone: phone,
                                                password: password,
                                                username: account,
                                                nickname: nickname,
                                                device_id: deviceID,
                                                social_account: socialAccount,
                                                invite_code: inviteCode)
        
        ApiClient.register(request)
            .subscribe { [unowned self] info in
                DataAccess.shared.checkUserAccountAndDatabase(country: country, phone: number) { [weak self] in
                    self?.updateUserData(info)
                    self?.fetchUserMe()
                }
            } onError: { [unowned self] _ in
                self.showLoading.accept(false)
            } onCompleted: { [unowned self] in
                self.showLoading.accept(false)
            }.disposed(by: self.disposeBag)
    }
    
    private func fetchUserMe() {
        DataAccess.shared.fetchUserMe().subscribe { [unowned self] _ in
            self.showLoading.accept(false)
            self.goSetProfile.accept(())
        } onError: { [unowned self] _ in
            self.showLoading.accept(false)
        }.disposed(by: self.disposeBag)
    }
    
    func getRegisterInfo() {
        self.showLoading.accept(true)
        ApiClient.getRegisterInfo().subscribe { [unowned self] result in
            self.showLoading.accept(false)
            /* result 1: 隐藏 2: 显示且选填 3: 显示且必填 */
            switch result {
            case 3:
                self.socialAccountInputVM = MultipleRulesInputViewModel(title: Localizable.accountRemark,
                                                                        isOptional: false,
                                                                        showHint: true,
                                                                        rules: .alphabetAndDigit(min: 5, max: 15))
                self.socialAccountInputVM.maxInputLength = 15
                self.socialAccountInputVM.config.placeholder = Localizable.accountRemarkPlaceholder
                Observable.combineLatest(inputValidation, socialAccountInputVM.output.correct)
                    .subscribeSuccess { others, social in
                        self.nextEnable.accept(others && social)
                    }.disposed(by: disposeBag)
                
                showSocialAccount.onNext(true)
            case 2:
                self.socialAccountInputVM = MultipleRulesInputViewModel(title: Localizable.accountRemark,
                                                                        isOptional: true,
                                                                        showHint: true,
                                                                        rules: .alphabetAndDigit(min: 5, max: 15))
                self.socialAccountInputVM.maxInputLength = 15
                self.socialAccountInputVM.config.placeholder = Localizable.accountRemarkPlaceholder + Localizable.optional
                
                self.socialAccountInputVM.outputText.subscribeSuccess { [unowned self] inputText in
                    guard let text = inputText, text.count > 0 else {
                        self.socialAccountInputVM.updateCustomRuleTo(false)
                        return
                    }
                    self.socialAccountInputVM.updateCustomRuleTo(text.isValidate(type: .vtSocialAccount))
                }.disposed(by: self.disposeBag)
                
                Observable.combineLatest(inputValidation, socialAccountInputVM.output.correct)
                    .subscribeSuccess { others, social in
                    self.nextEnable.accept(others && social)
                }.disposed(by: disposeBag)
                
                showSocialAccount.onNext(true)
            default:
                inputValidation.bind(to: nextEnable).disposed(by: disposeBag)
                showSocialAccount.onNext(false)
            }
        } onError: { [unowned self] _ in
            self.showLoading.accept(false)
            self.showSocialAccount.onNext(false)
        }.disposed(by: disposeBag)
    }
}

private extension RegisterControllerVM {
    func initBinding() {
        Observable.combineLatest(self.passwordInputVM.outputText, self.confirmPwdInputVM.outputText).subscribeSuccess { [unowned self] (pwd, confirmPwd) in
            guard let pwd = pwd, let confirmPwd = confirmPwd, confirmPwd.count > 0 else {
                self.confirmPwdInputVM.updateCustomRuleTo(false)
                return
            }
            self.confirmPwdInputVM.updateCustomRuleTo(pwd == confirmPwd)
        }.disposed(by: self.disposeBag)

        self.nicknameInputVM.outputText.subscribeSuccess { [unowned self] inputText in
            guard let text = inputText, text.count > 0 else {
                self.nicknameInputVM.updateCustomRuleTo(false)
                return
            }
            self.nicknameInputVM.updateCustomRuleTo(text.isValidate(type: .vtNickname))
        }.disposed(by: self.disposeBag)

        self.inviteCodeInputVM.outputText.subscribeSuccess { [unowned self] inputText in
            guard let text = inputText, text.count > 0 else {
                self.inviteCodeInputVM.updateCustomRuleTo(false)
                return
            }
            self.inviteCodeInputVM.updateCustomRuleTo(text.isValidate(type: .vtInviteCode))
        }.disposed(by: self.disposeBag)

        inputValidation = Observable.combineLatest(self.accountInputVM.output.correct,
                                 self.passwordInputVM.output.correct,
                                 self.confirmPwdInputVM.output.correct,
                                 self.nicknameInputVM.output.correct,
                                 self.inviteCodeInputVM.output.correct)
                            .map { $0 && $1 && $2 && $3 && $4 }
    }

    func updateUserData(_ info: RLoginRegister) {
        DataAccess.shared.saveUserInformation(info)
    }
}
