//
//  FileModel.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/6/15.
//

import Foundation

struct FileModel: ModelPotocol, ResponseModelPotocol {
    typealias DBObject = RLMFiles
    typealias ResponseObject = RFile
    
    var id: String = ""
    var mimetype: String = ""
    var type: String = ""
    var size: Int = 0
    var url: String = ""
    var thumbURL: String = ""
    var createAt: Int = 0
    
    init() {
        self.id = ""
    }
    
    init(with rlmFile: RLMFiles) {
        id = rlmFile._id
        mimetype = rlmFile.mimetype
        type = rlmFile.type
        size = rlmFile.size
        url = rlmFile.url
        thumbURL = rlmFile.thumbURL
        createAt = rlmFile.createAt
    }
    
    func convertToDBObject() -> DBObject {
        let dbObject = DBObject.init()
        dbObject._id = self.id
        dbObject.mimetype = self.mimetype
        dbObject.type = self.type
        dbObject.size = self.size
        dbObject.url = self.url
        dbObject.thumbURL = self.thumbURL
        dbObject.createAt = self.createAt
        return dbObject
    }
    
    // MARK: - ResponseModelPotocol
    mutating func updateByResponseObject(_ object: ResponseObject) {
        id = object.id
        mimetype = object.mimetype
        type = object.type
        size = object.size
        url = object.url
        thumbURL = object.thumbURL
        createAt = object.createAt
    }
}
