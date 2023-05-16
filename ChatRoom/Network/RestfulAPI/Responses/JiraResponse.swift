//
//  JiraResponse.swift
//  ChatRoom
//
//  Created by Kedia on 2023/4/6.
//

import Foundation

// MARK: - JiraResponse
struct JiraResponse: Codable {
    let jiraResponseSelf: String?
    let id, filename: String?
    let author: JiraAuthor?
    let created: String?
    let size: Int?
    let mimeType: String?
    let content, thumbnail: String?

    enum CodingKeys: String, CodingKey {
        case jiraResponseSelf = "self"
        case id, filename, author, created, size, mimeType, content, thumbnail
    }
}

// MARK: - JiraAuthor
struct JiraAuthor: Codable {
    let authorSelf: String?
    let name, key, emailAddress: String?
    let avatarUrls: JiraAvatarUrls?
    let displayName: String?
    let active: Bool?
    let timeZone: String?

    enum CodingKeys: String, CodingKey {
        case authorSelf = "self"
        case name, key, emailAddress, avatarUrls, displayName, active, timeZone
    }
}

// MARK: - JiraAvatarUrls
struct JiraAvatarUrls: Codable {
    let the48X48, the24X24, the16X16, the32X32: String?

    enum CodingKeys: String, CodingKey {
        case the48X48 = "48x48"
        case the24X24 = "24x24"
        case the16X16 = "16x16"
        case the32X32 = "32x32"
    }
}
