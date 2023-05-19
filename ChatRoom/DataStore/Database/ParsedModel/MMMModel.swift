//
//  MMMModel.swift
//  ChatRoom
//
//  Created by Winston_Chuang on 2023/5/15.
//

import Foundation

struct MessageContentConfig {
    var groupType: GroupType = .dm
    var sender: MessageSenderType = .others
    var order: MessageOrder = .first
    var isRead: Bool = false
    var isFailure: Bool = false
}

struct MessageBaseModel {
    var message: MessageModel
    var transceiver: TransceiverModel?
    var config: MessageContentConfig = MessageContentConfig()
}

struct MessageContentSize {
    static let maxWidth: CGFloat = ceil(AppConfig.Screen.mainFrameWidth * (265 / 414))
    static let minHeight: CGFloat = 40
    static let horizontalMargin: CGFloat = 32 // textView左右間距，L12+R20 or R20+L12

    static let imageNormalWidth: CGFloat = ceil(AppConfig.Screen.mainFrameWidth * (265 / 414))
    static let imageNormalHeight: CGFloat = ceil(imageNormalWidth * (180 / 256))
    static let imageMissSize = CGSize(width: 120, height: 120)
}

enum AnchorPosition {
    case top
    case bottom
}

enum Sender {
    case oneself
    case others
}

enum ToolScene {
    case directMessage
    case groupMember
    case groupAdmin
    case groupOwner
}

enum ActionType: Int, Comparable {
    case copy
    case reply
    case announcement
    case delete
    case unsend
    
    var name: String {
        switch self {
        case .delete:
            return Localizable.delete
        case .reply:
            return Localizable.reply
        case .unsend:
            return Localizable.unsend
        case .copy:
            return Localizable.copy
        case .announcement:
            return Localizable.setAsAnnouncement
        }
    }
    
    var icon: String {
        switch self {
        case .delete:
            return "iconIconDelete"
        case .reply:
            return "iconIconArrowReply"
        case .unsend:
            return "iconIconRetract"
        case .copy:
            return "iconIconFill"
        case .announcement:
            return "iconIconAnnouncement"
        }
    }
    
    static func < (lhs: ActionType, rhs: ActionType) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

enum ScrollToPositionType {
    case bottom
    case unread(indexPath: IndexPath)
    case highLightMessage(indexPath: IndexPath)
    case message(messageID: String)
}

enum LocatePosition {
    case unread
    case bottom
    case searchingMessage(messageID: String)
    case targetMessage(messageID: String)
}

enum NotifyOption: String, CaseIterable, OptionTypeProtocol {
    case newMessage = "notify"
    case detail = "notify_detail"
    case sound = "sound"
    case vibration = "vibration"
    
    var key: String {
        return self.rawValue
    }
    
    var title: String {
        switch self {
        case .newMessage:
            return Localizable.newMessageNotice
        case .detail:
            return Localizable.notifyDetail
        case .sound:
            return Localizable.voice
        case .vibration:
            return Localizable.vibration
        }
    }
    
    var onConfirmMessage: String? {
        return nil
    }
    
    var offConfirmMessage: String? {
        switch self {
        case .newMessage:
            return Localizable.closeMessageHint
        case .detail:
            return Localizable.closeMessageDetailHint
        default:
            return nil
        }
    }
    
    var status: NotifyType {
        guard let userInfo = UserData.shared.userInfo else { return .off }
        switch self {
        case .newMessage:
            return userInfo.notify
        case .detail:
            return userInfo.notifyDetail
        case .vibration:
            return userInfo.vibration
        case .sound:
            return userInfo.sound
        }
    }
    
    func isEqual(to: OptionTypeProtocol) -> Bool {
        return self.key == to.key
    }
}

protocol SettingStatusVMProtocol {
    associatedtype Option: CaseIterable
    var cellOptions: [Option] { get }
    var cellVMs: [TitleSwitchTableViewCellVM] { get }

    func getStatus(_ option: Option) -> NotifyType
    func modifyStatus(_ option: Option, isOn: Bool)

    func cellViewModel(at index: Int) -> TitleSwitchTableViewCellVM?
    func cancelAction(_ option: TitleSwitchTableViewCellVM.OptionType)
}

extension SettingStatusVMProtocol {
    func cellViewModel(at index: Int) -> TitleSwitchTableViewCellVM? {
        guard self.cellVMs.count > index else {
            return nil
        }

        return self.cellVMs[index]
    }

    func cancelAction(_ option: OptionTypeProtocol) {
        if let cellVM = self.cellVMs.first(where: { $0.option.isEqual(to: option) }) {
            cellVM.cancelAction()
        }
    }
}

enum ConversationNavigationBackType {
    case toOriginal
    case toChatList
}

enum ConversationContentType {
    case nature           // 原始聊天窗內容
    case searching        // 原始聊天窗內容＋SearchBar
    case searchResult     // 訊息搜索結果
    case highlightMessage // 聊天窗內容＋Highlight
}

struct NotifyCellConfig: CellConfigProtocol {
    var leading: CGFloat
    var title: String
    var notify: NotifyType
    var onConfirm: String?
    var offConfirm: String?
    var isEnable: Bool
}

protocol OptionTypeProtocol {
    var key: String { get }
    var title: String { get }
    var onConfirmMessage: String? { get }
    var offConfirmMessage: String? { get }
    func isEqual(to: OptionTypeProtocol) -> Bool
}

protocol SwitchOptionProtocol {
    associatedtype OptionType
    init(config: NotifyCellConfig, option: OptionTypeProtocol, enable: Bool)
}

protocol SettingCellProtocol {
    associatedtype CellConfig: CellConfigProtocol
    func setupConfig(_ config: CellConfig)
}

protocol CellConfigProtocol {
    var title: String { get }
    var leading: CGFloat { get }
}
