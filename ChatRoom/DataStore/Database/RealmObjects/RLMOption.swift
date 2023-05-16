//
//  RLMOption.swift
//  ChatRoom
//
//  Created by Andy Yang on 2021/7/9.
//

import Foundation
import RealmSwift

class RLMOption: Object {
    @objc dynamic var _id: String = ""
    @objc dynamic var text: String = ""
    @objc dynamic var color: String = ""
    
    override class func primaryKey() -> String? {
        "_id"
    }
    
    convenience init(with option: ROption, messageID: String) {
        self.init()
        _id = messageID
        text = option.text
        color = option.color
    }
}
