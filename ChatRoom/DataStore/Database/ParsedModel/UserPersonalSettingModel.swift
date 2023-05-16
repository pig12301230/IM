//
//  UserPersonalSettingModel.swift
//  ChatRoom
//
//  Created by Winston_Chuang on 2022/3/24.
//

import Foundation

struct UserPersonalSettingModel: ModelPotocol {
    typealias DBObject = RLMUserPersonalSetting
    
    var id: String
    var nickname: String?
    var memo: String?
    
    
    init(with rlmUserPersonalSetting: DBObject) {
        id = rlmUserPersonalSetting._id
        nickname = rlmUserPersonalSetting.nickname
        memo = rlmUserPersonalSetting.memo
    }
    
    init(memberID: String, nickname: String? = nil, memo: String? = nil) {
        self.id = memberID
        self.nickname = nickname
        self.memo = memo
    }

    func convertToDBObject() -> DBObject {
        let obj = DBObject()
        obj._id = id
        obj.nickname = nickname
        obj.memo = memo
        return obj
    }
}
