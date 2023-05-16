//
//  DateTimeCellVM.swift
//  ChatRoom
//
//  Created by Saffi Peng on 2021/7/20.
//

import Foundation
import RxSwift
import RxCocoa

class DateTimeCellVM: ConversationBaseCellVM {

    let dateTime: BehaviorRelay<String> = BehaviorRelay(value: "")

    init(dateTime: String = "") {
        super.init()
        self.cellIdentifier = "DateTimeCell"
        self.dateTime.accept(dateTime)
    }
}
