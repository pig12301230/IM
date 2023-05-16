//
//  ApiClient+util.swift
//  ChatRoom
//
//  Created by Kedia on 2023/4/6.
//

import Foundation
import Alamofire

extension ApiClient {
    
    @discardableResult
    final class func sendJiraIssueRequest(name: String, password: String, issueNo: String, fileURL: URL) async -> JiraResponse? {
#if !DEBUG
        return nil
#else
        let authString = "\(name):\(password)"
        guard let authData = authString.data(using: .utf8) else {
            return nil
        }
        let authValue = "Basic \(authData.base64EncodedString())"
        
        let headers: HTTPHeaders = [
            "Authorization": authValue,
            "X-Atlassian-Token": "nocheck"
        ]
        
        guard let endpointURL = URL(string: "https://jira.paradise-soft.com.tw/rest/api/2/issue/IOS-\(issueNo)/attachments") else {
            return nil
        }
        
        return try? await withCheckedThrowingContinuation { continuation in
            CustomAFSession.session.upload(multipartFormData: { multipartFormData in
                multipartFormData.append(fileURL, withName: "file")
            }, to: endpointURL, headers: headers)
            .responseData { response in
                switch response.result {
                case .success(let data):
                    let objs = try? JSONDecoder().decode([JiraResponse].self, from: data)
                    continuation.resume(returning: objs?.first)
                case .failure( _):
                    continuation.resume(returning: nil)
                }
            }
            
        }
#endif
    }
    
    
}
