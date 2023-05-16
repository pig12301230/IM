//
//  ConversationViewControllerVM.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/5/12.
//

import Foundation
import RxSwift
import RxCocoa

class ConversationViewControllerVM: BaseViewModel {
    var disposeBag = DisposeBag()
    
    let showToast = PublishSubject<String>()
    let showLoading = PublishRelay<Bool>()
    let vcTitle: BehaviorRelay<String> = BehaviorRelay(value: "")
    let memberCount: BehaviorRelay<String> = BehaviorRelay(value: "")
    var attachmentShowed = PublishRelay<Void>()
    var dismissAddAsFriend = PublishRelay<Bool>()
    let popToChatList = PublishSubject<Void>()
    let otherUnreadDisplay: BehaviorRelay<String> = BehaviorRelay(value: "")
    let showBlockConfirm = PublishRelay<Void>()
    let isDeletedUser: BehaviorRelay<Bool> = .init(value: false)
    
    private(set) var addAsFriendVM: AddAsFriendViewVM?
    private(set) var searchVM: SearchNavigationViewVM!
    private(set) var messageVM: MessageViewControllerVM
    private(set) var messageSearchVM: MessageSearchViewControllerVM
    private(set) var resendModels = [String]()
    private(set) var navigationBackType: ConversationNavigationBackType // 用來決定返回到哪
    private(set) var highlightModel: MessageModel?
    private(set) var memberCountWidth: CGFloat = 0
    let dataSource: ConversationDataSource

    var currentContentType: BehaviorRelay<ConversationContentType> {
        messageVM.interactor.dataSource.input.currentContentType
    }

    init(with dataSource: ConversationDataSource, backType: ConversationNavigationBackType = .toChatList, highlightModel: MessageModel? = nil) {
        self.dataSource = dataSource
        self.searchVM = SearchNavigationViewVM(config: SearchViewConfig(underLine: false))
        self.messageVM = MessageViewControllerVM(with: dataSource, target: highlightModel?.id)
        self.messageSearchVM = MessageSearchViewControllerVM(searchVM: searchVM, dataSource: dataSource)
        self.navigationBackType = backType
        self.highlightModel = highlightModel
        super.init()
        self.updateTitle(dataSource.group, memberCount: dataSource.group.memberCount)
        self.initBinding()
        self.updateHighlightMessage()
        self.setupAddAsFriendViewModel()
    }
    
    func dispose() {
//        self.messageDataSource.setAllMessageRead()
        self.disposeBag = DisposeBag()
    }
 
    func detailVM() -> ChatDetailViewControllerVM? {
        switch messageVM.group.groupType {
        case .dm:
            guard let member = dataSource.input.transceiverDict.value.values.filter({ $0.userID != UserData.shared.userInfo?.id }).first else { return nil }
            return ChatDetailViewControllerVM(data: FriendModel.converTransceiverToFriend(transceiver: member), style: .chatToPerson)
        case .group:
            return ChatDetailViewControllerVM(data: FriendModel.convertGroupToFriend(group: dataSource.group), style: .chatToGroup)
        }
    }

    func refreshGroupData() {
        updateTitle(dataSource.group, memberCount: dataSource.group.memberCount)
    }

    private func updateHighlightMessage() {
        let type: ConversationContentType = highlightModel != nil ? .highlightMessage : .nature
        currentContentType.accept(type)
    }
    
    func bolckUser() {
        guard let transceiverId = self.addAsFriendVM?.transceiver?.userID else {
            return
        }
        
        self.showLoading.accept(true)
        DataAccess.shared.fetchBlockUser(userID: transceiverId) { [weak self] (isSuccess) in
            guard let self = self else { return }
            if isSuccess {
                self.addAsFriendVM?.actionFinishIsBlocked.onNext(isSuccess)
            }
            self.showLoading.accept(false)
        }
    }
}

private extension ConversationViewControllerVM {
    func updateTitle(_ group: GroupModel, memberCount: Int) {
        self.vcTitle.accept(group.display)
        
        if group.groupType == .dm {
            if let trans = dataSource.input.transceiverDict.value.values.first(where: { $0.userID != UserData.shared.userID }) {
                self.vcTitle.accept(trans.display)
                if trans.deleteAt != nil {
                    self.isDeletedUser.accept(true)
                }
            } else {
                // 自己與自己的對話框
                self.vcTitle.accept(UserData.shared.userInfo?.nickname ?? "")
            }
        } else {
            // 空兩格是為了 line break, 不然當title過長時, 會讓 title and count 前後 label 都...
            let countString = "(\(memberCount))"
            let width = countString.size(font: .boldParagraphLargeLeft, maxSize: CGSize.init(width: 100, height: 23)).width
            self.memberCountWidth = ceil(width)
            self.memberCount.accept(countString)
        }
    }
    
    func initBinding() {
        searchVM.output.searchString.bind(to: messageVM.input.searchingContent).disposed(by: disposeBag)
        
        self.messageSearchVM.selectedMessage.bind(to: self.messageVM.input.selectedMessage).disposed(by: self.disposeBag)
        
        // 被踢出群族 or 自行離開
        DataAccess.shared.dismissGroup.subscribeSuccess { [unowned self] groupID in
            if dataSource.group.id == groupID {
                popToChatList.onNext(())
            }
        }.disposed(by: disposeBag)

        dataSource.output.othersUnread.map { count -> String in
            count > 0 ? count > 99 ? "99+" : "\(count)" : ""
        }.bind(to: otherUnreadDisplay).disposed(by: disposeBag)
        
        dataSource.output.updateMessageReadStats
            .bind(to: self.messageVM.input.setReadMessage).disposed(by: disposeBag)
        
        // 黑名單功能
        guard dataSource.group.groupType == .dm, let member = dataSource.input.transceiverDict.value.values.filter({ $0.userID != UserData.shared.userID }).first else {
            return
        }
        
        let isBlocked = DataAccess.shared.isBlockedUser(with: member.userID)
        self.messageVM.toolBarViewModel.input.suspended.accept(isBlocked ? .userBlocked : nil)
        
        DataAccess.shared.blockedListUpdate.subscribeSuccess { [unowned self] _ in
            let isBlocked = DataAccess.shared.isBlockedUser(with: member.userID)
            self.messageVM.toolBarViewModel.input.suspended.accept(isBlocked ? .userBlocked : nil)
        }.disposed(by: self.disposeBag)
    }
    
    func setupAddAsFriendViewModel() {
        guard let transceiver = getAddAsFriendTransceiver() else {
            self.addAsFriendVM = AddAsFriendViewVM.init()
            return
        }
        
        let vm = AddAsFriendViewVM.init(with: transceiver)
        vm.actionFinishIsBlocked.subscribeSuccess { [unowned self] isBlocked in
            self.dismissAddAsFriend.accept(isBlocked)
            if isBlocked {
                self.messageVM.toolBarViewModel.input.suspended.accept(.userBlocked)
            }
        }.disposed(by: self.disposeBag)
        vm.showBlockConfirm.subscribeSuccess { [unowned self] _ in
            self.showBlockConfirm.accept(())
        }.disposed(by: self.disposeBag)
        
        self.addAsFriendVM = vm
    }
    
    func getAddAsFriendTransceiver() -> TransceiverModel? {
        guard dataSource.group.groupType == .dm, let transceiver = dataSource.input.transceiverDict.value.values.filter({ $0.userID != UserData.shared.userID }).first else {
            return nil
        }
        return transceiver
    }
}
