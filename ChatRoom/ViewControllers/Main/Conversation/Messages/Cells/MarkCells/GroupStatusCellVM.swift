//
//  GroupStatusCellVM.swift
//  ChatRoom
//
//  Created by Saffi Peng on 2021/7/20.
//

import Foundation
import RxSwift
import RxCocoa

class GroupStatusCellVM: ConversationBaseCellVM {

    let groupStatus: BehaviorRelay<String> = BehaviorRelay(value: "")
    private(set) var type: MessageType

    init(type: MessageType, groupStatus: String = "") {
        self.type = type
        super.init()
        self.cellIdentifier = "GroupStatusCell"
        self.groupStatus.accept(groupStatus)
    }
    
    func updateGroupStatus(_ groupStatus: String) {
        self.groupStatus.accept(groupStatus)
    }
}
