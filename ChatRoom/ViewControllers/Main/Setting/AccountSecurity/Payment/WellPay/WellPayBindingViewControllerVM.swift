//
//  WellPayBindingViewControllerVM.swift
//  ChatRoom
//
//  Created by ERay_Peng on 2023/2/20.
//

import Foundation
import RxSwift
import RxCocoa

enum WellPayBindAlertType {
    case securityCodeError
    case firstTimeBind
    
    var title: String? {
        switch self {
        case .securityCodeError:
            return nil
        case .firstTimeBind:
            return Localizable.pleaseAttention
        }
    }
    
    var alertContent: String {
        switch self {
        case .securityCodeError:
            return Localizable.sercurityPasswordInputError
        case .firstTimeBind:
            return Localizable.firstTimeExchangeWellPayHint
        }
    }
    
    var cancelBtnTitle: String? {
        switch self {
        case .securityCodeError:
            return nil
        case .firstTimeBind:
            return Localizable.cancel
        }
    }
}

class WellPayBindingViewControllerVM: BaseViewModel {
    
    struct Output {
        let submitEnable: BehaviorRelay<Bool> = BehaviorRelay(value: false)
        let alertType = PublishSubject<WellPayBindAlertType>()
        let popToExchangeAndGoto = PublishSubject<Navigator.Scene>()
        let showToast = PublishSubject<String>()
    }
    
    var disposeBag = DisposeBag()
    
    private(set) var walletTitleInputViewModel: MultipleRulesInputViewModel
    private(set) var walletAddressInputViewModel: MultipleRulesInputViewModel
    private(set) var securityPasswordInputViewModel: MultipleRulesInputViewModel
    
    let output = Output()
    
    override init() {
        self.walletTitleInputViewModel = MultipleRulesInputViewModel.init(title: Localizable.walletName)
        self.walletTitleInputViewModel.config.placeholder = Localizable.wellPay

        
        self.walletAddressInputViewModel = MultipleRulesInputViewModel.init(title: Localizable.walletAddress,
                                                                            check: false,
                                                                            rules: .limit(min: 1, max: nil))
        self.walletAddressInputViewModel.config.placeholder = Localizable.pleaseEnterWalletAddress
        self.walletAddressInputViewModel.config.keyboardType = .numbersAndPunctuation
        
        
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
    }
    
    func initBinding() {
        
        Observable.combineLatest(self.walletAddressInputViewModel.output.correct,
                                 self.securityPasswordInputViewModel.output.correct).subscribeSuccess { [weak self] (term1, term2) in
            guard let self = self else { return }
            let enable = term1 && term2
            self.output.submitEnable.accept(enable)
        }.disposed(by: self.disposeBag)
    }
    
    func submit() {
        self.output.alertType.onNext(.firstTimeBind)
    }
    
    func bindWellPayWallet() {
        guard let securityPassword = self.securityPasswordInputViewModel.outputText.value,
              let address = self.walletAddressInputViewModel.outputText.value else { return }
        DataAccess.shared.bindWellPayWallet(securityPassword, address)
            .subscribeSuccess { [weak self] error in
                guard let self = self else { return }
                guard let error = error as? ApiError else {
                    let vm = WellPayExchangeViewControllerVM(walletAddress: address)
                    self.output.popToExchangeAndGoto.onNext(.wellPayExchange(vm: vm))
                    return
                }
                if case .requestError(let code, _, _) = error {
                    // failed
                    if code == "api.body.param_invalid.code" {
                        self.output.alertType.onNext(.securityCodeError)
                    }
                }
            }
            .disposed(by: disposeBag)
    }
    
    func popToExchangeAndGotoWellPayExchange() {
        let vm = WellPayExchangeViewControllerVM(walletAddress: self.walletAddressInputViewModel.outputText.value ?? "")
        self.output.popToExchangeAndGoto.onNext(.wellPayExchange(vm: vm))
    }
}
