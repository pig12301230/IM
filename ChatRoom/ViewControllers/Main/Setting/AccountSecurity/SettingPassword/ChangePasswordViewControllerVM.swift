//
//  ChangePasswordViewControllerVM.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/7/29.
//

import Foundation
import RxSwift
import RxCocoa

enum AlertNoticeType {
    case resetSuccess
    case oldPasswordError
    case getVerificationCodeByPhone
    
    var message: String {
        switch self {
        case .resetSuccess:
            return Localizable.resetPasswordSuccess
        case .oldPasswordError:
            return Localizable.oldPasswordErrorRefill
        case .getVerificationCodeByPhone:
            return Localizable.getVerificationCode + "+" + (UserData.shared.userInfo?.phone ?? "")
        }
    }
    
    var dismissActionName: String {
        switch self {
        case .getVerificationCodeByPhone:
            return Localizable.cancel
        default:
            return Localizable.sure
        }
    }
    
    var goBackAferDismiss: Bool {
        switch self {
        case .resetSuccess:
            return true
        default:
            return false
        }
    }
    
    var nextActionName: String? {
        switch self {
        case .getVerificationCodeByPhone:
            return Localizable.sure
        default:
            return nil
        }
    }
}

class ChangePasswordViewControllerVM: BaseViewModel {
    /**
     兩種 Type:
     1. 需輸入舊密碼 and 新密碼
     2. 僅輸入新密碼
     */
    enum ChangePasswordType {
        case withOldPassword
        case withoutOldPassword
        var submitTitle: String {
            return Localizable.done
        }
        
        var showBackButton: Bool {
            switch self {
            case .withOldPassword:
                return true
            case .withoutOldPassword:
                return false
            }
        }
    }
    
    struct Output {
        let submitEnable: BehaviorRelay<Bool> = BehaviorRelay(value: false)
        let alertType = PublishSubject<AlertNoticeType>()
        let gotoScene = PublishSubject<Navigator.Scene>()
    }
    
    struct Input {
        let resetAction = PublishSubject<Void>()
        let forgotAction = PublishSubject<Void>()
        let doAlertNextAction = PublishSubject<AlertNoticeType>()
    }
    
    var disposeBag = DisposeBag()
    
    private(set) var userIDTitleViewModel: TitleInputViewModel
    private(set) var originalInputViewModel: MultipleRulesInputViewModel
    private(set) var newPasswordInputViewModel: MultipleRulesInputViewModel
    private(set) var confirmPasswordInputViewModel: MultipleRulesInputViewModel
    private var oneTimeToken: String?
    let changePasswordType: ChangePasswordType
    let input = Input()
    let output = Output()
    
    init(type: ChangePasswordType, token: String? = nil) {
        self.changePasswordType = type
        
        self.userIDTitleViewModel = TitleInputViewModel.init(title: Localizable.userID, inputEnable: false, showStatus: false)
        self.userIDTitleViewModel.config.defaultString = UserData.shared.userInfo?.nickname ?? ""
        
        self.originalInputViewModel = MultipleRulesInputViewModel.init(title: Localizable.oldPassword,
                                                                       needSecurity: true, showHint: false,
                                                                       rules: .limit(min: 1, max: 16))
        self.originalInputViewModel.maxInputLength = 16
        self.originalInputViewModel.config.placeholder = Localizable.oldPasswordPlaceholder
        self.originalInputViewModel.config.keyboardType = .numbersAndPunctuation
        
        self.newPasswordInputViewModel = MultipleRulesInputViewModel.init(title: Localizable.newPassword,
                                                                          needSecurity: true, showHint: true,
                                                                          rules: .alphabetAndDigit(min: 8, max: 16),
                                                                          .atLeastAlphabet(count: 1),
                                                                          .atLeastDigit(count: 1))
        self.newPasswordInputViewModel.maxInputLength = 16
        self.newPasswordInputViewModel.config.placeholder = Localizable.newPasswordPlaceholder
        self.newPasswordInputViewModel.config.keyboardType = .numbersAndPunctuation
        
        self.confirmPasswordInputViewModel = MultipleRulesInputViewModel.init(title: Localizable.confirmPassword,
                                                                              needSecurity: true,
                                                                              showHint: true,
                                                                              rules: .custom(message: Localizable.passwordConfirmValidationRule))
        self.confirmPasswordInputViewModel.maxInputLength = 16
        self.confirmPasswordInputViewModel.config.placeholder = Localizable.newPasswordConfirmPlaceholder
        self.confirmPasswordInputViewModel.config.keyboardType = .numbersAndPunctuation
        
        super.init()
        self.oneTimeToken = token
        self.initBinding()
    }
    
    func initBinding() {
        Observable.combineLatest(self.confirmPasswordInputViewModel.outputText, self.newPasswordInputViewModel.outputText).subscribeSuccess { [unowned self] (confirm, original) in
            guard let confirm = confirm, !confirm.isEmpty, let original = original, confirm == original else {
                self.confirmPasswordInputViewModel.updateCustomRuleTo(false)
                return
            }
            
            self.confirmPasswordInputViewModel.updateCustomRuleTo(confirm == original)
        }.disposed(by: self.disposeBag)
        
        if self.changePasswordType == .withOldPassword {
            Observable.combineLatest(self.originalInputViewModel.output.correct, self.newPasswordInputViewModel.output.correct, self.confirmPasswordInputViewModel.output.correct).subscribeSuccess { [unowned self] (term1, term2, term3) in
                let enable = term1 && term2 && term3
                self.output.submitEnable.accept(enable)
            }.disposed(by: self.disposeBag)
        } else {
            Observable.combineLatest(self.newPasswordInputViewModel.output.correct, self.confirmPasswordInputViewModel.output.correct).subscribeSuccess { [unowned self] (term1, term2) in
                let enable = term1 && term2
                self.output.submitEnable.accept(enable)
            }.disposed(by: self.disposeBag)
        }
        
        self.input.resetAction.subscribeSuccess { _ in
            PRINT("reset action")
            self.resetPassword()
        }.disposed(by: self.disposeBag)
        
        self.input.forgotAction.subscribeSuccess { [unowned self] _ in
            self.output.alertType.onNext(.getVerificationCodeByPhone)
        }.disposed(by: self.disposeBag)
        
        self.input.doAlertNextAction.subscribeSuccess { [unowned self] actionType in
            switch actionType {
            case .getVerificationCodeByPhone:
                self.getVerifyCode()
            default:
                break
            }
        }.disposed(by: self.disposeBag)
    }
}

private extension ChangePasswordViewControllerVM {
    
    func getVerifyCode() {
        guard let info = UserData.shared.userInfo else { return }
        let request = ApiClient.VerifyRequset(country: info.country,
                                              phone: info.phone,
                                              device_id: AppConfig.Device.uuid,
                                              number: "")
        
        ApiClient.getVerifyCode(request)
            .subscribe(onCompleted: { [unowned self] in
                let vm = FillVerificationCodeViewControllerVM.init()
                let fillScene = Navigator.Scene.fillVerificationCode(vm: vm)
                self.output.gotoScene.onNext(fillScene)
            }).disposed(by: self.disposeBag)
    }
    
    func resetPassword() {
        switch self.changePasswordType {
        case .withOldPassword:
            self.resetWithOldPassword()
        case .withoutOldPassword:
            self.resetWithoutOldPassword()
        }
    }
    
    func resetWithOldPassword() {
        guard let oldPassword = self.originalInputViewModel.outputText.value, let newPassword = self.newPasswordInputViewModel.outputText.value else {
            return
        }
        
        ApiClient.updatePassword(from: oldPassword, to: newPassword).subscribe(onCompleted: {[unowned self] in
            self.output.alertType.onNext(.resetSuccess)
        }).disposed(by: self.disposeBag)
    }
    
    func resetWithoutOldPassword() {
        guard let password = self.newPasswordInputViewModel.outputText.value, let token = self.oneTimeToken else {
            return
        }
        
        ApiClient.resetUserPassword(password: password, oneTimeToken: token).subscribe(onNext: nil) { _ in
            // Fail
        } onCompleted: { [unowned self] in
            self.output.alertType.onNext(.resetSuccess)
        }.disposed(by: self.disposeBag)
    }
}
