//
//  HongBaoMessageCellVM.swift
//  ChatRoom
//
//  Created by Winston_Chuang on 2022/12/21.
//


import Foundation
import RxSwift
import RxCocoa

class HongBaoMessageCellVM: MessageBaseCellVM {
    
    let showHongBaoView: PublishSubject<HongBaoContent> = .init()
    let showToast: PublishSubject<String> = .init()
    let content: BehaviorRelay<HongBaoContent?> = .init(value: nil)
    
    override init(model: MessageBaseModel, withRead: Bool) {
        super.init(model: model, withRead: withRead)
        self.cellIdentifier = (model.config.sender == .me ? "HongBaoMessageRCell" : "HongBaoMessageLCell")
        self.config.accept(model.config)
        self.updateView(model: model)
        self.content.accept(model.message.hongBaoContent)
    }
    
    func clickHongBao() {
        guard let content = content.value else { return }
        // 1.確認是否為自己開啟
        guard content.senderID != UserData.shared.userID else {
            self.showToast.onNext(Localizable.cantOpenOwnHongBao)
            return
        }
        self.showHongBaoView.onNext(content)
    }
}
