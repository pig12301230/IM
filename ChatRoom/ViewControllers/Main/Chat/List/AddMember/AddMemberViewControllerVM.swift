//
//  AddMemberViewControllerVM.swift
//  ChatRoom
//
//  Created by Winston_Chuang on 2022/1/19.
//

import Foundation
import RxSwift
import RxRelay

enum AddMemberType {
    case createGroup
    case addFriend
    case addAdmin
    case addBlacklist
    
    var maxLimit: Int {
        switch self {
        case .createGroup, .addFriend:
            return 2000
        case .addBlacklist:
            return 50
        default:
            return 1
        }
    }
    
    var title: String {
        switch self {
        case .createGroup, .addFriend:
            return Localizable.addMembers
        case .addBlacklist:
            return Localizable.groupBlacklistSetting
        case .addAdmin:
            return Localizable.groupAddAdmin
        }
    }
    
    var groupName: String {
        switch self {
        case .createGroup, .addFriend:
            return Localizable.friend
        case .addBlacklist, .addAdmin:
            return Localizable.groupMembers
        }
    }
    
    var selectedEmptyInfo: String? {
        switch self {
        case .createGroup, .addFriend:
            return Localizable.addMembersHint
        case .addBlacklist, .addAdmin:
            return nil
        }
    }
    
    var exceedAlert: String {
        switch self {
        case .createGroup, .addFriend:
            return Localizable.exceedTheLimitGroupMembers
        case .addBlacklist:
            return Localizable.exceedTheLimitBlacklist
        default:
            return ""
        }
    }
}

struct MemberSection {
    var title: String
    var members: [FriendModel]
}

class AddMemberViewControllerVM {
    let searchVM: SearchViewModel = SearchViewModel()
    var currentMemeberList: [FriendModel] = []
    private(set) var memberList: [MemberSection] = []
    private var defaultMembers: [FriendModel] = []
    
    let selectedMemberList: BehaviorRelay<[FriendModel]> = .init(value: [])
    let addSelectedMember: PublishSubject<FriendModel> = .init()
    let removeSelectedMember: PublishSubject<FriendModel> = .init()
    let reloadData: PublishSubject<Void> = .init()
    let alertMessage: PublishSubject<String> = .init()
    let showError: PublishSubject<String> = .init()
    let showLoading: BehaviorRelay<Bool> = .init(value: false)
    let dissmissVC: PublishSubject<Void> = .init()
    let navigateToCreateGroup: PublishSubject<Void> = .init()
    
    private(set) var isSearching: Bool = false
    private(set) var mySelfData: FriendModel?
    private(set) var blockedTransceivers: [TransceiverModel] = []
    private(set) var type: AddMemberType
    private(set) var groupID: String?
    private let disposeBag = DisposeBag()
    var selectedViewHeight: Int {
        if type.selectedEmptyInfo == nil && selectedMemberList.value.isEmpty {
            return 0
        }
        
        return 84
    }
    
    /// ViewModel的初始化
    /// - Parameters:
    ///   - type:  目前有三種 `CreatGroup`, `Invite Friend`,  `AddBlacklist`
    ///   - members: 已存在群組內的成員
    init(type: AddMemberType, members: [FriendModel] = [], groupID: String? = nil) {
        self.type = type
        self.groupID = groupID
        
        switch type {
        case .createGroup:
            getContactList()
        case .addFriend:
            currentMemeberList = members
            getGroupBlackList()
            getContactList()
        case .addBlacklist:
            setBlackList(members: members)
        case .addAdmin:
            setGroupMemberListWithAdmin(members: members)
        }
        
        addSelectedMember.subscribeSuccess { [unowned self] member in
            var list = selectedMemberList.value
            list.append(member)
            selectedMemberList.accept(list)
        }.disposed(by: disposeBag)
        
        removeSelectedMember.subscribeSuccess { [unowned self] member in
            var list = selectedMemberList.value
            if let index = list.firstIndex(where: { $0.id == member.id }) {
                list.remove(at: index)
                selectedMemberList.accept(list)
            }
        }.disposed(by: disposeBag)
        
        setupSearch()
    }
    
    func nextAction() {
        switch type {
        case .createGroup:
            self.navigateToCreateGroup.onNext(())
        case .addFriend:
            let message = parseAlertMessage()
            self.alertMessage.onNext(message)
        case .addBlacklist:
            let message = parseAlertMessage()
            self.alertMessage.onNext(message)
        default:
            break
        }
    }
    
    func confirmAction() {
        switch type {
        case .addFriend:
            self.addMembers()
        case .addBlacklist:
            self.addBlockedMember()
        default:
            break
        }
    }
    
    // 顯示 邀請/黑名單 的訊息
    private func parseAlertMessage() -> String {
        var str: String = ""
        let selectedList = selectedMemberList.value
        for (index, value) in selectedList.enumerated() {
            if index == 0 {
                str = value.displayName
                continue
            }
            if index >= 3 {
                let other = String(format: Localizable.andOtherPeopleIOS, String(selectedList.count - 3))
                str = str.appending(other)
                break
            }
            str = "\(str), \(value.displayName)"
        }
        var groupName: String = ""
        if let groupID = groupID,
           let group = DataAccess.shared.getGroup(groupID: groupID) {
            groupName = group.display
        }
        if case .addBlacklist = self.type {
            return "\(String(format: Localizable.willJoinBlacklistIOS, str))\n\(Localizable.joinTheBlacklistWillBeRemoveFormTheGroup)"
        } else {
            return String(format: Localizable.isAddMembersToGroupIOS, str, groupName)
        }
    }
    
    private func addMembers() {
        let userList: [String] = self.selectedMemberList.value.map { $0.id }
        guard let groupId = self.groupID else { return }
        
        showLoading.accept(true)
        DataAccess.shared.addGroupMembers(groupId, userList) { [weak self] result in
            self?.showLoading.accept(false)
            if result {
                self?.dissmissVC.onNext(())
            } else {
                self?.showError.onNext(Localizable.serverUnknown)
            }
        }
    }
    
    private func addBlockedMember() {
        let userList: [String] = self.selectedMemberList.value.map { $0.id }
        
        guard let groupId = self.groupID else { return }
        
        showLoading.accept(true)
        DataAccess.shared.addGroupBlockedMembers(groupId, usersID: userList) { [weak self] result in
            self?.showLoading.accept(false)
            if result {
                self?.dissmissVC.onNext(())
            } else {
                self?.showError.onNext(Localizable.serverUnknown)
            }
        }
    }
    
    private func getGroupBlackList() {
        guard let groupID = self.groupID else {
            return
        }
        blockedTransceivers = DataAccess.shared.getGroupObserver(by: groupID).transceiverDict.value.values
            .filter { $0.blocked }
    }
    
    private func getContactList() {
        DataAccess.shared.getContacts { [weak self] contacts in
            guard let self = self else { return }
            let members = contacts.compactMap { FriendModel.convertContactToFriend(contact: $0) }
                .filter { contact in
                    return !self.blockedTransceivers.contains(where: { $0.userID == contact.id })
                }
            self.defaultMembers = members.sorted(by: { $0.displayName < $1.displayName })
            let section = members.groupedByName().compactMap { MemberSection(title: $0.key, members: $0.value) }
            
            let sortedSections = self.sortKeyByAToZToDigits(sections: section)
            
            self.mySelfData = members.first(where: { $0.id == UserData.shared.userInfo?.id })
            self.memberList = sortedSections
            self.reloadData.onNext(())
        }
    }
    
    private func setBlackList(members: [FriendModel]) {
        self.defaultMembers = members.sorted(by: { $0.displayName < $1.displayName })
        let section = members.groupedByName().compactMap { MemberSection(title: $0.key, members: $0.value) }
        let sortedSections = self.sortKeyByAToZToDigits(sections: section)

        self.memberList = sortedSections
        
        self.reloadData.onNext(())
    }
    
    private func setGroupMemberListWithAdmin(members: [FriendModel]) {
        self.defaultMembers = members.filter { $0.id != UserData.shared.userInfo?.id }.sorted(by: { $0.displayName < $1.displayName })
        let section = members.groupedByName().compactMap { MemberSection(title: $0.key, members: $0.value) }
        let sortedSections = self.sortKeyByAToZToDigits(sections: section)
        self.memberList = sortedSections
        self.reloadData.onNext(())
    }
    
    private func sortKeyByAToZToDigits(sections: [MemberSection]) -> [MemberSection] {
        return sections.sorted(by: { cur, next in
            if cur.title == AppConfig.GlobalProperty.sectionNumberSign {
                return false
            }
            if next.title == AppConfig.GlobalProperty.sectionNumberSign {
                return true
            }
            return cur.title < next.title
        })
    }
    
    // 取得 memberList 的 IndexPath
    func getFriendIndexPath(member: FriendModel) -> IndexPath? {
        for (sectionIndex, section)  in memberList.enumerated() {
            for (rowIndex, row) in section.members.enumerated() where row.id == member.id {
                return IndexPath(row: rowIndex, section: sectionIndex)
            }
        }
        return nil
    }
    
    // 檢查是否已經在名單內
    func isAlreadyInList(member: FriendModel) -> Bool {
        return currentMemeberList.contains(where: { $0.id == member.id }) || mySelfData?.id == member.id
    }
    
    func getFriendModel(section: Int, row: Int) -> FriendModel? {
        guard section < memberList.count else { return nil }
        let members = memberList[section].members
        guard row < members.count else { return nil }
        return members[row]
    }
    
    func needCheckBox() -> Bool {
        return self.type != .addAdmin
    }
    
    func getNextScene(at indexPath: IndexPath) -> Navigator.Scene? {
        guard type == .addAdmin else { return nil }
        guard let groupID = groupID, let model = getFriendModel(section: indexPath.section, row: indexPath.row) else { return nil }
        
        guard let transceiver = DataAccess.shared.getGroupObserver(by: groupID).transceiverDict.value.values.first(where: { $0.userID == model.id }) else {
            return nil
        }
        
        let authVM = AuthSettingViewControllerVM.init(type: .addAdmin, model: transceiver, allowSetting: true)
        return .authSetting(vm: authVM)
    }
}

// MARK: - search
fileprivate extension AddMemberViewControllerVM {
    func setupSearch() {
        searchVM.searchString.skip(1).distinctUntilChanged().subscribeSuccess { [weak self] searchStr in
            guard let self = self else { return }
            self.search(searchStr: searchStr)
        }.disposed(by: disposeBag)
    }
    
    func search(searchStr: String?) {
        // set back to default
        guard let searchStr = searchStr?.lowercased(), !searchStr.isEmpty else {
            isSearching = false
            _ = defaultMembers.map { $0.searchStr = nil }
            memberList = defaultMembers.groupedByName().compactMap { MemberSection(title: $0.key, members: $0.value) }
            memberList = sortKeyByAToZToDigits(sections: memberList)

            reloadData.onNext(())
            return
        }
        
        let filterMember = defaultMembers
            .filter { member in
                if member.displayName.lowercased().contains(searchStr) {
                    member.searchStr = searchStr
                    return true
                }
                return false
            }
        
        isSearching = true
        memberList = [MemberSection(title: "", members: filterMember)]
        reloadData.onNext(())
    }
}
