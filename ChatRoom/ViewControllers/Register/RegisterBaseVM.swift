//
//  RegisterBaseVM.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/5/4.
//

import Foundation
import RxCocoa

class RegisterBaseVM: BaseViewModel {

    struct RegisterInfo {
        var country: String?
        var phone: String?
        var deviceID: String?
        var account: String?
        var nickname: String?
        var password: String?
        var inviteCode: String?
        var number: String?
    }

    var registerInfo = RegisterInfo()
    
    /**
     呼叫API時使用, 當收到 error and complete(next) 呼叫
     */
    let showLoading: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    let errorHappened = PublishRelay<Error>()
    let nextEnable: BehaviorRelay<Bool> = BehaviorRelay(value: false)
}
