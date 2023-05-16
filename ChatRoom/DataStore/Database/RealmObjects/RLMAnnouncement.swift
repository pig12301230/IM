//
//  RLMAnnouncement.swift
//  ChatRoom
//
//  Created by Winston_Chuang on 2022/2/23.
//

import Foundation
import RealmSwift

class RLMAnnouncement: Object {
    @objc dynamic var _id: String = ""
    @objc dynamic var groupID: String = ""
    @objc dynamic var message: RLMAnnouncementMessage?
    @objc dynamic var pinAt: Date?
    
    override static func primaryKey() -> String {
        return "_id"
    }

    convenience init(groupID: String, message: RLMAnnouncementMessage, pinAt: Int?) {
        self.init()
        self._id = groupID + "_" + message._id
        self.groupID = groupID
        self.message = message
        
        if let pinAt = pinAt {
            self.pinAt = Date(timeIntervalSince1970: TimeInterval(Double(pinAt) / 1000))
        }
    }
}
