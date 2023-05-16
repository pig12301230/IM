//
//  UnreadCellVM.swift
//  ChatRoom
//
//  Created by Saffi Peng on 2021/7/20.
//

import Foundation
import RxSwift
import RxCocoa

enum MarkUnreadType {
    case hide
    case show(messageID: String)
}

class UnreadCellVM: ConversationBaseCellVM {

    override init() {
        super.init()
        self.cellIdentifier = "UnreadCell"
    }
}
