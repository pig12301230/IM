//
//  MessageDataSource+CreateMessageVM.swift
//  ChatRoom
//
//  Created by Saffi Peng on 2021/7/20.
//

import Foundation

// MARK: - Create mark sections: DateTime
extension MessageDataSource {
    func createDateTime(lastMessage: MessageModel?, message: MessageModel) -> MessageViewModel? {
        guard message.messageType.withTime, let time = self.getDateTime(lastMessage: lastMessage, message: message) else {
            return nil
        }

        let dateTimeVM = DateTimeCellVM(dateTime: time)
        return MessageViewModel(type: .dateTime(forModelID: message.diffIdentifier), model: nil, status: message.messageStatus, cellModel: dateTimeVM, timestamp: message.timestamp)
    }

    func getDateTime(lastMessage: MessageModel?, message: MessageModel) -> String? {
        if message.messageType == .groupCreate || message.messageType == .groupDisplayName {
            return message.localeTimeString
        }

        guard let lastMessage = lastMessage else { return message.localeTimeString }
        switch lastMessage.messageType {
        case .text, .image, .recommend:
            return lastMessage.localeTimeString == message.localeTimeString ? nil : message.localeTimeString
        default:
            return message.localeTimeString
        }
    }
}

// MARK: - Create mark sections: Unread
extension MessageDataSource {
    func createUnread(unreadType: MarkUnreadType, lastMessage: MessageModel?) -> MessageViewModel? {
        switch unreadType {
        case .hide:
            return nil

        case .show(let messageID):
            if lastMessage == nil, messageID.isEmpty { // 聊天室訊息都尚未看過
                return MessageViewModel(type: .unread, model: nil, status: .success, cellModel: UnreadCellVM(), timestamp: lastMessage?.timestamp ?? 0)
            } else if let lastMessage = lastMessage, lastMessage.id == messageID { // 聊天室訊息已看到某一則
                return MessageViewModel(type: .unread, model: nil, status: .success, cellModel: UnreadCellVM(), timestamp: lastMessage.timestamp)
            } else {
                return nil
            }
        }
    }

    func getUnreadType(_ messages: [MessageModel]) -> MarkUnreadType {
        guard let lastMessageID = group.lastMessage?.id, !lastMessageID.isEmpty else {
            return .hide
        }
        
        guard lastMessageID != group.lastViewedID else {
            return .hide
        }
        
        var startIndex = 0
        if let index = messages.firstIndex(where: { $0.id == group.lastViewedID }) {
            startIndex = index
        }
        
        guard let receivedMessage = messages[startIndex...].first(where: { $0.userID != UserData.shared.userID }) else {
            return .hide
        }
        
        return .show(messageID: receivedMessage.id)
    }
}

// MARK: - Create mark sections: Group Status
extension MessageDataSource {
    
    func createGroupStatus(type: MessageType, message: MessageModel) -> MessageViewModel {
        let status = type.getGroupStatus(allUser: transciversDict, messageModel: message)
        let groupStatusVM = GroupStatusCellVM(groupStatus: status)
        return MessageViewModel(type: .groupStatus, model: message, status: message.messageStatus, cellModel: groupStatusVM, timestamp: message.timestamp)
    }
}

// MARK: - Message sections
extension MessageDataSource {
    func createMessage(viewType: MessageViewType, lastMessage: MessageModel?, message: MessageModel) -> MessageViewModel {
        let sender: MessageSenderType = message.userID == UserData.shared.userID ? .me : .others
        var order: MessageOrder {
            // 失敗的訊息使用 nth 的 UI
            guard message.messageStatus != .failed else {
                return .nth
            }
            
            guard let lastMessage = lastMessage, lastMessage.userID == message.userID, (lastMessage.messageType == .text || lastMessage.messageType == .image) else {
                return .first
            }
            
            return self.parseMessageOrder(lastMessage: lastMessage, message: message)
        }
        var isRead: Bool {
            guard sender == .me else {
                return false
            }
            guard let createTime = message.createAt, let lastReadCreateTime = self.lastReadMessage?.createAt, createTime <= lastReadCreateTime else {
                return false
            }
            return true
        }
        let isFailure = message.messageStatus == .failed
        
        let transceiver = self.transciversDict[message.userID] ?? nil
        let config = MessageContentConfig(groupType: self.group.groupType, sender: sender, order: order, isFailure: isFailure)
        let model = MessageBaseModel(message: message, transceiver: transceiver, config: config)

        var messageVM: MessageContentCellProtocol {
            switch viewType {
            case .text:
                return TextMessageCellVM(model: model, withRead: isRead)

            case .image:
                let imageURL = message.files.first?.url ?? ""
                guard let uploading = message.image else {
                    return ImageMessageCellVM(model: model, withRead: isRead, imageType: .url(imageURL))
                }
                return ImageMessageCellVM(model: model, withRead: isRead, imageType: .image(uploading, modelID: message.id))

            case .recommend:
                return RecommandMessageCellVM(model: model, withRead: isRead)
            default: //never happen
                return MessageBaseCellVM(model: model, withRead: isRead)
            }
        }
        return MessageViewModel(type: viewType, model: message, status: message.messageStatus, cellModel: messageVM, timestamp: message.timestamp)
    }

    func parseMessageOrder(lastMessage: MessageModel, message: MessageModel) -> MessageOrder {
        guard lastMessage.messageType == .text || lastMessage.messageType == .image else {
            return .first
        }

        guard message.messageType == .text || message.messageType == .image else {
            return .first
        }
        let formatter: Date.Formatter = .yearToMinutes
        let lastMsgTime = lastMessage.updateAt ?? Date(timeIntervalSince1970: TimeInterval(lastMessage.timestamp / 1000))
        let msgTime = message.updateAt ?? Date(timeIntervalSince1970: TimeInterval(message.timestamp / 1000))

        return lastMsgTime.toString(format: formatter.rawValue) == msgTime.toString(format: formatter.rawValue) ? .nth : .first
    }
}
