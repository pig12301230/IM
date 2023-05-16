//
//  RecordModel.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/6/8.
//

import Foundation

struct RecordModel: ModelPotocol {
    typealias DBObject = RLMRecord
    
    var groupID: String = ""
    var deleteTime: Int = 0
    var deletedLastMessage: String = ""
    var checkedLastMessage: String = ""
    
    init(with rlmRecord: RLMRecord) {
        groupID = rlmRecord.groupID
        deleteTime = rlmRecord.deleteTime
        deletedLastMessage = rlmRecord.deletedLastMessage
        checkedLastMessage = rlmRecord.checkedLastMessage
    }
    
    func convertToDBObject() -> DBObject {
        let dbObject = DBObject.init()
        dbObject.groupID = self.groupID
        dbObject.deleteTime = self.deleteTime
        dbObject.deletedLastMessage = self.deletedLastMessage
        dbObject.checkedLastMessage = self.checkedLastMessage
        return dbObject
    }
}
