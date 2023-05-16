//
//  WalletResponses.swift
//  ChatRoom
//
//  Created by ERay_Peng on 2023/4/20.
//

import Foundation

struct RWalletProvider: Codable {
    let userId: String
    let providers: [RProvider]
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case providers
    }
}

struct RProvider: Codable {
    let walletName: String
    let name: String
    let enable: Bool
    let isBind: Bool
    let bindAddress: String
    
    enum CodingKeys: String, CodingKey {
        case name, enable
        case walletName = "code"
        case isBind = "is_binding"
        case bindAddress = "binding_address"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        walletName = try values.decode(String.self, forKey: .walletName)
        name = try values.decode(String.self, forKey: .name)
        enable = try values.decode(Bool.self, forKey: .enable)
        isBind = try values.decode(Bool.self, forKey: .isBind)
        bindAddress = try values.decode(String.self, forKey: .bindAddress)
    }
    
    func encode(to encoder: Encoder) throws {
        // TODO: if need encode
    }
}
