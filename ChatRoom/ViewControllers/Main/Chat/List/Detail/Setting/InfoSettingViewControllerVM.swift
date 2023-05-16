//
//  InfoSettingViewControllerVM.swift
//  ChatRoom
//
//  Created by Andy Yang on 2021/6/7.
//

import Foundation
import RxSwift
import RxCocoa

enum InfoSettingStyle {
    case contact
    case transceiver
    case group
}

class InfoSettingViewControllerVM: BaseViewModel {
    var disposeBag = DisposeBag()
    
    let reload = PublishRelay<Void>()
    let showLoading = PublishRelay<Bool>()
    let errorMessage = PublishRelay<String>()
    let showBlockConfirm = PublishRelay<Void>()
    let gotoReport = PublishRelay<Void>()
    let deleteHistory = PublishRelay<Void>()
    let leaverGroup = PublishRelay<Void>()
    let unFriend = PublishRelay<String>()
    let goto = PublishSubject<Navigator.Scene>()
    private let actionTapped = PublishRelay<ChatDetailAction>()
    
    private(set) var blockVM: SettingItemCellVM?
    private(set) var reportVM: SettingMoreCellVM?
    private(set) var notifyVM: SettingItemCellVM?
    private(set) var unfriendVM: SettingDangerCellVM?
    private(set) var deleteHistoryVM: SettingDangerCellVM?
    private(set) var deleteNLeaveVM: SettingDangerCellVM?
    
    var style: InfoSettingStyle
    private(set) var vmList: [[BaseTableViewCellVM?]] = []
    var friend: FriendModel {
        didSet {
            updateFriendData()
        }
    }
    
    init(data: FriendModel, style: InfoSettingStyle) {
        self.style = style
        self.friend = data
        super.init()
        
        switch style {
        case .transceiver,
             .contact:
            let blockItem = SettingItemCellVM.ItemModel(title: Localizable.addBlacklist,
                                                        isOn: data.isBlock ?? false)
            blockVM = SettingItemCellVM(with: blockItem)
            
            reportVM = SettingMoreCellVM(with: Localizable.report,
                                         actionType: .report)
            
            vmList.append([blockVM, reportVM])
            
            unfriendVM = SettingDangerCellVM(with: Localizable.delete,
                                             actionType: .unfriend)
            vmList.append([unfriendVM])
        case .group:
            reportVM = SettingMoreCellVM(with: Localizable.report,
                                         actionType: .report)
            let notifyItem = SettingItemCellVM.ItemModel(title: ChatDetailAction.notification.actionTitle,
                                                         isOn: data.isNotifyOn ?? false)
            notifyVM = SettingItemCellVM(with: notifyItem)
            vmList.append([notifyVM, reportVM])
            
            deleteHistoryVM = SettingDangerCellVM(with: ChatDetailAction.deleteHistory.actionTitle,
                                                  actionType: .deleteHistory)
            deleteNLeaveVM = SettingDangerCellVM(with: ChatDetailAction.deleteAndLeave.actionTitle,
                                                 actionType: .deleteAndLeave)
            vmList.append([deleteHistoryVM, deleteNLeaveVM])
        }
        initBinding()
    }
    
    func fetchData() {
        guard !friend.isDM, style == .group else {
            return
        }
        
        // 每次都要更新 group 的非 member permission role
        fetchGroupAuth()
        // 更新 group的 Blacklist
        fetchBlockList()
    }
    
    func initBinding() {
        blockVM?.switchUpdated.subscribeSuccess({ [weak self] (isOn) in
            guard let self = self else { return }
            if isOn {
                self.showBlockConfirm.accept(())
            } else {
                self.disableBlock()
            }
        }).disposed(by: disposeBag)
        
        notifyVM?.switchUpdated.subscribeSuccess { [weak self] isOn in
            guard let self = self else { return }
            self.updateNotifyStatus(isOn: isOn)
        }.disposed(by: self.disposeBag)
        
        self.actionTapped.subscribeSuccess { [weak self] (action) in
            guard let self = self else { return }
            switch action {
            case .report:
                self.gotoReport.accept(())
            case .unfriend:
                self.unFriend.accept(self.friend.displayName)
            case .deleteHistory:
                self.deleteHistory.accept(())
            case .deleteAndLeave:
                self.leaverGroup.accept(())
            case .groupSetting:
                guard let groupID = self.friend.groupID, let targetModel = DataAccess.shared.getGroup(groupID: groupID) else {
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
                let transceivers = DataAccess.shared.getGroupObserver(by: groupID).transceiverDict.value.values.filter { $0.isMember == true }
                let sorted = transceivers.sorted { $0.joinAt?.timeIntervalSince1970 ?? 0 < $1.joinAt?.timeIntervalSince1970 ?? 0 }
                let vm = EditMemberViewControllerVM.init(type: .member, role: role, userInfo: sorted, groupID: groupID)
                self.goto.onNext(.editGroupMember(vm: vm))
            case .blockList:
                guard let groupID = self.friend.groupID else { return }
                let role = DataAccess.shared.getSelfGroupRole(groupID: groupID)
                let blockedUser = DataAccess.shared.getGroupBlockedTransceivers(by: groupID)
                let vm = EditMemberViewControllerVM.init(type: .block, role: role, userInfo: blockedUser, groupID: groupID)
                self.goto.onNext(.editGroupMember(vm: vm))
            default: break
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
    
    func didSelect(at indexPath: IndexPath) {
        if let vm = vmList[indexPath.section][indexPath.item] as? ChatDetailActionProtocol {
            vm.actionTapped.onNext(vm.actionType ?? .none)
        }
    }
    
    func deleteHistoryRecord(completion: ((Bool) -> Void)? = nil) {
        guard let groupID = friend.groupID else { return }
        showLoading.accept(true)
        DataAccess.shared.clearGroupMessages(groupID: groupID) { [weak self] isFinish in
            self?.showLoading.accept(false)
            completion?(isFinish)
        }
    }
    
    func leaveGroup(completion: ((Bool, String?) -> Void)? = nil) {
        guard let groupID = friend.groupID, let userID = UserData.shared.userID else { return }
        showLoading.accept(true)
        // 先刪除訊息後, 再離開群組
        DataAccess.shared.clearGroupMessages(groupID: groupID) { _ in
            DataAccess.shared.fetchLeaveGroup(groupID, userID) { [weak self] isLeft, error in
                self?.showLoading.accept(false)
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
    
    func unfriend(completion: ((Bool) -> Void)? = nil) {
        showLoading.accept(true)
        DataAccess.shared.removeContact(contactID: friend.id) { [weak self] (isSuccess) in
            self?.showLoading.accept(false)
            completion?(isSuccess)
        }
    }
    
    func getReportViewModel() -> ReportViewControllerVM? {
        switch style {
        case .group:
            return ReportViewControllerVM(groupID: friend.id, userID: "")
        default:
            return ReportViewControllerVM(userID: friend.id)
        }
    }
}

private extension InfoSettingViewControllerVM {
    
    func setNotify(isOn: Bool) {
        notifyVM?.isOn.accept(isOn)
    }
    
    func updateNotifyStatus(isOn: Bool) {
        guard let groupID = friend.groupID else {
            return
        }
        
        if case .group = style {
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
    
    func fetchGroupAuth() {
        guard let groupID = friend.groupID, let ownerID = friend.ownerID else {
            return
        }
        
        self.showLoading.accept(true)

        DataAccess.shared.fetchGroupPermission(with: groupID, ownerID: ownerID) { [weak self] userRole in
            guard let self = self, let userRole = userRole else {
                self?.showLoading.accept(false)
                return
            }
            
            self.vmList.removeAll()
            self.vmList.append([self.notifyVM, self.reportVM])
            
            let authList = self.getAuthSettingList(groupID: groupID, role: userRole)
            if !authList.isEmpty {
                self.vmList.append(authList)
            }
            
            self.vmList.append([self.deleteHistoryVM, self.deleteNLeaveVM])
            self.reload.accept(())
            self.showLoading.accept(false)
        }
    }
    
    func getAuthSettingList(groupID: String, role: UserRoleModel) -> [BaseTableViewCellVM] {
        guard role.type == .owner || role.type == .admin else { return [] }

        var authCellVM = [BaseTableViewCellVM]()
        if role.permission.inviteUsers {
            authCellVM.append(SettingMoreCellVM(with: Localizable.joinMembers, actionType: .addMember, icon: "iconIconUserAdd"))
        }
        
        if role.permission.changeGroupInfo {
            let cellVM = SettingMoreInfoCellVM(with: Localizable.groupSettings, actionType: .groupSetting, info: "")
            DataAccess.shared.getGroupConversationDataSource(by: groupID)?.detail?.settingOnCount.map { return String(format: "%ld/4", $0) }.bind(to: cellVM.info).disposed(by: self.disposeBag)
            authCellVM.append(cellVM)
        }
        
        if role.type == .admin || role.type == .owner {
            let cellVM = SettingMoreInfoCellVM(with: Localizable.admin, actionType: .administrator, info: "")
            DataAccess.shared.getGroupConversationDataSource(by: groupID)?.detail?.adminIds.map { return "\($0.count + 1)" }.bind(to: cellVM.info).disposed(by: self.disposeBag)
            authCellVM.append(cellVM)
        }
        
        if role.permission.banUsers {
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
extension InfoSettingViewControllerVM {
    func updateFriendData() {
        NotificationCenter.default.post(name: Notification.Name(FriendModel.updateFriendModelNotification + friend.id), object: nil, userInfo: ["data": friend])
    }
    
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
        DataAccess.shared.fetchBlockUser(userID: friend.id) { [weak self] (isSuccess)  in
            guard let self = self else { return }
            self.showLoading.accept(false)
            guard isSuccess else {
                self.setBlock(on: false)
                return
            }
            self.setBlock(on: true)
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
        }
    }
}

// MARK: - Setup TableView
extension InfoSettingViewControllerVM {
    func numberOfSections() -> Int { vmList.count }
    func numberOfRow(in section: Int) -> Int { vmList[section].count }
    func cellViewModel(in indexPath: IndexPath) -> BaseTableViewCellVM? { vmList[indexPath.section][indexPath.item] }
    func heightForRow(in indexPath: IndexPath) -> CGFloat { 56 }
}
