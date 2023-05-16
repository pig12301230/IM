//
//  UserRequests.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/4/14.
//

import Foundation
import Alamofire
import RxSwift
import RxCocoa

extension ApiClient {

    struct VerifyRequset {
        let country: String
        let phone: String
        let device_id: String
        var code: String = ""
        let number: String
    }

    class func phoneVerify(_ request: VerifyRequset) -> Observable<Int> {
        return fetch(ApiRouter.phoneVerify(request: request))
    }

    class func getVerifyCode(_ request: VerifyRequset) -> Observable<Empty> {
        return fetch(ApiRouter.getVerifyCode(request: request))
    }

    class func examVerifyCode(_ request: VerifyRequset) -> Observable<Empty> {
        return fetch(ApiRouter.examVerifyCode(request: request), takeoverError: true)
    }
}
