//
//  RLMAvatar.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/5/7.
//

import Foundation
import RealmSwift

class RLMAvatar: Object {
    /// same as RLMContact.avatar
    @objc dynamic var _id: String = ""
    @objc dynamic var dataPNGImg: Data?
    
    override static func primaryKey() -> String {
        return "_id"
    }
}
