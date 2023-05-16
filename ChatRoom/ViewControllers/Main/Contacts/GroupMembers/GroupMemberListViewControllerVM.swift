//
//  GroupMemberListViewControllerVM.swift
//  ChatRoom
//
//  Created by Andy Yang on 2021/6/7.
//

import Foundation
import RxSwift
import RxCocoa

enum FromWhere {
    case friendList
    case chat
    case search
}

class GroupMemberListViewControllerVM {
    
    private var disposeBag = DisposeBag()
    let reloadData = PublishSubject<Void>()
    let isLoading: BehaviorRelay<Bool> = BehaviorRelay(value: true)
    let showEmptyView: PublishRelay<Bool> = PublishRelay()

    private var friends: [FriendModel] = []
    private let defaultVMList: [FriendListCellVM]
    var vmList: [FriendListCellVM]
    let fromWhere: FromWhere
    
    let searchVM: SearchViewModel
    private var isSearching: Bool = false
    
    init(fromWhere: FromWhere, friends: [FriendModel], searchStr: String?) {
        var defaultKey = ""
        if case .search = fromWhere {
            isSearching = true
            defaultKey = searchStr ?? ""
        }
        searchVM = SearchViewModel.init(config: .init(underLine: true,
                                                      defaultKey: defaultKey,
                                                      placeHolder: Localizable.searchMemberName))
        self.friends = friends.sorted(by: { $0.joinAt ?? Date() < $1.joinAt ?? Date() })
        defaultVMList = self.friends.compactMap { FriendListCellVM(friend: $0) }
        self.vmList = defaultVMList
        self.fromWhere = fromWhere
        self.initBinding()
    }
    
    func detailViewModel(at indexPath: IndexPath) -> ChatDetailViewControllerVM? {
        guard let vm = cellViewModel(indexPath: indexPath), let friend = vm.friend else { return nil }
        switch fromWhere {
        case .chat:
            return ChatDetailViewControllerVM(data: friend,
                                              style: .chatToGroupMember)
        case .friendList:
            return ChatDetailViewControllerVM(data: friend,
                                              style: .friendListToGroupMember)
        case .search:
            return ChatDetailViewControllerVM(data: friend,
                                              style: friend.isGroup ? .friendListToGroup : .friendListToPerson)
        }
    }
    
    func title() -> String {
        switch fromWhere {
        case .chat, .friendList: return Localizable.member
        case .search: return Localizable.friendsList
        }
    }
}
// MARK: - search
private extension GroupMemberListViewControllerVM {
    func initBinding() {
        searchVM.searchString.skip(1).distinctUntilChanged().subscribeSuccess { [weak self] searchStr in
            guard let self = self else { return }
            self.search(searchStr: searchStr)
        }.disposed(by: disposeBag)
    }
    
    func search(searchStr: String?) {
        
        // set back to default
        vmList = defaultVMList
        
        guard let searchStr = searchStr?.lowercased(), !searchStr.isEmpty else {
            _ = defaultVMList.map { $0.friend?.searchStr = nil }
            vmList = defaultVMList
            isSearching = false
            showEmptyView.accept(false)
            reloadData.onNext(())
            return
        }
        isSearching = true
        vmList = vmList.filter({ data in
            if data.friend?.displayName.lowercased().contains(searchStr) == true {
                data.friend?.searchStr = searchStr
                return true
            }
            return false
        })
        showEmptyView.accept(vmList.count == 0 ? true : false)
        reloadData.onNext(())
    }
}

// MARK: - tableview
extension GroupMemberListViewControllerVM {
    func numberOfSection() -> Int {
        1
    }
    
    func numberOfRow(in section: Int) -> Int {
        return vmList.count
    }
    
    func cellViewModel(indexPath: IndexPath) -> FriendListCellVM? {
        guard indexPath.item < vmList.count else { return nil }
        return vmList[indexPath.item]
    }
    
    func heightForRow(at indexPath: IndexPath) -> CGFloat {
        60
    }
    
    func heightForHeader(in section: Int) -> CGFloat {
        44
    }
    
    func titleForHeader(in section: Int) -> String? {
        switch fromWhere {
        case .chat, .friendList:
            return Localizable.member + "\(vmList.count)"
        case .search:
            return friends.first?.isGroup == true ? Localizable.group : Localizable.friend
        }
    }
}
