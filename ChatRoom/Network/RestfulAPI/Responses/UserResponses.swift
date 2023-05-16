//
//  UserResponses.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/4/14.
//

import Foundation

struct RAccountInfo: Codable {
    let id: String
    let username: String
    var nickname: String
    let country: String
    let phone: String
    var avatar: String
    var avatarThumbnail: String
    var permissions: RAccountPermission
    var socialAccount: String
    let createAt: Int
    let updateAt: Int
    var notify: NotifyType
    var notifyDetail: NotifyType
    var vibration: NotifyType
    var sound: NotifyType
    var hadSecurityCode: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, username, nickname, country, phone, avatar, notify, vibration, sound, permissions
        case avatarThumbnail = "avatar_thumbnail"
        case socialAccount = "social_account"
        case createAt = "create_at"
        case updateAt = "update_at"
        case notifyDetail = "notify_detail"
        case hadSecurityCode = "had_security_code"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        username = try values.decode(String.self, forKey: .username)
        nickname = try values.decode(String.self, forKey: .nickname)
        country = try values.decode(String.self, forKey: .country)
        phone = try values.decode(String.self, forKey: .phone)
        avatar = try values.decode(String.self, forKey: .avatar)
        avatarThumbnail = try values.decode(String.self, forKey: .avatarThumbnail)
        permissions = try values.decode(RAccountPermission.self, forKey: .permissions)
        socialAccount = try values.decode(String.self, forKey: .socialAccount)
        createAt = try values.decode(Int.self, forKey: .createAt)
        updateAt = try values.decode(Int.self, forKey: .updateAt)
        hadSecurityCode = try values.decode(Bool.self, forKey: .hadSecurityCode)
        
        let notifySetting = try values.decode(Int.self, forKey: .notify)
        notify = NotifyType.init(rawValue: notifySetting) ?? .on
        
        let notifyDetailSetting = try values.decode(Int.self, forKey: .notifyDetail)
        notifyDetail = NotifyType.init(rawValue: notifyDetailSetting) ?? .off
        
        let vibrationSetting = try values.decode(Int.self, forKey: .vibration)
        vibration = NotifyType.init(rawValue: vibrationSetting) ?? .on
        
        let soundSetting = try values.decode(Int.self, forKey: .sound)
        sound = NotifyType.init(rawValue: soundSetting) ?? .on
    }
    
    func encode(to encoder: Encoder) throws {
        // TODO: if need encode
    }
}

struct RAccountPermission: Codable {
    var canCreateGroup: Bool
    
    enum CodingKeys: String, CodingKey {
        case canCreateGroup = "can_create_group"
    }
}

struct RUserInfo: Codable {
    let id: String
    let username: String
    var nickname: String
    let country: String
    let phone: String
    var avatar: String
    var avatarThumbnail: String
    let blocked: Bool?
    let createAt: Int
    let updateAt: Int
    let deleteAt: Int
    let leaveAt: Int?
    let joinAt: Int?
    
    enum CodingKeys: String, CodingKey {
        case id, username, nickname, country, phone, avatar, blocked
        case avatarThumbnail = "avatar_thumbnail"
        case createAt = "create_at"
        case updateAt = "update_at"
        case deleteAt = "delete_at"
        case leaveAt = "leave_at"
        case joinAt = "join_at"
    }
}

struct RUserData: Codable {
    let id: String
    let name: String
    let create_at: Int
    let update_at: Int
}

struct RUserShareLink: Codable {
    let title: String
    let content: String
    let link: String
    
    enum CodingKeys: String, CodingKey {
        case title, content, link
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        title = try values.decode(String.self, forKey: .title)
        content = try values.decode(String.self, forKey: .content)
        link = try values.decode(String.self, forKey: .link)
    }
}

struct RUserUnread: Codable {
    let unreads: [String: Int]
}

struct RUserGroupsPart: Codable {
    let dms: [RUserGroupPart]?
    let groups: [RUserGroupPart]?
}

struct RUserGroupPart: Codable {
    let id: String
    let type: GroupType
    let name: String
    let displayName: String
    let icon: String
    let iconThumbnail: String
    let memberCount: Int?
    let updateAt: Int
    let notify: NotifyType
    
    enum CodingKeys: String, CodingKey {
        case id, type, name, icon, notify
        case displayName = "display_name"
        case iconThumbnail = "icon_thumbnail"
        case memberCount = "member_count"
        case updateAt = "update_at"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        let gType = try values.decode(Int.self, forKey: .type)
        type = GroupType.init(rawValue: gType) ?? .group
        name = try values.decode(String.self, forKey: .name)
        displayName = try values.decode(String.self, forKey: .displayName)
        updateAt = try values.decode(Int.self, forKey: .updateAt)
        
        let notifyType = try values.decode(Int.self, forKey: .notify)
        notify = NotifyType.init(rawValue: notifyType) ?? .on
        icon = try values.decode(String.self, forKey: .icon)
        iconThumbnail = try values.decode(String.self, forKey: .iconThumbnail)
        memberCount = try values.decodeIfPresent(Int.self, forKey: .memberCount)
    }
    
    func encode(to encoder: Encoder) throws {
        // TODO: if need encode
    }
}

struct RUserGroups: Codable {
    let id: String
    let type: GroupType
    let name: String
    let displayName: String
    let ownerID: String
    var lastMessage: RMessage?
    var unread: Int
    let createAt: Int
    let updateAt: Int
    var lastViewed: String
    let lastRead: String
    let notify: NotifyType
    let icon: String
    let iconThumbnail: String
    let memberCount: Int
    let auth: RUserAuth?
    let adminCount: Int
    let blockCount: Int
    let memberPermission: RPermission?
    
    enum CodingKeys: String, CodingKey {
        case id, type, name, unread, notify, icon
        case displayName = "display_name"
        case ownerID = "owner_id"
        case lastMessage = "last_message"
        case createAt = "create_at"
        case updateAt = "update_at"
        case lastViewed = "last_viewed"
        case lastRead = "last_read"
        case iconThumbnail = "icon_thumbnail"
        case memberCount = "member_count"
        case auth = "user_auth"
        case adminCount = "admin_count"
        case blockCount = "block_count"
        case memberPermission = "member_permission"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        let gType = try values.decode(Int.self, forKey: .type)
        type = GroupType.init(rawValue: gType) ?? .group
        name = try values.decode(String.self, forKey: .name)
        displayName = try values.decode(String.self, forKey: .displayName)
        ownerID = try values.decode(String.self, forKey: .ownerID)
        lastMessage = try values.decode(RMessage.self, forKey: .lastMessage)
        unread = try values.decode(Int.self, forKey: .unread)
        createAt = try values.decode(Int.self, forKey: .createAt)
        updateAt = try values.decode(Int.self, forKey: .updateAt)
        lastViewed = try values.decode(String.self, forKey: .lastViewed)
        lastRead = try values.decode(String.self, forKey: .lastRead)
        let notifyType = try values.decode(Int.self, forKey: .notify)
        notify = NotifyType.init(rawValue: notifyType) ?? .on
        icon = try values.decode(String.self, forKey: .icon)
        iconThumbnail = try values.decode(String.self, forKey: .iconThumbnail)
        memberCount = try values.decode(Int.self, forKey: .memberCount)
        auth = try values.decodeIfPresent(RUserAuth.self, forKey: .auth)
        adminCount = try values.decode(Int.self, forKey: .adminCount)
        blockCount = try values.decode(Int.self, forKey: .blockCount)
        memberPermission = try values.decodeIfPresent(RPermission.self, forKey: .memberPermission)
    }
    
    init(from groupPart: RUserGroupPart, lastMessage: RGroupLastMessage?, groupModel: GroupModel) {
        self.id = groupPart.id
        self.type = groupPart.type
        self.name = groupPart.name
        self.displayName = groupPart.displayName
        self.ownerID = groupModel.ownerID
        if let lastMessage = lastMessage {
            self.lastMessage = lastMessage.lastMessage
        } else if let lastMessage = groupModel.lastMessage {
            self.lastMessage = RMessage(from: lastMessage)
        } else {
            self.lastMessage = nil
        }
        self.unread = lastMessage?.unread ?? groupModel.unreadCount
        self.createAt = Int(groupModel.createAt.timeIntervalSince1970 * 1000)
        self.updateAt = groupPart.updateAt
        self.lastViewed = lastMessage?.lastViewd ?? groupModel.lastViewedID
        self.lastRead = groupModel.lastReadID
        self.notify = groupPart.notify
        self.icon = groupPart.icon
        self.iconThumbnail = groupPart.iconThumbnail
        self.memberCount = groupPart.memberCount ?? groupModel.memberCount
        self.auth = nil
        self.adminCount = 0
        self.blockCount = 0
        self.memberPermission = nil
    }
    
    func encode(to encoder: Encoder) throws {
        // TODO: if need encode
    }
}

struct RUserAuth: Codable {
    let role: PermissionType
    var permissions: RPermission?
    
    enum CodingKeys: String, CodingKey {
        case role, permissions
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let pType = try values.decode(String.self, forKey: .role)
        role = PermissionType.init(rawValue: pType) ?? .none
        
        guard role != .none else {
            return
        }
        
        permissions = try values.decodeIfPresent(RPermission.self, forKey: .permissions)
        permissions?.updateTo(role: role)
    }
    
    func encode(to encoder: Encoder) throws {
        // TODO: if need encode
    }
}

struct RPermission: Codable {
    // owner
    var editAmdins: Bool
    var transferOwner: Bool
    
    // admin, owner
    var deleteMessages: Bool
    var banUsers: Bool
    var removeUsers: Bool
    var addAdmins: Bool
    var addExceptionUsers: Bool
    var inviteUsersViaLink: Bool
    var changeGroupInfo: Bool
    var canAddFriend: Bool
    // member, admin
    let sendMessages: Bool
    let sendImages: Bool
    let sendHyperlinks: Bool
    let inviteUsers: Bool
    
    enum CodingKeys: String, CodingKey {
        // only admin
        case deleteMessages = "can_delete_messages"
        case banUsers = "can_ban_users"
        case removeUsers = "can_remove_users"
        case addAdmins = "can_add_admins"
        case addExceptionUsers = "can_add_exception_users"
        case inviteUsersViaLink = "can_invite_users_via_link"
        case changeGroupInfo = "can_change_group_info"
        case canAddFriend = "can_add_friend"
        // member, admin
        case sendMessages = "can_send_messages"
        case sendImages = "can_send_images"
        case sendHyperlinks = "can_send_hyperlink"
        case inviteUsers = "can_invite_users"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        editAmdins = true
        transferOwner = true
        
        deleteMessages = try values.decodeIfPresent(Bool.self, forKey: .deleteMessages) ?? true
        banUsers = try values.decodeIfPresent(Bool.self, forKey: .banUsers) ?? true
        removeUsers = try values.decodeIfPresent(Bool.self, forKey: .removeUsers) ?? true
        addAdmins = try values.decodeIfPresent(Bool.self, forKey: .addAdmins) ?? true
        addExceptionUsers = try values.decodeIfPresent(Bool.self, forKey: .addExceptionUsers) ?? true
        inviteUsersViaLink = try values.decodeIfPresent(Bool.self, forKey: .inviteUsersViaLink) ?? true
        changeGroupInfo = try values.decodeIfPresent(Bool.self, forKey: .changeGroupInfo) ?? true
        canAddFriend = try values.decodeIfPresent(Bool.self, forKey: .canAddFriend) ?? false
        
        sendMessages = try values.decodeIfPresent(Bool.self, forKey: .sendMessages) ?? true
        sendImages = try values.decodeIfPresent(Bool.self, forKey: .sendImages) ?? true
        sendHyperlinks = try values.decodeIfPresent(Bool.self, forKey: .sendHyperlinks) ?? true
        inviteUsers = try values.decodeIfPresent(Bool.self, forKey: .inviteUsers) ?? true
    }
    
    mutating func updateTo(role: PermissionType) {
        if role == .member {
            // admin and owner will be true
            self.deleteMessages = false
            self.banUsers = false
            self.removeUsers = false
            self.addAdmins = false
            self.addExceptionUsers = false
            self.inviteUsersViaLink = false
            self.changeGroupInfo = false
            self.editAmdins = false
            self.transferOwner = false
            self.canAddFriend = false
        } else if role == .admin {
            self.editAmdins = false
            self.transferOwner = false
        } else if role == .owner {
            self.canAddFriend = true
        }
    }
}

struct RAvatarInfo: Codable {
    let avatar: String
    let avatar_thumbnail: String
}

struct RUserNickname: Codable {
    let id: String
    let nickname: String
}

struct RUserMemo: Codable {
    let memo: String
}

struct RHongBaoBalance: Codable {
    let signValid: Bool
    let balance: String
    
    enum CodingKeys: String, CodingKey {
        case signValid = "sign_valid"
        case balance
    }
}

struct RHongBaoRecord: Codable {
    let list: [HongBaoRecord]
    let nextId: String
    
    enum CodingKeys: String, CodingKey {
        case list
        case nextId = "next_id"
    }
}

struct HongBaoRecord: Codable {
    let amount: String
    let remainingBalance: String
    let createAt: Date
    let tradingType: TradingType
    let status: StateType
    
    enum CodingKeys: String, CodingKey {
        case amount, status
        case remainingBalance = "balance"
        case createAt = "created_at"
        case tradingType = "trading_type"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        amount = try values.decode(String.self, forKey: .amount)
        remainingBalance = try values.decode(String.self, forKey: .remainingBalance)
        let createDate = try values.decode(Int.self, forKey: .createAt)
        createAt = Date(timeIntervalSince1970: TimeInterval(Double(createDate) / 1000))
        let tType = try values.decode(Int.self, forKey: .tradingType)
        tradingType = TradingType(rawValue: tType) ?? .unknown
        let statusType = try values.decode(Int.self, forKey: .status)
        status = StateType(rawValue: statusType) ?? .success
    }
    
    func encode(to encoder: Encoder) throws {
        // TODO: if need encode
    }
}
