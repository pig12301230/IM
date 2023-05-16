//
//  ConversationBaseCellVM.swift
//  ChatRoom
//
//  Created by Saffi Peng on 2021/7/20.
//

import Foundation

class ConversationBaseCellVM: BaseTableViewCellVM, MessageContentCellProtocol {

    var status: MessageStatus
    var withRead: Bool

    override init() {
        self.status = .success
        self.withRead = false
        super.init()
    }

    // MARK: - MessageContentCellProtocol
    func updateMessageStatus(_ status: MessageStatus) {
        guard status != self.status else {
            return
        }
        self.status = status
    }
    
    func updateUserNickname(_ nickname: String?) { }
    
    func updateReadStatus(_ read: Bool) {}
    
    func updateTransceiverRole(_ role: PermissionType) { }

    func updateTransceiver(_ transceiver: TransceiverModel) { }
}
