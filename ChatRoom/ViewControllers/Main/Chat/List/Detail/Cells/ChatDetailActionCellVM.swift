//
//  ChatDetailActionCellVM.swift
//  ChatRoom
//
//  Created by Andy Yang on 2021/5/24.
//

import Foundation
import RxSwift
import RxCocoa

class ChatDetailActionCellVM: BaseTableViewCellVM, ChatDetailActionProtocol {
    typealias DataType = ItemModel
    
    struct ItemModel {
        let title: String
        let icon: UIImage?
    }
    
    let title: BehaviorRelay<String> = BehaviorRelay(value: "")
    let icon: BehaviorRelay<UIImage?> = BehaviorRelay(value: nil)
    var actionTapped: PublishSubject<ChatDetailAction> = .init()

    var data: ItemModel?
    var actionType: ChatDetailAction?
     
    override init() {
        super.init()
        cellIdentifier = "ChatDetailActionCell"
    }
    
    convenience init(with data: ItemModel, actionType: ChatDetailAction) {
        self.init()
        self.data = data
        self.actionType = actionType
    }
    
    func setupViews() {
        guard let item = data else { return }
        title.accept(item.title)
        icon.accept(item.icon)
    }
}
