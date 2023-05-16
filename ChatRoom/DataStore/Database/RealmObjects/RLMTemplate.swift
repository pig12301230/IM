//
//  RLMTemplate.swift
//  ChatRoom
//
//  Created by Andy Yang on 2021/7/9.
//

import Foundation
import RealmSwift

class RLMTemplate: Object {
    @objc dynamic var _id: String = ""
    @objc dynamic var game: String = ""
    @objc dynamic var freq: String = ""
    @objc dynamic var num: String = ""
    @objc dynamic var betType: String = ""
    @objc dynamic var option: RLMOption?
    @objc dynamic var desc: String = ""
    @objc dynamic var action: RLMAction?
    
    override static func primaryKey() -> String? {
        "_id"
    }
    
    convenience init(with messageID: String, template: RTemplate) {
        self.init()
        _id = messageID
        game = template.game
        freq = template.freq ?? ""
        num = template.num ?? ""
        betType = template.betType ?? ""
        desc = template.description ?? ""
        if let rOption = template.option {
            option = RLMOption(with: rOption, messageID: messageID)
        }
        if let rAction = template.action {
            action = RLMAction(with: rAction, messageID: messageID)
        }
    }
}
