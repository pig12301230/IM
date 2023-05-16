//
//  AddFriendViewControllerVM.swift
//  ChatRoom
//
//  Created by Andy Yang on 2021/6/24.
//

import Foundation
import RxSwift
import RxCocoa

class AddFriendViewControllerVM {
    
    private var disposeBag = DisposeBag()
    var searchVM: SearchViewModel = SearchViewModel(config: SearchViewConfig(placeHolder: Localizable.idSearchHint))
    let currentSearchStr: PublishRelay<SearchResultView.SearchStatus> = PublishRelay()
    let goto: PublishRelay<Navigator.Scene> = PublishRelay()
    let showErrorMsg: PublishRelay<String> = PublishRelay()
    let showSearchFailToast: PublishRelay<String> = PublishRelay()
    let isLoading: PublishRelay<Bool> = PublishRelay()
    
    let currentAccountStr: String = String(format: Localizable.myIdIOS, UserData.shared.userInfo?.username ?? "")
    
    init() {
        initBinding()
    }
        
    func setDefaultSearchStatus() {
        search(searchStr: nil)
    }
    
    func initBinding() {
        searchVM.searchString.skip(1).distinctUntilChanged().subscribeSuccess { [weak self] searchStr in
            guard let self = self else { return }
            self.search(searchStr: searchStr)
        }.disposed(by: disposeBag)
        
        searchVM.doSearch.observe(on: MainScheduler.instance).subscribeSuccess { [weak self] searchStr in
            guard let self = self else { return }
            self.searchNewContact(searchStr: searchStr)
        }.disposed(by: disposeBag)
    }
    
    func searchNewContact(searchStr: String?) {
        guard let searchStr = searchStr, searchStr != "" else { return }
        guard !isSelfUserName(input: searchStr),
              !isSelfPhone(input: searchStr) else {
            showErrorMsg.accept(Localizable.cantAddSelf)
            return
        }
        isLoading.accept(true)
        
        DataAccess.shared.fetchNewUserContact(searchStr) { [weak self] contact in
            guard let self = self else { return }
            self.isLoading.accept(false)
            
            guard let contact = contact else {
                // 搜尋不到
                self.currentSearchStr.accept(SearchResultView.SearchStatus(isSearching: false,
                                                                           searchStr: Localizable.accountNotFount))
                return
            }
            
            if DataAccess.shared.isFriend(with: contact.id) {
                // 好友名單成員
                let friendModel = FriendModel.convertContactToFriend(contact: contact)
                let vm = ChatDetailViewControllerVM.init(data: friendModel, style: .friendListToPerson)
                self.goto.accept(.chatDetail(vm: vm))
            } else if let blockedModel = DataAccess.shared.getBlocked(userID: contact.id) {
                // 黑名單成員
                let friendModel = FriendModel.converBlockedToFriend(blocked: blockedModel)
                let vm = ChatDetailViewControllerVM.init(data: friendModel, style: .blockedListToPerson)
                self.goto.accept(.chatDetail(vm: vm))
            } else {
                // 非黑名單 且 非好友名單
                let vm = ChatDetailViewControllerVM(data: FriendModel.convertContactToFriend(contact: contact),
                                                    style: .searchNewContact)
                self.goto.accept(.chatDetail(vm: vm))
            }
        }
    }
    
    func search(searchStr: String?) {
        guard let searchStr = searchStr, searchStr != "" else {
            currentSearchStr.accept(SearchResultView.SearchStatus(isSearching: false,
                                                                  searchStr: currentAccountStr))
            return
        }
        currentSearchStr.accept(SearchResultView.SearchStatus(isSearching: true,
                                                              searchStr: String(format: Localizable.searchWithColonIOS, searchStr)))
    }
    
    private func isSelfUserName(input: String?) -> Bool {
        guard let input = input else { return false }
        return input == UserData.shared.userInfo?.username
    }
    
    private func isSelfPhone(input: String?) -> Bool {
        guard let input = input else { return false }
        return input == UserData.shared.userInfo?.phone
    }
}
