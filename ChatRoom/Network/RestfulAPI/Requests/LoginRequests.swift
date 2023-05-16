//
//  LoginRequests.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/4/27.
//

import RxSwift
import Alamofire

extension ApiClient {
    
    class func accessLogin(_ token: String) -> Observable<RLoginRegister> {
        return fetch(ApiRouter.login(refreshToken: token))
    }
    
    class func parmaterLogin(country: String, phone: String, password: String) -> Observable<RLoginRegister> {
        return fetch(ApiRouter.parmaterLogin(country: country, phone: phone, password: password))
    }
    
    class func scanQRCodeLogin(deviceID: String, data: String) -> Observable<RScanQRCodeLoginResult> {
        return fetch(ApiRouter.scanLoginQRCode(deviceID: deviceID, data: data), takeoverError: true)
    }
    
    class func validateLoginQRCode(deviceID: String, data: String, passcode: String) -> Observable<Empty> {
        return fetch(ApiRouter.validateLoginQRCode(deviceID: deviceID, data: data, passcode: passcode))
    }
    
    class func recoveryAccount(country: String, phone: String, code: String) -> Observable<RRecovery> {
        return fetch(ApiRouter.recovery(country: country, phone: phone, code: code))
    }
    
    class func logout() -> Observable<Empty> {
        return fetch(ApiRouter.logout)
    }
}
