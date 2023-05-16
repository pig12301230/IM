//
//  RLMBlackList.swift
//  ChatRoom
//
//  Created by Winston_Chuang on 2022/1/26.
//

import Foundation
import RealmSwift

class RLMBlackList: Object {
    @objc dynamic var _id: String = UUID().uuidString
    @objc dynamic var groupID: String = ""
    @objc dynamic var userID: String = ""
    @objc dynamic var createAt: Date?
    @objc dynamic var updateAt: Date?
    
    override static func primaryKey() -> String {
        return "_id"
    }

    convenience init(groupID: String, info: RUserInfo) {
        self.init()
        self._id = groupID + "_" + info.id
        self.groupID = groupID
        self.userID = info.id
        self.createAt = Date(timeIntervalSince1970: TimeInterval(Double(info.createAt) / 1000))
        self.updateAt = Date(timeIntervalSince1970: TimeInterval(Double(info.updateAt) / 1000))
    }
    
    convenience init(groupID: String, userID: String) {
        self.init()
        self._id = groupID + "_" + userID
        self.groupID = groupID
        self.userID = userID
    }
}
