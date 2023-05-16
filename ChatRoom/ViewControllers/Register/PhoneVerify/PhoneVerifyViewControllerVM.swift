//
//  PhoneVerifyViewControllerVM.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/4/21.
//

import Foundation
import RxSwift
import RxCocoa
import libPhoneNumber_iOS

class PhoneVerifyViewControllerVM: RegisterBaseVM {

    enum PhoneVerifyStatus: Int {
        case notVerified = 1, verified
    }

    var disposeBag = DisposeBag()

    let phoneValid: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    let agreementRead: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    let verifyCompleted = PublishRelay<(PhoneVerifyStatus, RegisterInfo)>()

    private(set) var regionInputVM: TitleInputViewModel
    private(set) var phoneInputVM: PhoneInputViewModel

    private(set) var regionSelectVM = SelectRegionViewControllerVM()

    override init() {
        self.regionInputVM = TitleInputViewModel(title: Localizable.countryAndRegion, inputEnable: false)
        self.regionInputVM.inputTextFont = .midiumParagraphLargeLeft

        self.phoneInputVM = PhoneInputViewModel(title: "", rules: .custom(message: ""))
        self.phoneInputVM.config.placeholder = Localizable.inputCellphoneNumbers
        self.phoneInputVM.config.keyboardType = .numberPad
        self.phoneInputVM.maxInputLength = Application.shared.maxInputLenght

        super.init()
        self.initBinding()
    }

    // MARK: - Api methods
    func checkPhone() {
        guard NetworkManager.reachability() else {
            self.errorHappened.accept(ApiError.unreachable)
            return
        }
        
        self.showLoading.accept(true)
        let request = ApiClient.VerifyRequset(country: self.regionSelectVM.localeCountryCode,
                                              phone: self.getPhoneNumber(),
                                              device_id: AppConfig.Device.uuid,
                                              number: self.phoneInputVM.outputText.value ?? "")
        ApiClient.phoneVerify(request)
            .subscribe { [unowned self] result in
                let verified: PhoneVerifyStatus = PhoneVerifyStatus(rawValue: result) ?? .notVerified
                let info = RegisterInfo(country: request.country, phone: request.phone, deviceID: request.device_id, number: request.number)
                self.verifyCompleted.accept((verified, info))
            } onError: { [unowned self] _ in
                self.showLoading.accept(false)
            } onCompleted: { [unowned self] in
                self.showLoading.accept(false)
            } .disposed(by: self.disposeBag)
    }
}

private extension PhoneVerifyViewControllerVM {
    func initBinding() {
        self.regionSelectVM.localeDigit.bind(to: self.phoneInputVM.typeTitle).disposed(by: self.disposeBag)
        self.regionSelectVM.localeCountryName.bind(to: self.regionInputVM.outputText).disposed(by: self.disposeBag)

        Observable.combineLatest(self.phoneInputVM.output.correct, self.agreementRead).subscribeSuccess { [unowned self] (term1, term2) in
            self.nextEnable.accept(term1 && term2)
        }.disposed(by: self.disposeBag)
        
        self.regionSelectVM.locateCountryCode.bind(to: self.phoneInputVM.countryCode).disposed(by: self.disposeBag)
    }
    
    func getPhoneNumber() -> String {
        guard var countryCode = self.phoneInputVM.typeTitle.value, let phone = self.phoneInputVM.outputText.value else {
            return ""
        }
        countryCode.removeFirst()
        return countryCode + phone
    }
}
