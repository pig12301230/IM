//
//  ContactResponses.swift
//  ChatRoom
//
//  Created by Winston_Chuang on 2022/8/29.
//

import Foundation

struct RContact: Codable {
    let id: String
    let username: String
    let nickname: String
    let avatar: String
    let avatarThumbnail: String
    let updateAt: Int
    let deleteAt: Int
    
    enum CodingKeys: String, CodingKey {
        case id, username, nickname, avatar
        case avatarThumbnail = "avatar_thumbnail"
        case updateAt = "update_at"
        case deleteAt = "delete_at"
    }
}
