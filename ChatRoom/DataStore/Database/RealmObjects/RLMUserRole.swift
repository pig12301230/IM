//
//  RLMUserRole.swift
//  ChatRoom
//
//  Created by ZoeLin on 2022/1/19.
//

import Foundation
import RealmSwift

class RLMUserRole: Object {
    @objc dynamic var _id: String = UUID().uuidString
    @objc dynamic var type: String = PermissionType.none.rawValue
    @objc dynamic var groupID: String = ""
    @objc dynamic var userID: String = ""
    @objc dynamic var permission: RLMPermission?
    
    var role: PermissionType {
        get { return PermissionType(rawValue: type) ?? .none }
        set { type = newValue.rawValue }
    }
    
    override static func primaryKey() -> String {
        return "_id"
    }

    convenience init(with groupID: String, userID: String, auth: RUserAuth) {
        self.init()
        self._id = groupID + "_" + userID
        self.role = auth.role
        self.groupID = groupID
        self.userID = userID
        if let per = auth.permissions {
            permission = RLMPermission(with: _id, groupID: groupID, permission: per)
        }
    }
}

class RLMPermission: Object {
    @objc dynamic var _id: String = UUID().uuidString
    @objc dynamic var groupID: String = ""
    
    // owner
    @objc dynamic var editAmdins: Bool = true
    @objc dynamic var transferOwner: Bool = true
    
    // admin, owner
    @objc dynamic var deleteMessages: Bool = true
    @objc dynamic var banUsers: Bool = true
    @objc dynamic var removeUsers: Bool = true
    @objc dynamic var addAdmins: Bool = true
    @objc dynamic var addExceptionUsers: Bool = true
    @objc dynamic var inviteUsersViaLink: Bool = true
    @objc dynamic var changeGroupInfo: Bool = true
    @objc dynamic var canAddFriend: Bool = false
    // member, admin
    @objc dynamic var sendMessages: Bool = true
    @objc dynamic var sendImages: Bool = true
    @objc dynamic var sendHyperlinks: Bool = true
    @objc dynamic var inviteUsers: Bool = true
    
    override static func primaryKey() -> String {
        return "_id"
    }

    convenience init(with id: String, groupID: String, permission: RPermission) {
        self.init()
        // groupID_userID
        self._id = id
        self.groupID = groupID
        self.inviteUsers = permission.inviteUsers
        self.sendHyperlinks = permission.sendHyperlinks
        self.sendImages = permission.sendImages
        self.sendMessages = permission.sendMessages
        
        self.canAddFriend = permission.canAddFriend
        self.changeGroupInfo = permission.changeGroupInfo
        self.inviteUsersViaLink = permission.inviteUsersViaLink
        self.addExceptionUsers = permission.addExceptionUsers
        self.addAdmins = permission.addAdmins
        self.removeUsers = permission.removeUsers
        self.banUsers = permission.banUsers
        self.deleteMessages = permission.deleteMessages
        
        self.editAmdins = permission.editAmdins
        self.transferOwner = permission.transferOwner
    }
    
    func updateTo(role: PermissionType) {
        if role == .member {
            // admin and owner will be true
            self.deleteMessages = false
            self.banUsers = false
            self.removeUsers = false
            self.addAdmins = false
            self.addExceptionUsers = false
            self.inviteUsersViaLink = false
            self.changeGroupInfo = false
            self.editAmdins = false
            self.transferOwner = false
            self.canAddFriend = false
        } else if role == .admin {
            self.editAmdins = false
            self.transferOwner = false
        } else if role == .owner {
            self.canAddFriend = true
        }
    }
}
