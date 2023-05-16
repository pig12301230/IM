//
//  SettingItemCellVM.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/5/8.
//

import Foundation
import RxSwift
import RxCocoa

class SettingItemCellVM: BaseTableViewCellVM {

    struct ItemModel {
        let title: String
        let isOn: Bool
    }
    let title: BehaviorRelay<String> = BehaviorRelay(value: "")
    let isOn: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    let switchUpdated = PublishRelay<Bool>()

    private(set) var item: ItemModel?

    override init() {
        super.init()
        self.cellIdentifier = "SettingItemCell"
    }

    convenience init(with data: ItemModel) {
        self.init()
        self.item = data
        self.setupViews()
    }

    func setupViews() {
        guard let item = item else {
            return
        }
        self.title.accept(item.title)
        self.isOn.accept(item.isOn)
    }
}
