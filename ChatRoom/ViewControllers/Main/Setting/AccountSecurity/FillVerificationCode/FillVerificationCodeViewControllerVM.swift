//
//  FillVerificationCodeViewControllerVM.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/7/30.
//

import Foundation
import RxSwift
import RxCocoa

class FillVerificationCodeViewControllerVM: BaseViewModel {
    struct Output {
        let submitEnable: BehaviorRelay<Bool> = BehaviorRelay(value: false)
        let popToSecurityAndGoto = PublishSubject<Navigator.Scene>()
    }
    
    struct Input {
        let submitAction = PublishSubject<Void>()
    }
    var disposeBag = DisposeBag()
    let input = Input()
    let output = Output()
    
    private(set) var phoneTitleViewModel: TitleInputViewModel
    private(set) var verificationCodeInputViewModel: MultipleRulesInputViewModel
    
    override init() {
        self.phoneTitleViewModel = TitleInputViewModel.init(title: Localizable.phoneNumber, inputEnable: false, showStatus: false)
        self.phoneTitleViewModel.config.defaultString = "+" + (UserData.shared.userInfo?.phone ?? "")
        
        self.verificationCodeInputViewModel = MultipleRulesInputViewModel.init(title: Localizable.verificationCode, rules: .allDigit(min: 6, max: 6))
        self.verificationCodeInputViewModel.config.placeholder = Localizable.pleaseInputVerificationCode
        self.verificationCodeInputViewModel.config.keyboardType = .numberPad
        self.verificationCodeInputViewModel.maxInputLength = Application.shared.maxInputLenght
        
        super.init()
        self.initBinding()
    }
    
    func getVerifyCode() {
        guard let info = UserData.shared.userInfo else { return }
        
        let request = ApiClient.VerifyRequset(country: info.country,
                                              phone: info.phone,
                                              device_id: AppConfig.Device.uuid,
                                              number: "")
        ApiClient.getVerifyCode(request)
            .subscribe()
            .disposed(by: self.disposeBag)
    }
}

private extension FillVerificationCodeViewControllerVM {
    func initBinding() {
        self.verificationCodeInputViewModel.output.correct.distinctUntilChanged().bind(to: self.output.submitEnable).disposed(by: self.disposeBag)
        
        self.input.submitAction.subscribeSuccess { [unowned self] _ in
            self.examVerifyCode()
        }.disposed(by: self.disposeBag)
    }
    
    func examVerifyCode() {
        guard let info: RAccountInfo = UserData.shared.userInfo, let code = self.verificationCodeInputViewModel.outputText.value  else {
            return
        }
        
        ApiClient.recoveryAccount(country: info.country, phone: info.phone, code: code).subscribeOn { [unowned self] (access) in
            let vm = ChangePasswordViewControllerVM.init(type: .withoutOldPassword, token: access.access_token)
            let changePasswoed = Navigator.Scene.changePassword(vm: vm)
            self.output.popToSecurityAndGoto.onNext(changePasswoed)
        } error: { _ in
            
        }.disposed(by: self.disposeBag)
    }
}
