//
//  Alamofire+util.swift
//  ChatRoom
//
//  Created by Kedia on 2023/4/11.
//

import Foundation
import Alamofire

/// 在 Debug 環境下攔截 Restful API request/response 內容的 class
final class CustomAFSession {
    
    static let session: Session = {
        return CustomAFSession.shared.session
    }()
    
    private static let shared: CustomAFSession = CustomAFSession()
    
    private lazy var session: Session = {
#if DEBUG
        return debugSession
#else
        return AF
#endif
    }()
    
    private lazy var requestInterceptor = {
        return CustomRequestInterceptor()
    }()
    private lazy var eventMonitor = {
        return CustomEventMonitor()
    }()
    
    private lazy var debugSession: Session = {
        return Session(interceptor: requestInterceptor, eventMonitors: [eventMonitor])
    }()
}

final class CustomRequestInterceptor: RequestInterceptor {
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        
        let adaptedRequest = urlRequest
        let urlString = urlRequest.url?.absoluteString ?? ""
        if let httpBody = urlRequest.httpBody, let bodyString = String(data: httpBody, encoding: .utf8) {
            PRINT("送出 Request URL: \(urlString)\tbody: \(bodyString)", ignoresThirdParty: true)
        } else {
            PRINT("送出 Request URL: \(urlString)", ignoresThirdParty: true)
        }

        completion(.success(adaptedRequest))
    }
}

final class CustomEventMonitor: EventMonitor {
    
    func requestDidFinish(_ request: Request) {
        guard let dataRequest = request as? DataRequest else {
            return
        }
        
        dataRequest.responseString { response in
            let urlString = dataRequest.request?.url?.absoluteString ?? ""
            switch response.result {
            case .success(let responseBody):
                if let mimeType = response.response?.mimeType, mimeType.hasPrefix("image/") {
                    let size = response.data?.fileSizeInKB ?? -1
                    PRINT("收到 Response from Request URL: \(urlString)\timage size:\(size) KB", ignoresThirdParty: true)
                } else {
                    PRINT("收到 Response from Request URL: \(urlString)\tbody:\(responseBody)", ignoresThirdParty: true)
                }
            case .failure(let error):
                PRINT("收到 Response from Request URL: \(urlString)\terror:\(error.localizedDescription)", ignoresThirdParty: true)
            }
        }
    }
}
