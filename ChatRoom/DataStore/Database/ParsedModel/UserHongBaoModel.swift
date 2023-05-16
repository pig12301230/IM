//
//  UserHongBaoModel.swift
//  ChatRoom
//
//  Created by Winston_Chuang on 2022/12/28.
//

import Foundation

struct UserHongBaoModel {
    var userID: String = ""
    var nickname: String = ""
    var amount: String = ""
    var description: String = ""
    var status: HongBaoStatus
    var type: HongBaoType
    
    init(with object: RUserHongBao) {
        self.userID = object.userID
        self.nickname = object.nickname
        self.status = object.status
        self.type = object.type
        self.description = object.description
        self.amount = object.amount
    }
    
    init(status: HongBaoStatus, type: HongBaoType) {
        self.status = status
        self.type = type
    }
}

struct HongBaoClaimStatus {
    var userID: String
    var nickname: String
    var avatar: String
    var avatarThumbnail: String
    var status: HongBaoStatus
    
    init(with info: RHongBaoClaimStatus) {
        userID = info.userID
        nickname = info.nickname
        avatar = info.avatar
        avatarThumbnail = info.avatarThumbnail
        status = HongBaoStatus(rawValue: info.status) ?? .withdrawble
    }
}

struct UnOpenedHongBaoModel {
    var amount: Int
    var firstMessageID: String
    var floatingHongBaoList: [FloatingHongBao]
    
    init(with info: RHongBaoUnOpened) {
        amount = info.amount
        firstMessageID = info.firstMessageID
        floatingHongBaoList = info.floatingHongBaoList.compactMap({ FloatingHongBao(with: $0) })
    }
}

struct FloatingHongBao {
    var campaignID: String
    var messageID: String
    var floatingUrl: String
    
    init(with info: RFloatingHongBao) {
        campaignID = info.campaignID
        messageID = info.messageID
        floatingUrl = info.floatingUrl
    }
}
