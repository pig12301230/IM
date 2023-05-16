//
//  ChatTableViewCellVM.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/5/3.
//

import Foundation
import RxSwift
import RxCocoa

class ChatTableViewCellVM: RecordTableViewCellVM {
    let unreadWidth: BehaviorRelay<CGFloat> = BehaviorRelay(value: 0)
    let isMute: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    let updateTime: BehaviorRelay<String> = BehaviorRelay(value: "")
    let unreadCount: BehaviorRelay<Int> = BehaviorRelay(value: 0)
    let showFailure: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    let isDeletedUser: BehaviorRelay<Bool> = .init(value: false)
    
    private(set) var draftMessageMutableAttributedString: NSMutableAttributedString = NSMutableAttributedString.init(string: "")
    private var draftMessage: String = ""
    
    override init(with type: NameCellType) {
        super.init(with: type)
        self.cellIdentifier = "ChatTableViewCell"
    }
    
    override func setupByData(_ data: GroupModel) {
        super.setupByData(data)
        self.adjustMemberCountLabelWidth(with: data.unreadCount)
        self.isMute.accept(data.notifyType == .off)
        
        let isFailure = data.unreadCount == 0 && data.hasFailure == true
        self.showFailure.accept(isFailure)
        self.draftMessage = data.draft
        self.setupDraftMessage(message: self.draftMessage)
        
        var date: Date = data.updateAt
        if let lastMessage = data.lastMessage, !lastMessage.id.isEmpty, let messageDate = lastMessage.createAt {
            date = messageDate
        }
        
        let time = date.messageDateFormat(todayFormat: .symbolTime)
        self.updateTime.accept(time)
    }
    
    override func initBinding(_ group: GroupModel) {
        super.initBinding(group)

        DataAccess.shared.getGroupObserver(by: group.id).unread.distinctUntilChanged().observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] count in
            let isFailure = count == 0 && group.hasFailure == true
            self.showFailure.accept(isFailure)
            self.unreadCount.accept(count)
        }.disposed(by: self.disposeBag)
        
        DataAccess.shared.getGroupObserver(by: group.id).groupObserver.observe(on: MainScheduler.instance).subscribeSuccess { [weak self] model in
            self?.cellType = .record(group: model)
        }.disposed(by: self.disposeBag)

        DataAccess.shared.getGroupObserver(by: group.id).draftObserver.observe(on: MainScheduler.instance).subscribeSuccess { [weak self] model in
            guard let self = self else { return }
            self.setupDraftMessage(message: model?.message ?? "")
        }.disposed(by: self.disposeBag)
        
        DataAccess.shared.getGroupObserver(by: group.id).transceiverDict
            .observe(on: MainScheduler.instance)
            .subscribeSuccess { [weak self] _ in
                // 只有 dm 需要顯示 已註銷人員
                guard let self = self else { return }
                guard group.groupType == .dm else { return }
                let selfUserID = UserData.shared.userID ?? ""
                guard let otherTrans = self.transceivers.values.first(where: { $0.userID != selfUserID }),
                    otherTrans.deleteAt != nil else {
                    return
                }
                self.isDeletedUser.accept(true)
            }.disposed(by: disposeBag)
    }
    
    override func setupSearchContentColor(key: String) {
        super.setupSearchContentColor(key: key)
        
        if key.isEmpty {
            self.setupDraftMessage(message: self.draftMessage)
        }
    }
    
    private func setupDraftMessage(message: String) {
        guard self.unreadCount.value == 0, self.showFailure.value == false else {
            return
        }
        
        guard !message.isEmpty else {
            self.attributedMessage.accept(self.messageMutableAttributedString)
            return
        }
        
        self.draftMessageMutableAttributedString = NSMutableAttributedString.init(string: Localizable.draftMessagePrefix + " " + message)
        self.draftMessageMutableAttributedString.setColor(color: Theme.c_05_warning_700.rawValue.toColor(), forText: Localizable.draftMessagePrefix)
        self.draftMessageMutableAttributedString.setColor(color: Theme.c_10_grand_1.rawValue.toColor(), forText: message)
        self.attributedMessage.accept(self.draftMessageMutableAttributedString)
        
    }
    
    private func adjustMemberCountLabelWidth(with count: Int) {
        let countString = "\(count)"
        let width = countString.size(font: .boldParagraphSmallLeft, maxSize: CGSize.init(width: 45, height: 24)).width
        let finalWidth = max(24, width + 16)  // 16: leading and trailing edge, 24: 最小寬度
        self.unreadWidth.accept(finalWidth)
    }
}
