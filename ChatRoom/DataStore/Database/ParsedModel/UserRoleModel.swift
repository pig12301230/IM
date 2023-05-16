//
//  UserRoleModel.swift
//  ChatRoom
//
//  Created by ZoeLin on 2022/1/19.
//

import Foundation

struct UserRoleModel: ModelPotocol {
    typealias DBObject = RLMUserRole
    
    var _id: String = UUID().uuidString
    var type: PermissionType = .none
    var groupID: String = ""
    var userID: String = ""
    var permission: RolePermissionModel
    
    init(with object: DBObject) {
        self._id = object._id
        self.type = PermissionType(rawValue: object.type) ?? .none
        self.groupID = object.groupID
        self.userID = object.userID
        if let per = object.permission {
            self.permission = RolePermissionModel.init(with: per)
        } else {
            self.permission = RolePermissionModel()
        }
        
    }
    
    init(groupID: String, userID: String, type: PermissionType, permission: RolePermissionModel) {
        self.type = type
        self.groupID = groupID
        self.userID = userID
        self.permission = permission
    }
    
    func convertToDBObject() -> DBObject {
        let dbObject = DBObject.init()
        dbObject.groupID = self.groupID
        dbObject.userID = self.userID
        dbObject._id = self._id
        dbObject.type = self.type.rawValue
        dbObject.permission = self.permission.convertToDBObject()
        return dbObject
    }
}

struct RolePermissionModel: ModelPotocol {
    typealias DBObject = RLMPermission
    
    var _id: String = UUID().uuidString
    var groupID: String = ""
    
    // owner
    var editAmdins: Bool = true
    var transferOwner: Bool = true
    
    // admin, owner
    var deleteMessages: Bool = true
    var banUsers: Bool = true
    var removeUsers: Bool = true
    var addAdmins: Bool = true
    var addExceptionUsers: Bool = true
    var inviteUsersViaLink: Bool = true
    var changeGroupInfo: Bool = true
    var canAddFriend: Bool = false
    
    // member, admin
    var sendMessages: Bool = true
    var sendImages: Bool = true
    var sendHyperlinks: Bool = true
    var inviteUsers: Bool = true
    
    init() {
        
    }
    
    init(with role: PermissionType) {
        self.init()
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
    
    init(with object: DBObject) {
        self._id = object._id
        self.groupID = object.groupID
        
        self.editAmdins = object.editAmdins
        self.transferOwner = object.transferOwner
        
        self.deleteMessages = object.deleteMessages
        self.banUsers = object.banUsers
        self.removeUsers = object.removeUsers
        self.addAdmins = object.addAdmins
        self.addExceptionUsers = object.addExceptionUsers
        self.inviteUsersViaLink = object.inviteUsersViaLink
        self.changeGroupInfo = object.changeGroupInfo
        self.canAddFriend = object.canAddFriend
        
        self.sendMessages = object.sendMessages
        self.sendImages = object.sendImages
        self.sendHyperlinks = object.sendHyperlinks
        self.inviteUsers = object.inviteUsers
    }
    
    func convertToDBObject() -> DBObject {
        let dbObject = DBObject.init()
        dbObject._id = self._id
        dbObject.groupID = self.groupID
        
        dbObject.editAmdins = self.editAmdins
        dbObject.transferOwner = self.transferOwner
        
        dbObject.deleteMessages = self.deleteMessages
        dbObject.banUsers = self.banUsers
        dbObject.removeUsers = self.removeUsers
        dbObject.addAdmins = self.addAdmins
        dbObject.addExceptionUsers = self.addExceptionUsers
        dbObject.inviteUsersViaLink = self.inviteUsersViaLink
        dbObject.changeGroupInfo = self.changeGroupInfo
        dbObject.canAddFriend = self.canAddFriend
        
        dbObject.sendMessages = self.sendMessages
        dbObject.sendImages = self.sendImages
        dbObject.sendHyperlinks = self.sendHyperlinks
        dbObject.inviteUsers = self.inviteUsers
        return dbObject
    }
    
    mutating func update(by permission: RPermission, role: PermissionType) {
        var object = permission
        object.updateTo(role: role)
                
        self.editAmdins = object.editAmdins
        self.transferOwner = object.transferOwner
        
        self.deleteMessages = object.deleteMessages
        self.banUsers = object.banUsers
        self.removeUsers = object.removeUsers
        self.addAdmins = object.addAdmins
        self.addExceptionUsers = object.addExceptionUsers
        self.inviteUsersViaLink = object.inviteUsersViaLink
        self.changeGroupInfo = object.changeGroupInfo
        self.canAddFriend = object.canAddFriend
        
        self.sendMessages = object.sendMessages
        self.sendImages = object.sendImages
        self.sendHyperlinks = object.sendHyperlinks
        self.inviteUsers = object.inviteUsers
    }
}
