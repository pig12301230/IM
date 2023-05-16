//
//  RLMContact.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/5/7.
//

import Foundation
import RealmSwift

class RLMContact: Object {
    /// same as Other RLMObject.user_id
    @objc dynamic var _id: String = ""
    @objc dynamic var username: String = ""
    @objc dynamic var nickname: String = ""
    @objc dynamic var displayName: String = ""
    /// same as RLMAvatar._id
    @objc dynamic var avatar: String = ""
    /// same as RLMAvatarThumbnail._id
    @objc dynamic var avatarThumbnail: String = ""
    @objc dynamic var createAt: Date?
    @objc dynamic var updateAt: Date?
    @objc dynamic var timestamp: Int = 0
    
    override static func primaryKey() -> String {
        return "_id"
    }
    
    convenience init(with user: RUserInfo, display: String?) {
        self.init()
        self._id = user.id
        self.username = user.username
        self.nickname = user.nickname
        self.displayName = display ?? user.nickname
        self.avatar = user.avatar
        self.avatarThumbnail = user.avatarThumbnail
        self.createAt = Date(timeIntervalSince1970: TimeInterval(Double(user.createAt) / 1000))
        self.updateAt = Date(timeIntervalSince1970: TimeInterval(Double(user.updateAt) / 1000))
    }
    
    convenience init(with account: RAccountInfo) {
        self.init()
        self._id = account.id
        self.username = account.username
        self.nickname = account.nickname
        self.displayName = account.nickname
        self.avatar = account.avatar
        self.avatarThumbnail = account.avatarThumbnail
        self.createAt = Date(timeIntervalSince1970: TimeInterval(Double(account.createAt) / 1000))
        self.updateAt = Date(timeIntervalSince1970: TimeInterval(Double(account.updateAt) / 1000))
    }
    
    convenience init(with contact: RContact, display: String?) {
        self.init()
        self._id = contact.id
        self.username = contact.username
        self.nickname = contact.nickname
        self.displayName = display ?? contact.nickname
        self.avatar = contact.avatar
        self.avatarThumbnail = contact.avatarThumbnail
        self.createAt = Date(timeIntervalSince1970: TimeInterval(Double(contact.updateAt) / 1000))
        self.updateAt = Date(timeIntervalSince1970: TimeInterval(Double(contact.updateAt) / 1000))
    }
}

class RLMBlockedContact: RLMContact {
    
}
