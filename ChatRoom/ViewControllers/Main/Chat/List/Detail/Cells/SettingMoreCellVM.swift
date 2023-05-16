//
//  SettingMoreCellVM.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/5/10.
//

import Foundation
import RxSwift
import RxCocoa

class SettingMoreCellVM: BaseTableViewCellVM, ChatDetailActionProtocol {
    
    var actionType: ChatDetailAction?
    var actionTapped: PublishSubject<ChatDetailAction> = PublishSubject()

    let title: BehaviorRelay<String> = BehaviorRelay(value: "")

    var titleText: String?
    private(set) var iconName: String = "iconArrowsChevronRight"

    override init() {
        super.init()
        self.cellIdentifier = "SettingMoreCell"
    }

    convenience init(with title: String, actionType: ChatDetailAction) {
        self.init()
        self.titleText = title
        self.actionType = actionType
    }
    
    convenience init(with title: String, actionType: ChatDetailAction, icon: String) {
        self.init()
        self.titleText = title
        self.actionType = actionType
        self.iconName = icon
    }

    func setupViews() {
        guard let title = titleText else {
            return
        }
        self.title.accept(title)
    }
}
