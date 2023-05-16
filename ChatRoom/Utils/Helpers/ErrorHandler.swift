//
//  ErrorHandler.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/4/9.
//

import Foundation

struct ErrorMessage {
    var error: Error
    var requestID: String = ""
    var statusCode: Int = 0
    
    var description: String {
        if let err = self.error as? ApiError {
            return "requestID: \(self.requestID)\nstatusCode: \(self.statusCode)\n\(err.localizedString)"
        }
        return "requestID: \(self.requestID)\nstatusCode: \(self.statusCode)\nError: \(self.error)"
    }
}

enum HttpError: Int, Error {
    case tokenError = 401
    case forbidden = 403
    case notFound = 404
    case conflict = 409
    case internalServerError = 500
}

enum ApiError: Error, Equatable {
    case invalidResponse
    case noAccess
    case invalidAccess
    // request error, need show error
    case requestError(code: String, requestID: String, present: ApiClient.ErrorPresent)
    // request error, no need show error
    case requestErrorForDoNothing(code: String?, message: String?)
    case unreachable

    var localizedString: String {
        switch self {
        case .invalidResponse:
            return "Invalid response"
        case .noAccess:
            return "No access token"
        case .invalidAccess:
            return "Get access token failed"
        case .requestError(let code, let requestID, _):
            return "(\(code), \(requestID))"
        case .requestErrorForDoNothing(let code, let message):
            return "errorCode: \(code ?? "")\nerrorMessage: \(message ?? "")"
        case .unreachable:
            return "network unreachable"
        }
    }
}

enum WSError: Error {
    case parsedFailed

    var localizedString: String {
        switch self {
        case .parsedFailed:
            return "WS Error: Parsed response failed"
        }
    }
}

enum DBError: Error {
    case writeFailed(err: Error)
    case deleteFailed(err: Error)

    var localizedString: String {
        switch self {
        case .writeFailed(let err):
            return "DB Write error: \(err)"
        case .deleteFailed(err: let err):
            return "DB Delete error: \(err)"
        }
    }
}
