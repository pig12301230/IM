//
//  LoginRegisterResponses.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/4/27.
//

import Foundation

struct RLoginRegister: Codable {
    let accessToken: String
    let expiresIn: Int
    let tokenType: String
    let refreshToken: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
        case refreshToken = "refresh_token"
    }
}

struct RRecovery: Codable {
    let access_token: String
    let token_type: String
}
