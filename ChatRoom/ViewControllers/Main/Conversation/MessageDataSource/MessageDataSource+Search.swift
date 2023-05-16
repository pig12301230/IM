//
//  MessageDataSource+Search.swift
//  ChatRoom
//
//  Created by Saffi Peng on 2021/7/15.
//

import Foundation

extension MessageDataSource {
    func prepareSearchResource() {
        let textMessageItems = self.messageItems.filter { model in
            switch model.type {
            case .text: return true
            default: return false
            }
        }
        self.searchResource = textMessageItems.compactMap { messageItem in
            return messageItem.cellModel as? TextMessageCellVM
        }
    }

    func updateSearchText(_ text: String) {
        guard self.searchResource.count > 0 else {
            return
        }
        self.searchResults = self.searchResource.filter { $0.isFitSearchContent(key: text) == true }
    }
}
