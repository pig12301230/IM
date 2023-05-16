//
//  SearchListViewControllerVM.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/5/28.
//

import RxSwift
import RxCocoa

public class SearchListViewControllerVM: ListViewControllerVM {
    enum ListType {
        case input
        case chatList
        case blockedList
        case friendList
        
        var title: String? {
            switch self {
            case .chatList:
                return Localizable.chat
            case .blockedList:
                return Localizable.blockList
            case .friendList:
                return Localizable.friendsList
            default:
                return nil
            }
        }
        
        var keepRefreshData: Bool {
            switch self {
            case .chatList, .friendList:
                return true
            default:
                return false
            }
        }
    }
    
    private(set) var searchVM: SearchViewModel!
    var isSearchMode: Bool = false
    var title: String? {
        return listType.title
    }
    private var listType: ListType = .input
    
    var reloadWhileAppear: Bool {
        return listType.keepRefreshData
    }
    
    override init() {
        self.searchVM = SearchViewModel.init()
        super.init()
        self.initBinding()
        self.fetchData()
    }
    
    init(_ type: ListType = .input) {
        self.searchVM = SearchViewModel.init()
        super.init()
        listType = type
        self.initBinding()
        self.fetchData()
    }
    
    init(list: [NameTableViewCellVM], searchKey: String, type: TitleSectionViewModel.SectionType) {
        super.init()
        self.isSearchMode = true
        self.searchVM = SearchViewModel.init(config: SearchViewConfig.init(underLine: true, defaultKey: searchKey))
        let sectionVM = TitleSectionViewModel.init(with: type, cellVMs: list)
        self.sortedSectionVM = [sectionVM]
        self.setupEmptyView(type: self.emptyType)
        self.initBinding()
    }
    
    override var emptyType: EmptyView.EmptyType {
        return .noSearchResults
    }
    
    func fetchData() {
        switch self.listType {
        case .blockedList:
            self.fetchBlockList()
        case .chatList:
            self.fetchChatList()
        case .friendList:
            self.fetchFriendList()
        default:
            break
        }
    }
    
    func fetchBlockList() {
        DataAccess.shared.getBlockedList { [weak self] contacts in
            guard let self = self else { return }
            
            self.sortedSectionVM.removeAll()
            
            for (key, value) in contacts {
                let cellVMs = value.compactMap { NameTableViewCellVM.init(with: .blocked(blocked: $0)) }
                let titleVM = TitleSectionViewModel.init(with: .friendList, tag: key, cellVMs: cellVMs)
                self.sortedSectionVM.append(titleVM)
            }
            
            self.reloadData.onNext(())
        }
    }
    
    func fetchChatList() {
        
    }
    
    func fetchFriendList() {
        
    }
    
    func initBinding() {
        self.searchVM.searchString.skip(1).distinctUntilChanged().subscribeSuccess { [unowned self] (searchText) in
            self.isSearchMode = searchText.count > 0
            self.updateSectionSearchText(text: searchText)
        }.disposed(by: self.disposeBag)
        
        guard self.listType == .blockedList else {
            return
        }
        
        DataAccess.shared.blockedListUpdate.subscribeSuccess { [unowned self] _ in
            self.fetchBlockList()
        }.disposed(by: self.disposeBag)
    }
    
    func updateSectionSearchText(text: String) {
        for sectionVM in self.sortedSectionVM {
            sectionVM.searchText(with: text, changeDisplay: false)
        }
        
        self.finishLoad()
    }
    
    func finishLoad() {
        DispatchQueue.main.async {
            self.parserDataAfterFilter()
            self.reloadData.onNext(())
        }
    }
    
    func parserDataAfterFilter() {
        
    }
}
