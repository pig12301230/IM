//
//  RLMHongBaoContent.swift
//  ChatRoom
//
//  Created by Winston_Chuang on 2022/12/30.
//

import RealmSwift

class RLMHongBaoStyle: Object {
    @objc dynamic var _id: String = ""
    @objc dynamic var select_style: Int = 1
    @objc dynamic var background_color: String = ""
    @objc dynamic var icon: String = ""
    @objc dynamic var background_image: String = ""
    @objc dynamic var floating_style: String = ""
    
    override static func primaryKey() -> String {
        return "_id"
    }
    
    convenience init(style: RHongBaoStyle, id: String) {
        self.init()
        self._id = id
        self.select_style = style.selectStyle.rawValue
        self.background_color = style.backgroundColor.rawValue
        self.background_image = style.backgroundImage
        self.icon = style.icon.rawValue
        self.floating_style = style.floatingStyle
    }
    
    func toStyle() -> HongBaoStyle {
        return HongBaoStyle(style: self.select_style,
                             backgroundColor: self.background_color,
                             icon: self.icon,
                            backgroundImage: self.background_image,
                            floatingStyle: self.floating_style)
    }
}

class RLMHongBaoContent: Object {
    @objc dynamic var _id: String = ""
    @objc dynamic var recipient: String = ""
    @objc dynamic var status: Int = 0
    @objc dynamic var envelope_type: Int = 0
    @objc dynamic var envelope_desc: String = ""
    @objc dynamic var amount: Int = 0
    @objc dynamic var balance: String = ""
    @objc dynamic var executes_at: Int = 0
    @objc dynamic var expire_at: Int = 0
    @objc dynamic var style: RLMHongBaoStyle?
    
    override static func primaryKey() -> String {
        return "_id"
    }
  
    convenience init(with hongBao: RHongBaoContent) {
        self.init()
        self._id = hongBao.id
        self.recipient = hongBao.recipient ?? ""
        self.status = hongBao.status
        self.envelope_type = hongBao.type
        self.envelope_desc = hongBao.description
        self.amount = hongBao.amount
        self.balance = hongBao.balance
        self.executes_at = hongBao.executesAt
        self.expire_at = hongBao.expiredAt
        if let style = hongBao.style {
            self.style = RLMHongBaoStyle(style: style, id: hongBao.id)
        } else {
            self.style = nil
        }
    }
}
