//
//  RLMMessage.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/5/7.
//

import Foundation
import RealmSwift

class RLMMessage: Object {
    @objc dynamic var _id: String = ""
    @objc dynamic var cid: String = ""
    @objc dynamic var diffID: String = ""
    @objc dynamic var message: String = ""
    /// combine `group_id` + `_` + `user_id`
    @objc dynamic var transceiverID: String = ""
    @objc dynamic var userID: String = ""
    @objc dynamic var groupID: String = ""
    @objc dynamic var createAt: Date?
    @objc dynamic var updateAt: Date?
    @objc dynamic var read: Bool = false
    @objc dynamic var viewed: Bool = false
    @objc dynamic var notified: Bool = false
    @objc dynamic var notifiedAt: Int = 0
    @objc dynamic var timestamp: Int = 0
    // for group status
    @objc dynamic var targetID: String = ""
    @objc dynamic var threadID: String?
    @objc dynamic var threadMessage: RLMThreadMessage?
    @objc dynamic var hongBaoContent: RLMHongBaoContent?
    @objc private dynamic var type: String = ""
    @objc private dynamic var status: String = ""
    
    @objc dynamic var imageFileName: String?
    @objc dynamic var template: RLMTemplate?
    
    @objc dynamic var deleted: Bool = false
    var blockedUserIDs = List<String>()
    
    var fileIDs = List<String>()
    var files = List<RLMFiles>()
    var emojiFileIDs = List<String>()
    
    var messageStatus: MessageStatus {
        get { return MessageStatus(rawValue: status) ?? .success }
        set { status = newValue.rawValue }
    }
    
    var messageType: MessageType {
        get { return MessageType(rawValue: type) ?? .text }
        set { type = newValue.rawValue }
    }
    
    override static func primaryKey() -> String {
        return "_id"
    }
    
    convenience init(with message: RMessage, read: Bool = false, viewed: Bool = false) {
        self.init()
        self._id = message.id
        self.cid = message.cid
        self.diffID = message.diffID
        self.type = message.type.rawValue
        self.message = message.text
        self.transceiverID = TransceiverModel.uniqueID(message.groupID, message.userID)
        self.userID = message.userID
        self.groupID = message.groupID
        self.createAt = Date(timeIntervalSince1970: TimeInterval(Double(message.createAt) / 1000))
        self.updateAt = Date(timeIntervalSince1970: TimeInterval(Double(message.updateAt) / 1000))
        self.timestamp = message.createAt
        self.read = read
        self.viewed = viewed
        self.targetID = message.targetID
        self.threadID = message.threadID
        if let threadRLMMessage = message.threadMessage?.first {
           self.threadMessage = RLMThreadMessage(with: threadRLMMessage)
        }
        
        if let hongBaoContent = message.hongBaoContent {
            self.hongBaoContent = RLMHongBaoContent(with: hongBaoContent)
        }
        
        self.messageStatus = .success
        self.status = self.messageStatus.rawValue
        if let rTemplate = message.template {
            self.template = RLMTemplate(with: message.id, template: rTemplate)
        }
        
        for fileID in message.fileIDs {
            self.fileIDs.append(fileID)
        }
        
        for file in message.files {
            let rlm_file = RLMFiles.init(with: file)
            self.files.append(rlm_file)
        }
        
        for blockUserID in message.blockUserIDs {
            self.blockedUserIDs.append(blockUserID)
        }

        if !message.emojiContent.isEmpty {
            self.emojiFileIDs.append(self.diffID)
        }
    }
    
    func update(with message: RMessage) {
        self.message = message.text
        self.updateAt = Date(timeIntervalSince1970: TimeInterval(Double(message.updateAt) / 1000))
        
        if let rTemplate = message.template {
            self.template = RLMTemplate(with: message.id, template: rTemplate)
        }
        
        for fileID in message.fileIDs {
            self.fileIDs.append(fileID)
        }
        
        for file in message.files {
            let rlm_file = RLMFiles.init(with: file)
            self.files.append(rlm_file)
        }
        
        for blockUserID in message.blockUserIDs {
            self.blockedUserIDs.append(blockUserID)
        }

        if !message.emojiContent.isEmpty {
            self.emojiFileIDs.append(message.diffID)
        }
    }
    
    func updateRLMFiles(_ fileList: [RLMFiles]) {
        for file in fileList {
            if files.contains(where: { $0._id == file._id }) { continue }
            self.files.append(file)
        }
    }
}

class RLMDraftMessage: RLMMessage {
    
    @objc dynamic var isDraft: Bool = false
    
    convenience init(by rlmMessage: RLMMessage) {
        self.init()
        self._id = rlmMessage._id
        self.cid = rlmMessage.cid
        self.diffID = rlmMessage.diffID
        self.messageType = rlmMessage.messageType
        self.message = rlmMessage.message
        self.transceiverID = rlmMessage.transceiverID
        self.userID = rlmMessage.userID
        self.groupID = rlmMessage.groupID
        self.createAt = rlmMessage.createAt
        self.updateAt = rlmMessage.updateAt
        self.timestamp = rlmMessage.timestamp
        self.read = rlmMessage.read
        self.viewed = rlmMessage.viewed
        self.targetID = rlmMessage.targetID
        self.threadID = rlmMessage.threadID
        self.threadMessage = rlmMessage.threadMessage
        self.imageFileName = rlmMessage.imageFileName
        self.fileIDs = rlmMessage.fileIDs
        self.files = rlmMessage.files
        self.blockedUserIDs = rlmMessage.blockedUserIDs
        self.messageStatus = rlmMessage.messageStatus
        self.template = rlmMessage.template
    }
}

class RLMAnnouncementMessage: RLMMessage {
    
}

class RLMThreadMessage: RLMMessage {
    
}
/*
 FOR: RLMGroup.lastMessage
 RLMGroup.lastMessage 與 Messages 在同一個訊息會有不同的 id
 所以建立另外一個 Table, 減少 Query messages 的複雜度
 */
class RLMGMessage: RLMMessage {
    convenience init(by rlmMessage: RLMMessage) {
        self.init()
        self._id = rlmMessage._id
        self.cid = rlmMessage.cid
        self.diffID = rlmMessage.diffID
        self.messageType = rlmMessage.messageType
        self.message = rlmMessage.message
        self.transceiverID = rlmMessage.transceiverID
        self.userID = rlmMessage.userID
        self.groupID = rlmMessage.groupID
        self.createAt = rlmMessage.createAt
        self.updateAt = rlmMessage.updateAt
        self.timestamp = rlmMessage.timestamp
        self.read = rlmMessage.read
        self.viewed = rlmMessage.viewed
        self.targetID = rlmMessage.targetID
        self.fileIDs = rlmMessage.fileIDs
        self.files = rlmMessage.files
        self.imageFileName = rlmMessage.imageFileName
        self.blockedUserIDs = rlmMessage.blockedUserIDs
        self.template = rlmMessage.template
    }
}
