//
//  CodeVerifyViewControllerVM.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/4/26.
//

import Foundation
import RxSwift
import RxCocoa

class CodeVerifyViewControllerVM: RegisterBaseVM {

    var disposeBag = DisposeBag()

    let goCreateAccount = PublishRelay<RegisterInfo>()
    let showError = PublishSubject<String>()
    
    private(set) var verifyCodeInputVM: VerificationCodeInputViewModel

    override init() {
        self.verifyCodeInputVM = VerificationCodeInputViewModel(title: Localizable.verificationCode,
                                                                rules: .allDigit(min: 6, max: nil))
        self.verifyCodeInputVM.config.keyboardType = .numberPad
        self.verifyCodeInputVM.maxInputLength = Application.shared.maxInputLenght

        super.init()
        self.initBinding()
    }

    func initBinding() {
        self.verifyCodeInputVM.output.correct.distinctUntilChanged().bind(to: self.nextEnable).disposed(by: self.disposeBag)

        self.verifyCodeInputVM.getVerificationCodeAction.subscribeSuccess { [unowned self] _ in
            self.getVerifyCode()
        }.disposed(by: self.disposeBag)
    }

    // MARK: - Api methods
    func getVerifyCode() {
        guard NetworkManager.reachability() else {
            self.verifyCodeInputVM.finishVerificationCodeAction()
            self.errorHappened.accept(ApiError.unreachable)
            return
        }
        guard let country = self.registerInfo.country, let phone = self.registerInfo.phone, let deviceID = self.registerInfo.deviceID, let number = self.registerInfo.number else {
            return
        }
        
        self.showLoading.accept(true)
        let request = ApiClient.VerifyRequset(country: country, phone: phone, device_id: deviceID, number: number)
        ApiClient.getVerifyCode(request)
            .subscribe(onNext: nil) { [unowned self] _ in
                self.showLoading.accept(false)
                self.verifyCodeInputVM.finishVerificationCodeAction()
            } onCompleted: { [unowned self] in
                self.verifyCodeInputVM.startCountDown()
                self.showLoading.accept(false)
            }.disposed(by: self.disposeBag)
    }

    func checkVerifyCode() {
        guard NetworkManager.reachability() else {
            self.errorHappened.accept(ApiError.unreachable)
            return
        }
        guard let country = self.registerInfo.country, let phone = self.registerInfo.phone, let deviceID = self.registerInfo.deviceID, let code = self.verifyCodeInputVM.outputText.value, let number = self.registerInfo.number else {
            return
        }
        
        self.showLoading.accept(true)
        let request = ApiClient.VerifyRequset(country: country, phone: phone, device_id: deviceID, code: code, number: number)
        ApiClient.examVerifyCode(request)
            .subscribe(onError: { [unowned self] _ in
                showError.onNext(Localizable.verificationCodeErrorHint)
                self.showLoading.accept(false)
            }, onCompleted: { [unowned self] in
                let info = RegisterInfo(country: country, phone: phone, deviceID: deviceID, number: number)
                self.goCreateAccount.accept(info)
                self.showLoading.accept(false)
            }).disposed(by: disposeBag)
    }
}
