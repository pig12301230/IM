//
//  RLMFiles.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/6/15.
//

import RealmSwift

class RLMFiles: Object {
    
    @objc dynamic var _id: String = ""
    @objc dynamic var mimetype: String = ""
    @objc dynamic var type: String = ""
    @objc dynamic var size: Int = 0
    @objc dynamic var url: String = ""
    @objc dynamic var thumbURL: String = ""
    @objc dynamic var createAt: Int = 0
    
    override static func primaryKey() -> String {
        return "_id"
    }
    
    convenience init(with file: RFile) {
        self.init()
        self._id = file.id
        self.mimetype = file.mimetype
        self.type = file.type
        self.size = file.size
        self.url = file.url
        self.thumbURL = file.thumbURL
        self.createAt = file.createAt
    }
}
