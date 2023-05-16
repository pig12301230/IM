//
//  HongBaoContent.swift
//  ChatRoom
//
//  Created by Winston_Chuang on 2022/12/30.
//

import Foundation
import UIKit

enum HongBaoSelectStyle: Int {
    case custom = 1
    case single = 2
}

enum HongBaoBackgroundColor: String {
    case message_random_amount_color_1
    case message_random_amount_color_2
    case message_random_amount_color_3
    case message_random_amount_color_4
    case message_random_amount_color_5
    
    var imageName: String {
        switch self {
        case .message_random_amount_color_1:
            return "image_new_envelope_bg"
        case .message_random_amount_color_2:
            return "image_new_envelope_bg_orange"
        case .message_random_amount_color_3:
            return "image_new_envelope_bg_pink"
        case .message_random_amount_color_4:
            return "image_new_envelope_bg_purple"
        case .message_random_amount_color_5:
            return "image_new_envelope_bg_red"
        }
    }
}

enum HongBaoIcon: String {
    case message_random_amount_style_1
    case message_random_amount_style_2
    case message_random_amount_style_3
    case message_random_amount_style_4
    case message_random_amount_style_5
    case message_random_amount_style_6
    case message_random_amount_style_7
    case message_random_amount_style_8
    case message_random_amount_style_9
    
    var imageName: String {
        switch self {
        case .message_random_amount_style_1:
            return "chat_bubble_envelope_x_icon_red_envelope_fortunewheel"
        case .message_random_amount_style_2:
            return "chat_bubble_envelope_x_icon_red_envelope_fortune_a"
        case .message_random_amount_style_3:
            return "chat_bubble_envelope_x_icon_red_envelope_fortune_b"
        case .message_random_amount_style_4:
            return "chat_bubble_envelope_x_icon_red_envelope_fortune_c"
        case .message_random_amount_style_5:
            return "chat_bubble_envelope_x_icon_red_envelope_fortune_d"
        case .message_random_amount_style_6:
            return "chat_bubble_envelope_x_icon_red_envelope_fortune_e"
        case .message_random_amount_style_7:
            return "chat_bubble_envelope_x_icon_red_envelope_fortune_f"
        case .message_random_amount_style_8:
            return "chat_bubble_envelope_x_icon_red_envelope_fortune_g"
        case .message_random_amount_style_9:
            return "chat_bubble_envelope_x_icon_red_envelope_fortune_h"
        }
    }
}

struct HongBaoStyle: Hashable {
    let selectStyle: HongBaoSelectStyle
    let backgroundColor: HongBaoBackgroundColor
    let icon: HongBaoIcon
    let backgroundImage: String
    let floatingStyle: String
    
    init(style: Int, backgroundColor: String, icon: String, backgroundImage: String, floatingStyle: String) {
        self.selectStyle = HongBaoSelectStyle(rawValue: style) ?? .custom
        self.icon = HongBaoIcon(rawValue: icon) ?? .message_random_amount_style_1
        self.backgroundColor = HongBaoBackgroundColor(rawValue: backgroundColor) ?? .message_random_amount_color_1
        self.backgroundImage = backgroundImage
        self.floatingStyle = floatingStyle
    }
}

struct HongBaoContent: ModelPotocol {
    static func == (lhs: HongBaoContent, rhs: HongBaoContent) -> Bool {
        return lhs.campaignID == rhs.campaignID
    }
    
    typealias DBObject = RLMHongBaoContent
    
    let campaignID: String
    let senderID: String?
    let groupID: String?
    let recipient: String?
    let status: Int
    let type: HongBaoType
    let description: String
    let amount: Int
    let balance: String
    let executeAt: Int
    let expiredAt: Int
    let style: HongBaoStyle?
    
    var executeDate: Date {
        return Date(timeIntervalSince1970: TimeInterval(Double(executeAt) / 1000))
    }
    
    var expiredDate: Date {
        Date(timeIntervalSince1970: TimeInterval(Double(expiredAt) / 1000))
    }
    
    init(with object: RLMHongBaoContent, senderID: String, groupID: String) {
        self.campaignID = object._id
        self.senderID = senderID
        self.groupID = groupID
        self.recipient = object.recipient
        self.status = object.status
        self.type = HongBaoType(rawValue: object.envelope_type) ?? .basic
        self.description = object.envelope_desc
        self.amount = object.amount
        self.balance = object.balance
        self.executeAt = object.executes_at
        self.expiredAt = object.expire_at
        self.style = object.style?.toStyle()
    }
    
    init(with object: RLMHongBaoContent) {
        self.campaignID = object._id
        self.recipient = object.recipient
        self.senderID = nil
        self.groupID = nil
        self.status = object.status
        self.type = HongBaoType(rawValue: object.envelope_type) ?? .basic
        self.description = object.envelope_desc
        self.amount = object.amount
        self.balance = object.balance
        self.executeAt = object.executes_at
        self.expiredAt = object.expire_at
        self.style = object.style?.toStyle()
    }
    
    func convertToDBObject() -> RLMHongBaoContent {
        let object = DBObject()
        object._id = self.campaignID
        object.recipient = self.recipient ?? ""
        object.status = self.status
        object.envelope_type = self.type.rawValue
        object.envelope_desc = self.description
        object.amount = self.amount
        object.balance = self.balance
        object.executes_at = self.executeAt
        object.expire_at = self.expiredAt
        
        if let style = self.style {
            object.style = RLMHongBaoStyle(style: RHongBaoStyle(style: style), id: self.campaignID)
        }
        return object
    }
}
