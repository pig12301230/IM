//
//  GroupBlackListModel.swift
//  ChatRoom
//
//  Created by Winston_Chuang on 2022/1/26.
//

import Foundation

struct GroupBlackListModel: ModelPotocol {
    typealias DBObject = RLMBlackList
    
    var id: String
    var groupID: String
    var userID: String
    var createAt: Date?
    var updateAt: Date?
    
    init(with rlmBlackList: DBObject) {
        id = rlmBlackList._id
        groupID = rlmBlackList.groupID
        userID = rlmBlackList.userID
        createAt = rlmBlackList.createAt
        updateAt = rlmBlackList.updateAt
    }
    
    func convertToDBObject() -> DBObject {
        let obj = DBObject()
        obj._id = id
        obj.groupID = groupID
        obj.userID = userID
        obj.createAt = createAt
        obj.updateAt = updateAt
        return obj
    }
}
