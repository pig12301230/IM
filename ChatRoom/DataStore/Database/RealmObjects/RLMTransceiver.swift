//
//  RLMTransceiver.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/5/7.
//

import Foundation
import RealmSwift

class RLMTransceiver: Object {
    /// combine by RLMGroup._id + RLMGroup.user_id
    @objc dynamic var _id: String = ""
    /// same as Group.member.user_id
    @objc dynamic var userID: String = ""
    /// same as RLMGroup.group_id
    @objc dynamic var groupID: String = ""
    @objc dynamic var username: String = ""
    @objc dynamic var nickname: String = ""
    @objc dynamic var displayName: String = ""
    @objc dynamic var blocked: Bool = false
    /// same as RLMAvatar._id
    @objc dynamic var avatar: String = ""
    /// same as RLMAvatarThumbnail._id
    @objc dynamic var avatarThumbnail: String = ""
    @objc dynamic var createAt: Date?
    @objc dynamic var updateAt: Date?
    @objc dynamic var deleteAt: Date?
    @objc dynamic var joinAt: Date?
    @objc dynamic var isMember: Bool = false
    @objc dynamic var role: String = ""
    
    override static func primaryKey() -> String {
        return "_id"
    }
    
    convenience init(with groupID: String, userID: String, isMember: Bool = true, info: RUserInfo? = nil, display: String?) {
        self.init()
        self._id = TransceiverModel.uniqueID(groupID, userID)
        self.userID = userID
        self.groupID = groupID
        
        guard let info = info else {
            return
        }

        self.isMember = isMember && info.leaveAt == nil
        self.username = info.username
        self.nickname = info.nickname
        self.displayName = display ?? info.nickname
        self.blocked = info.blocked ?? false
        self.avatar = info.avatar
        self.avatarThumbnail = info.avatarThumbnail
        self.createAt = Date(timeIntervalSince1970: TimeInterval(Double(info.createAt) / 1000))
        self.updateAt = Date(timeIntervalSince1970: TimeInterval(Double(info.updateAt) / 1000))
        self.joinAt = Date(timeIntervalSince1970: TimeInterval(Double(info.joinAt ?? 0) / 1000))
        if info.deleteAt != 0 {
            self.deleteAt = Date(timeIntervalSince1970: TimeInterval(Double(info.deleteAt) / 1000))
        } else {
            self.deleteAt = nil
        }
    }
}
