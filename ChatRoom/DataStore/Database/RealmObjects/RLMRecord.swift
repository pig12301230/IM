//
//  RLMRecord.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/5/31.
//

import RealmSwift

class RLMRecord: Object {
    @objc dynamic var groupID: String = ""
    @objc dynamic var deleteTime: Int = 0
    @objc dynamic var deletedLastMessage: String = ""
    @objc dynamic var checkedLastMessage: String = ""
    var deletedMessageList = List<String>()
    
    override class func primaryKey() -> String {
        return "groupID"
    }
    
}
