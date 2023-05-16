//
//  RLMGroup.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/5/6.
//

import Foundation
import RealmSwift

class RLMGroup: Object {
    @objc dynamic var _id: String = ""
    @objc dynamic var name: String = ""
    @objc dynamic var displayName: String = ""
    @objc dynamic var ownerID: String = ""
    @objc dynamic var lastMessage: RLMGMessage?
    @objc dynamic var unreadCount: Int = 0
    @objc dynamic var createAt: Date = Date()
    @objc dynamic var updateAt: Date = Date()
    // user 最後讀取的 messageID
    @objc dynamic var lastViewedID: String = ""
    // user 最後被他人讀取的 messageID
    @objc dynamic var lastReadID: String = ""
    @objc dynamic var avatar: String = ""
    @objc dynamic var createTime: Int = 0
    // 僅手機端使用，用來標記要回溯舊訊息的最早時間 (刪除群組後會更新為刪除當下時間)
    @objc dynamic var latestSyncTimestamp: Int = 0
    @objc dynamic var timestamp: Int = 0
    @objc dynamic var icon: String = ""
    @objc dynamic var iconThumbnail: String = ""
    @objc dynamic var memberCount: Int = 0
    @objc dynamic var hidden: Bool = false
    @objc dynamic var hasFailure: Bool = false
    
    @objc private dynamic var type: Int = GroupType.group.rawValue
    @objc private dynamic var notify: Int = 1
    @objc dynamic var draftContent: String = ""
    
    var groupType: GroupType {
        get { return GroupType(rawValue: type) ?? .group }
        set { type = newValue.rawValue }
    }
    
    var notifyType: NotifyType {
        get { return NotifyType(rawValue: notify) ?? .on }
        set { notify = newValue.rawValue }
    }
    
    override static func primaryKey() -> String {
        return "_id"
    }

    convenience init(with group: RUserGroups) {
        self.init()
        self._id = group.id
        self.groupType = group.type
        self.name = group.name
        self.displayName = group.displayName
        self.ownerID = group.ownerID
        self.unreadCount = group.unread
        self.lastViewedID = group.lastViewed
        self.lastReadID = group.lastRead
        self.icon = group.icon
        self.iconThumbnail = group.iconThumbnail
        self.createAt = Date(timeIntervalSince1970: TimeInterval(Double(group.createAt) / 1000))
        self.updateAt = Date(timeIntervalSince1970: TimeInterval(Double(group.updateAt) / 1000))
        self.createTime = group.createAt
        self.timestamp = group.updateAt
        self.notifyType = group.notify
        self.memberCount = group.memberCount
        if let lastMsg = group.lastMessage {
            let msg = RLMGMessage.init(with: lastMsg)
            self.lastMessage = msg
        } else {
            self.setHidden()
        }
    }
    
    func update(with group: RUserGroups) {
        self.displayName = group.displayName
        self.ownerID = group.ownerID
        self.lastReadID = group.lastRead
        self.unreadCount = group.unread
        self.lastViewedID = group.lastViewed
        self.icon = group.icon
        self.iconThumbnail = group.iconThumbnail
        self.notifyType = group.notify
        self.memberCount = group.memberCount
        self.updateAt = Date(timeIntervalSince1970: TimeInterval(Double(group.updateAt) / 1000))
        self.timestamp = group.updateAt
        if let lastMsg = group.lastMessage {
            let msg = RLMGMessage.init(with: lastMsg)
            self.lastMessage = msg
        } else {
            self.setHidden()
        }
    }

    // 若非自己建立的1v1聊天室＆聊天室沒有任何訊息 => 聊天室hidden
    func setHidden() {
        guard let myUserID = UserData.shared.getData(key: .userID) as? String, self.ownerID != myUserID else {
            return
        }
        self.hidden = self.groupType == .dm
    }
}
