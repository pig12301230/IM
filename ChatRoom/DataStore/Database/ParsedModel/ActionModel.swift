//
//  ActionModel.swift
//  ChatRoom
//
//  Created by Andy Yang on 2021/7/9.
//

import Foundation

struct ActionModel: ModelPotocol {
    typealias DBObject = RLMAction
    
    var id: String
    var icon: String
    var label: String
    var url: String
    
    init(with action: DBObject) {
        id = action._id
        icon = action.icon
        label = action.label
        url = action.url
    }
    
    init(with action: RAction, messageID: String) {
        id = messageID
        icon = action.icon
        label = action.label
        url = action.url
    }
    
    func convertToDBObject() -> DBObject {
        let obj = DBObject()
        obj._id = id
        obj.icon = icon
        obj.label = label
        obj.url = url
        return obj
    }
    
    mutating func updateByResponseObject(_ object: RAction) {
        self.icon = object.icon
        self.label = object.label
        self.url = object.url
    }
}
