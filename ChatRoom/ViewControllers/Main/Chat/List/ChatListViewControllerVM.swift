//
//  ChatListViewControllerVM.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/5/3.
//

import RxSwift
import RxCocoa

public class ChatListViewControllerVM: SearchListViewControllerVM {
    let deleteRow = PublishSubject<IndexPath>()
    let insertRow = PublishSubject<IndexPath>()
    let loading: BehaviorRelay<Bool> = BehaviorRelay(value: true)
    
    private(set) var conversationSectionVM: TitleSectionViewModel!
    private(set) var friendSectionVM: TitleSectionViewModel!
    private(set) var groupSectionVM: TitleSectionViewModel!
    
    private var cacheSearchingTxt: String = ""
    
    public override init() {
        super.init(.chatList)
        showEmptyView.accept((true, .noConversation))
    }
    
    override func didSelectRow(at indexPath: IndexPath) {
        guard self.isSearchMode else {
            self.showConversation(at: indexPath)
            return
        }
        
        guard let sectionVM = self.sectionViewModel(in: indexPath.section) else {
            return
        }
        
        // 進入好友列表
        if sectionVM.displayType == .searchFriend || sectionVM.displayType == .searchGroup {
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
        
        guard let cellVM = self.cellViewModel(in: indexPath) as? RecordTableViewCellVM else {
            PRINT("did select row do Action Error", cate: .error)
            return
        }
        
        self.didSelectRecord(with: cellVM)
    }

    func deleteGroup(at indexPath: IndexPath) {
        guard let cellVM = self.cellViewModel(in: indexPath) as? CellTypeProtocol else {
            return
        }
        let groupID = cellVM.cellType.primaryKey
        
        DataAccess.shared.deleteGroupMessages(groupID: groupID)
        DataAccess.shared.setupLastSyncTimeTo(groupID: groupID)
    }
    
    func getUserMe(completion: (() -> Void)? = nil) {
        DataAccess.shared.fetchUserMe()
            .subscribeOn(finished: {
                completion?()
            })
            .disposed(by: disposeBag)
    }
    
    func resetReadingConversation() {
        DataAccess.shared.lastReadingConversation.accept("")
    }
    
    func isMute(indexPath: IndexPath) -> Bool {
        guard let cellVM = self.cellViewModel(in: indexPath) as? CellTypeProtocol else {
            return false
        }
        
        switch cellVM.cellType {
        case .record(group: let group):
            return group.notifyType == .off
        default:
            return false
        }
    }

    func muteGroup(indexPath: IndexPath, mute: Bool) {
        guard let cellVM = self.cellViewModel(in: indexPath) as? CellTypeProtocol else {
            return
        }
        
        DataAccess.shared.setGroupNotify(groupID: cellVM.cellType.primaryKey, mute: mute)
    }
    
    override func initBinding() {
        super.initBinding()
        
        self.getConversationData()
        self.getUserNicknames()
        
        DataAccess.shared.dismissGroup.observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] identifier in
            self.groupListDelete(identifier: identifier)
        }.disposed(by: self.disposeBag)
        
        DataAccess.shared.groupListInfoObserver.observe(on: MainScheduler.instance).subscribeSuccess { [weak self] (action, rGroup) in
            guard let self = self else { return }
            self.groupListInfoUpdate(action: action, info: rGroup)
        }.disposed(by: self.disposeBag)
        
        // MARK: - data update finished
        DataAccess.shared.groupListLoadedFinished.subscribeSuccess { [unowned self] in
            self.getConversationData()
            self.getGroupData()
        }.disposed(by: self.disposeBag)
        
        DataAccess.shared.contactListUpdate.subscribeSuccess { [unowned self] in
            self.getContactData()
        }.disposed(by: self.disposeBag)
        
        NetworkManager.websocketStatus
            .skip(1)
            .distinctUntilChanged()
            .bind { [weak self] status in
                guard let self = self else { return }
                switch status {
                case .connected:
                    // 重連後更新斷線期間 unread count
                    self.refetchChatList()
                default:
                    break
                }
            }.disposed(by: self.disposeBag)
    }
    
    override func parserDataAfterFilter() {
        self.sortedSectionVM.removeAll()
        guard self.isSearchMode else {
            if let groupVM = self.conversationSectionVM, groupVM.originalCellVMs.count > 0 {
                self.conversationSectionVM.section = self.sortedSectionVM.count
                self.sortedSectionVM.append(self.conversationSectionVM)
                self.showEmptyView.accept((self.conversationSectionVM.originalCellVMs.count == 0, .noConversation))
            }
            return
        }

        var isEmpty = true
        
        if let friendVM = self.friendSectionVM, friendVM.cellCount > 0 {
            self.friendSectionVM.section = self.sortedSectionVM.count
            self.sortedSectionVM.append(friendVM)
            isEmpty = false
        }
        
        if let groupVM = self.groupSectionVM, groupVM.cellCount > 0 {
            self.groupSectionVM.section = self.sortedSectionVM.count
            self.sortedSectionVM.append(groupVM)
            isEmpty = false
        }
        
        if let conversationVM = self.conversationSectionVM, conversationVM.cellCount > 0 {
            self.conversationSectionVM.section = self.sortedSectionVM.count
            self.sortedSectionVM.append(conversationVM)
            isEmpty = false
        }
        
        self.showEmptyView.accept((isEmpty, .noSearchResults))
    }
    
    override func updateSectionSearchText(text: String) {
        self.cacheSearchingTxt = text
        if let cViewModel = self.conversationSectionVM {
            cViewModel.searchText(with: text)
            self.updateSearchTextForMessages(text: text)
        }
        
        if let gViewModel = self.groupSectionVM {
            gViewModel.searchText(with: text)
        }
        
        if let fViewModel = self.friendSectionVM {
            fViewModel.searchText(with: text)
        }
        
        self.finishLoad()
    }
    
    override func finishLoad() {
        super.finishLoad()
        self.loading.accept(false)
    }
    
    override func fetchChatList() {
        DataAccess.shared.fetchChatListNeededInformation()
//        DataAccessManager.shared.resetSendingMessageStatus()
//        DataAccessManager.shared.fetchBlockedList()
//        
//        DataAccessManager.shared.fetchGroupsAndContacts().observe(on: MainScheduler.instance).subscribeSuccess { (_, _) in
//            
//        }.disposed(by: self.disposeBag)
    }
    
    func refetchChatList() {
        DataAccess.shared.refetchChatList()
    }
}

// MARK: - fetch new data
private extension ChatListViewControllerVM {
    
    func getConversationData() {
        DataAccess.shared.getConversationModelsFromChatList { [weak self] (groups) in
            guard let self = self else { return }
            let newGroups = groups.filter { !$0.hidden }
            self.convertConversationCellViewModel(newGroups)
            if self.isSearchMode {
                self.updateSectionSearchText(text: self.cacheSearchingTxt)
            }
        }
    }
    
    func getContactData() {
        DataAccess.shared.getContacts(sortedByAZ09: true) { [weak self] (contacts) in
            guard let self = self else { return }
            self.convertFriendCellViewModel(contacts)
            if self.isSearchMode {
                self.updateSectionSearchText(text: self.cacheSearchingTxt)
            }
        }
    }
    
    func getGroupData(needSorted: Bool = true) {
        self.convertGroupCellViewModel(DataAccess.shared.getGroupConversation(sortedByAZ09: true))
        if self.isSearchMode {
            self.updateSectionSearchText(text: self.cacheSearchingTxt)
        }
    }
    
    func getUserNicknames() {
        DataAccess.shared.getUserNicknames()
    }
}

// MARK: - common Function
private extension ChatListViewControllerVM {
    func updateEmptyView() {
        guard self.isSearchMode else {
            self.showEmptyView.accept((self.conversationSectionVM.originalCellVMs.count == 0, .noConversation))
            return
        }
        
        let isEmpty = self.friendSectionVM.cellCount == 0 && self.groupSectionVM.cellCount == 0 && self.conversationSectionVM.cellCount == 0
        self.showEmptyView.accept((isEmpty, .noSearchResults))
    }
}

// MARK: - Group function
private extension ChatListViewControllerVM {
    
    func convertConversationCellViewModel(_ data: [GroupModel]) {
        var vmList: [ChatTableViewCellVM] = []
        data.forEach { (group) in
            vmList.append(ChatTableViewCellVM.init(with: .record(group: group)))
        }
        
        self.conversationSectionVM = TitleSectionViewModel.init(with: TitleSectionViewModel.SectionType.conversation, cellVMs: vmList)
        self.bindConversationSectionViewModel()
        self.checkLoading()
    }
    
    func bindConversationSectionViewModel() {
        self.conversationSectionVM.reloadData.observe(on: MainScheduler.instance).subscribeSuccess { [weak self] in
            guard let self = self else { return }
            self.reloadData.onNext(())
        }.disposed(by: disposeBag)
        self.conversationSectionVM.sortUpdated.subscribeSuccess { [weak self] in
            guard let self = self, !self.isSearchMode else {
                return
            }
            self.reloadData.onNext(())
        }.disposed(by: self.disposeBag)
    }
    
    func groupListDelete(identifier: String) {
        guard let gIndex = self.conversationSectionVM.deleteCellViewModelAt(by: identifier) else {
            return
        }
        
        self.deleteRow.onNext(IndexPath.init(row: gIndex, section: self.conversationSectionVM.section))
        self.updateEmptyView()
    }
    
    func groupListInfoUpdate(action: DataAction, info: GroupModel) {
        guard let sectionVM = self.conversationSectionVM else {
            return
        }
        
        switch action {
        case .add:
            // 如果已存在則更新, 避免重複insert造成 crash
            if let cellViewModel = sectionVM.originalCellVMs.first(where: { $0.pramryKey == info.id }) as? RecordTableViewCellVM {
                cellViewModel.setupByData(info)
                sectionVM.updateSortAfterInfoUpdate()
                return
            }
            
            guard info.hidden == false else {
                return
            }
            
            guard sectionVM.cellCount > 0 else {
                self.getConversationData()
                self.getGroupData()
                self.getContactData()
                return
            }
            
            guard let index = sectionVM.insertCellViewModelAt(vm: ChatTableViewCellVM.init(with: .record(group: info))) else {
                self.reloadData.onNext(())
                return
            }
            self.insertRow.onNext(IndexPath.init(row: index, section: sectionVM.section))
        case .update:
            guard let cellViewModel = sectionVM.originalCellVMs.first(where: { $0.pramryKey == info.id }) as? RecordTableViewCellVM else {
                return
            }
            
            cellViewModel.setupByData(info)
            sectionVM.updateSortAfterInfoUpdate()
        default:
            break
        }
    }

    func updateSearchTextForMessages(text: String) {
        /*
        self.conversationSectionVM.originalCellVMs.forEach { cellVM in
            guard let group = cellVM.cellType.data as? GroupModel, let dataSource = DataAccess.shared.groupDataSource[group.id] else {
                return
            }

            dataSource.searchingMessage(text: text)
        }*/
    }
}

// MARK: - contacts function
private extension ChatListViewControllerVM {
    func convertGroupCellViewModel(_ data: [GroupModel]) {
        let vmList = data.compactMap { NameTableViewCellVM.init(with: .group(group: $0)) }
        self.groupSectionVM = TitleSectionViewModel.init(with: TitleSectionViewModel.SectionType.searchGroup, cellVMs: vmList)
        self.checkLoading()
    }
    
    func convertFriendCellViewModel(_ data: [ContactModel]) {
        let vmList = data.compactMap { NameTableViewCellVM.init(with: .contact(contact: $0)) }
        self.friendSectionVM = TitleSectionViewModel.init(with: TitleSectionViewModel.SectionType.searchFriend, cellVMs: vmList)        
        self.checkLoading()
    }
    
    func checkLoading() {
        if self.conversationSectionVM != nil, self.friendSectionVM != nil, self.groupSectionVM != nil {
            self.showEmptyView.accept((self.conversationSectionVM.cellCount == 0, .noConversation))
            self.finishLoad()
        }
    }
}
