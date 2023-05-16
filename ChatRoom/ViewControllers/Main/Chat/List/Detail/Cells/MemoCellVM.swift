//
//  MemoCellVM.swift
//  ChatRoom
//
//  Created by Winston_Chuang on 2022/3/28.
//

import Foundation
import RxSwift
import RxCocoa

class MemoCellVM: BaseTableViewCellVM, ChatDetailActionProtocol {
    var actionType: ChatDetailAction? = .memo
    
    var actionTapped: PublishSubject<ChatDetailAction> = .init()

    let description: BehaviorRelay<String> = BehaviorRelay(value: "")

    override init() {
        super.init()
        self.cellIdentifier = "MemoCell"
    }

    convenience init(with memo: String) {
        self.init()
        self.description.accept(memo)
    }
    
    func update(memo: String) {
        self.description.accept(memo)
    }
}
