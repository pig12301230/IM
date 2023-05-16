//
//  AnnouncementModel.swift
//  ChatRoom
//
//  Created by Winston_Chuang on 2022/2/23.
//

import Foundation

struct AnnouncementModel: ModelPotocol {
    typealias DBObject = RLMAnnouncement
    
    var id: String
    var groupID: String
    var message: MessageModel?
    var pinAt: Date?
    
    init(with object: RLMAnnouncement) {
        self.id = object._id
        self.groupID = object.groupID
        if let message = object.message {
            self.message = MessageModel(with: message)
        }
        self.pinAt = object.pinAt
    }
    
    func convertToDBObject() -> RLMAnnouncement {
        let obj = DBObject()
        obj._id = id
        obj.groupID = groupID
        obj.message = message?.convertToAnnoucementDBObject()
        obj.pinAt = pinAt
        return obj
    }
}
