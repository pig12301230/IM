//
//  MessageModel.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/6/8.
//

import Foundation
import UIKit

protocol ResponseModelPotocol {
    associatedtype ResponseObject: Codable
    mutating func updateByResponseObject(_ object: ResponseObject)
}

enum MessageStatus: String {
    case success
    case sending
    case failed
    case fakeSending

    var isTemporaryMessage: Bool {
        return self == .sending || self == .fakeSending
    }
}

enum MessageTargetType: String {
    case none
    case user = "usc"
    case message = "msc"
    case unknown
}

public struct MessageModel: ModelPotocol, DataPotocol, ResponseModelPotocol, DiffAware {
    typealias DiffId = String
    var diffIdentifier: DiffId {
        return diffID
    }
    static func compareContent(_ a: MessageModel, _ b: MessageModel) -> Bool {
        return a.diffIdentifier == b.diffIdentifier && a.message == b.message && a.messageStatus == b.messageStatus && a.emojiContent == b.emojiContent
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(diffID)
        hasher.combine(emojiContent)
    }
    
    var display: String {
        get { return message }
        set { message = newValue }
    }

    var targetUser: String? {
        guard !targetID.isEmpty else { return  nil }
        guard messageTargetType == .user else { return nil }
        return targetID
    }

    var targetMessage: String? {
        guard !targetID.isEmpty else { return  nil }
        guard messageTargetType == .message else { return nil }
        return targetID
    }
    
    typealias DBObject = RLMMessage
    typealias RLMGDBObject = RLMGMessage
    typealias AnnouncementDBObject = RLMAnnouncementMessage
    typealias ThreadMessageDBObject = RLMThreadMessage
    typealias ResponseObject = RMessage
    
    var id: String = ""
    var cid: String = ""
    var diffID: String = ""
    private(set) var type: String = ""
    var message: String = ""
    /// combine `group_id` + `_` + `user_id`
    var transceiverID: String = ""
    var userID: String = ""
    var groupID: String = ""
    var createAt: Date?
    var updateAt: Date?
    var read: Bool = false
    var viewed: Bool = false
    var notified: Bool = false
    var deleted: Bool = false
    var notifiedAt: Int = 0
    var timestamp: Int = 0
    // for group status
    var targetID: String = ""
    var threadID: String?
    var threadMessage: [MessageModel] = []
    var hongBaoContent: HongBaoContent?
    var files: [FileModel] = []
    var fileIDs: [String] = []
    var blockUserIDs: [String] = []
    var isDraft: Bool = false
    private(set) var status: String = ""
    var imageFileName: String?
    var template: TemplateModel?
    var localeTimeString: String = ""
    var emojiFileIDs: [String] = []
    var emojiContent: EmojiContentModel?

    var messageStatus: MessageStatus {
        get { return MessageStatus(rawValue: status) ?? .success }
        set { status = newValue.rawValue }
    }
    
    var messageType: MessageType {
        get { return MessageType(rawValue: type) ?? .text }
        set { type = newValue.rawValue }
    }

    var messageTargetType: MessageTargetType {
        guard !targetID.isEmpty else { return .none }
        if targetID.hasPrefix(MessageTargetType.user.rawValue) {
            return .user
        } else if targetID.hasPrefix(MessageTargetType.message.rawValue) {
            return .message
        }
        return .unknown
    }
    
    var isBlocked: Bool {
        return blockUserIDs.contains(userID) && userID != UserData.shared.userID
    }
    
    init() {
        self.id = ""
        self.messageStatus = .success
    }
    
    // MARK: - ModelPotocol
    init(with rlmMessage: DBObject) {
        id = rlmMessage._id
        cid = rlmMessage.cid
        diffID = rlmMessage.diffID
        messageType = rlmMessage.messageType
        message = rlmMessage.message
        transceiverID = rlmMessage.transceiverID
        userID = rlmMessage.userID
        groupID = rlmMessage.groupID
        createAt = rlmMessage.createAt
        updateAt = rlmMessage.updateAt
        read = rlmMessage.read
        viewed = rlmMessage.viewed
        notified = rlmMessage.notified
        notifiedAt = rlmMessage.notifiedAt
        timestamp = rlmMessage.timestamp
        targetID = rlmMessage.targetID
        threadID = rlmMessage.threadID
        imageFileName = rlmMessage.imageFileName
        if let rlmThread = rlmMessage.threadMessage {
            threadMessage = [MessageModel(with: rlmThread)]
        }
        
        if let rlmHongBaoContent = rlmMessage.hongBaoContent {
            hongBaoContent = HongBaoContent(with: rlmHongBaoContent, senderID: rlmMessage.userID, groupID: rlmMessage.groupID)
        }
        
        messageStatus = rlmMessage.messageStatus
        status = messageStatus.rawValue
        fileIDs = rlmMessage.fileIDs.toArray()
        blockUserIDs = rlmMessage.blockedUserIDs.toArray()
        files = rlmMessage.files.compactMap { FileModel(with: $0) }
        if let rlmTemplate = rlmMessage.template {
            template = TemplateModel(with: rlmTemplate)
        }
        emojiFileIDs = rlmMessage.emojiFileIDs.toArray()
        
        if let id = emojiFileIDs.first {
            emojiContent = self.getContent(id: id)
        }
        
        deleted = rlmMessage.deleted
        if let time = createAt {
            switch messageType {
            case .groupCreate, .groupDisplayName:
                localeTimeString = time.toLocaleString(format: .yearToSymbolTime)
            default:
                localeTimeString = time.toLocaleString(format: .symbolTime)
            }
        }
    }
    
    func getContent(id: String) -> EmojiContentModel? {
        return DataAccess.shared.getMessageEmojiContent(messageID: id)
    }
    
    func convertToDBObject() -> DBObject {
        let dbObject = DBObject.init()
        dbObject._id = self.id
        dbObject.cid = self.cid
        dbObject.diffID = self.diffID
        dbObject.messageType = self.messageType
        dbObject.message = self.message
        dbObject.transceiverID = self.transceiverID
        dbObject.userID = self.userID
        dbObject.groupID = self.groupID
        dbObject.createAt = self.createAt
        dbObject.updateAt = self.updateAt
        dbObject.read = self.read
        dbObject.viewed = self.viewed
        dbObject.notified = self.notified
        dbObject.notifiedAt = self.notifiedAt
        dbObject.timestamp = self.timestamp
        dbObject.targetID = self.targetID
        dbObject.threadID = self.threadID
        dbObject.template = self.template?.convertToDBObject()
        if let threadMsg = self.threadMessage.first {
            dbObject.threadMessage = threadMsg.convertToThreadDBObject()
        }
        
        if let hongBaoContent = self.hongBaoContent {
            dbObject.hongBaoContent = hongBaoContent.convertToDBObject()
        }
        
        dbObject.messageStatus = self.messageStatus
        dbObject.imageFileName = self.imageFileName
        dbObject.deleted = self.deleted

        dbObject.fileIDs.append(objectsIn: self.fileIDs)
        dbObject.blockedUserIDs.append(objectsIn: self.blockUserIDs)
        dbObject.emojiFileIDs.append(objectsIn: self.emojiFileIDs)
        
        for file in self.files {
            dbObject.files.append(file.convertToDBObject())
        }
        return dbObject
    }
    
    func convertToRLMGDBObject() -> RLMGDBObject {
        let dbObject = RLMGDBObject.init()
        dbObject._id = self.id
        dbObject.cid = self.cid
        dbObject.diffID = self.diffID
        dbObject.messageType = self.messageType
        dbObject.message = self.message
        dbObject.transceiverID = self.transceiverID
        dbObject.userID = self.userID
        dbObject.groupID = self.groupID
        dbObject.createAt = self.createAt
        dbObject.updateAt = self.updateAt
        dbObject.read = self.read
        dbObject.viewed = self.viewed
        dbObject.notified = self.notified
        dbObject.notifiedAt = self.notifiedAt
        dbObject.timestamp = self.timestamp
        dbObject.targetID = self.targetID
        dbObject.threadID = self.threadID
        dbObject.template = self.template?.convertToDBObject()
        
        if let threadMsg = self.threadMessage.first {
            dbObject.threadMessage = threadMsg.convertToThreadDBObject()
        }
        
        if let hongBaoContent = self.hongBaoContent {
            dbObject.hongBaoContent = hongBaoContent.convertToDBObject()
        }
        
        dbObject.messageStatus = self.messageStatus
        dbObject.imageFileName = self.imageFileName
        dbObject.deleted = self.deleted

        dbObject.fileIDs.append(objectsIn: self.fileIDs)
        dbObject.blockedUserIDs.append(objectsIn: self.blockUserIDs)
        dbObject.emojiFileIDs.append(objectsIn: self.emojiFileIDs)
        
        for file in self.files {
            dbObject.files.append(file.convertToDBObject())
        }
        return dbObject
    }
    
    func convertToAnnoucementDBObject() -> AnnouncementDBObject {
        let dbObject = AnnouncementDBObject.init()
        dbObject._id = self.id
        dbObject.cid = self.cid
        dbObject.messageType = self.messageType
        dbObject.message = self.message
        dbObject.transceiverID = self.transceiverID
        dbObject.userID = self.userID
        dbObject.groupID = self.groupID
        dbObject.createAt = self.createAt
        dbObject.updateAt = self.updateAt
        dbObject.read = self.read
        dbObject.viewed = self.viewed
        dbObject.notified = self.notified
        dbObject.notifiedAt = self.notifiedAt
        dbObject.timestamp = self.timestamp
        dbObject.targetID = self.targetID
        dbObject.messageStatus = self.messageStatus
        dbObject.imageFileName = self.imageFileName
        
        dbObject.fileIDs.append(objectsIn: self.fileIDs)
        dbObject.blockedUserIDs.append(objectsIn: self.blockUserIDs)
        dbObject.emojiFileIDs.append(objectsIn: self.emojiFileIDs)

        for file in self.files {
            dbObject.files.append(file.convertToDBObject())
        }
        return dbObject
    }
    
    func convertToThreadDBObject() -> ThreadMessageDBObject {
        let dbObject = ThreadMessageDBObject.init()
        dbObject._id = self.id
        dbObject.cid = self.cid
        dbObject.messageType = self.messageType
        dbObject.message = self.message
        dbObject.transceiverID = self.transceiverID
        dbObject.userID = self.userID
        dbObject.groupID = self.groupID
        dbObject.createAt = self.createAt
        dbObject.updateAt = self.updateAt
        dbObject.read = self.read
        dbObject.viewed = self.viewed
        dbObject.notified = self.notified
        dbObject.notifiedAt = self.notifiedAt
        dbObject.timestamp = self.timestamp
        dbObject.threadID = self.threadID

        dbObject.targetID = self.targetID
        dbObject.messageStatus = self.messageStatus
        dbObject.imageFileName = self.imageFileName
        dbObject.template = self.template?.convertToDBObject()
        
        dbObject.deleted = self.deleted

        for fileID in self.fileIDs {
            dbObject.fileIDs.append(fileID)
        }

        for file in self.files {
            dbObject.files.append(file.convertToDBObject())
        }
        
        for blockUserID in self.blockUserIDs {
            dbObject.blockedUserIDs.append(blockUserID)
        }
        
        for emojiID in self.emojiFileIDs {
            dbObject.emojiFileIDs.append(emojiID)
        }

        return dbObject
    }
    
    // MARK: - ResponseModelPotocol
    mutating func updateByResponseObject(_ object: RMessage) {
        self.id = object.id
        self.cid = object.cid
        self.diffID = object.diffID
        self.messageType = object.type
        self.message = object.text
        self.transceiverID = TransceiverModel.uniqueID(object.groupID, object.userID)
        self.userID = object.userID
        self.groupID = object.groupID
        self.createAt = Date(timeIntervalSince1970: TimeInterval(Double(object.createAt) / 1000))
        self.updateAt = Date(timeIntervalSince1970: TimeInterval(Double(object.updateAt) / 1000))
        self.timestamp = object.createAt
        self.targetID = object.targetID
        self.threadID = object.threadID
        if let template = object.template {
            self.template = TemplateModel(with: template, messageID: object.id)
        }
        if let threadMsg = object.threadMessage?.first {
            var messageModel = MessageModel()
            messageModel.updateByResponseObject(threadMsg)
            threadMessage = [messageModel]
        }
        
        self.fileIDs = object.fileIDs
        self.files = object.files.map {
            var model = FileModel.init()
            model.updateByResponseObject($0)
            return model
        }
        self.emojiFileIDs = [object.diffID]
        
        self.blockUserIDs = object.blockUserIDs
        
        if let rlmTemplate = object.template {
            self.template?.updateByResponseObject(rlmTemplate)
        }
        
        if let time = createAt {
            switch messageType {
            case .groupCreate, .groupDisplayName:
                localeTimeString = time.toLocaleString(format: .yearToSymbolTime)
            default:
                localeTimeString = time.toLocaleString(format: .symbolTime)
            }
        }
    }
    
    static func getDraftID(with groupID: String) -> String {
        return "draft_\(groupID)"
    }
}
