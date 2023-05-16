//
//  EmojiListViewVM.swift
//  ChatRoom
//
//  Created by Winston_Chuang on 2022/11/24.
//

import Foundation
import RxSwift
import RxRelay

class EmojiListViewVM: BaseViewModel {
        
    let selectedType: BehaviorRelay<EmojiType> = .init(value: .all)
    let groupedEmojis: BehaviorRelay<[String: [EmojiDetailModel]]> = .init(value: [:])
    
    private(set) var messageID: String
    private(set) var groupID: String
    private var disposeBag = DisposeBag()
    
    init(messageID: String, groupID: String) {
        self.messageID = messageID
        self.groupID = groupID
        super.init()
        self.getEmojiList()
        self.fetchEmojiList()
    }
    
    // fetch emojiList from server
    private func fetchEmojiList() {
        DataAccess.shared.fetchEmojiList(messageID: messageID) { [weak self] models in
            // 如果是 nil 不做事
            guard let self = self, let models = models else { return }
            
            self.groupedEmojis.accept(self.parseList(models: models))            
        }
    }
    
    // fetch emojiList from database
    private func getEmojiList() {
        DataAccess.shared.getEmojiList(messageID: messageID) { [weak self] models in
            guard let self = self else { return }
            self.groupedEmojis.accept(self.parseList(models: models))
        }
    }
    
    private func parseList(models: [EmojiDetailModel]) -> [String: [EmojiDetailModel]] {
        let newModels = self.convertData(models: models)
        var groupSorted = Dictionary(grouping: newModels, by: { $0.emojiCode })
        groupSorted["all"] = newModels
        return groupSorted
    }
    
    //檢查是否有使用者設定的暱稱可替換, 以及群組成員權限
    private func convertData(models: [EmojiDetailModel]) -> [EmojiDetailModel] {
        return models.map { oriModel -> EmojiDetailModel in
            var model = oriModel
            // use DB PersonalSetting nickname
            if let personalNickname = DataAccess.shared.getUserPersonalSetting(with: model.userID)?.nickname {
                model.nickname = personalNickname
            }
            //TODO: set user role
            if let transceiver = DataAccess.shared.getGroupTransceiver(by: groupID, memberID: oriModel.userID) {
                model.userRole = transceiver.role
            }
            
            return model
        }.sorted(by: { $0.updateAt < $1.updateAt })
    }
}
