//
//  RLMEmojiDetail.swift
//  ChatRoom
//
//  Created by Winston_Chuang on 2022/11/29.
//

import RealmSwift

class RLMEmojiDetail: Object {
    @objc dynamic var _id: String = ""
    @objc dynamic var messageID: String = ""
    @objc dynamic var userID: String = ""
    @objc dynamic var username: String = ""
    @objc dynamic var nickname: String = ""
    @objc dynamic var avatar: String = ""
    @objc dynamic var avatarThumbnail: String = ""
    @objc dynamic var emojiCode: String = ""
    @objc dynamic var createAt: Int = 0
    @objc dynamic var updateAt: Int = 0
    
    override static func primaryKey() -> String {
        return "_id"
    }
    
    convenience init(content: ListContent) {
        self.init()
        self._id = content.messageID + "_" + content.userID
        self.messageID = content.messageID
        self.userID = content.userID
        self.username = content.username
        self.nickname = content.nickname
        self.avatar = content.avatar
        self.avatarThumbnail = content.avatarThumbnail
        self.emojiCode = content.emojiCode
        self.createAt = content.createAt
        self.updateAt = content.updateAt
    }
}
