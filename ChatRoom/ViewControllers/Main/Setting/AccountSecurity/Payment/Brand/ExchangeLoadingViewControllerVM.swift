//
//  ExchangeLoadingViewControllerVM.swift
//  GuChat
//
//  Created by ERay_Peng on 2023/2/16.
//

import RxSwift
import RxCocoa

enum ExchangeResult {
    case success
    case addressFail
    case addressErrorOrBindingUnmatch
    
    var toastOrAlertTxt: String {
        switch self {
        case .success:
            return Localizable.exchangeSuccessHint
        case .addressFail:
            return Localizable.exchangeAddressFail
        case .addressErrorOrBindingUnmatch:
            return Localizable.exchangeAddressUnmatchHint
        }
    }
}

class ExchangeLoadingViewControllerVM {
    
    let exchangeResult = PublishSubject<ExchangeResult>()
    
    init() {
        self.executeExchange()
    }
    
    private func executeExchange() {
        // throw ExchangeResult
    }
}
