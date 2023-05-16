//
//  RLMConversation.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/5/7.
//

import Foundation
import RealmSwift

class RLMConversation: Object {
    // same as RLMGroup._id
    @objc dynamic var _id: String = ""
    @objc dynamic var name: String = ""
    @objc dynamic var muted: Bool = false
    
    var messages = List<RLMMessage>()
    var members = List<RLMTransceiver>()
    
    override static func primaryKey() -> String {
        return "_id"
    }
    
    convenience init<S: Sequence>(with groupID: String, name: String, messages: S) where S.Iterator.Element == RMessage {
        self.init()
        self._id = groupID
        self.name = name
        
        for msg in messages {
            let rlm_msg = RLMMessage.init(with: msg)
            self.messages.append(rlm_msg)
        }
    }
}
