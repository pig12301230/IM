//
//  ForgotPasswordViewControllerVM.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/4/22.
//

import Foundation
import RxSwift
import RxCocoa

class ForgotPasswordViewControllerVM: ReachableViewControllerVM {
    var disposeBag = DisposeBag()
    
    /// Output for view controller
    let submitEnable: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    let errorMessage = PublishSubject<String>()
    let resetBy = PublishSubject<String>()
    let shouldReload = PublishSubject<Void>()
    /**
     呼叫API時使用, 當收到 error and complete(next) 呼叫
     */
    let showLoading: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    
    private(set) var regionInputViewModel: TitleInputViewModel
    private(set) var phoneInputViewModel: PhoneInputViewModel
    private(set) var verificationCodeInputViewModel: VerificationCodeInputViewModel
    private(set) var regionSelectVM: SelectRegionViewControllerVM = SelectRegionViewControllerVM.init()
    
    override init() {
        self.regionInputViewModel = TitleInputViewModel.init(title: Localizable.countryAndRegion, inputEnable: false)
        self.regionInputViewModel.inputTextFont = .midiumParagraphLargeLeft
        
        self.phoneInputViewModel = PhoneInputViewModel.init(title: "", rules: .custom(message: ""))
        self.phoneInputViewModel.config.placeholder = Localizable.inputCellphoneNumbers
        self.phoneInputViewModel.config.keyboardType = .numberPad
        self.phoneInputViewModel.maxInputLength = Application.shared.maxInputLenght
        
        self.verificationCodeInputViewModel = VerificationCodeInputViewModel.init(title: Localizable.verificationCode, rules: .allDigit(min: 1, max: nil))
        self.verificationCodeInputViewModel.maxInputLength = Application.shared.maxInputLenght
        
        super.init()
        self.initBinding()
    }
    
    func getPhoneTitle() -> String {
        guard let digit = self.regionSelectVM.localeDigit.value, let number = self.phoneInputViewModel.outputText.value else {
            return ""
        }
        
        return digit + " " + number
    }
    
    func getCurrentCountryCode() -> String {
        return self.regionSelectVM.localeCountryCode
    }
    
    func recoveryAccount() {
        guard self.isReachable() else {
            return
        }
        
        guard let code = self.verificationCodeInputViewModel.outputText.value else {
            return
        }
        
        let phone = self.getPhoneNumber()
        
        self.showLoading.accept(true)
        ApiClient.recoveryAccount(country: self.regionSelectVM.localeCountryCode, phone: phone, code: code).subscribeOn { [unowned self] (access) in
            self.resetBy.onNext((access.access_token))
            self.showLoading.accept(false)
        } error: { [unowned self] _ in
            self.showLoading.accept(false)
        }.disposed(by: self.disposeBag)
    }
}

private extension ForgotPasswordViewControllerVM {
    
    func initBinding() {
        self.regionSelectVM.localeDigit.bind(to: self.phoneInputViewModel.typeTitle).disposed(by: self.disposeBag)
        self.regionSelectVM.localeCountryName.bind(to: self.regionInputViewModel.outputText).disposed(by: self.disposeBag)
        
        Observable.combineLatest(self.phoneInputViewModel.output.correct, self.verificationCodeInputViewModel.output.correct).subscribeSuccess { [unowned self] (term1, term2) in
            self.submitEnable.accept(term1 && term2)
        }.disposed(by: self.disposeBag)
        
        self.phoneInputViewModel.output.correct.distinctUntilChanged().subscribeSuccess { [unowned self] enable in
            self.verificationCodeInputViewModel.layoutStyleEnable.accept(enable)
            self.verificationCodeInputViewModel.isUserInteractionEnabled.onNext(enable)
        }.disposed(by: self.disposeBag)
        
        self.verificationCodeInputViewModel.getVerificationCodeAction.subscribeSuccess { [unowned self] _ in
            self.fetchVerifyCode()
        }.disposed(by: self.disposeBag)
        
        self.regionSelectVM.locateCountryCode.bind(to: self.phoneInputViewModel.countryCode).disposed(by: self.disposeBag)
        
        self.verificationCodeInputViewModel.isCounting.distinctUntilChanged().subscribeSuccess { [unowned self] counting in
            self.setRegionAndPhoneInput(enable: !counting)
        }.disposed(by: self.disposeBag)
    }
    
    func fetchVerifyCode() {
        guard self.isReachable() else {
            self.verificationCodeInputViewModel.finishVerificationCodeAction()
            return
        }
        
        self.showLoading.accept(true)
        
        let request = ApiClient.VerifyRequset(country: self.regionSelectVM.localeCountryCode, phone: self.getPhoneNumber(), device_id: AppConfig.Device.uuid, number: self.phoneInputViewModel.outputText.value ?? "")
        ApiClient.getVerifyCode(request).subscribe(onNext: nil) { [unowned self] _ in
            self.verificationCodeInputViewModel.finishVerificationCodeAction()
            self.showLoading.accept(false)
        } onCompleted: { [unowned self] in
            self.showLoading.accept(false)
            self.verificationCodeInputViewModel.startCountDown()
            self.setRegionAndPhoneInput(enable: false)
        }.disposed(by: self.disposeBag)
    }
    
    func getPhoneNumber() -> String {
        guard let digit = self.phoneInputViewModel.typeTitle.value,
              let number = self.phoneInputViewModel.outputText.value else {
            return ""
        }
        
        var phone: String = digit + number
        phone.remove(at: phone.startIndex)
        return phone
    }
    
    func setRegionAndPhoneInput(enable: Bool) {
        self.regionInputViewModel.interactionEnabled.accept(enable)
        self.phoneInputViewModel.interactionEnabled.accept(enable)
    }
}
