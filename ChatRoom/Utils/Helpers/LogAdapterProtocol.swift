//
//  LoggerProtocol.swift
//  ChatRoom
//
//  Created by Kedia on 2023/3/30.
//

import Foundation

enum LogCategory: String {
    case debug
    case error
    case request
    case process
    case `deinit`
    case socket
    case database
    case thread
    
    var prefix: String {
        return String(format: "[Logger-%@]", self.rawValue)
    }
    
    var showTimestamp: Bool {
        if self == .socket {
            return true
        }
        return false
    }
}

protocol LogAdapterProtocol {
    func log(_ message: String)
}
