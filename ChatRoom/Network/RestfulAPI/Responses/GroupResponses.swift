//
//  UserResponses.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/4/14.
//

import Foundation

struct RGroupInfo: Codable {
    let id: String
    let name: String
    let type: Int
    let create_at: Int
    let update_at: Int
}

struct RGropIcon: Codable {
    let icon: String
    let icon_thumbnail: String
}

struct RGroupLastMessage: Codable {
    let unread: Int
    let lastMessage: RMessage
    let lastViewd: String
    
    enum CodingKeys: String, CodingKey {
        case unread
        case lastMessage = "last_message"
        case lastViewd = "last_viewed"
    }
}
