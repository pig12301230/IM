//
//  MultiRequestAPI.swift
//  ChatRoom
//
//  Created by ERay_Peng on 2022/8/29.
//

import Foundation
import Alamofire

enum MultiRequestAPI {
    case parallel
    case iterate
    
    func request(domains: [String], target: String, completion: @escaping (String?) -> Void) {
        switch self {
        case .parallel:
            let request = ParallelRequest(domains: domains, target: target, completion: completion)
            request.request()
        case .iterate:
            break
        }
    }
}

private class ParallelRequest {
    private let domains: [String]
    private let target: String
    private var result: [String] = []
    private let completion: ((String?) -> Void)?
    private var isRequestDone: Bool = false
    
    init(domains: [String], target: String, completion: ((String?) -> Void)? = nil) {
        self.domains = domains
        self.target = target
        self.completion = completion
    }
    
    func request() {
        for domain in domains {
            CustomAFSession.session.request("https://" + domain + self.target).validate().response { result in
                switch result.result {
                case.success(_):
                    self.handelResult(domain)
                    self.result.append(domain)
                case .failure(_):
                    break
                }
            }
        }
        
    }
    
    private func handelResult(_ target: String) {
        guard !self.isRequestDone else { return }
        self.isRequestDone.toggle()
        self.completion?(target)
    }
}
