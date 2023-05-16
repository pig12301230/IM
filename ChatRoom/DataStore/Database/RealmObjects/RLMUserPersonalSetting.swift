//
//  RLMUserPersonalSetting.swift
//  ChatRoom
//
//  Created by Winston_Chuang on 2022/3/24.
//

import Foundation
import RealmSwift


class RLMUserPersonalSetting: Object {
    /// same as Other RLMObject.user_id
    @objc dynamic var _id: String = ""
    @objc dynamic var nickname: String?
    @objc dynamic var memo: String?
    
    override static func primaryKey() -> String {
        return "_id"
    }
}
