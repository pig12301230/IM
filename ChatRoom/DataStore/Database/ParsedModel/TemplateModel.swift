//
//  TemplateModel.swift
//  ChatRoom
//
//  Created by Andy Yang on 2021/7/9.
//

import Foundation

struct TemplateModel: ModelPotocol {
    typealias DBObject = RLMTemplate
    
    var id: String
    var game: String
    var freq: String
    var num: String
    var betType: String
    var option: OptionModel?
    var description: String
    var action: ActionModel?
    
    init(with template: DBObject) {
        id = template._id
        game = template.game
        freq = template.freq
        num = template.num
        betType = template.betType
        description = template.desc
        if let rlmOption = template.option {
            option = OptionModel(with: rlmOption)
        }
        if let rlmAction = template.action {
            action = ActionModel(with: rlmAction)
        }
    }
    
    init(with template: RTemplate, messageID: String) {
        id = messageID
        game = template.game
        freq = template.freq ?? ""
        num = template.num ?? ""
        betType = template.betType ?? ""
        description = template.description ?? ""
        if let rOption = template.option {
            option = OptionModel(with: rOption, messageID: id)
        }
        if let rAction = template.action {
            action = ActionModel(with: rAction, messageID: id)
        }
    }
    
    func convertToDBObject() -> DBObject {
        let obj = DBObject()
        obj._id = id
        obj.game = game
        obj.freq = freq
        obj.num = num
        obj.betType = betType
        obj.option = option?.convertToDBObject()
        obj.desc = description
        obj.action = action?.convertToDBObject()
        return obj
    }
    
    mutating func updateByResponseObject(_ object: RTemplate) {
        self.game = object.game
        self.freq = object.freq ?? self.freq
        self.num = object.num ?? self.num
        self.betType = object.betType ?? self.betType
        self.description = object.description ?? self.description
        
        if let rOption = object.option {
            self.option?.updateByResponseObject(rOption)
        }
        
        if let rAction = object.action {
            self.action?.updateByResponseObject(rAction)
        }
    }
}
