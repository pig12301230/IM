//
//  RegisterRequests.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/5/1.
//

import RxSwift
import Alamofire

extension ApiClient {

    struct RegisterRequset {
        let country: String
        let phone: String
        let password: String
        let username: String
        let nickname: String
        let device_id: String
        let social_account: String
        let invite_code: String
    }

    /* result： 1:隐藏, 2:显示且选填, 3:显示且必填 */
    class func getRegisterInfo() -> Observable<Int> {
        return fetch(ApiRouter.getRegisterInfo)
    }
    
    class func register(_ request: RegisterRequset) -> Observable<RLoginRegister> {
        return fetch(ApiRouter.reigster(request: request))
    }

    class func checkAccount(phone: String, account: String) -> Observable<Empty> {
        return fetch(ApiRouter.checkAccount(phone: phone, account: account))
    }
}
