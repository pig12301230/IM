//
//  ReportItemCellVM.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/5/17.
//

import Foundation
import RxSwift
import RxCocoa

class ReportItemCellVM: BaseTableViewCellVM {

    struct ItemModel {
        let selected: Bool
        let title: String
        var hideSeparatorLine: Bool = false
    }
    let selected: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    let title: BehaviorRelay<String> = BehaviorRelay(value: "")
    let hideSeparatorLine: BehaviorRelay<Bool> = BehaviorRelay(value: false)

    private(set) var item: ItemModel?

    override init() {
        super.init()
        self.cellIdentifier = "ReportItemCell"
    }

    convenience init(with item: ItemModel? = nil) {
        self.init()
        self.item = item
        self.setupViews()
    }

    func setupViews() {
        guard let item = self.item else {
            return
        }
        self.selected.accept(item.selected)
        self.title.accept(item.title)
        self.hideSeparatorLine.accept(item.hideSeparatorLine)
    }
}
