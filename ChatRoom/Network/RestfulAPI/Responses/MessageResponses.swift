//
//  UserResponses.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/4/14.
//

import Foundation

enum MessageDirection: String {
    case previous = "before"
    case after
}

enum MessageType: String {
    case text
    case image
    case recommend
    case hongBao = "red_envelope"
    case groupCreate = "group_create"
    case groupDisplayName = "group_displayname"
    case groupIcon = "group_icon"
    case inviteMember = "invite_member"
    case removeMember = "remove_member"
    case memberJoin = "member_join"
    case memberLeft = "member_left"
    case messagePin = "message_pin"
    case unsend = "message_delete"
    case hongBaoClaim = "red_envelope_claim"

    var viewType: MessageViewType {
        switch self {
        case .text: return .text
        case .image: return .image
        case .recommend: return .recommend
        case .hongBao: return .hongBao
        default: return .groupStatus
        }
    }
}

extension MessageType {
    var localizedString: String {
        switch self {
        case .groupCreate:
            return Localizable.groupCreate
        case .groupDisplayName:
            return Localizable.groupDisplayname
        case .groupIcon:
            return Localizable.groupIcon
        case .inviteMember:
            return Localizable.inviteMember
        case .removeMember:
            return Localizable.removeMember
        case .memberJoin:
            return Localizable.memberJoin
        case .memberLeft:
            return Localizable.memberLeft
        case .messagePin:
            return Localizable.pinMessageIOS
        default :
            return ""
        }
    }
    
    private func getUserID(messageModel: MessageModel) -> String {
        return messageModel.userID
    }
    
    private func getTargetUserID(messageModel: MessageModel) -> String? {
        switch self {
        case .inviteMember, .removeMember:
            return messageModel.targetID
        default:
            return nil
        }
    }
    
    private func getTargetMessageContent(messageModel: MessageModel) -> String? {
        guard messageModel.messageType == .messagePin else { return nil }
        guard let targetMessageModel = DataAccess.shared.getMessage(by: messageModel.targetID) else { return nil }
        var message: String = targetMessageModel.message
        if targetMessageModel.messageType == .image {
            message = Localizable.messageReplyPicture
        } else if targetMessageModel.messageType == .recommend {
            message = Localizable.followBetMessage
        }
        return message
    }
    
    func getGroupStatus(allUser: [String: TransceiverModel], messageModel: MessageModel) -> String {
        switch self {
        case .inviteMember, .removeMember:
            let username = allUser[self.getUserID(messageModel: messageModel)]?.display ?? ""
            let targetUsername = allUser[self.getTargetUserID(messageModel: messageModel) ?? ""]?.display ?? ""
            return String(format: self.localizedString, username, targetUsername)
        case .groupCreate, .groupDisplayName:
            let username = allUser[self.getUserID(messageModel: messageModel)]?.display ?? ""
            return String(format: self.localizedString, username, messageModel.message)
        case .groupIcon, .memberJoin, .memberLeft:
            let username = allUser[self.getUserID(messageModel: messageModel)]?.display ?? ""
            return String(format: self.localizedString, username)
        case .messagePin:
            let userName = allUser[self.getUserID(messageModel: messageModel)]?.display ?? ""
            return String(format: Localizable.pinMessageUnsentIOS, userName)
        case .unsend:
            if messageModel.userID == UserData.shared.userID {
                return Localizable.youUnsendMessage
            } else {
                let userName = allUser[self.getUserID(messageModel: messageModel)]?.display ?? ""
                return String(format: Localizable.nickNameUnsendMessage, userName)
            }
        case .hongBaoClaim:
            let username = allUser[self.getUserID(messageModel: messageModel)]?.display ?? ""
            return String(format: Localizable.openedHongBao, username)
        default:
            return ""
        }
    }
}

struct RMessage: Codable {
    let diffID: String
    let id: String
    let cid: String
    let type: MessageType
    let userID: String
    let groupID: String
    let targetID: String
    let text: String
    let threadID: String?
    let threadMessage: [RMessage]?
    let hongBaoContent: RHongBaoContent?
    let createAt: Int
    let updateAt: Int
    let fileIDs: [String]
    let files: [RFile]
    let blockUserIDs: [String]
    let template: RTemplate?
    let pinAt: Int?
    let emojiContent: [REmojiContent]

    enum CodingKeys: String, CodingKey {
        case id, cid, type, text, files, template
        case userID = "user_id"
        case groupID = "group_id"
        case targetID = "target_id"
        case threadID = "thread_id"
        case threadMessage = "thread_message"
        case hongBaoContent = "red_envelope_content"
        case fileIDs = "file_ids"
        case blockUserIDs = "block_user_ids"
        case createAt = "create_at"
        case updateAt = "update_at"
        case pinAt = "pin_at"
        case emojiContent = "emoji_content"
    }
    
    init(from model: MessageModel) {
        self.id = model.id
        self.cid = model.cid
        self.diffID = model.diffID
        self.type = model.messageType
        self.userID = model.userID
        self.groupID = model.groupID
        self.targetID = model.targetID
        self.text = model.message
        self.threadID = model.threadID
        if let threadMessage = model.threadMessage.first {
            self.threadMessage = [RMessage(from: threadMessage)]
        } else {
            self.threadMessage = nil
        }
        
        if let hongBaoContent = model.hongBaoContent {
            self.hongBaoContent = RHongBaoContent(with: hongBaoContent)
        } else {
            self.hongBaoContent = nil
        }
        
        if let createAt = model.createAt {
            self.createAt = Int(createAt.timeIntervalSince1970 * 1000)
        } else {
            self.createAt = Int(Date().timeIntervalSince1970 * 1000)
        }
        
        if let updateAt = model.updateAt {
            self.updateAt = Int(updateAt.timeIntervalSince1970 * 1000)
        } else {
            self.updateAt = Int(Date().timeIntervalSince1970 * 1000)
        }
        
        self.fileIDs = model.fileIDs
        self.files = []
        self.blockUserIDs = model.blockUserIDs
        self.template = nil
        self.pinAt = nil
        self.emojiContent = []
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        cid = try values.decode(String.self, forKey: .cid)
        let mType = try values.decode(String.self, forKey: .type)
        type = MessageType.init(rawValue: mType) ?? .text
        userID = try values.decode(String.self, forKey: .userID)
        groupID = try values.decode(String.self, forKey: .groupID)
        targetID = try values.decodeIfPresent(String.self, forKey: .targetID) ?? ""
        threadID = try values.decodeIfPresent(String.self, forKey: .threadID)
        diffID = type == .unsend ? targetID : id
        createAt = try values.decode(Int.self, forKey: .createAt)
        updateAt = try values.decode(Int.self, forKey: .updateAt)
        text = try values.decode(String.self, forKey: .text)
        fileIDs = try values.decodeIfPresent([String].self, forKey: .fileIDs) ?? []
        blockUserIDs = try values.decodeIfPresent([String].self, forKey: .blockUserIDs) ?? []
        files = try values.decodeIfPresent([RFile].self, forKey: .files) ?? []
        pinAt = try values.decodeIfPresent(Int.self, forKey: .pinAt)
        emojiContent = try values.decodeIfPresent([REmojiContent].self, forKey: .emojiContent) ?? []
        do {
            template = try values.decode(RTemplate.self, forKey: .template)
        } catch {
            template = nil
        }
        
        if let threadMsg = try values.decodeIfPresent(RMessage.self, forKey: .threadMessage) {
           threadMessage = [threadMsg]
        } else {
           threadMessage = nil
        }
        
        if let hongBaoContent = try values.decodeIfPresent(RHongBaoContent.self, forKey: .hongBaoContent) {
            self.hongBaoContent = hongBaoContent
         } else {
             hongBaoContent = nil
         }
    }
    
    func encode(to encoder: Encoder) throws {
        // TODO: if need encode
    }
}

struct RFile: Codable {
    let id: String
    let mimetype: String
    let type: String
    let size: Int
    let url: String
    let thumbURL: String
    let createAt: Int
    
    enum CodingKeys: String, CodingKey {
        case id, mimetype, type, size, url
        case thumbURL = "thumb_url"
        case createAt = "create_at"
    }
}

struct RTemplate: Codable {
    let game: String
    let freq: String?
    let num: String?
    let betType: String?
    let option: ROption?
    let description: String?
    let action: RAction?
    
    enum CodingKeys: String, CodingKey {
        case game, freq, num, option, description, action
        case betType = "bet_type"
    }
}

struct ROption: Codable {
    let text: String
    let color: String
}

struct RAction: Codable {
    let icon: String
    let label: String
    let url: String
    
    enum CodingKeys: String, CodingKey {
        case icon, label, url
    }
}

struct REmojiContent: Codable {
    let emoji: String
    let count: Int
    
    enum CodingKeys: String, CodingKey {
        case emoji
        case count = "number"
    }
}

struct REmoji: Codable {
    let emoji: String
}

struct ListContent: Codable {
    let userID: String
    let username: String
    let nickname: String
    let avatar: String
    let avatarThumbnail: String
    let messageID: String
    let emojiCode: String
    let createAt: Int
    let updateAt: Int
    
    enum CodingKeys: String, CodingKey {
        case username, nickname, avatar
        case userID = "user_id"
        case avatarThumbnail = "avatar_thumbnail"
        case messageID = "message_id"
        case emojiCode = "emoji"
        case createAt = "create_at"
        case updateAt = "update_at"
    }
}

struct REmojiList: Codable {
    let totalEmoji: Int
    let emojiContent: [REmojiContent]
    let list: [ListContent]
    let nextUserID: String
    
    enum CodingKeys: String, CodingKey {
        case list
        case totalEmoji = "total_emoji"
        case emojiContent = "emoji_content"
        case nextUserID = "next_user_id"
    }
}

// HongBao
struct RHongBaoContent: Codable {
    let id: String
    let recipient: String?
    let status: Int
    let type: Int
    let description: String
    let amount: Int
    let balance: String
    let executesAt: Int
    let expiredAt: Int
    let style: RHongBaoStyle?

    enum CodingKeys: String, CodingKey {
        case id, status, amount, balance, recipient, style
        case type = "envelope_type"
        case description = "envelope_desc"
        case executesAt = "executes_at"
        case expiredAt = "expire_at"
    }
    
    init(with content: HongBaoContent) {
        id = content.campaignID
        recipient = content.recipient
        status = content.status
        type = content.type.rawValue
        description = content.description
        amount = content.amount
        balance = content.balance
        executesAt = content.executeAt
        expiredAt = content.expiredAt
        if let hongBaoStyle = content.style {
            style = RHongBaoStyle(style: hongBaoStyle)
        } else {
            style = nil
        }
    }
}

struct RUserHongBao: Codable {
    let userID: String
    let nickname: String
    let status: HongBaoStatus
    let type: HongBaoType
    let description: String
    let amount: String
    
    enum CodingKeys: String, CodingKey {
        case nickname, status, amount
        case userID = "user_id"
        case type = "envelope_type"
        case description = "envelope_desc"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        userID = try values.decode(String.self, forKey: .userID)
        nickname = try values.decode(String.self, forKey: .nickname)
        
        let hongBaoType = try values.decode(Int.self, forKey: .type)
        type = HongBaoType.init(rawValue: hongBaoType) ?? .basic
        
        let hongBaoStatus = try values.decode(Int.self, forKey: .status)
        status = HongBaoStatus.init(rawValue: hongBaoStatus) ?? .win
        
        description = try values.decode(String.self, forKey: .description)
        amount = try values.decode(String.self, forKey: .amount)
    }
    
    func encode(to encoder: Encoder) throws {
        // TODO: if need encode
    }
}

struct RHongBaoUnOpened: Codable {
    let amount: Int
    let firstMessageID: String
    let floatingHongBaoList: [RFloatingHongBao]
    
    enum CodingKeys: String, CodingKey {
        case amount
        case firstMessageID = "first_message_id"
        case floatingHongBaoList = "floating_red_envelope"
    }
}

struct RFloatingHongBao: Codable {
    let campaignID: String
    let messageID: String
    let floatingUrl: String
    
    enum CodingKeys: String, CodingKey {
        case campaignID = "campaign_id"
        case messageID = "message_id"
        case floatingUrl = "floating"
    }
}

struct RHongBaoClaimStatus: Codable {
    let userID: String
    let nickname: String
    let avatar: String
    let avatarThumbnail: String
    let status: Int
    
    enum CodingKeys: String, CodingKey {
        case status, nickname, avatar
        case userID = "user_id"
        case avatarThumbnail = "avatar_thumbnail"
    }
}

struct RHongBaoStyle: Codable {
    let selectStyle: HongBaoSelectStyle
    let backgroundColor: HongBaoBackgroundColor
    let icon: HongBaoIcon
    let backgroundImage: String
    let floatingStyle: String
    
    enum CodingKeys: String, CodingKey {
        case icon
        case selectStyle = "select_style"
        case backgroundColor = "background_color"
        case backgroundImage = "background_image"
        case floatingStyle = "floating_style"
    }
    
    init(style: HongBaoStyle) {
        self.selectStyle = style.selectStyle
        self.icon = style.icon
        self.backgroundColor = style.backgroundColor
        self.backgroundImage = style.backgroundImage
        self.floatingStyle = style.floatingStyle
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        backgroundImage = try values.decode(String.self, forKey: .backgroundImage)
        floatingStyle = try values.decode(String.self, forKey: .floatingStyle)
        
        let style = try values.decode(Int.self, forKey: .selectStyle)
        selectStyle = HongBaoSelectStyle.init(rawValue: style) ?? .single
        
        let color = try values.decode(String.self, forKey: .backgroundColor)
        backgroundColor = HongBaoBackgroundColor.init(rawValue: color) ?? .message_random_amount_color_1
        
        let iconImage = try values.decode(String.self, forKey: .icon)
        icon = HongBaoIcon.init(rawValue: iconImage) ?? .message_random_amount_style_1
    }
    
    func encode(to encoder: Encoder) throws {
        // TODO: if need encode
    }
}
