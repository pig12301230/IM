//
//  RLMAvatarThumbnail.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/5/7.
//

import Foundation
import RealmSwift

class RLMAvatarThumbnail: Object {
    /// same as RLMContact.avatar_thumbnail
    @objc dynamic var _id: String = ""
    @objc dynamic var dataPNGImg: Data?
    
    override static func primaryKey() -> String {
        return "_id"
    }
}
