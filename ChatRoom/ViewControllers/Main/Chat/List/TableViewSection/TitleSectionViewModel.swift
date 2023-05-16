//
//  TitleSectionViewModel.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/5/3.
//

import Foundation
import RxSwift

class TitleSectionViewModel: BaseSectionVM {
    
    enum SectionType {
        case conversation
        case searchFriend
        case searchGroup
        case searchRecord
        case friendList
        case groupList
        case messageList
        case searchMessage
        
        var title: String {
            switch self {
            case .searchFriend, .friendList:
                return Localizable.friend
            case .messageList:
                return Localizable.aboutChatHistory
            case .searchRecord:
                return Localizable.chatHistory
            case .searchGroup, .groupList:
                return Localizable.group
            case .searchMessage:
                return Localizable.messages
            default:
                return ""
            }
        }
        
        var cellName: String {
            switch self {
            case .conversation:
                return "ChatTableViewCell"
            case .searchFriend, .searchGroup, .friendList, .groupList:
                return "NameTableViewCell"
            case .searchRecord:
                return "RecordTableViewCell"
            case .messageList:
                return "MessageTableViewCell"
            case .searchMessage:
                return "MessageSearchTableViewCell"
            }
        }
        
        var needFoot: Bool {
            switch self {
            case .searchFriend, .searchGroup:
                return true
            default:
                return false
            }
        }
    }
    
    override var reuseIdentifier: String {
        return "TitleSectionView"
    }
    
    private(set) var originalCellVMs: [NameTableViewCellVM] = []
    private(set) var originalCellVMsWithAlphabetical: [BaseTableViewCellVM] = []
    private(set) var displayType: SectionType {
        didSet {
            if let tag = self.headerTag, !tag.isEmpty {
                self.title = tag
            } else {
                self.title = displayType.title
            }
        }
    }
    private(set) var filterText: String = ""
    let sectionType: SectionType
    var section: Int = 0
    let showHeaderTag: Bool
    let reloadData = PublishSubject<Void>()
    private(set) var headerTag: String?
    private(set) var headerHeight: CGFloat = 44
    private(set) var backgroundColor: UIColor = Theme.c_07_neutral_50.rawValue.toColor()
    let sortUpdated = PublishSubject<Void>()
    
    init(with type: SectionType, originalCellVMs: [NameTableViewCellVM] = [], tag: String? = nil, cellVMs: [BaseTableViewCellVM], sorted: Bool = false) {
        self.sectionType = type
        self.displayType = type
        self.headerTag = tag
        self.showHeaderTag = tag != nil && !(tag?.isEmpty ?? false)
        self.originalCellVMs = originalCellVMs
        super.init()
        self.cellCount = cellVMs.count
        self.title = self.showHeaderTag ? self.headerTag ?? "" : type.title
        self.headerHeight = self.showHeaderTag ? 36 : 44
        self.cellViewModels = cellVMs
        
        if self.displayType == .groupList || self.displayType == .friendList { // cellVM 需要包含字母開頭
            self.originalCellVMsWithAlphabetical = cellVMs
        }
        
        // Friend List 的 search section 用此 class, 只會用到 cell count, 用來判斷是否需顯示
        if let list = cellVMs as? [NameTableViewCellVM] {
            if sorted == false {
                self.sortedList(newList: list)
            } else {
                self.originalCellVMs = list
                self.updateCellViewModels(list: list, sendUpdate: true)
            }
        }
        
        if showHeaderTag == true {
            self.backgroundColor = .clear
        }
    }
    
    /**
     搜索 cell view model 的顯示文字
     - Paramaters:
        - text: 搜索的字串
        - changeDisplay: ture - 需要顯示更多, false - 不需要顯示更多
     */
    func searchText(with text: String, changeDisplay: Bool = true) {
        self.filterText = text
        guard text.count > 0 else {
            self.displayType = self.sectionType
            self.originalCellVMs.forEach {
                _ = $0.isFitSearchContent(key: text)
                $0.setupSearchContentColor(key: text)
            }
            if self.displayType == .groupList || self.displayType == .friendList {
                self.updateCellViewModels(list: self.originalCellVMsWithAlphabetical)
            } else {
                self.updateCellViewModels(list: self.originalCellVMs)
            }
            return
        }

        let searchResult = self.originalCellVMs.filter { $0.isFitSearchContent(key: text) == true }
        
        if changeDisplay {
            if self.displayType == .conversation {
                self.displayType = .searchRecord
            } else if self.displayType == .friendList {
                self.displayType = .searchFriend
            } else if self.displayType == .groupList {
                self.displayType = .searchGroup
            } else if self.displayType == .searchMessage {
                self.title = self.displayType.title + String(searchResult.count)
            }
        }

        self.updateCellViewModels(list: searchResult)
    }
    
    func updateSortAfterInfoUpdate() {
        self.sortedList(newList: self.originalCellVMs)
    }
    
    func insertCellViewModelAt(vm: ChatTableViewCellVM) -> Int? {
        var sorted = self.originalCellVMs
        sorted.append(vm)
        guard !self.originalCellVMs.isEmpty else {
            self.originalCellVMs = sorted
            self.sortedList(newList: sorted)
            return nil
        }
        sorted = Array(Set(sorted)).sorted(by: { $0.updateAt > $1.updateAt })
        self.originalCellVMs = sorted
        self.updateCellViewModels(list: sorted, sendUpdate: false)
        
        guard self.filterText.count == 0 else {
            return nil
        }
        
        return sorted.firstIndex(where: { $0.pramryKey == vm.pramryKey })
    }
    
    func deleteCellViewModelAt(by key: String) -> Int? {
        var sorted = self.originalCellVMs
        
        guard let gIndex = sorted.firstIndex(where: { $0.pramryKey == key }) else {
            return nil
        }
        
        sorted.remove(at: gIndex)
        self.originalCellVMs = sorted
        self.updateCellViewModels(list: sorted)
        return gIndex
    }
    
    func cellViewModel(at index: Int) -> BaseTableViewCellVM? {
        guard self.cellViewModels.count > index else {
            return nil
        }
        
        if (self.displayType == .searchFriend || self.displayType == .searchGroup) && index == 3 {
            return nil
        }
        
        return self.cellViewModels[index]
    }
}

private extension TitleSectionViewModel {
    
    func updateList(sorted: [NameTableViewCellVM], sendUpdate: Bool = false) {
        self.originalCellVMs = sorted
        self.updateCellViewModels(list: self.originalCellVMs, sendUpdate: sendUpdate)
    }
    
    func sortedList(newList: [NameTableViewCellVM]) {
        DispatchQueue.init(label: "process.sorted.queue").sync {
            let sortedNewList = newList.sorted(by: { $0.updateAt > $1.updateAt })
            
            if newList.count != self.originalCellVMs.count {
                self.originalCellVMs = sortedNewList
                self.updateCellViewModels(list: sortedNewList, sendUpdate: true)
                return
            }
            
            let oriKeys = self.originalCellVMs.compactMap { $0.pramryKey }
            let newKeys = sortedNewList.compactMap { $0.pramryKey }
            guard oriKeys != newKeys else {
                return
            }
            self.originalCellVMs = sortedNewList
            self.updateCellViewModels(list: sortedNewList, sendUpdate: true)
        }
    }
    
    func updateCellViewModels(list: [BaseTableViewCellVM], sendUpdate: Bool = false) {
        DispatchQueue.main.async {
            self.cellViewModels = list
            
            if self.displayType == .searchFriend || self.displayType == .searchGroup, list.count > 3 {
                self.cellCount = 4
            } else {
                self.cellCount = list.count
            }
            if sendUpdate {
                self.sortUpdated.onNext(())
            }
        }
    }
}
