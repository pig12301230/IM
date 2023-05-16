//
//  MessageBaseCellVM.swift
//  ChatRoom
//
//  Created by Saffi Peng on 2021/7/20.
//

import Foundation
import RxSwift
import RxCocoa

class MessageBaseCellVM: ConversationBaseCellVM {

    var disposeBag = DisposeBag()

    var cellID: String = "MessageBaseCell"

    // For, Search
    var compareString: String = ""
    var keyString: String = ""

    // For, Message data
    var baseModel: MessageBaseModel
    override var status: MessageStatus {
        didSet {
            checkStatus()
        }
    }

    let config: BehaviorRelay<MessageContentConfig> = BehaviorRelay(value: MessageContentConfig())
    // Avatar
    let avatarURL: BehaviorRelay<String> = BehaviorRelay(value: "")
    let avatarHidden: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    let roleIcon: BehaviorRelay<PermissionType> = BehaviorRelay(value: .none)
    let isDeletedUser: BehaviorRelay<Bool> = .init(value: false)
    // Name
    let name: BehaviorRelay<String> = BehaviorRelay(value: "")
    let nameHidden: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    // Time＆Read
    var isRead: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    let dateTime: BehaviorRelay<String> = BehaviorRelay(value: "")
    // MessageStatus
    let isFailure: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    let isLoading: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    let showImageViewer = PublishSubject<ImageViewerConfig>()
    let goToContactDetail = PublishSubject<FriendModel>()
    let showImageFailureToast = PublishSubject<(String, String)>()
    let resendMessage = PublishSubject<MessageModel>()
    let showEmojiView = PublishSubject<MessageModel>()
    let showEmojiList = PublishSubject<String>()
    let updateEmojiFootView: BehaviorRelay<(GroupType?, EmojiContentModel?)> = BehaviorRelay(value: (nil, nil))

    init(model: MessageBaseModel, withRead: Bool) {
        self.baseModel = model
        super.init()
        self.status = model.message.messageStatus
        self.withRead = withRead
    }
    
    override func updateUserNickname(_ nickname: String?) {
        let name: String = nickname ?? self.baseModel.transceiver?.display ?? ""
        self.baseModel.transceiver?.display = name
        self.name.accept(name)
    }
    
    override func updateTransceiverRole(_ role: PermissionType) {
        self.baseModel.transceiver?.role = role
        self.roleIcon.accept(role)
    }

    override func updateTransceiver(_ transceiver: TransceiverModel) {
        self.baseModel.transceiver = transceiver
        self.name.accept(transceiver.display)
        self.avatarURL.accept(transceiver.avatarThumbnail)
    }
    
    func showContactDetail() {
        guard let transceiver = self.baseModel.transceiver else {
            return
        }
        let friend = FriendModel.converTransceiverToFriend(transceiver: transceiver)
        self.goToContactDetail.onNext(friend)
    }
    
    func doResendAction() {
        guard self.baseModel.message.messageType == .text || self.baseModel.message.messageType == .image else {
            return
        }
        self.resendMessage.onNext(self.baseModel.message)
    }
    
    func showEmojiToolView() {
        guard !self.baseModel.message.diffID.contains("tmp") else { return }
        self.showEmojiView.onNext(self.baseModel.message)
    }
    
    func handleDoubleTap() {
        DataAccess.shared.handleEmojiDidTap(model: self.baseModel.message, emojiType: .like)
    }
    
    func openEmojiList() {
        self.showEmojiList.onNext(self.baseModel.message.id)
    }
}

// MARK: - PRIVATE methods
extension MessageBaseCellVM {
    func updateView(model: MessageBaseModel) {
        status = model.message.messageStatus

        // Avatar
        let url = model.transceiver?.avatarThumbnail ?? ""
        self.avatarURL.accept(url)
        self.avatarHidden.accept(model.config.order == .nth)
        
        if model.config.groupType == .dm {
            self.roleIcon.accept(.none)
        } else {
            switch model.transceiver?.role {
            case .owner:
                self.roleIcon.accept(.owner)
            case .admin:
                self.roleIcon.accept(.admin)
            default:
                self.roleIcon.accept(.none)
            }
        }
        
        // Name
        let name = model.transceiver?.display ?? ""
        self.name.accept(name)
        let shouldNameHidden = model.config.order == .nth || model.config.groupType == .dm
        self.nameHidden.accept(shouldNameHidden)
        self.dateTime.accept(model.message.localeTimeString)

        self.checkStatus()
        self.updateRead()
        self.checkIsDeletedUser()
        self.updateEmoji()
    }

    func checkStatus() {
        self.isFailure.accept(status == .failed)

        let loading = status == .sending || status == .fakeSending
        self.isLoading.accept(loading)
    }

    func updateRead() {
        self.isRead.accept(self.withRead)
        self.baseModel.config.isRead = self.withRead
    }
    
    func checkIsDeletedUser() {
        guard let transceiver = self.baseModel.transceiver else { return }
        self.isDeletedUser.accept(transceiver.deleteAt != nil)
    }
    
    func updateEmoji() {
        DataAccess.shared.getMessageEmojiContent(diffID: self.baseModel.message.diffID) { [weak self] emojiContentModel in
            guard let self = self else { return }
            self.updateEmojiFootView.accept((self.baseModel.config.groupType, emojiContentModel))
        }
    }
}
