//
//  RLMAction.swift
//  ChatRoom
//
//  Created by Andy Yang on 2021/7/9.
//

import Foundation
import RealmSwift

class RLMAction: Object {
    @objc dynamic var _id: String = ""
    @objc dynamic var icon: String = ""
    @objc dynamic var label: String = ""
    @objc dynamic var url: String = ""
    
    override static func primaryKey() -> String? {
        "_id"
    }
    
    convenience init(with action: RAction, messageID: String) {
        self.init()
        _id = messageID
        icon = action.icon
        label = action.label
        url = action.url
    }
}
