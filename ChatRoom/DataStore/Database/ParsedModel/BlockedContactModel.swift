//
//  BlockedContactModel.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/7/9.
//

import Foundation

struct BlockedContactModel: ModelPotocol, DataPotocol {
    typealias DBObject = RLMBlockedContact
    
    var id: String = ""
    var username: String = ""
    var nickname: String = ""
    var display: String = ""
    var icon: String = ""
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
