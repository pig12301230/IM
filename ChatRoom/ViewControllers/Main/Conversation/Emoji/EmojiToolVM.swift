//
//  EmojiToolVM.swift
//  ChatRoom
//
//  Created by ERay_Peng on 2022/11/21.
//

import Foundation
import RxSwift
import RxCocoa

class EmojiToolVM: BaseViewModel {
    let currentTapEmoji = BehaviorRelay<EmojiType?>(value: nil)
    
    struct Setting {
        var messageModel: MessageModel?
    }
    
    struct Output {
        let action = PublishSubject<(EmojiType, MessageModel)>()
    }
    
    private(set) var setting: Setting = Setting()
    private(set) var output: Output = Output()
    let emojiTypes = EmojiType.allCases.filter { $0 != .all }
    
    func setup(message: MessageModel, emojiType: EmojiType?) {
        setting.messageModel = message
        self.currentTapEmoji.accept(emojiType)
    }
    
    func didTapEmojiButton(emojiType: EmojiType) {
        guard let model = self.setting.messageModel else { return }
        self.output.action.onNext((emojiType, model))
    }
}
