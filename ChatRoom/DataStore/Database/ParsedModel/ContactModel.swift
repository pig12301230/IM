//
//  ContactModel.swift
//  ChatRoom
//
//  Created by Andy Yang on 2021/6/7.
//

import Foundation

struct ContactModel: ModelPotocol, DataPotocol {
    typealias DBObject = RLMContact
    
    var id: String = ""
    var username: String = ""
    var nickname: String = ""
    var display: String = ""
    /// same as RLMAvatar._id
    var icon: String = ""
    /// same as RLMAvatarThumbnail._id
    var iconThumbnail: String = ""
    var createAt: Date?
    var updateAt: Date?
    var timestamp: Int = 0
    
    init(with rlmContact: DBObject) {
        id = rlmContact._id
        username = rlmContact.username
        nickname = rlmContact.nickname
        display = rlmContact.displayName
        icon = rlmContact.avatar
        iconThumbnail = rlmContact.avatarThumbnail
        createAt = rlmContact.createAt
        updateAt = rlmContact.updateAt
        timestamp = rlmContact.timestamp
    }
    
    func convertToDBObject() -> DBObject {
        let dbObject = DBObject.init()
        dbObject._id = self.id
        dbObject.username = self.username
        dbObject.nickname = self.nickname
        dbObject.displayName = self.display
        dbObject.avatar = self.icon
        dbObject.avatarThumbnail = self.iconThumbnail
        dbObject.createAt = self.createAt
        dbObject.updateAt = self.updateAt
        dbObject.timestamp = self.timestamp
        return dbObject
    }

}
