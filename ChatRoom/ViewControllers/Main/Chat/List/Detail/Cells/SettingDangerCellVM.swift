//
//  SettingDangerCellVM.swift
//  ChatRoom
//
//  Created by Andy Yang on 2021/5/26.
//

import Foundation
import RxSwift
import RxCocoa

class SettingDangerCellVM: BaseTableViewCellVM, ChatDetailActionProtocol {
    
    let title: PublishRelay<String> = PublishRelay()
    
    var data: String?
    var actionType: ChatDetailAction?
    var actionTapped: PublishSubject<ChatDetailAction> = .init()
    
    override init() {
        super.init()
        self.cellIdentifier = "SettingDangerCell"
    }
    
    convenience init(with title: String, actionType: ChatDetailAction) {
        self.init()
        data = title
        self.actionType = actionType
    }
    
    func setupViews() {
        guard let titleStr = data else { return }
        title.accept(titleStr)
    }
}
