//
//  MessageViewModels.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/6/1.
//

import Foundation

protocol MessageContentCellProtocol: CellViewModelProtocol {
    var status: MessageStatus { get set }
    var withRead: Bool { get set }
    func updateMessageStatus(_ status: MessageStatus)
    func updateReadStatus(_ read: Bool)
    func updateUserNickname(_ nickname: String?)
    func updateTransceiverRole(_ role: PermissionType)
    func updateTransceiver(_ transceiver: TransceiverModel)
}

struct MessageViewModel: DiffAware, Hashable {
    static func == (lhs: MessageViewModel, rhs: MessageViewModel) -> Bool {
        guard let lModel = lhs.model, let rModel = rhs.model else {
            return lhs.diffIdentifier == rhs.diffIdentifier
        }
        return lhs.diffIdentifier == rhs.diffIdentifier && lModel == rModel && lModel.emojiContent == rModel.emojiContent
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(diffIdentifier)
        hasher.combine(model)
    }
    
    typealias DiffId = String
    var diffIdentifier: DiffId { model?.diffIdentifier ?? "\(String(timestamp))_\(type)" }
    
    static func compareContent(_ a: MessageViewModel, _ b: MessageViewModel) -> Bool {
        guard let aModel = a.model, let bModel = b.model else {
            return a.diffIdentifier == b.diffIdentifier
        }
        return MessageModel.compareContent(aModel, bModel)
    }    
    
    let type: MessageViewType
    var model: MessageModel?
    var status: MessageStatus {
        didSet {
            if oldValue != status {
                updateMessageStatus(status)
            }
        }
    }
    var cellModel: MessageContentCellProtocol
    let timestamp: Int

    private func updateMessageStatus(_ status: MessageStatus) {
        cellModel.updateMessageStatus(status)
    }
}

// 訊息類別：每個 MessageViewCell 的類別
enum MessageViewType: Equatable {
    // 來自 RLMMessage 經業務邏輯判斷後產生
    case dateTime(forModelID: String)
    case unread
    // 來自 RLMMessage (same as server)
    case groupStatus
    case text
    case image
    case recommend
    case hongBao
}

// 訊息傳送對象類型
enum MessageSenderType {
    case others
    case me
}

// 連續訊息的順序
enum MessageOrder {
    case first
    case nth
}
