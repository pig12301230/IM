//
//  TransceiverModel.swift
//  ChatRoom
//  Created by Andy Yang on 2021/6/11.
//

import Foundation

struct TransceiverModel: ModelPotocol, DataPotocol, AuthTargetPotocol {
    
    typealias DBObject = RLMTransceiver
    /// combine by RLMGroup._id + RLMGroup.user_id
    var id: String
    /// same as Group.member.user_id
    var userID: String
    /// same as RLMGroup.group_id
    var groupID: String
    var username: String
    var nickname: String
    var display: String
    var blocked: Bool
    /// same as RLMAvatar._id
    var avatar: String
    /// same as RLMAvatarThumbnail._id
    var avatarThumbnail: String
    var createAt: Date?
    var updateAt: Date?
    var deleteAt: Date?
    var joinAt: Date?
    // TODO: 有需要就接上createAt
    var timestamp: Int = 0
    var isMember: Bool = false
    
    // AuthTargetPotocol
    var thumbnail: String {
        return avatarThumbnail
    }
    
    var targetID: String {
        return id
    }
    
    var targetGroupID: String {
        return groupID
    }
    
    var role: PermissionType
    
    init(with rlmTransceiver: RLMTransceiver) {
        id = rlmTransceiver._id
        userID = rlmTransceiver.userID
        groupID = rlmTransceiver.groupID
        username = rlmTransceiver.username
        nickname = rlmTransceiver.nickname
        display = rlmTransceiver.displayName
        blocked = rlmTransceiver.blocked
        avatar = rlmTransceiver.avatar
        avatarThumbnail = rlmTransceiver.avatarThumbnail
        createAt = rlmTransceiver.createAt
        updateAt = rlmTransceiver.updateAt
        deleteAt = rlmTransceiver.deleteAt
        joinAt = rlmTransceiver.joinAt
        isMember = rlmTransceiver.isMember
        role = PermissionType.init(rawValue: rlmTransceiver.role) ?? .none
    }
    
    func convertToDBObject() -> DBObject {
        let dbObject = DBObject.init()
        dbObject._id = self.id
        dbObject.userID = self.userID
        dbObject.groupID = self.groupID
        dbObject.username = self.username
        dbObject.nickname = self.nickname
        dbObject.displayName = self.display
        dbObject.blocked = self.blocked
        dbObject.avatar = self.avatar
        dbObject.avatarThumbnail = self.avatarThumbnail
        dbObject.createAt = self.createAt
        dbObject.updateAt = self.updateAt
        dbObject.deleteAt = self.deleteAt
        dbObject.joinAt = self.joinAt
        dbObject.isMember = self.isMember
        dbObject.role = self.role.rawValue
        return dbObject
    }

    static func uniqueID(_ groupID: String, _ userID: String) -> String {
        return groupID + "_" + userID
    }
}
