//
//  SelectFriendChatViewControllerVM.swift
//  ChatRoom
//
//  Created by Andy Yang on 2021/6/30.
//

import Foundation
import RxSwift
import RxCocoa

class SelectFriendChatViewControllerVM {
    private var disposeBag = DisposeBag()
    
    let reloadData = PublishSubject<Void>()
    let isLoading: PublishRelay<Bool> = PublishRelay()
    let goto: PublishRelay<Navigator.Scene> = PublishRelay()
    let showEmptyView: PublishRelay<Bool> = PublishRelay()

    private var friends: [String: [FriendModel]] = [:]
    private var defaultFriends: [String: [FriendModel]] = [:]
    private var vmList: [[FriendListCellVM]] = []
    private var sectionList: [IndexSectionHeaderViewVM] = []
    private var sectionIndex: [String] = []
    
    let searchVM: SearchViewModel = SearchViewModel.init()
    var isSearching: Bool = false

    init() {
        initBinding()
        getFriendList()
    }
}

// MARK: - table view
extension SelectFriendChatViewControllerVM {
    func numberOfSections() -> Int {
        sectionIndex.count
    }
    
    func numberOfItem(in section: Int) -> Int {
        guard section < vmList.count else { return 0 }
        return vmList[section].count
    }
    
    func cellViewModel(at indexPath: IndexPath) -> FriendListCellVM? {
        guard indexPath.item < vmList[indexPath.section].count else { return nil }
        return vmList[indexPath.section][indexPath.item]
    }
    
    func sectionViewModel(in section: Int) -> IndexSectionHeaderViewVM? {
        guard section < sectionList.count else { return nil }
        return sectionList[section]
    }
    
    func sectionIndexTitle() -> [String]? {
        sectionIndex
    }
    
    func heightForHeader(in section: Int) -> CGFloat {
        36
    }
    
    func heightForRow(at indexPath: IndexPath) -> CGFloat {
        60
    }
    
    func didSelect(at indexPath: IndexPath) {
        guard indexPath.section < vmList.count,
              indexPath.item < vmList[indexPath.section].count,
              let userID = vmList[indexPath.section][indexPath.item].friend?.id else { return }
        guard let group = getConversationGroup(userID: userID) else {
            createDirectConversation(userID: userID,
                                     displayName: vmList[indexPath.section][indexPath.item].friend?.displayName ?? "")
            return
        }
        gotoConversation(group: group)
    }
}

// MARK: - private
private extension SelectFriendChatViewControllerVM {
    func initBinding() {
        searchVM.searchString.observe(on: MainScheduler.instance).subscribeSuccess { [weak self] searchStr in
            guard let self = self else { return }
            self.search(searchStr: searchStr)
        }.disposed(by: disposeBag)
    }
    
    func handleVMListData(needReload: Bool = true) {
        vmList = []
        sectionIndex = []
        sectionList = []
        
        for (key, value) in sortByAToZToDigits(dict: defaultFriends) {
            sectionIndex.append(key)
            sectionList.append(IndexSectionHeaderViewVM(with: key))
            vmList.append(value.sorted(by: { $0.displayName < $1.displayName }).compactMap { FriendListCellVM(friend: $0) })
        }
        
        if needReload {
            reloadData.onNext(())
        }
    }
    
    func sortByAToZToDigits(dict: [String: [FriendModel]]) -> [Dictionary<String, [FriendModel]>.Element] {
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
    
    func getFriendList() {
        DataAccess.shared.getContacts { [weak self] (contactList) in
            guard let self = self else { return }
            self.defaultFriends = self.parseToSectionData(list: contactList.compactMap { FriendModel.convertContactToFriend(contact: $0) })
            self.friends = self.defaultFriends
            self.handleVMListData()
        }
    }
    
    func parseToSectionData(list: [FriendModel]) -> [String: [FriendModel]] {
        var sectionDict: [String: [FriendModel]] = [:]
        for friend in list {
            var prefix = String(friend.displayName.prefix(1)).uppercased()
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
    
    func search(searchStr: String?) {
        // set back to default
        handleVMListData(needReload: false)
        
        guard let searchStr = searchStr?.lowercased(), !searchStr.isEmpty else {
            isSearching = false
            showEmptyView.accept(vmList.count == 0)
            reloadData.onNext(())
            vmList.forEach { $0.forEach { $0.friend?.searchStr = nil } }
            return
        }
        
        isSearching = true
        var tobeRemoveIdx: [Int] = []
        
        for (index, vm) in vmList.enumerated() {
            let filterData = vm.filter({ data in
                data.friend?.searchStr = searchStr
                return data.friend?.displayName.lowercased().contains(searchStr) ?? false
            })
            vmList[index] = filterData
            if filterData.isEmpty {
                tobeRemoveIdx.append(index)
            }
        }
        
        tobeRemoveIdx.reversed().forEach {
            vmList.remove(at: $0)
            sectionIndex.remove(at: $0)
            sectionList.remove(at: $0)
        }
        
        showEmptyView.accept(vmList.count == 0 ? true : false)
        reloadData.onNext(())
    }
    
    func getConversationGroup(userID: String) -> GroupModel? {
        return isSelf(userID: userID) ? DataAccess.shared.getSelfDMConversation(id: userID) : DataAccess.shared.getDirectConversation(userID)
    }
    
    func createDirectConversation(userID: String, displayName: String) {
        DataAccess.shared.createDirectConversation(with: userID, displayName: displayName).subscribeSuccess { [weak self] group in
            guard let self = self else { return }
            self.gotoConversation(group: group)
        }.disposed(by: disposeBag)
    }
    
    func gotoConversation(group: GroupModel) {
        guard let dataSource = DataAccess.shared.getGroupConversationDataSource(by: group.id) else {
            return
        }
        let vm = ConversationViewControllerVM(with: dataSource)
        goto.accept(.conversation(vm: vm))
    }
    
    func isSelf(userID: String) -> Bool {
        guard let selfID = UserData.shared.userID else { return false }
        return userID == selfID
    }
}
