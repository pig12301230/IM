//
//  HongBaoRequests.swift
//  ChatRoom
//
//  Created by ERay_Peng on 2022/12/27.
//

import Foundation
import RxSwift
import RxCocoa
import Alamofire

extension ApiClient {
    static func getHongBaoBalance() -> Observable<RHongBaoBalance> {
        return fetch(ApiRouter.getHongBaoBalance, takeoverError: true)
    }
    
    static func getHongBaoRecord() -> Observable<RHongBaoRecord> {
        return fetch(ApiRouter.getHongBaoRecord, takeoverError: true)
    }
    
    static func getUserHongBao(campaignID: String) -> Observable<RUserHongBao> {
        return fetch(.getHongBao(campaignID: campaignID), takeoverError: true)
    }
    
    static func getGroupHongBaoNumbers(groupID: String) -> Observable<RHongBaoUnOpened> {
        return fetch(.getHongBaoNumbers(groupID: groupID), takeoverError: true)
    }
    
    static func getHongBaoClaimStatus(campaignID: String) -> Observable<RHongBaoClaimStatus> {
        return fetch(.getHongBaoClaimStatus(campaignID: campaignID), takeoverError: true)
    }
}
