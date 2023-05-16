//
//  FriendModel.swift
//  ChatRoom
//
//  Created by Andy Yang on 2021/6/24.
//

import Foundation
import UIKit

class FriendModel {
    var id: String
    var displayName: String
    var searchStr: String?
    var isGroup: Bool
    var isDM: Bool = true
    var isBlock: Bool?
    var isNotifyOn: Bool?
    var avatar: String?
    var thumbNail: String?
    var memberCount: Int?
    var ownerID: String?
    var groupID: String?
    var createAt: Date?
    var joinAt: Date?
    var deleteAt: Date?
    var userName: String?
    var nickname: String?
    
    static let updateFriendModelNotification = "updateFriendModelNotification"
    
    init(id: String, displayName: String, nickname: String? = nil, isGroup: Bool, isBlock: Bool? = nil, isNotifyOn: Bool? = nil, avatar: String? = nil, thumbNail: String? = nil, memberCount: Int? = nil, ownerID: String? = nil, groupID: String? = nil, createAt: Date? = nil, userName: String? = nil, joinAt: Date? = nil, deleteAt: Date? = nil) {
        self.id = id
        self.displayName = displayName
        self.nickname = nickname
        self.isGroup = isGroup
        self.isBlock = isBlock
        self.isNotifyOn = isNotifyOn
        self.avatar = avatar
        self.thumbNail = thumbNail
        self.memberCount = memberCount
        self.ownerID = ownerID
        self.groupID = groupID
        self.createAt = createAt
        self.userName = userName
        self.joinAt = joinAt
        self.deleteAt = deleteAt
        
        registerNotification()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    static func convertContactToFriend(contact: ContactModel) -> FriendModel {
        return FriendModel(id: contact.id,
                           displayName: contact.display,
                           nickname: contact.nickname,
                           isGroup: false,
                           avatar: contact.icon,
                           thumbNail: contact.iconThumbnail,
                           createAt: contact.createAt,
                           userName: contact.username)
    }
    
    static func convertGroupToFriend(group: GroupModel) -> FriendModel {
        let model = FriendModel(id: group.id,
                                displayName: group.display,
                                isGroup: true,
                                isNotifyOn: !group.notifyType.value,
                                avatar: group.icon,
                                thumbNail: group.iconThumbnail,
                                memberCount: group.memberCount,
                                ownerID: group.ownerID,
                                groupID: group.id,
                                createAt: group.createAt)
        model.isDM = group.groupType == .dm
        return model
    }
    
    static func converTransceiverToFriend(transceiver: TransceiverModel) -> FriendModel {
        return FriendModel(id: transceiver.userID,
                           displayName: transceiver.display,
                           nickname: transceiver.nickname,
                           isGroup: false,
                           isBlock: transceiver.blocked,
                           avatar: transceiver.avatar,
                           thumbNail: transceiver.avatarThumbnail,
                           groupID: transceiver.groupID,
                           createAt: transceiver.createAt,
                           userName: transceiver.username,
                           joinAt: transceiver.joinAt,
                           deleteAt: transceiver.deleteAt)
    }
    
    static func converBlockedToFriend(blocked: BlockedContactModel) -> FriendModel {
        return FriendModel(id: blocked.id,
                           displayName: blocked.display,
                           nickname: blocked.nickname,
                           isGroup: false,
                           isBlock: true,
                           avatar: blocked.icon,
                           thumbNail: blocked.iconThumbnail,
                           createAt: blocked.createAt)
    }
    
    func registerNotification() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateSelf),
                                               name: Notification.Name(FriendModel.updateFriendModelNotification + id),
                                               object: nil)
    }
    
    @objc func updateSelf(_ notification: Notification) {
        if let nickname = DataAccess.shared.getUserPersonalSetting(with: id)?.nickname, !nickname.isEmpty {
            self.displayName = nickname
        } else if let nickname = nickname {
            self.displayName = nickname
        }
        
        guard let newSelf = notification.userInfo?["data"] as? FriendModel else { return }
        self.isBlock = newSelf.isBlock
        self.isNotifyOn = newSelf.isNotifyOn
    }
    
    func display() -> NSMutableAttributedString {
        return displayName.toSearchHighlightStr(searchStr: searchStr)
    }
    
    func getDisplayName() -> String {
        return displayName
    }

}

fileprivate extension String {
    func toSearchHighlightStr(searchStr: String?) -> NSMutableAttributedString {
        let defaultAttr = [NSAttributedString.Key.font: UIFont.midiumParagraphLargeLeft,
                           NSAttributedString.Key.foregroundColor: Theme.c_10_grand_1.rawValue.toColor()]
        let attStr: NSMutableAttributedString = NSMutableAttributedString(string: self, attributes: defaultAttr)
        
        guard let searchStr = searchStr, !searchStr.isEmpty else { return attStr }
        
        let ranges = self.ranges(of: searchStr, options: .caseInsensitive)
        ranges.forEach {
            attStr.addAttributes([NSAttributedString.Key.font: UIFont.midiumParagraphLargeLeft,
                                  NSAttributedString.Key.foregroundColor: Theme.c_01_primary_0_500.rawValue.toColor()],
                                 range: NSRange($0, in: self))
        }
        return attStr
    }
}
