//
//  OptionModel.swift
//  ChatRoom
//
//  Created by Andy Yang on 2021/7/9.
//

import Foundation

struct OptionModel: ModelPotocol {
    typealias DBObject = RLMOption
    
    var id: String
    var text: String
    var color: String
    
    init(with option: DBObject) {
        id = option._id
        text = option.text
        color = option.color
    }
    
    init(with option: ROption, messageID: String) {
        id = messageID
        text = option.text
        color = option.color
    }
    
    func convertToDBObject() -> RLMOption {
        let obj = DBObject()
        obj._id = id
        obj.text = text
        obj.color = color
        return obj
    }
    
    mutating func updateByResponseObject(_ object: ROption) {
        self.text = object.text
        self.color = object.color
    }
}
