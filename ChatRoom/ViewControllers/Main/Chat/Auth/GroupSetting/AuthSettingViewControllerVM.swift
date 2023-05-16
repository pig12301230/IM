//
//  AuthSettingViewControllerVM.swift
//  ChatRoom
//
//  Created by ZoeLin on 2022/1/20.
//

import Foundation
import RxSwift
import RxCocoa

enum AuthOption: String, CaseIterable, OptionTypeProtocol {
    case sendMessages = "can_send_messages"
    case sendImages = "can_send_images"
    case sendHyperlinks = "can_send_hyperlink"
    case inviteUsers = "can_invite_users"
    case addAdmins = "can_add_admins"
    case removeUsers = "can_remove_users"
    case banUsers = "can_ban_users"
    case changeGroupInfo = "can_change_group_info"
    case canAddFriend = "can_add_friend"
    
    var key: String {
        return self.rawValue
    }
    
    var title: String {
        switch self {
        case .sendMessages:
            return Localizable.sendMessages
        case .sendImages:
            return Localizable.sendImages
        case .sendHyperlinks:
            return Localizable.sendHyperlink
        case .inviteUsers:
            return Localizable.inviteUsers
        case .addAdmins:
            return Localizable.groupAddAdmin
        case .removeUsers:
            return Localizable.removeGroupMember
        case .banUsers:
            return Localizable.blockList
        case .changeGroupInfo:
            return Localizable.modifyGroupProfile
        case .canAddFriend:
            return Localizable.clickAvatarToAddFriend
        }
    }
    
    var onConfirmMessage: String? {
        return nil
    }
    
    var offConfirmMessage: String? {
        return nil
    }
    
    func isEqual(to: OptionTypeProtocol) -> Bool {
        return self.key == to.key
    }
}

enum AuthSettingType {
    case group
    case admin
    case addAdmin
    
    var title: String {
        switch self {
        case .group:
            return Localizable.groupSettings
        case .admin, .addAdmin:
            return Localizable.adminSettings
        }
    }
    
    var editImmediately: Bool {
        switch self {
        case .group:
            return true
        case .admin, .addAdmin:
            return false
        }
    }
    
    var canEdit: Bool {
        switch self {
        case .group:
            return true
        case .admin, .addAdmin:
            return false
        }
    }
    
    var backgroundTheme: Theme {
        switch self {
        case .group:
            return Theme.c_07_neutral_50
        case .admin, .addAdmin:
            return Theme.c_07_neutral_0
        }
    }
    
    var authOptions: [AuthOption] {
        switch self {
        case .group:
            return [.sendMessages, .sendImages, .sendHyperlinks, .inviteUsers]
        case .admin, .addAdmin:
            return [.removeUsers, .banUsers, .changeGroupInfo, .addAdmins, .canAddFriend]
        }
    }
    
    var authHint: String {
        switch self {
        case .group:
            return Localizable.whatCanMembersOfThisGroupDo
        case .admin, .addAdmin:
            return Localizable.whatIsAdminCanDo
        }
    }
    
    var defautIcon: String {
        switch self {
        case .group:
            return "oval"
        case .admin, .addAdmin:
            return "avatarsPhoto"
        }
    }
    
    var backButtonIcon: String {
        switch self {
        case .group:
            return "iconArrowsChevronLeft"
        case .admin, .addAdmin:
            return "iconIconCross"
        }
    }
    
    var useDefaultValue: Bool {
        switch self {
        case .group, .admin:
            return false
        case .addAdmin:
            return true
        }
    }
    
    var popTarget: AnyClass? {
        switch self {
        case .group, .admin:
            return nil
        case .addAdmin:
            return EditMemberViewController.self
        }
    }
}

class AuthSettingViewControllerVM: BaseViewModel, SettingStatusVMProtocol {
    typealias Option = AuthOption
    
    var disposeBag = DisposeBag()
    let cellOptions: [AuthOption]
    private(set) var cellVMs = [TitleSwitchTableViewCellVM]()
    
    let execOnAction = PublishSubject<TitleSwitchTableViewCellVM.OptionType>()
    let execOffAction = PublishSubject<TitleSwitchTableViewCellVM.OptionType>()
    let showLoading = PublishRelay<Bool>()
    let reload = PublishSubject<Void>()
    let popView = PublishSubject<Void>()
    
    let targetName = BehaviorRelay<String>(value: "")
    let targetThumbnail = BehaviorRelay<String>(value: "")
    
    private(set) var allowSetting: Bool = false
    private(set) var authSettingType: AuthSettingType = .group
    private(set) var memberRole: UserRoleModel?
    private var currentUserRole: UserRoleModel?
    
    private(set) var targetModel: AuthTargetPotocol? {
        didSet {
            if let val = targetModel {
                targetName.accept(val.display)
                targetThumbnail.accept(val.thumbnail)
            }
        }
    }
    
    init(type: AuthSettingType, model: AuthTargetPotocol, allowSetting: Bool = true) {
        self.allowSetting = allowSetting
        self.cellOptions = type.authOptions
        self.authSettingType = type
        self.targetModel = model
        switch type {
        case .group:
            self.memberRole = DataAccess.shared.getGroupMemberRole(groupID: model.targetID)
        case .admin, .addAdmin:
            // admin tyep model's targetID = groupID_userID
            self.memberRole = DataAccess.shared.getGroupUserRole(targetID: model.targetID)
            if let selfID = UserData.shared.userID {
                let currentUserTargetID = model.targetGroupID + "_" + selfID
                self.currentUserRole = DataAccess.shared.getGroupUserRole(targetID: currentUserTargetID)
            }
        }
        super.init()
        self.setupViewModel()
    }
    
    private func setupViewModel() {
        self.targetThumbnail.accept(self.targetModel?.thumbnail ?? "")
        self.targetName.accept(self.targetModel?.display ?? "")
        self.setupViewModels()
        self.initBinding()
    }
    
    func uploadIcon(_ image: UIImage) {
        guard case .group = authSettingType, let model = targetModel else {
            return
        }
            
        showLoading.accept(true)
        DataAccess.shared.uploadGroupIcon(groupID: model.targetID, image: image) { [weak self] thumbnail in
            self?.showLoading.accept(false)
            self?.targetThumbnail.accept(thumbnail ?? "")
        }
    }
    
    func executeAuthSetting() {
        guard !authSettingType.editImmediately else {
            return
        }
        
        guard let model = targetModel, let trans = model as? TransceiverModel else {
            return
        }
        
        let parameter = self.getSettingParameters()
        self.showLoading.accept(true)
        
        if case .admin = authSettingType {
            DataAccess.shared.setGroupAdminPermissions(groupID: trans.groupID, userID: trans.userID, parameter: parameter) { [weak self] isSuccess in
                self?.showLoading.accept(false)
                self?.popView.onNext(())
                if !isSuccess {
                    self?.resetStatus()
                }
            }
        } else if case .addAdmin = authSettingType {
            DataAccess.shared.addGroupAdmin(groupID: trans.groupID, userID: trans.userID, permissions: parameter) { [weak self] _ in
                guard let self = self else { return }
                self.showLoading.accept(false)
                self.popView.onNext(())
            }
        }
    }
    
    // MARK: - SettingStatusVMProtocol
    func cellViewModel(at index: Int) -> TitleSwitchTableViewCellVM? {
        guard self.cellVMs.count > index else {
            return nil
        }
        
        return self.cellVMs[index]
    }
    
    func cancelAction(_ option: TitleSwitchTableViewCellVM.OptionType) {
        if let cellVM = self.cellVMs.first(where: { $0.option.isEqual(to: option) }) {
            cellVM.cancelAction()
        }
    }
    
    func confiromExecAction(_ option: TitleSwitchTableViewCellVM.OptionType) {
        if let cellVM = self.cellVMs.first(where: { $0.option.isEqual(to: option) }) {
            cellVM.execAction(cellVM.config.notify.value)
        }
    }
    
    func getEnable(_ option: Option) -> Bool {
        // 群組設定: 若傳文字訊息為off, 則傳送圖片及超連結的開關為 disabled
        if authSettingType == .group {
            guard let model = memberRole else { return false }
            switch option {
            case .sendImages, .sendHyperlinks:
                return model.permission.sendMessages
            default:
                return true
            }
        }
        
        guard let model = currentUserRole else { return false }
        if authSettingType == .admin, model.type != .owner { return false }
        
        var setting: Bool = false
        switch option {
        case .sendMessages:
            setting = model.permission.sendMessages
        case .sendImages:
            setting = model.permission.sendImages
        case .sendHyperlinks:
            setting = model.permission.sendHyperlinks
        case .inviteUsers:
            setting = model.permission.inviteUsers
        case .addAdmins:
            setting = model.permission.addAdmins
        case .removeUsers:
            setting = model.permission.removeUsers
        case .banUsers:
            setting = model.permission.banUsers
        case .changeGroupInfo:
            setting = model.permission.changeGroupInfo
        case .canAddFriend:
            setting = model.permission.canAddFriend
        }
        
        return setting
    }
    
    func getStatus(_ option: Option) -> NotifyType {
        guard !authSettingType.useDefaultValue else {
            switch option {
            case .canAddFriend:
                return .off
            default:
                return getEnable(option) ? .on : .off
            }
        }
        
        guard let model = memberRole else { return .off }
        
        var setting: Bool = false
        switch option {
        case .sendMessages:
            setting = model.permission.sendMessages
        case .sendImages:
            setting = model.permission.sendImages
        case .sendHyperlinks:
            setting = model.permission.sendHyperlinks
        case .inviteUsers:
            setting = model.permission.inviteUsers
        case .addAdmins:
            setting = model.permission.addAdmins
        case .removeUsers:
            setting = model.permission.removeUsers
        case .banUsers:
            setting = model.permission.banUsers
        case .changeGroupInfo:
            setting = model.permission.changeGroupInfo
        case .canAddFriend:
            setting = model.permission.canAddFriend
        }
        
        return setting == true ? .on : .off
    }
    
    func modifyStatus(_ option: Option, isOn: Bool) {
        guard let model = targetModel, authSettingType.editImmediately else {
            return
        }
        
        switch authSettingType {
        case .group:
            let parameter = [option.key: isOn]
            self.showLoading.accept(true)
            DataAccess.shared.setGroupMemberPermissions(groupID: model.targetID, parameter: parameter) { [weak self] isSuccess in
                self?.showLoading.accept(false)
                if !isSuccess {
                    self?.cancelAction(option)
                }
            }
        default:
            break
        }
    }
    
}

private extension AuthSettingViewControllerVM {
    func initBinding() {
        self.execOnAction.subscribeSuccess { [unowned self] option in
            guard let option = option as? Option else { return }
            self.modifyStatus(option, isOn: true)
        }.disposed(by: self.disposeBag)

        self.execOffAction.subscribeSuccess { [unowned self] option in
            guard let option = option as? Option else { return }
            self.modifyStatus(option, isOn: false)
        }.disposed(by: self.disposeBag)
        
        
        guard let model = targetModel else {
            return
        }
        
        if case .group = authSettingType {
            DataAccess.shared.getGroupObserver(by: model.targetID).groupObserver.observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] model in
                self.targetModel = model
            }.disposed(by: self.disposeBag)

            DataAccess.shared.getGroupConversationDataSource(by: model.targetID)?.detail?.settingOnCount.skip(1).subscribeSuccess { [unowned self] _ in
                self.memberRole = DataAccess.shared.getGroupMemberRole(groupID: model.targetID)
                self.setupViewModels()
                self.reload.onNext(())
            }.disposed(by: disposeBag)
        }        
    }
    
    func setupViewModels() {
        self.cellVMs.removeAll()
        
        for enumerate in cellOptions.enumerated() {
            let option = self.cellConfig(at: enumerate.offset)
            let cellVM = TitleSwitchTableViewCellVM.init(config: option, option: enumerate.element, enable: allowSetting)
            if self.authSettingType.editImmediately {
                cellVM.output.execOnAction.bind(to: self.execOnAction).disposed(by: self.disposeBag)
                cellVM.output.execOffAction.bind(to: self.execOffAction).disposed(by: self.disposeBag)
            }
            self.cellVMs.append(cellVM)
        }
    }
    
    func getSettingParameters() -> [String: Any] {
        var parameter = [String: Any]()
        for cellVM in self.cellVMs {
            parameter[cellVM.option.key] = cellVM.config.notify.value
        }
        
        return parameter
    }
    
    func resetStatus() {
        cellOptions.forEach { option in
            if let cellVM = self.cellVMs.first(where: { $0.option.isEqual(to: option) }) {
                if cellVM.config.notify != self.getStatus(option) {
                    cellVM.cancelAction()
                }
            }
        }
        
    }
}

extension AuthSettingViewControllerVM: SettingViewModelProtocol {
    var cellTypes: [SettingCellType] {
        return [.titleSwitch]
    }
    
    func numberOfRows() -> Int {
        return cellOptions.count
    }
    
    func cellIdentifier(at index: Int) -> String {
        SettingCellType.titleSwitch.cellIdentifier
    }
    
    func cellConfig(at index: Int) -> NotifyCellConfig {
        let option = cellOptions[index]
        let notify = self.getStatus(option)
        let isEnable = self.getEnable(option)
        let leading: CGFloat = index == cellOptions.count - 1 ? 0 : 16
        return NotifyCellConfig(leading: leading, title: option.title, notify: notify, onConfirm: option.onConfirmMessage, offConfirm: option.offConfirmMessage, isEnable: isEnable)
    }
    
    func getScene(at index: Int) -> Navigator.Scene? {
        return nil
    }
    
}
