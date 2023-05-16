//
//  GroupModel.swift
//  ChatRoom
//
//  Created by Andy Yang on 2021/6/7.
//

import Foundation
import RealmSwift

protocol ModelPotocol: Hashable {
    associatedtype DBObject: Object
    init(with object: DBObject)
    func convertToDBObject() -> DBObject
}

protocol DataPotocol {
    var id: String { get set }
    var display: String { get set }
    var timestamp: Int { get set }
}

protocol AuthTargetPotocol {
    var targetGroupID: String { get }
    var targetID: String { get }
    var display: String { get set }
    var thumbnail: String { get }
}

struct GroupModel: ModelPotocol, DataPotocol, AuthTargetPotocol {
    typealias DBObject = RLMGroup
    
    var id: String = ""
    var name: String = ""
    var display: String = ""
    var ownerID: String = ""
    var lastMessage: MessageModel?
    var unreadCount: Int = 0
    var createAt: Date = Date()
    var updateAt: Date = Date()
    // user 最後讀取的 messageID
    var lastViewedID: String = ""
    // user 最後被他人讀取的 messageID
    var lastReadID: String = ""
    var avatar: String = ""
    var createTime: Int = 0
    // 僅手機端使用，用來標記要回溯舊訊息的最早時間 (刪除群組後會更新為刪除當下時間)
    var latestSyncTimestamp: Int = 0
    var timestamp: Int = 0
    var icon: String = ""
    var iconThumbnail: String = ""
//    var members: [TransceiverModel]?
    var memberCount: Int = 0
    var hidden: Bool = false
    var hasFailure: Bool = false
    var draft: String = ""
    
    var groupType: GroupType {
        get { return GroupType(rawValue: type) ?? .group }
        set { type = newValue.rawValue }
    }
    
    var notifyType: NotifyType {
        get { return NotifyType(rawValue: notify) ?? .on }
        set { notify = newValue.rawValue }
    }
    
    // AuthTargetPotocol
    var thumbnail: String {
        return iconThumbnail
    }
    
    var targetID: String {
        return id
    }
    
    var targetGroupID: String {
        return id
    }
    
    private var type: Int = GroupType.group.rawValue
    private var notify: Int = 1
    
    init(with rlmGroup: DBObject) {
        id = rlmGroup._id
        name = rlmGroup.name
        display = rlmGroup.displayName
        ownerID = rlmGroup.ownerID
        unreadCount = rlmGroup.unreadCount
        createAt = rlmGroup.createAt
        updateAt = rlmGroup.updateAt
        lastViewedID = rlmGroup.lastViewedID
        lastReadID = rlmGroup.lastReadID
        avatar = rlmGroup.avatar
        createTime = rlmGroup.createTime
        latestSyncTimestamp = rlmGroup.latestSyncTimestamp
        timestamp = rlmGroup.timestamp
        icon = rlmGroup.icon
        iconThumbnail = rlmGroup.iconThumbnail
        notify = rlmGroup.notifyType.rawValue
        memberCount = rlmGroup.memberCount
        groupType = rlmGroup.groupType
        hidden = rlmGroup.hidden
        draft = rlmGroup.draftContent
        hasFailure = rlmGroup.hasFailure
        if let rlmMessage = rlmGroup.lastMessage {
            lastMessage = MessageModel(with: rlmMessage)
        }
    }
    
    func convertToDBObject() -> DBObject {
        let dbObject = DBObject.init()
        dbObject._id = self.id
        dbObject.groupType = self.groupType
        dbObject.name = self.name
        dbObject.displayName = self.display
        dbObject.ownerID = self.ownerID
        dbObject.unreadCount = self.unreadCount
        dbObject.lastViewedID = self.lastViewedID
        dbObject.lastReadID = self.lastReadID
        dbObject.icon = self.icon
        dbObject.iconThumbnail = self.iconThumbnail
        dbObject.createAt = self.createAt
        dbObject.updateAt = self.updateAt
        dbObject.createTime = self.createTime
        dbObject.timestamp = self.timestamp
        dbObject.notifyType = self.notifyType
        dbObject.memberCount = self.memberCount
        dbObject.hidden = self.hidden
        dbObject.draftContent = self.draft
        dbObject.hasFailure = self.hasFailure
        if let lastMessage = self.lastMessage, lastMessage.id.count > 0 {
            dbObject.lastMessage = RLMGMessage.init(value: lastMessage.convertToDBObject())
        }
        
        return dbObject
    }
}
