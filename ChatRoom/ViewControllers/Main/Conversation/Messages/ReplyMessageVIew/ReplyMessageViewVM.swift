//
//  ReplyMessageViewVM.swift
//  ChatRoom
//
//  Created by Winston_Chuang on 2022/3/3.
//

import Foundation
import RxSwift
import RxRelay

class ReplyMessageViewVM: BaseViewModel {
    private(set) var transceivers: [TransceiverModel] = []
    let replyMessage: BehaviorRelay<MessageModel?> = .init(value: nil)
    let deleteMessage: PublishSubject<String> = .init()
    let closeReplyMessage: PublishSubject<Void> = .init()
    
    init(with transceivers: [TransceiverModel]) {
            self.transceivers = transceivers
        }
        
    func updateTransceivers(transceivers: [TransceiverModel]) {
        self.transceivers = transceivers
    }
    
    func getFileUrl(by id: String) -> URL? {
        guard let file = DataAccess.shared.getFile(by: id) else { return nil }
        return URL(string: file.url)
    }
    
}
