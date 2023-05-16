//
//  WalletRequests.swift
//  ChatRoom
//
//  Created by ERay_Peng on 2023/4/20.
//

import Foundation
import RxSwift
import RxCocoa
import Alamofire

extension ApiClient {
    class func getMediumBinding() -> Observable<RWalletProvider> {
        return fetch(.getMediumBinding)
    }
    
    class func wellPayExchange(amount: String, securityCode: String) -> Observable<Empty> {
        return fetch(.wellPayExchange(amount: amount, securityCode: securityCode))
    }
    
    class func bindWellPayWallet(code: String, address: String) -> Observable<Empty> {
        return fetch(.bindWellPayWallet(code: code, address: address))
    }
}
