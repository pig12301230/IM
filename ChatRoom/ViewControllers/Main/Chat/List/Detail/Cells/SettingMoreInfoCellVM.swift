//
//  SettingMoreInfoCellVM.swift
//  ChatRoom
//
//  Created by ZoeLin on 2022/1/19.
//

import Foundation
import RxSwift
import RxCocoa

class SettingMoreInfoCellVM: SettingMoreCellVM {
    
    let info: BehaviorRelay<String> = BehaviorRelay(value: "")


    override init() {
        super.init()
        self.cellIdentifier = "SettingMoreInfoCell"
    }

    convenience init(with title: String, actionType: ChatDetailAction, info: String) {
        self.init()
        self.titleText = title
        self.actionType = actionType
        self.info.accept(info)
    }

    override func setupViews() {
        guard let title = titleText else {
            return
        }
        self.title.accept(title)
    }
}
