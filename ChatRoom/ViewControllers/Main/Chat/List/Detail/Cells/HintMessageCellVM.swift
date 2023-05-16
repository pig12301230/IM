//
//  HintMessageCellVM.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/7/9.
//

import RxCocoa

class HintMessageCellVM: BaseTableViewCellVM {
    
    private(set) var message: String = ""
    private(set) var icon: String?
    let hidden: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    
    override init() {
        super.init()
        self.cellIdentifier = "HintMessageCell"
    }
    
    convenience init(with message: String, icon iconName: String) {
        self.init()
        self.message = message
        self.icon = iconName
    }
    
    func updateHidden(to isHidden: Bool) {
        self.hidden.accept(isHidden)
    }
}
