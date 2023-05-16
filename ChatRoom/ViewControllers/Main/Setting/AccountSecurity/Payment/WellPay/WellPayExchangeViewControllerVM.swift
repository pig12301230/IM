//
//  WellPayExchangeViewControllerVM.swift
//  ChatRoom
//
//  Created by ERay_Peng on 2023/2/23.
//

import Foundation
import RxSwift
import RxCocoa

enum WellPayExchangeAlertType {
    case exchangeFailed
    case mediumFailed
    case securityInputError
    
    var description: String {
        switch self {
        case .exchangeFailed:
            return Localizable.insufficientPointsHint
        case .mediumFailed:
            return Localizable.exchangeDisableHint
        case .securityInputError:
            return Localizable.securityCodeError
        }
    }
}

class WellPayExchangeViewControllerVM: BaseViewModel {
    
    struct Output {
        let submitEnable: BehaviorRelay<Bool> = BehaviorRelay(value: false)
        let isUserInteractionEnabled: BehaviorRelay<Bool> = BehaviorRelay(value: true)
        let wellPayExchangeAlert = PublishSubject<WellPayExchangeAlertType>()
        let gotoScene = PublishSubject<Navigator.Scene>()
        let showToast = PublishSubject<String>()
        let balance: BehaviorRelay<String?> = .init(value: nil)
        let isHiddenExchangeAlert = PublishSubject<Bool>()
        let isHiddenSecurityAlert = PublishSubject<Bool>()
    }
    
    var disposeBag = DisposeBag()
    
    private(set) var walletTitleViewModel: TitleInputViewModel
    private(set) var exchangeInputViewModel: MultipleRulesInputViewModel
    private(set) var securityPasswordInputViewModel: MultipleRulesInputViewModel
    
    let output = Output()
    
    init(walletAddress: String) {
        
        self.walletTitleViewModel = TitleInputViewModel.init(title: Localizable.walletAddress,
                                                             inputEnable: false,
                                                             showStatus: false)
        self.walletTitleViewModel.config.placeholder = walletAddress

        self.exchangeInputViewModel = MultipleRulesInputViewModel.init(title: Localizable.exchangeAmount,
                                                                       check: false)
        self.exchangeInputViewModel.config.placeholder = Localizable.exchangeAmountHint
        self.exchangeInputViewModel.config.keyboardType = .decimalPad
        
        self.securityPasswordInputViewModel = MultipleRulesInputViewModel.init(title: Localizable.securityPassword,
                                                                               needSecurity: true,
                                                                               canCheckSecurity: false,
                                                                               check: false,
                                                                               rules: .specifyNumber(count: 6),
                                                                               needKerning: true,
                                                                               clearButtonMode: .never)
        self.securityPasswordInputViewModel.maxInputLength = 6
        self.securityPasswordInputViewModel.config.keyboardType = .numberPad
        
        super.init()
        self.initBinding()
        self.fetchBalance()
    }
    
    func initBinding() {
        Observable.combineLatest(self.exchangeInputViewModel.output.correct,
                                 self.exchangeInputViewModel.outputText,
                                 self.securityPasswordInputViewModel.output.correct)
            .observe(on: MainScheduler.instance)
            .subscribeSuccess { [weak self] (term1, term1Text, term2) in
                guard let self = self else { return }
                let exchangeInputIsEmpty = term1Text?.isEmpty ?? true
                self.output.isHiddenExchangeAlert.onNext(exchangeInputIsEmpty || term1)
                let validInput = term1Text?.isPositiveFormatNumber(with: 9, decimal: 2) ?? false
                self.output.submitEnable.accept(term1 && term2 && validInput)
            }.disposed(by: self.disposeBag)
        
        self.securityPasswordInputViewModel.outputText
            .observe(on: MainScheduler.instance)
            .subscribeSuccess { [weak self] _ in
                guard let self = self else { return }
                self.output.isHiddenSecurityAlert.onNext(true)
            }.disposed(by: self.disposeBag)
    }
    
    func submit() {
        guard let amount = self.exchangeInputViewModel.outputText.value,
              let securityCode = self.securityPasswordInputViewModel.outputText.value else { return }
        self.output.isUserInteractionEnabled.accept(false)
        DataAccess.shared.wellPayExchange(amount, securityCode).subscribeSuccess { [weak self] error in
            guard let self = self else { return }
            guard let error = error as? ApiError else {
                // success
                self.output.showToast.onNext(Localizable.exchangeSuccessHint)
                return
            }
            if case .requestError(let code, _, _) = error {
                // failed
                if code == "api.body.param_invalid.balance" {
                    self.output.wellPayExchangeAlert.onNext(.exchangeFailed)
                } else if code == "api.body.param_invalid.security_code" {
                    self.output.wellPayExchangeAlert.onNext(.securityInputError)
                    self.output.isHiddenSecurityAlert.onNext(false)
                    self.fetchBalance()
                } else {
                    self.output.wellPayExchangeAlert.onNext(.mediumFailed)
                }
            }
        }.disposed(by: disposeBag)
    }
    
    func fetchBalance() {
        DataAccess.shared.getWalletBalance { [weak self] _, balance in
            guard let self = self else { return }
            self.output.balance.accept(balance)
            let amount: Double = Double(balance ?? "") ?? 0.0
            self.exchangeInputViewModel.setupRules([.largerNumber(original: amount)])
        }
    }
}
