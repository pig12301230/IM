//
//  EmojiDetailModel.swift
//  ChatRoom
//
//  Created by Winston_Chuang on 2022/11/30.
//

import Foundation

struct EmojiDetailModel: ModelPotocol {
    typealias DBObject = RLMEmojiDetail
    
    var id: String
    var messageID: String
    var userID: String
    var username: String
    var nickname: String
    var avatar: String
    var avatarThumbnail: String
    var emojiCode: String
    var createAt: Int
    var updateAt: Int
    var userRole: PermissionType = .member
    
    init(with object: RLMEmojiDetail) {
        self.id = object._id
        self.messageID = object.messageID
        self.userID = object.userID
        self.username = object.username
        self.nickname = object.nickname
        self.avatar = object.avatar
        self.avatarThumbnail = object.avatarThumbnail
        self.emojiCode = object.emojiCode
        self.createAt = object.createAt
        self.updateAt = object.updateAt
    }
    
    func convertToDBObject() -> RLMEmojiDetail {
        let obj = DBObject()
        obj._id = id
        obj.messageID = messageID
        obj.userID = userID
        obj.username = username
        obj.nickname = nickname
        obj.avatar = avatar
        obj.avatarThumbnail = avatarThumbnail
        obj.emojiCode = emojiCode
        obj.createAt = createAt
        obj.updateAt = updateAt
        return obj
    }
}
