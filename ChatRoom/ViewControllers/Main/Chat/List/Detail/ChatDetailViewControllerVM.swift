//
//  ChatDetailViewControllerVM.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/5/7.
//

import Foundation
import RxSwift
import RxCocoa

// swiftlint:disable file_length
enum ChatDetailStyle {
    case friendListToPerson
    case friendListToGroup
    case friendListToGroupMember
    case chatToPerson
    case chatToGroup
    case chatToGroupMember
    case searchNewContact
    case blockedListToPerson
    case blockedDetailToSetting
    
    var fromWhere: FromWhere? {
        switch self {
        case .chatToGroup: return .chat
        case .friendListToGroup: return .friendList
        default: return nil
        }
    }
    
    var title: String? {
        switch self {
        case .chatToGroup: return Localizable.groupOverview
        case .chatToGroupMember, .chatToPerson: return Localizable.chatDetailed
        default:
            return ""
        }
    }
}

enum ChatDetailAction {
    case message
    case greeting
    case allowAddContact
    case banAddContact
    case deleteHistory
    case deleteAndLeave
    case report
    case unfriend
    case none
    case notification
    case blockList
    case addMember
    case groupSetting
    case administrator
    case blockUser
    case memo
    
    var actionTitle: String {
        switch self {
        case .message: return Localizable.sendMessage
        case .greeting: return Localizable.sayHello
        case .allowAddContact: return Localizable.addToList
        case .banAddContact: return ""
        case .deleteHistory: return Localizable.deleteHistory
        case .deleteAndLeave: return Localizable.deleteAndLeave
        case .unfriend: return Localizable.delete
        case .notification: return Localizable.closeNotitication
        case .blockList: return Localizable.addBlacklist
        case .report: return Localizable.report
        case .memo: return Localizable.memo
        default: return ""
        }
    }
    
    var actionTitleIcon: UIImage? {
        switch self {
        case .message: return UIImage(named: "iconIconMessage")
        case .greeting: return UIImage(named: "iconIconMessage")
        case .allowAddContact: return UIImage(named: "iconIconUserAdd")
        case .banAddContact: return nil
        default: return nil
        }
    }
}

protocol ChatDetailActionProtocol: AnyObject {
    var actionType: ChatDetailAction? { get set }
    var actionTapped: PublishSubject<ChatDetailAction> { get set }
}

// swiftlint:disable type_body_length
class ChatDetailViewControllerVM: BaseViewModel {
    
    struct ToastMessage {
        let isSuccess: Bool
        let message: String
    }
    
    var disposeBag = DisposeBag()

    let reload = PublishRelay<Void>()
    let showLoading = PublishRelay<Bool>()
    let errorMessage = PublishRelay<String>()
    let showImageViewer = PublishRelay<ImageViewerConfig>()
    let showBlockConfirm = PublishRelay<Void>()
    let deleteHistory = PublishRelay<Void>()
    let deleteHistorySuccess = PublishSubject<Void>()
    let leaverGroup = PublishRelay<Void>()
    let showToast = PublishRelay<ToastMessage>()
    let goto = PublishSubject<Navigator.Scene>()

    private(set) var memberInfoVM: MemberInfoCellVM?
    private(set) var memoVM: MemoCellVM?
    private(set) var notifyVM: SettingItemCellVM?
    private(set) var blockVM: SettingItemCellVM?
    private(set) var reportVM: SettingMoreCellVM?
    private(set) var deleteVM: SettingDangerCellVM?
    private(set) var deleteNLeaveVM: SettingDangerCellVM?
    private(set) var actionVM: ChatDetailActionCellVM?
    private(set) var hintVM: HintMessageCellVM?
    private let actionTapped = PublishSubject<ChatDetailAction>()

    var style: ChatDetailStyle
    var friend: FriendModel

    private(set) var vmList: [[BaseTableViewCellVM?]] = [] // This array define cell display order.

    init(data: FriendModel, style: ChatDetailStyle) {
        self.style = style
        self.friend = data
        super.init()
        switch style {
        case .chatToPerson:
            DataAccess.shared.getUserMemo(userID: friend.id)
            let info = MemberInfoCellVM.InfoModel(avatarURL: data.thumbNail ?? "",
                                                  nickname: data.getDisplayName(),
                                                  members: nil,
                                                  isDeleted: data.deleteAt != nil)
            memberInfoVM = MemberInfoCellVM(with: info)
            vmList.append([memberInfoVM])
            self.setupMemo()
            let group = DataAccess.shared.getGroupConversationDataSource(by: data.groupID ?? "")?.group
            let notifyItem = SettingItemCellVM.ItemModel(title: ChatDetailAction.notification.actionTitle,
                                                         isOn: (group?.notifyType == .on) ? false : true)
            notifyVM = SettingItemCellVM(with: notifyItem)

            let userBlock = DataAccess.shared.isBlockedUser(with: data.id)//data.isBlock ?? false
            let blockItem = SettingItemCellVM.ItemModel(title: ChatDetailAction.blockList.actionTitle,
                                                        isOn: userBlock)
            blockVM = SettingItemCellVM(with: blockItem)
            
            reportVM = SettingMoreCellVM(with: Localizable.report,
                                         actionType: .report)
            vmList.append([notifyVM, blockVM, reportVM])
            initBinding()
        case .chatToGroup:
            let members = DataAccess.shared.getGroupConversationDataSource(by: data.groupID ?? "")?.getConversationTransceivers()
            let info = MemberInfoCellVM.InfoModel(avatarURL: data.thumbNail ?? "",
                                                  nickname: data.displayName,
                                                  members: members?.compactMap { FriendModel.converTransceiverToFriend(transceiver: $0) })
            memberInfoVM = MemberInfoCellVM(with: info)
            vmList.append([memberInfoVM])
            
            let notifyItem = SettingItemCellVM.ItemModel(title: ChatDetailAction.notification.actionTitle,
                                                         isOn: data.isNotifyOn ?? false)
            notifyVM = SettingItemCellVM(with: notifyItem)
            reportVM = SettingMoreCellVM(with: Localizable.report,
                                         actionType: .report)
            vmList.append([notifyVM, reportVM])
            deleteVM = SettingDangerCellVM(with: ChatDetailAction.deleteHistory.actionTitle,
                                           actionType: .deleteHistory)
            deleteNLeaveVM = SettingDangerCellVM(with: ChatDetailAction.deleteAndLeave.actionTitle,
                                                 actionType: .deleteAndLeave)
            vmList.append([deleteVM, deleteNLeaveVM])
            initBinding()
        case .chatToGroupMember:
            let info = MemberInfoCellVM.InfoModel(avatarURL: data.thumbNail ?? "",
                                                  nickname: data.getDisplayName(),
                                                  members: nil)
            memberInfoVM = MemberInfoCellVM(with: info)
            vmList.append([memberInfoVM])
            self.setupMemo()
            showLoading.accept(true)
            fetchGroupMember {
                self.getAllowActions { [weak self] (action) in
                    guard let self = self else { return }
                    if action != .none, action != .banAddContact {
                        if DataAccess.shared.isBlockedUser(with: data.id) {
                            let item = ChatDetailActionCellVM.ItemModel(title: ChatDetailAction.message.actionTitle,
                                                                        icon: ChatDetailAction.message.actionTitleIcon)
                            self.actionVM = ChatDetailActionCellVM(with: item,
                                                                   actionType: ChatDetailAction.message)
                            
                            self.hintVM = HintMessageCellVM.init(with: Localizable.alreadyAddBlacklistHint, icon: "iconIconAlertErrorOutline")
                            
                            self.vmList.append([self.actionVM])
                            self.vmList.append([self.hintVM])
                        } else {
                            let item = ChatDetailActionCellVM.ItemModel(title: action.actionTitle,
                                                                        icon: action.actionTitleIcon)
                            self.actionVM = ChatDetailActionCellVM(with: item,
                                                                   actionType: action)
                            self.vmList.append([self.actionVM])
                        }
                    }
                    self.initBinding()
                }
            }
        case .friendListToPerson:
            DataAccess.shared.getUserMemo(userID: friend.id)
            let info = MemberInfoCellVM.InfoModel(avatarURL: data.thumbNail ?? "",
                                                  nickname: data.getDisplayName(),
                                                  members: nil)
            memberInfoVM = MemberInfoCellVM(with: info)
            vmList.append([memberInfoVM])
            getAllowActions { [weak self] (action) in
                guard let self = self else { return }
                let item = ChatDetailActionCellVM.ItemModel(title: action.actionTitle,
                                                            icon: action.actionTitleIcon)
                self.actionVM = ChatDetailActionCellVM(with: item,
                                                       actionType: action)
                self.setupMemo()
                self.vmList.append([self.actionVM])
                self.hintVM = HintMessageCellVM.init(with: Localizable.alreadyAddBlacklistHint, icon: "iconIconAlertErrorOutline")
                self.hintVM?.updateHidden(to: true)
                self.vmList.append([self.hintVM])
                self.initBinding()
            }
        case .friendListToGroup:
            let members = DataAccess.shared.getGroupConversationDataSource(by: data.id)?.getConversationTransceivers()
            let info = MemberInfoCellVM.InfoModel(avatarURL: data.thumbNail ?? "",
                                                  nickname: data.displayName,
                                                  members: members?.compactMap { FriendModel.converTransceiverToFriend(transceiver: $0) })
            memberInfoVM = MemberInfoCellVM(with: info)
            vmList.append([memberInfoVM])
            
            getAllowActions { [weak self] (action) in
                guard let self = self else { return }
                let item = ChatDetailActionCellVM.ItemModel(title: action.actionTitle,
                                                            icon: action.actionTitleIcon)
                self.actionVM = ChatDetailActionCellVM(with: item,
                                                       actionType: action)
                self.vmList = [[self.memberInfoVM], [self.actionVM]]
                self.initBinding()
            }
        case .friendListToGroupMember:
            let info = MemberInfoCellVM.InfoModel(avatarURL: data.thumbNail ?? "",
                                                  nickname: data.displayName,
                                                  members: nil)
            memberInfoVM = MemberInfoCellVM(with: info)
            vmList.append([memberInfoVM])
            getAllowActions { [weak self] (action) in
                guard let self = self else { return }

                if action != .none, action != .banAddContact {
                    let item = ChatDetailActionCellVM.ItemModel(title: action.actionTitle,
                                                                icon: action.actionTitleIcon)
                    self.actionVM = ChatDetailActionCellVM(with: item,
                                                           actionType: action)
                    self.setupMemo()
                    self.vmList.append([self.actionVM])
                }
                self.initBinding()
            }
        case .searchNewContact:
            let info = MemberInfoCellVM.InfoModel(avatarURL: data.thumbNail ?? "",
                                                  nickname: data.getDisplayName(),
                                                  members: nil)
            memberInfoVM = MemberInfoCellVM(with: info)
            vmList.append([memberInfoVM])
            self.getAllowActions { [weak self] action in
                guard let self = self else { return }
                self.setupMemo()
                let item = ChatDetailActionCellVM.ItemModel(title: action.actionTitle,
                                                            icon: action.actionTitleIcon)
                self.actionVM = ChatDetailActionCellVM(with: item,
                                                       actionType: action)
                self.vmList.append([self.actionVM])
                self.initBinding()
            }
        case .blockedListToPerson:
            let info = MemberInfoCellVM.InfoModel(avatarURL: data.thumbNail ?? "", nickname: data.displayName, members: nil)
            memberInfoVM = MemberInfoCellVM(with: info)
            let item = ChatDetailActionCellVM.ItemModel(title: ChatDetailAction.message.actionTitle,
                                                        icon: ChatDetailAction.message.actionTitleIcon)
            self.actionVM = ChatDetailActionCellVM(with: item,
                                                   actionType: ChatDetailAction.message)
            
            hintVM = HintMessageCellVM.init(with: Localizable.alreadyAddBlacklistHint, icon: "iconIconAlertErrorOutline")
            
            self.vmList.append([memberInfoVM])
            self.setupMemo()
            self.vmList.append([actionVM])
            self.vmList.append([hintVM])
            self.initBinding()
        case .blockedDetailToSetting:
            let info = MemberInfoCellVM.InfoModel(avatarURL: data.thumbNail ?? "", nickname: data.getDisplayName(), members: nil)
            memberInfoVM = MemberInfoCellVM(with: info)
            self.setupMemo()
            let notifyItem = SettingItemCellVM.ItemModel(title: ChatDetailAction.notification.actionTitle, isOn: data.isNotifyOn ?? false)
            notifyVM = SettingItemCellVM(with: notifyItem)
            
            let blockItem = SettingItemCellVM.ItemModel(title: ChatDetailAction.blockList.actionTitle, isOn: data.isBlock ?? true)
            blockVM = SettingItemCellVM(with: blockItem)
            reportVM = SettingMoreCellVM(with: Localizable.report,
                                         actionType: .report)
            
            self.vmList.append([memberInfoVM])
            self.vmList.append([notifyVM, blockVM, reportVM])
            self.initBinding()
        }
    }

    func initBinding() {
        if let groupID = friend.groupID, !friend.isDM {
            switch style {
            case .chatToPerson, .chatToGroupMember, .friendListToPerson, .searchNewContact:
                break
            default:
                /// use debounce to solve frequent updates in a short period of time
                /// member info update might cause wrong result
                DataAccess.shared.getGroupConversationDataSource(by: groupID)?.output.allTransceivers.skip(1).debounce(.milliseconds(100), scheduler: MainScheduler.instance).subscribeSuccess { [unowned self] transceivers in
                    let members = transceivers.filter { $0.isMember == true }.compactMap({ FriendModel.converTransceiverToFriend(transceiver: $0) })
                    memberInfoVM?.updateMemebers(members: members)
                }.disposed(by: disposeBag)
            }
        }
        
        DataAccess.shared.nicknameUpdateObserver.subscribeSuccess { [unowned self] userID in
            guard userID == friend.id else { return }
            switch style {
            case .chatToPerson, .chatToGroupMember, .friendListToPerson, .searchNewContact:
                if let personalSetting = DataAccess.shared.getUserPersonalSetting(with: userID) {
                    let nickname =  personalSetting.nickname ?? friend.nickname ?? friend.displayName
                    self.memberInfoVM?.updateNickname(nickname: nickname)
                    self.friend.displayName = nickname
                }
            default:
                break
            }
        }.disposed(by: disposeBag)
        
        DataAccess.shared.memoUpdateObserver.subscribeSuccess { [unowned self] userID in
            guard userID == friend.id else { return }
            switch style {
            case .chatToPerson, .chatToGroupMember, .friendListToPerson, .searchNewContact:
                if let personalSetting = DataAccess.shared.getUserPersonalSetting(with: userID),
                   let memo = personalSetting.memo {
                    self.memoVM?.update(memo: memo)
                    reload.accept(())
                }
            default:
                break
            }
        }.disposed(by: disposeBag)
        
        reload.accept(())
        self.memberInfoVM?.avatarTapped.subscribeSuccess { [weak self] in
            guard let self = self, let imgURL = self.friend.avatar, !imgURL.isEmpty else { return }
            
            var title: String = ""
            switch self.style {
            case .chatToGroup, .friendListToGroup:
                break
            default:
                title = Localizable.personalPhoto
            }
            self.showImageViewer.accept(ImageViewerConfig(title: title, date: nil, imageURL: imgURL, actionType: .viewAndDownload, fileID: nil, messageId: nil))
        }.disposed(by: self.disposeBag)

        self.memberInfoVM?.tapMemberList.subscribeSuccess { [weak self] _ in
            guard let self = self,
                  let groupID = self.friend.groupID else { return }
            let role = DataAccess.shared.getSelfGroupRole(groupID: groupID)
            let transceivers = DataAccess.shared.getGroupConversationDataSource(by: groupID)?.getConversationTransceivers() ?? []
            let sorted = transceivers.sorted { $0.joinAt?.timeIntervalSince1970 ?? 0 < $1.joinAt?.timeIntervalSince1970 ?? 0 }
            let vm = EditMemberViewControllerVM.init(type: .member, role: role, userInfo: sorted, groupID: groupID)
            self.goto.onNext(.editGroupMember(vm: vm))
        }.disposed(by: disposeBag)
        
        self.notifyVM?.switchUpdated.subscribeSuccess { [weak self] isOn in
            guard let self = self else { return }
            self.updateNotifyStatus(isOn: isOn)
        }.disposed(by: self.disposeBag)

        self.blockVM?.switchUpdated.subscribeSuccess { [weak self] isOn in
            guard let self = self else { return }
            if isOn {
                self.showBlockConfirm.accept(())
            } else {
                self.disableBlock()
            }
        }.disposed(by: self.disposeBag)
        
        self.bindBlockedStatus()
        
        self.actionTapped.subscribeSuccess { [weak self] (action) in
            guard let self = self else { return }
            switch action {
            case .memo:
                self.gotoContactorMemoPage()
            case .message, .greeting:
                self.gotoConversationPage()
            case .allowAddContact:
                self.addContact()
            case .banAddContact:
                break
            case .deleteHistory:
                self.deleteHistory.accept(())
            case .deleteAndLeave:
                self.leaverGroup.accept(())
            case .report:
                self.gotoReport()
            case .none, .unfriend, .notification:
                break
            case .groupSetting:
                guard let groupID = self.friend.groupID, let targetModel = DataAccess.shared.getGroupConversationDataSource(by: groupID)?.group else {
                    return
                }
                
                let vm = AuthSettingViewControllerVM.init(type: .group, model: targetModel)
                self.goto.onNext(.authSetting(vm: vm))
            case .administrator:
                guard let groupID = self.friend.groupID else { return }
                let role = DataAccess.shared.getSelfGroupRole(groupID: groupID)
                let trans = DataAccess.shared.getGroupOwnerAndAdmins(groupID: groupID)
                let vm = EditMemberViewControllerVM.init(type: .admin, role: role, userInfo: trans, groupID: groupID)
                self.goto.onNext(.editGroupMember(vm: vm))
            case .addMember:
                guard let groupID = self.friend.groupID else { return }
                let role = DataAccess.shared.getSelfGroupRole(groupID: groupID)
                let transceivers = DataAccess.shared.getGroupConversationDataSource(by: groupID)?.getConversationTransceivers() ?? []
                let sorted = transceivers.sorted { $0.joinAt?.timeIntervalSince1970 ?? 0 < $1.joinAt?.timeIntervalSince1970 ?? 0 }
                let vm = EditMemberViewControllerVM.init(type: .member, role: role, userInfo: sorted, groupID: groupID)
                self.goto.onNext(.editGroupMember(vm: vm))
            case .blockList:
                guard let groupID = self.friend.groupID else { return }
                let role = DataAccess.shared.getSelfGroupRole(groupID: groupID)
                let blockedUser = DataAccess.shared.getGroupBlockedTransceivers(by: groupID)
                let vm = EditMemberViewControllerVM.init(type: .block, role: role, userInfo: blockedUser, groupID: groupID)
                self.goto.onNext(.editGroupMember(vm: vm))
            default:
                // TODO:
                break
            }
        }.disposed(by: self.disposeBag)
        
        vmList.forEach { section in
            section.forEach {
                if let vm = $0 as? ChatDetailActionProtocol {
                    vm.actionTapped.bind(to: self.actionTapped).disposed(by: self.disposeBag)
                }
            }
        }
    }
    
    func fetchData() {
        guard !friend.isDM else { return }

        switch style {
        case .chatToGroup:
            fetchGroupMembers()
            // 每次都要更新 group 的非 member permission role
            fetchGroupAuth()
            // 更新 group的 Blacklist
            fetchBlockList()
        case .friendListToGroup:
            fetchGroupMembers()
            // 更新 group的 admin/owner permission role
            guard let groupID = friend.groupID, let ownerID = friend.ownerID else {
                return
            }
            DataAccess.shared.fetchGroupPermission(with: groupID, ownerID: ownerID)
        default: break
        }
    }
    
    private func bindBlockedStatus() {
        guard self.style == .blockedListToPerson || self.style == .friendListToPerson else {
            return
        }
        
        DataAccess.shared.blockedListUpdate.subscribeSuccess { [unowned self] _ in
            let isBlocked = DataAccess.shared.isBlockedUser(with: self.friend.id)
            self.friend.isBlock = isBlocked
            self.hintVM?.updateHidden(to: !isBlocked)
        }.disposed(by: self.disposeBag)
    }
    
    private func setupMemo() {
        guard friend.id != UserData.shared.userInfo?.id else { return }
        let memo = DataAccess.shared.getUserPersonalSetting(with: friend.id)?.memo
        memoVM = MemoCellVM(with: memo ?? "")
        self.vmList.append([memoVM])
    }

    func title() -> String { style.title ?? "" }
    
    func addContact() {
        let vm = AddFriendNicknameViewControllerVM(friend: friend)
        
        vm.showToastResult.subscribeSuccess { [weak self] isSuccess in
            if isSuccess {
                self?.setGreetAction()
            }
        }.disposed(by: disposeBag)
        
        self.goto.onNext(.addFriendNickname(vm: vm))
    }
    
    func setGreetAction() {
        self.createDirectConversation(userID: self.friend.id,
                                      displayName: self.friend.displayName,
                                      needNavigate: false)
        
        self.vmList = self.vmList.dropLast()
        let newAction = ChatDetailAction.greeting
        self.actionVM = ChatDetailActionCellVM(with: ChatDetailActionCellVM.ItemModel(title: newAction.actionTitle,
                                                                                      icon: newAction.actionTitleIcon),
                                               actionType: newAction)
        self.vmList.append([self.actionVM])
        self.disposeBag = DisposeBag()
        self.initBinding()
        self.reload.accept(())
    }
    
    func updateFriendData() {
        NotificationCenter.default.post(name: NSNotification.Name(FriendModel.updateFriendModelNotification + friend.id), object: nil, userInfo: ["data": friend])
    }
    
    func didSelect(at indexPath: IndexPath) {
        if let vm = vmList[indexPath.section][indexPath.item] as? ChatDetailActionProtocol {
            vm.actionTapped.onNext(vm.actionType ?? .none)
        }
    }
    
    func getAllowActions(completion: @escaping ((ChatDetailAction) -> Void)) {
        // 群組成員是好友 -> 傳訊息
        // 群組開放加好友且成員非好友 -> 新增通訊錄
        // 群組不開放加好友 -> ban 加好友
        // 目前後端API不開放加好友，只有已加入好友可以顯示傳訊息
        switch style {
        case .friendListToGroup,
             .friendListToPerson,
             .blockedListToPerson:
            completion(.message)
        case .chatToGroup, .chatToPerson, .blockedDetailToSetting:
            completion(.none)
        case .chatToGroupMember,
             .friendListToGroupMember:
            if DataAccess.shared.isFriend(with: friend.id) {
                completion(.message)
            } else if !(self.friend.userName ?? "").isEmpty {
                completion(.allowAddContact)
            } else {
                completion(.none)
            }
        case .searchNewContact:
            let isFriend = DataAccess.shared.isFriend(with: friend.id)
            completion(isFriend ? .message : .allowAddContact)            
        }
    }
    
    func isNeedSetting(completion: @escaping (Bool) -> Void) {
        switch style {
        case .chatToGroup,
             .chatToPerson,
             .chatToGroupMember,
             .searchNewContact,
             .blockedDetailToSetting:
            completion(false)
        case .friendListToPerson,
             .friendListToGroupMember:
            guard !isSelf(userID: friend.id) else {
                completion(false)
                return
            }
            completion(DataAccess.shared.isFriend(with: friend.id))
        case .friendListToGroup,
             .blockedListToPerson:
            completion(true)
        }
    }
    
    func isSelf(userID: String) -> Bool {
        guard let selfID = UserData.shared.userID else { return false }
        return userID == selfID
    }
    
    func getSettingViewModel() -> InfoSettingViewControllerVM? {
        switch style {
        case .friendListToPerson:
            return InfoSettingViewControllerVM(data: friend, style: .contact)
        case .friendListToGroup:
            return InfoSettingViewControllerVM(data: friend, style: .group)
        case .friendListToGroupMember:
            return InfoSettingViewControllerVM(data: friend, style: .transceiver)
        default: return nil
        }
    }
    
    func gotoBlockedSettingPage() {
        guard let group = getConversationGroup() else {
            if let ID = getConversationID() {
                createDirectConversation(userID: ID, displayName: friend.displayName)
            }
            return
        }
        gotoBlockedSetting(group: group)
    }
    
    func gotoConversationPage() {
        guard let group = getConversationGroup() else {
            if let ID = getConversationID() {
                createDirectConversation(userID: ID,
                                         displayName: friend.displayName)
            }
            return
        }
        
        gotoConversation(group: group)
    }
    
    func gotoContactorMemoPage() {
        let vm = ContactorMemoViewControllerVM(friend: friend)
        goto.onNext(.contactMemo(vm: vm))
    }
    
    func getConversationID() -> String? {
        switch style {
        case .friendListToGroup:
            return friend.ownerID
        case .friendListToPerson,
             .friendListToGroupMember,
             .chatToGroupMember,
             .blockedListToPerson:
            return friend.id
        default:
            return nil
        }
    }
    
    func getConversationGroup() -> GroupModel? {
        switch style {
        case .friendListToGroup:
            return DataAccess.shared.getGroupConversationDataSource(by: friend.id)?.group
        case .friendListToPerson,
             .friendListToGroupMember,
             .chatToGroupMember,
             .searchNewContact:
            return isSelf(userID: friend.id) ? DataAccess.shared.getSelfDMConversation(id: friend.id) : DataAccess.shared.getDirectConversation(friend.id)
        case .blockedListToPerson:
            return DataAccess.shared.getDirectConversation(friend.id, includeHidden: true)
        default:
            return nil
        }
    }
    
    func createDirectConversation(userID: String, displayName: String, needNavigate: Bool = true) {
        DataAccess.shared.createDirectConversation(with: userID, displayName: displayName, isHidden: self.style == .blockedListToPerson).subscribeSuccess { [weak self] (group) in
            guard let self = self, needNavigate else { return }
            guard self.style != .blockedListToPerson else {
                self.gotoBlockedSetting(group: group)
                return
            }
            self.gotoConversation(group: group)
        }.disposed(by: disposeBag)
    }
    
    func gotoConversation(group: GroupModel) {
        guard let dataSource = DataAccess.shared.getGroupConversationDataSource(by: group.id) else {
            gotoConversation(group: group)
            return
        }
        
        let vm = ConversationViewControllerVM(with: dataSource)
        goto.onNext(.conversation(vm: vm))
    }
    
    func gotoBlockedSetting(group: GroupModel) {
        self.friend.groupID = group.id
        self.friend.isNotifyOn = group.notifyType == .on
        let vm = ChatDetailViewControllerVM.init(data: self.friend, style: .blockedDetailToSetting)
        goto.onNext(.chatDetail(vm: vm))
    }
    
    func gotoReport() {
        switch style {
        case .chatToGroup:
            goto.onNext(.report(vm: ReportViewControllerVM(groupID: friend.id, userID: "")))
        default:
            goto.onNext(.report(vm: ReportViewControllerVM(userID: friend.id)))
        }
    }
    
    func deleteHistoryRecord(completion: ((Bool) -> Void)? = nil) {
        guard let groupID = friend.groupID else { return }
        showLoading.accept(true)
        DataAccess.shared.clearGroupMessages(groupID: groupID) { [weak self] isFinish in
            self?.showLoading.accept(false)
            if isFinish {
                self?.deleteHistorySuccess.onNext(())
            }
            completion?(isFinish)
        }
    }
    
    func leaveGroup(completion: ((Bool, String?) -> Void)? = nil) {
        guard let groupID = friend.groupID, let userID = UserData.shared.userID else { return }
        showLoading.accept(true)
        // 先刪除訊息後, 再離開群組
        DataAccess.shared.clearGroupMessages(groupID: groupID) { [weak self] isFinish in
            guard let self = self else { return }
            if isFinish {
                self.deleteHistorySuccess.onNext(())
            }
            DataAccess.shared.fetchLeaveGroup(groupID, userID) { [weak self] isLeft, error in
                guard let self = self else { return }
                self.showLoading.accept(false)
                guard let error = error as? ApiError else {
                    completion?(isLeft, nil)
                    return
                }
                
                if case .requestError(let code, _, _) = error {
                    if code == "api.body.param_invalid.owner_id" {
                        completion?(isLeft, Localizable.ownerCantLeaveGroup)
                        return
                    }
                }
                completion?(isLeft, Localizable.failedToDeleteAndLeave)
            }
        }
    }
}

// MARK: - Auth
private extension ChatDetailViewControllerVM {
    func fetchGroupMember(completion: @escaping() -> Void) {
        guard let groupID = friend.groupID else { return }
        DataAccess.shared.fetchGroupMember(by: groupID, memberID: friend.id) { [weak self] info in
            guard let self = self else { return }
            self.showLoading.accept(false)
            self.friend.userName = info?.username
            completion()
        }
    }
    
    func fetchGroupMembers() {
        guard let groupID = friend.groupID else { return }
        DataAccess.shared.fetchGroupMembers(by: groupID)
    }

    func fetchGroupAuth() {
        guard let groupID = friend.groupID, let ownerID = friend.ownerID else {
            return
        }
        
        self.showLoading.accept(true)
        DataAccess.shared.fetchGroupPermission(with: groupID, ownerID: ownerID) { [weak self] userRole in
            guard let self = self else { return }
            
            self.vmList.removeAll()
            self.vmList.append([self.memberInfoVM])
            self.vmList.append([self.notifyVM, self.reportVM])
            
            if let userRole = userRole {
                let authList = self.getAuthSettingList(groupID: groupID, role: userRole)
                if !authList.isEmpty {
                    self.vmList.append(authList)
                }
            }
            
            self.vmList.append([self.deleteVM, self.deleteNLeaveVM])
            self.reload.accept(())
            self.showLoading.accept(false)
        }
    }
    
    func getAuthSettingList(groupID: String, role: UserRoleModel) -> [BaseTableViewCellVM] {
        guard role.type == .owner || role.type == .admin else {
            return []
        }
        
        var authCellVM = [BaseTableViewCellVM]()
        
        if role.type == .owner || role.permission.inviteUsers {
            authCellVM.append(SettingMoreCellVM(with: Localizable.joinMembers, actionType: .addMember, icon: "iconIconUserAdd"))
        }
        
        if role.type == .owner || role.permission.changeGroupInfo {
            let cellVM = SettingMoreInfoCellVM(with: Localizable.groupSettings, actionType: .groupSetting, info: "")
            DataAccess.shared.getGroupConversationDataSource(by: groupID)?.detail?.settingOnCount.map { return String(format: "%ld/4", $0) }.bind(to: cellVM.info).disposed(by: self.disposeBag)
            authCellVM.append(cellVM)
        }
        
        if role.type == .owner || role.permission.addAdmins {
            let cellVM = SettingMoreInfoCellVM(with: Localizable.admin, actionType: .administrator, info: "")
            DataAccess.shared.getGroupConversationDataSource(by: groupID)?.detail?.adminIds.map { return "\($0.count + 1)" }.bind(to: cellVM.info).disposed(by: self.disposeBag)
            authCellVM.append(cellVM)
        }
        
        if role.type == .owner || role.permission.banUsers {
            let cellVM = SettingMoreInfoCellVM(with: Localizable.blockList, actionType: .blockList, info: "")
            DataAccess.shared.getGroupConversationDataSource(by: groupID)?.detail?.blocksCount.map { return "\($0)" }.bind(to: cellVM.info).disposed(by: self.disposeBag)
            authCellVM.append(cellVM)
        }
        
        authCellVM.forEach {
            if let vm = $0 as? ChatDetailActionProtocol {
                vm.actionTapped.bind(to: self.actionTapped).disposed(by: self.disposeBag)
            }
        }
        
        return authCellVM
    }
}

// MARK: - Setup Block
extension ChatDetailViewControllerVM {
    func fetchBlockList() {
        if let groupID = friend.groupID {
            DataAccess.shared.fetchGroupBlocks(groupID: groupID)
        }
    }
    
    func setBlock(on: Bool) {
        self.blockVM?.isOn.accept(on)
        self.friend.isBlock = on
    }

    func enableBlock() {
        self.showLoading.accept(true)
        DataAccess.shared.fetchBlockUser(userID: friend.id) { [weak self] (isSuccess) in
            guard let self = self else { return }
            self.showLoading.accept(false)
            guard isSuccess else {
                self.setBlock(on: false)
                return
            }
            self.setBlock(on: true)
            self.updateFriendData()
        }
    }

    func disableBlock() {
        self.showLoading.accept(true)
        DataAccess.shared.fetchUnBlockUser(userID: friend.id) { [weak self] (isSuccess) in
            guard let self = self else { return }
            self.showLoading.accept(false)
            guard isSuccess else {
                self.setBlock(on: true)
                return
            }
            self.setBlock(on: false)
            self.updateFriendData()
        }
    }
    
    func setNotify(isOn: Bool) {
        notifyVM?.isOn.accept(isOn)
    }
    
    func updateNotifyStatus(isOn: Bool) {
        if let groupID = friend.groupID {
            DataAccess.shared.setGroupNotify(groupID: groupID, mute: isOn) { [weak self] (isSuccess) in
                guard let self = self else { return }
                if !isSuccess {
                    // set back to prev status
                    self.setNotify(isOn: !isOn)
                }
                self.friend.isNotifyOn = isOn
                self.updateFriendData()
            }
        }
    }
}

// MARK: - Setup TableView
extension ChatDetailViewControllerVM {
    func numberOfSections() -> Int { vmList.count }
    func numberOfRow(in section: Int) -> Int { vmList[section].count }
    func cellViewModel(in indexPath: IndexPath) -> BaseTableViewCellVM? { vmList[indexPath.section][indexPath.item] }
    
    func heightForRow(in indexPath: IndexPath) -> CGFloat {
        switch style {
        case .chatToGroup,
             .friendListToGroup:
            return indexPath.section == 0 ? 202 : 56
        case .chatToPerson,
             .friendListToPerson,
             .chatToGroupMember,
             .friendListToGroupMember,
             .searchNewContact,
             .blockedListToPerson,
             .blockedDetailToSetting:
            return indexPath.section == 0 ? 150 : 56
        }
    }
}
// swiftlint:enable file_length
