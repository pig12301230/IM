//
//  ReplyTextMessageCellVM.swift
//  ChatRoom
//
//  Created by Winston_Chuang on 2022/3/4.
//

import RxSwift
import RxRelay

class ReplyTextMessageCellVM: TextMessageCellVM {
    let scrollToMessage: PublishSubject<String> = .init()
    var deletedMessage: PublishSubject<String> = .init()
    private var hasRefetch: Bool = false
    private(set) var threadMessage: BehaviorRelay<MessageModel?> = .init(value: nil)
    private(set) var threadSender: TransceiverModel?
    
    init(model: MessageBaseModel, withRead: Bool, threadSender: TransceiverModel?) {
        super.init(model: model, withRead: withRead)
        self.threadSender = threadSender
        
        self.threadMessage.accept(model.message.threadMessage.first)
        self.cellIdentifier = (model.config.sender == .me ? "ReplyTextMessageRCell" : "ReplyTextMessageLCell")
        self.adjustTextHeight(with: model.message.message)
        self.config.accept(model.config)
        self.updateView(model: model)
        let attrMessage = self.setupMessage(key: "")
        self.attributedMessage.accept(attrMessage)
        
        guard let threadMessageID = model.message.threadID, model.message.threadMessage.first == nil else { return }
        self.refetchThreadMessage(groupID: model.message.groupID, messageID: threadMessageID)
    }
    
    func refetchThreadMessage(groupID: String, messageID: String) {
        guard !hasRefetch else { return }
        hasRefetch = true
        
        if let threadMessage = DataAccess.shared.getMessage(by: messageID) {
            self.refreshThreadＭessage(by: threadMessage)
        } else { // 若是不存在於DB, 嘗試從Server拿
            DataAccess.shared.fetchMessage(groupID: groupID, messageID: messageID) { [weak self] threadMessage in
                guard let self = self else { return }
                guard let threadMessage = threadMessage else {
                    self.threadMessage.accept(nil)
                    return
                }
                self.refreshThreadＭessage(by: threadMessage)
            }
        }
    }
    
    private func refreshThreadＭessage(by message: MessageModel) {
        if let transceiver = DataAccess.shared.getGroupObserver(by: message.groupID).transceiverDict.value[message.userID] {
            self.threadSender = transceiver
        }
        
        DataAccess.shared.updateLocalThreadMessage(originID: self.baseModel.message.id,
                                                          threadMessage: message)
        self.threadMessage.accept(message)
    }
    
    func getFileUrl(by id: String) -> URL? {
        guard let file = DataAccess.shared.getFile(by: id) else { return nil }
        return URL(string: file.url)
    }
    
    func getFileID(by id: String) -> [String] {
        guard let message = DataAccess.shared.getMessage(by: id) else { return [] }
        return message.fileIDs
    }
}
