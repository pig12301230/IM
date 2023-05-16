//
//  FriendListViewControllerVM.swift
//  ChatRoom
//
//  Created by ERay_Peng on 2022/3/23.
//

import RxSwift
import RxCocoa

enum ListSection: Int {
    case group = 0
    case friend = 1
    
    var collapseKey: String {
        switch self {
        case .group:
            return "groupListCollapseKey"
        case .friend:
            return "friendListCollapseKey"
        }
    }
    
    var title: String {
        switch self {
        case .group:
            return Localizable.group
        case .friend:
            return Localizable.friend
        }
    }
}

class FriendListViewControllerVM: SearchListViewControllerVM {
    let loading: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    
    private(set) var friendSectionVM: TitleSectionViewModel!
    private(set) var groupSectionVM: TitleSectionViewModel!
    private var cacheSearchingTxt: String = ""
    
    var sectionList: [ListSection] = [.group, .friend]
    var sectionViewData: [FriendListMainHeaderVM] {
        var data: [FriendListMainHeaderVM] = []
        for section in sectionList {
            var isCollapsable: Bool
            switch section {
            case .group:
                isCollapsable = groupSectionVM.cellViewModels.count != 0
            case .friend:
                isCollapsable = friendSectionVM.originalCellVMs.count != 0
            }
            let vm = FriendListMainHeaderVM(section: section,
                                            title: section.title,
                                            collapsable: isCollapsable)
            data.append(vm)
        }
        return data
    }
    
    override init() {
        super.init(.friendList)
        UserDefaults.standard.set(false, forKey: ListSection.group.collapseKey)
        UserDefaults.standard.set(false, forKey: ListSection.friend.collapseKey)
    }
    
    override func didSelectRow(at indexPath: IndexPath) {
        guard let sectionVM = self.sectionViewModel(in: indexPath.section) else {
            return
        }
        
        guard self.isSearchMode else {
            guard let cellVM = sectionVM.originalCellVMsWithAlphabetical[indexPath.row] as? NameTableViewCellVM else { return }
            self.didSelectFriend(with: cellVM)
            return
        }

        // 進入好友列表
        guard let list = sectionVM.cellViewModels as? [NameTableViewCellVM] else {
            return
        }
        
        guard sectionVM.cellCount == 4, indexPath.row == 3 else {
            guard list.count > indexPath.row else {
                PRINT("did select row do Action -> List length Error", cate: .error)
                return
            }
            self.didSelectFriend(with: list[indexPath.row])
            return
        }
        
        // 查看更多
        let type: TitleSectionViewModel.SectionType = sectionVM.displayType == .searchFriend ? .friendList : .groupList
        let vm = SearchListViewControllerVM.init(list: list, searchKey: self.searchVM.searchString.value, type: type)
        self.goto.onNext(.searchList(vm: vm))
        return
    }
    
    override func initBinding() {
        super.initBinding()
        
        DataAccess.shared.groupListLoadedFinished.subscribeSuccess { [unowned self] in
            self.getGroupData()
        }.disposed(by: self.disposeBag)
        
        DataAccess.shared.contactListUpdate.subscribeSuccess { [unowned self] in
            self.getContactData()
        }.disposed(by: self.disposeBag)
        
        DataAccess.shared.dismissGroup.observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] _ in
            self.getGroupData()
        }.disposed(by: self.disposeBag)
        
        DataAccess.shared.groupListInfoObserver.observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] (action, group) in
            self.groupListInfoUpdate(action: action, info: group)
        }.disposed(by: self.disposeBag)
    }
    
    override func parserDataAfterFilter() {
        self.sortedSectionVM.removeAll()
        if let groupVM = self.groupSectionVM, let friendVM = self.friendSectionVM {
            if self.isSearchMode {
                var isEmpty = true
                
                if groupVM.cellCount > 0 {
                    self.groupSectionVM.section = self.sortedSectionVM.count
                    self.sortedSectionVM.append(groupVM)
                    isEmpty = false
                }
                
                if friendVM.cellCount > 0 {
                    self.friendSectionVM.section = self.sortedSectionVM.count
                    self.sortedSectionVM.append(friendVM)
                    isEmpty = false
                }
                
                self.showEmptyView.accept((isEmpty, .noSearchResults))
            } else {
                self.groupSectionVM.section = self.sortedSectionVM.count
                self.sortedSectionVM.append(self.groupSectionVM)

                self.friendSectionVM.section = self.sortedSectionVM.count
                self.sortedSectionVM.append(self.friendSectionVM)
                
                self.showEmptyView.accept((groupVM.originalCellVMs.count == 0 && friendVM.originalCellVMs.count == 0, .noSearchResults))
            }
        } else { self.showEmptyView.accept((true, .noSearchResults)) }
    }
    
    override func updateSectionSearchText(text: String) {
        self.cacheSearchingTxt = text
        if let gViewModel = self.groupSectionVM {
            gViewModel.searchText(with: text)
        }

        if let fViewModel = self.friendSectionVM {
            fViewModel.searchText(with: text)
        }

        self.finishLoad()
        super.updateSectionSearchText(text: text)
    }
    
    // 非搜尋狀態下 header view
    func withoutSearchingSectionViewModel(in section: Int) -> BaseSectionVM? {
        return sectionViewData[section]
    }
    
    override func finishLoad() {
        super.finishLoad()
        self.loading.accept(false)
    }
    
    override func fetchFriendList() {
//        DataAccess.shared.groupListLoadedFinished.subscribeSuccess { [unowned self] in
//            self.getGroupData()
//        }.disposed(by: self.disposeBag)
//
//        DataAccess.shared.contactListUpdate.subscribeSuccess { [unowned self] in
//            self.getContactData()
//        }.disposed(by: self.disposeBag)
    }
    
    func groupListInfoUpdate(action: DataAction, info: GroupModel) {
        guard let sectionVM = self.groupSectionVM else { return }
        
        switch action {
        case .add, .delete:
            guard info.hidden == false else {
                return
            }
            self.getGroupData()
            self.getContactData()
            self.reloadData.onNext(())
        case .update:
            // 搜尋狀態下 view model
            guard let cellViewModel = sectionVM.originalCellVMs.first(where: { $0.pramryKey == info.id }) else { return }
            
            cellViewModel.updateGroupMemberCount(info.memberCount)
            
            // 非搜尋狀態下 view model
            sectionVM.originalCellVMsWithAlphabetical.forEach { viewModel in
                
                guard let cellVM = viewModel as? NameTableViewCellVM else { return }
                if cellVM.pramryKey == info.id {
                    cellVM.updateGroupMemberCount(info.memberCount)
                }
            }
            self.reloadData.onNext(())
        default:
            break
        }
    }
}

// MARK: - fetch new data
private extension FriendListViewControllerVM {
    func getContactData() {
        DataAccess.shared.getContacts(sortedByAZ09: true) { [weak self] (contacts) in
            guard let self = self else { return }
            self.covertFriendCellViewModel(contacts)
        }
    }
    
    func getGroupData() {
        self.convertGroupCellViewModel(DataAccess.shared.getGroupConversation(sortedByAZ09: true, includeHidden: true))
    }
}

// MARK: - common Function
private extension FriendListViewControllerVM {
    func updateEmptyView() {
        guard self.isSearchMode else {
            self.showEmptyView.accept((self.groupSectionVM.originalCellVMs.count == 0 && self.friendSectionVM.originalCellVMs.count == 0, .noSearchResults))
            return
        }
        
        let isEmpty = self.friendSectionVM.cellCount == 0 && self.groupSectionVM.cellCount == 0
        self.showEmptyView.accept((isEmpty, .noSearchResults))
    }
}

// MARK: - contacts function
private extension FriendListViewControllerVM {
    func convertGroupCellViewModel(_ data: [GroupModel]) {
        let originalCellVMsList = data.compactMap { NameTableViewCellVM.init(with: .groupDetail(group: $0)) }
        let groupDict = self.parseToSectionData(list: data)
        var groupModels: [BaseTableViewCellVM] = []
        for (key, value) in sortKeyByAToZToDigits(dict: groupDict) {
            groupModels.append(IndexListCellVM(data: key))
            for model in value {
                groupModels.append(NameTableViewCellVM.init(with: .groupDetail(group: model)))
            }
        }
        self.groupSectionVM = TitleSectionViewModel.init(with: .groupList, originalCellVMs: originalCellVMsList, cellVMs: groupModels)
        // group update observe到時，會重新拿 data，若在搜尋狀態下把 text丟回去
        if self.isSearchMode {
            self.groupSectionVM.searchText(with: self.cacheSearchingTxt)
        }
        self.bindGroupSectionViewModel()
        self.checkLoading()
    }
    
    func covertFriendCellViewModel(_ data: [ContactModel]) {
        var friendModels: [BaseTableViewCellVM] = []
        let friendDict = self.parseToSectionData(list: data)
        for (key, value) in self.sortKeyByAToZToDigits(dict: friendDict) {
            friendModels.append(IndexListCellVM(data: key))
            for model in value {
                let cellVM = NameTableViewCellVM.init(with: .contactDetail(contact: model))
                friendModels.append(cellVM)
            }
        }
        let vmList = data.compactMap { NameTableViewCellVM.init(with: .contactDetail(contact: $0)) }
        self.friendSectionVM = TitleSectionViewModel.init(with: .friendList, originalCellVMs: vmList, cellVMs: friendModels)
        // contact update observe到時，若在搜尋狀態下把 text丟回去
        if self.isSearchMode {
            self.friendSectionVM.searchText(with: self.cacheSearchingTxt)
        }
        self.bindFriendSectionViewModel()
        self.checkLoading()
    }
    
    func checkLoading() {
        if self.friendSectionVM != nil, self.groupSectionVM != nil {
            self.showEmptyView.accept((self.groupSectionVM.cellCount == 0 && self.friendSectionVM.cellCount == 0, .noSearchResults))
            self.finishLoad()
        }
    }
    
    func bindGroupSectionViewModel() {
        self.groupSectionVM.reloadData.observe(on: MainScheduler.instance).subscribeSuccess { [weak self] _ in
            guard let self = self else { return }
            self.reloadData.onNext(())
        }.disposed(by: disposeBag)
        self.groupSectionVM.sortUpdated.subscribeSuccess { [weak self] in
            guard let self = self, !self.isSearchMode else { return }
            self.reloadData.onNext(())
        }.disposed(by: self.disposeBag)
    }

    func bindFriendSectionViewModel() {
        self.friendSectionVM.reloadData.observe(on: MainScheduler.instance).subscribeSuccess { [weak self] _ in
            guard let self = self else { return }
            self.reloadData.onNext(())
        }.disposed(by: disposeBag)
        self.friendSectionVM.sortUpdated.subscribeSuccess { [weak self] in
            guard let self = self, !self.isSearchMode else { return }
            self.reloadData.onNext(())
        }.disposed(by: self.disposeBag)
    }
    
    func parseToSectionData<T: DataPotocol>(list: [T]) -> [String: [T]] {
        var sectionDict: [String: [T]] = [:]
        for friend in list {
            var prefix = String(friend.display.prefix(1)).uppercased()
            if prefix.isIncludeChinese() {
                prefix = String(prefix.convertChineseToPinYin().prefix(1)).uppercased()
            }
            
            // 數字歸類到 '#' section
            if prefix.isDigit() {
                prefix = AppConfig.GlobalProperty.sectionNumberSign
            }
            
            if sectionDict[prefix] == nil {
                sectionDict[prefix] = [friend]
            } else {
                sectionDict[prefix]?.append(friend)
            }
        }
        return sectionDict
    }
    
    func sortKeyByAToZToDigits<T: DataPotocol>(dict: [String: [T]]) -> [Dictionary<String, [T]>.Element] {
        return dict.sorted(by: { cur, next in
            if cur.key == AppConfig.GlobalProperty.sectionNumberSign {
                return false
            }
            if next.key == AppConfig.GlobalProperty.sectionNumberSign {
                return true
            }
            return cur.key < next.key
        })
    }
}
