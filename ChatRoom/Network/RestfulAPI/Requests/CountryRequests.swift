//
//  CountryRequests.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/5/11.
//

import Foundation
import RxSwift

extension ApiClient {

    class func getCountryCode() -> Observable<[RCountryCode]> {
        print("path: ", NetworkConfig.URL.APIBaseURL, NetworkConfig.Path.country)
        return fetch(ApiRouter.country, takeoverError: true)
    }
}
