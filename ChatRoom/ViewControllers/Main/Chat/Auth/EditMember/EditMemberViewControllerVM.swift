//
//  EditMemberViewControllerVM.swift
//  ChatRoom
//
//  Created by ZoeLin on 2022/1/22.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

enum EditMemberType {
    case member
    case admin
    case block
    
    var title: String {
        switch self {
        case .member:
            return Localizable.member
        case .admin:
            return Localizable.groupAdmin
        case .block:
            return Localizable.groupBlacklistSetting
        }
    }
    
    var countFormat: String? {
        switch self {
        case .member:
            return Localizable.membersCountAndroid
        case .admin:
            return nil
        case .block:
            return Localizable.groupBlacklistMembersCountAndroid
        }
    }
    
    var removeFormat: String {
        switch self {
        case .member:
            return Localizable.deleteMemberFromGroupAndroid
        case .admin:
            return Localizable.removeAdminMessageAndroid
        case .block:
            return Localizable.deleteMemberFromBlacklistAndroid
        }
    }
    
    var hintMessage: String? {
        switch self {
        case .member:
            return nil
        case .admin:
            return Localizable.groupAdminHint
        case .block:
            return Localizable.groupBlacklistSettingHint
        }
    }
    
    var limitMember: Int {
        switch self {
        case .member:
            return 2000
        case .admin:
            return 15
        case .block:
            return 50
        }
    }
    
    var limitMessage: String {
        switch self {
        case .member:
            return Localizable.exceedTheLimitGroupMembers
        case .admin:
            return Localizable.exceedTheLimitAdmins
        case .block:
            return Localizable.exceedTheLimitBlacklist
        }
    }
    
    var backButtonIcon: String {
        switch self {
        case .member:
            return "iconArrowsChevronLeft"
        default:
            return "iconIconCross"
        }
    }
}

class EditMemberViewControllerVM: BaseViewModel {
    
    var disposeBag = DisposeBag()
    let countViewHight: CGFloat
    let showHintView: Bool
    private let addCellHight: CGFloat = 60
    private var modelCellHight: CGFloat
    private(set) var isEditing: Bool = false
    private(set) var canSearch: Bool = false
    private(set) var canAdd: Bool = false
    private(set) var canRemove: Bool = false
    private(set) var editType: EditMemberType
    private(set) var memberCellVMs = [MemberTableViewCellVM]() {
        didSet {
            updateMemberCountDisplayString()
            isEmptyResult.accept(memberCellVMs.isEmpty)
        }
    }
    private(set) var originalCellVMs = [MemberTableViewCellVM]()
    
    private(set) var searchVM: SearchViewModel
    private(set) var isSearchMode: Bool = false
    private(set) var groupID: String
    
    let isLoading = BehaviorRelay<Bool>(value: false)
    let reloadView = PublishSubject<Void>()
    let showAlert = PublishSubject<String>()
    let countText = BehaviorRelay<String>(value: "")
    let isEmptyResult = BehaviorRelay<Bool>(value: false)
    
    init(type: EditMemberType, role: UserRoleModel, userInfo: [TransceiverModel], groupID: String) {
        self.editType = type
        self.modelCellHight = type == .admin ? 72 : 60
        self.countViewHight = type == .admin ? 0 : 44
        self.showHintView = type != .member
        self.canSearch = type == .member
        self.searchVM = SearchViewModel.init(config: SearchViewConfig(placeHolder: Localizable.searchMemberName, underLineTheme: Theme.c_08_black_10))
        self.groupID = groupID
        
        switch type {
        case .member:
            canAdd = role.permission.inviteUsers
            canRemove = role.permission.removeUsers
            originalCellVMs = userInfo.sorted { $0.joinAt?.timeIntervalSince1970 ?? 0 < $1.joinAt?.timeIntervalSince1970 ?? 0 }.compactMap { MemberTableViewCellVM.init(model: $0, type: type) }
        case .admin:
            canAdd = role.permission.addAdmins
            canRemove = role.type == .owner
            originalCellVMs = userInfo.sorted { $0.joinAt?.timeIntervalSince1970 ?? 0 < $1.joinAt?.timeIntervalSince1970 ?? 0 }.enumerated().compactMap { MemberTableViewCellVM.init(model: $0.1, role: $0.0 == 0 ? .owner : .admin, type: type) }
        case .block:
            canAdd = role.permission.banUsers
            // Always show edit button
            canRemove = role.permission.banUsers
            originalCellVMs = userInfo.compactMap { MemberTableViewCellVM.init(model: $0, type: type) }
        }
        
        if canAdd {
            originalCellVMs.insert(MemberTableViewCellVM(addType: type), at: 0)
        }
        
        originalCellVMs.last?.leading = 0
        memberCellVMs = originalCellVMs
        
        super.init()
        self.updateMemberCountDisplayString()
        self.initBinding()
    }
    
    func cellHeight(at idnex: Int) -> CGFloat {
        guard canAdd else {
            return modelCellHight
        }
        
        return idnex == 0 ? addCellHight: modelCellHight
    }
    
    func changeEditStatus() {
        self.isEditing.toggle()
    }
    
    func cellCanEdit(at index: Int) -> Bool {
        guard canRemove, let config = getMemberCellVM(at: index) else {
            return false
        }
        
        return config.allowEdit
    }
    
    func deleteMessage(at index: Int) -> String {
        let message = String(format: editType.removeFormat, getMemberCellVM(at: index)?.transceiver?.display ?? "")
        return message
    }
    
    func delete(at index: Int) {
        guard let cellConfig = getMemberCellVM(at: index) else {
            return
        }
        
        switch editType {
        case .member:
            guard let transceiver = cellConfig.transceiver else { return }
            self.isLoading.accept(true)
            DataAccess.shared.deleteGroupMember(transceiver.groupID, transceiver.userID) { [weak self] isSuccess, _ in
                guard let self = self else { return }
                self.isLoading.accept(false)
                guard isSuccess else { return }
                self.removeMemberFromList(with: transceiver.userID)
                self.reloadView.onNext(())
            }
        case .admin:
            guard let transceiver = cellConfig.transceiver else { return }
            self.isLoading.accept(true)
            DataAccess.shared.deleteGroupAdmin(groupID: transceiver.groupID, userID: transceiver.userID) { [weak self] isSuccess in
                self?.isLoading.accept(false)
                guard isSuccess, let self = self else { return }
                self.removeMemberFromList(with: transceiver.userID)
                self.reloadView.onNext(())
            }
        case .block:
            guard let transceiver = cellConfig.transceiver else { return }
            self.isLoading.accept(true)
            DataAccess.shared.removeGroupBlockedMember(transceiver.groupID, userID: transceiver.userID) { [weak self] isSuccess in
                guard let self = self else { return }
                self.isLoading.accept(false)
                guard isSuccess else { return }
                self.removeMemberFromList(with: transceiver.userID)
                self.reloadView.onNext(())
            }
        }
    }
    
    private func getMemberCellVM(at index: Int) -> MemberTableViewCellVM? {
        guard memberCellVMs.count > index else {
            return nil
        }
        
        return memberCellVMs[index]
    }
}

private extension EditMemberViewControllerVM {
    func initBinding() {
        // skip 1 because init function will do the first time setup.
        DataAccess.shared.getGroupObserver(by: groupID).transceiverDict.skip(1).subscribeSuccess { [weak self] transceivers in
            guard let self = self else { return }
            switch self.editType {
            case .member:
                let userInfo = transceivers.values.filter { $0.isMember }
                    .sorted { $0.joinAt?.timeIntervalSince1970 ?? 0 < $1.joinAt?.timeIntervalSince1970 ?? 0 }
                
                self.originalCellVMs = userInfo.compactMap { MemberTableViewCellVM.init(model: $0, type: self.editType) }
            case .block:
                let userInfo = transceivers.values.filter { $0.blocked }
                    .sorted { $0.joinAt?.timeIntervalSince1970 ?? 0 < $1.joinAt?.timeIntervalSince1970 ?? 0 }
                
                self.originalCellVMs = userInfo.compactMap { MemberTableViewCellVM.init(model: $0, type: self.editType) }
                
            case .admin:
                // admin update by group's admin list, not transceiver list
                return
            }
            
            if self.canAdd {
                self.originalCellVMs.insert(MemberTableViewCellVM(addType: self.editType), at: 0)
            }
            
            self.originalCellVMs.last?.leading = 0
            self.memberCellVMs = self.originalCellVMs
            
            self.reloadView.onNext(())
        }.disposed(by: disposeBag)
        
        if case .admin = self.editType {
            DataAccess.shared.getGroupConversationDataSource(by: groupID)?.detail?.adminIds.skip(1).distinctUntilChanged().subscribeSuccess { [weak self] _ in
                guard let self = self else { return }
                let transceivers = DataAccess.shared.getGroupOwnerAndAdmins(groupID: self.groupID)
                self.originalCellVMs = transceivers.enumerated().compactMap { MemberTableViewCellVM.init(model: $0.1, role: $0.0 == 0 ? .owner : .admin, type: .admin) }
                
                if self.canAdd {
                    self.originalCellVMs.insert(MemberTableViewCellVM(addType: self.editType), at: 0)
                }
                
                self.originalCellVMs.last?.leading = 0
                self.memberCellVMs = self.originalCellVMs
                self.reloadView.onNext(())
            }.disposed(by: disposeBag)
        }
        
        guard self.canSearch else {
            self.isSearchMode = false
            return
        }
        
        self.searchVM.searchString.skip(1).distinctUntilChanged().subscribeSuccess { [weak self] (searchText) in
            guard let self = self else { return }
            self.isSearchMode = searchText.count > 0
            self.updateSectionSearchText(text: searchText)
        }.disposed(by: self.disposeBag)
    }
    
    func updateSectionSearchText(text: String) {
        guard !text.isEmpty else {
            memberCellVMs = originalCellVMs.filter { $0.isFitSearchContent(key: text) }
            reloadView.onNext(())
            return
        }
        
        memberCellVMs = originalCellVMs.filter { $0.isFitSearchContent(key: text) }
        reloadView.onNext(())
    }
    
    func removeMemberFromList(with userID: String) {
        self.originalCellVMs.removeAll { $0.transceiver?.userID == userID }
        self.memberCellVMs.removeAll { $0.transceiver?.userID == userID }
    }
    
    func updateMemberCountDisplayString() {
        guard let format = editType.countFormat else { return }
        
        let currentCount = memberCellVMs.count
        guard !isSearchMode else {
            countText.accept(String(format: format, "\(currentCount)"))
            return
        }
        
        let effectCount = canAdd ? currentCount - 1 : currentCount
        countText.accept(String(format: format, "\(effectCount)"))
    }
}

extension EditMemberViewControllerVM: SettingViewModelProtocol {
    typealias CellConfig = MemberTableViewCellVM
    
    var cellTypes: [SettingCellType] {
        return [.icon, .iconDescription]
    }
    
    func numberOfRows() -> Int {
        return memberCellVMs.count
    }
    
    func cellIdentifier(at index: Int) -> String {        
        guard case .admin = self.editType else {
            return SettingCellType.icon.cellIdentifier
        }
        
        guard index == 0, canAdd else {
            return SettingCellType.iconDescription.cellIdentifier
        }
                
        return SettingCellType.icon.cellIdentifier
    }
    
    func cellConfig(at index: Int) -> CellConfig {
        guard let cellConfig = getMemberCellVM(at: index) else {
            return MemberTableViewCellVM(addType: editType)
        }
        
        return cellConfig
    }
    
    func getScene(at index: Int) -> Navigator.Scene? {
        // block type, won't open user info view
        if canAdd, index == 0 {
            if (memberCellVMs.count - 1) == editType.limitMember {
                showAlert.onNext(editType.limitMessage)
                return nil
            }
            
            switch editType {
            case .member:
                let members = memberCellVMs
                    .compactMap { $0.transceiver }
                    .map { FriendModel.converTransceiverToFriend(transceiver: $0) }
                return .addMember(type: .addFriend, members: members, groupID: groupID)
            case .admin:
                let trans = DataAccess.shared.getGroupObserver(by: groupID).transceiverDict.value.values
                let admins = memberCellVMs.compactMap { $0.transceiver }
                let nonAdminTransceivers = trans.filter { transceiver in
                    transceiver.isMember == true && !admins.contains { $0.userID == transceiver.userID }
                }.compactMap { FriendModel.converTransceiverToFriend(transceiver: $0) }
                return .addMember(type: .addAdmin, members: nonAdminTransceivers, groupID: groupID)
            case .block:
                let trans = DataAccess.shared.getGroupObserver(by: groupID).transceiverDict.value.values
                let blocked = memberCellVMs.compactMap { $0.transceiver?.userID }
                let nonBlockedTransceiver = trans.filter { transceiver in
                    transceiver.userID != UserData.shared.userInfo?.id && !blocked.contains(transceiver.userID)
                }.compactMap { FriendModel.converTransceiverToFriend(transceiver: $0) }                
                return .addMember(type: .addBlacklist, members: nonBlockedTransceiver, groupID: groupID)
            }
        }
        
        if case .block = editType {
            return nil
        }
        
        guard let cellConfig = getMemberCellVM(at: index), let transceiver = cellConfig.transceiver else {
            // Add Action
            return nil
        }
        
        switch editType {
        case .admin:
            guard !cellConfig.isOwner else {
                return nil
            }
            
            let vm = AuthSettingViewControllerVM.init(type: .admin, model: transceiver, allowSetting: canRemove)
            return .authSetting(vm: vm)
        case .member:
            let model = FriendModel.converTransceiverToFriend(transceiver: transceiver)
            let vm = ChatDetailViewControllerVM.init(data: model, style: .chatToGroupMember)
            return .chatDetail(vm: vm)
        case .block:
            return nil
        }
    }
}
