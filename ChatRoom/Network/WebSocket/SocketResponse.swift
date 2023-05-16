//
//  SocketResponse.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/5/11.
//

import Foundation

class SocketResponse<T: Codable>: Codable {
    let event: String
    let data: T
}

struct RSocketInfo: Codable {
    let groupID: String
    let userID: String
    let notify: Int
    
    enum CodingKeys: String, CodingKey {
        case notify
        case groupID = "group_id"
        case userID = "user_id"
    }
}

struct RSocketReadInfo: Codable {
    let groupID: String
    let lastRead: String
    
    enum CodingKeys: String, CodingKey {
        case groupID = "group_id"
        case lastRead = "last_read"
    }
}

struct RSocketGroupDisplay: Codable {
    let groupID: String
    let displayName: String
    
    enum CodingKeys: String, CodingKey {
        case groupID = "group_id"
        case displayName = "display_name"
    }
}

struct RSocketGroupIcon: Codable {
    let groupID: String
    let icon: String
    let iconThumbnail: String
    
    enum CodingKeys: String, CodingKey {
        case icon
        case groupID = "group_id"
        case iconThumbnail = "icon_thumbnail"
    }
}

struct RSocketGroup: Codable {
    let groupID: String
    
    enum CodingKeys: String, CodingKey {
        case groupID = "group_id"
    }
}

struct RSocketGroupMessage: Codable {
    let groupID: String
    let messageID: String
    
    enum CodingKeys: String, CodingKey {
        case groupID = "group_id"
        case messageID = "message_id"
    }
}

struct RSocketHongBaoClaim: Codable {
    let groupID: String
    let messageID: String
    let userID: String
    let text: String
    let hongBaoContent: RHongBaoContent
    
    enum CodingKeys: String, CodingKey {
        case text
        case groupID = "group_id"
        case messageID = "id"
        case userID = "user_id"
        case hongBaoContent = "red_envelope_content"
    }
}
