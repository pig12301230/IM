//
//  ListViewControllerVM.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/5/27.
//

import RxSwift
import RxCocoa

public class ListViewControllerVM: BaseViewModel {
    
    var disposeBag = DisposeBag()
    let reloadData = PublishSubject<Void>()
    let showEmptyView: BehaviorRelay<(Bool, EmptyView.EmptyType)> = BehaviorRelay(value: (false, .noConversation))
    let goto = PublishSubject<Navigator.Scene>()
    
    var sortedSectionVM: [TitleSectionViewModel] = []
    var emptyType: EmptyView.EmptyType {
        return .noConversation
    }
    
    private var groupData: GroupModel?
    private var dataSource: ConversationDataSource? // 只有第二層ListVC用到
    
    convenience init(list: [NameTableViewCellVM], type: TitleSectionViewModel.SectionType, groupData: GroupModel? = nil, dataSource: ConversationDataSource? = nil) {
        self.init()
        let sectionVM = TitleSectionViewModel.init(with: type, cellVMs: list, sorted: true)
        self.sortedSectionVM = [sectionVM]
        self.groupData = groupData
        self.dataSource = dataSource
        
        self.showEmptyView.accept((list.isEmpty, emptyType))
    }
    
    func setupEmptyView(type: EmptyView.EmptyType) {
        guard let sectionVM = self.sortedSectionVM.first else {
            return
        }
        
        self.showEmptyView.accept((sectionVM.cellCount == 0, type))
    }
    
    func numberOfSection() -> Int {
        return self.sortedSectionVM.count
    }
    
    func numberOfRow(in section: Int) -> Int {
        guard self.sortedSectionVM.count > section else {
            return 0
        }
        
        return self.sortedSectionVM[section].cellCount
    }
    
    func sectionViewModel(in section: Int) -> TitleSectionViewModel? {
        guard self.sortedSectionVM.count > section else {
            return nil
        }
        
        return self.sortedSectionVM[section]
    }
    
    func cellViewModel(in indexPath: IndexPath) -> BaseTableViewCellVM? {
        guard self.sortedSectionVM.count > indexPath.section,
              let sViewModel = self.sectionViewModel(in: indexPath.section) else {
            return nil
        }
        
        return sViewModel.cellViewModel(at: indexPath.row)
    }
    
    func isNeedFooter(in section: Int) -> Bool {
        guard self.sortedSectionVM.count > section, self.sortedSectionVM[section].displayType.needFoot else {
            return false
        }
        
        return true
    }
    
    func didSelectRow(at indexPath: IndexPath) {
        guard let sectionVM = self.sectionViewModel(in: indexPath.section), let cellVM = self.cellViewModel(in: indexPath) else {
            return
        }
        
        PRINT("press \(sectionVM.displayType.self) cell at \(indexPath.row)")
        switch sectionVM.displayType {
        case .searchFriend, .friendList, .searchGroup, .groupList:
            if let vm = cellVM as? NameTableViewCellVM {
                self.didSelectFriend(with: vm)
            }
        case .messageList:
            if let vm = cellVM as? MessageTableViewCellVM {
                self.didSelectMessage(with: vm)
            }
        case .searchRecord:
            if let vm = cellVM as? RecordTableViewCellVM {
                self.didSelectRecord(with: vm)
            }
        default:
            break
        }
    }
    
    // MARK: - action function
    func showConversation(at indexPath: IndexPath) {
        guard let conversationVM = self.getConversationViewModel(at: indexPath) else { return }
        self.goto.onNext(.conversation(vm: conversationVM))
    }
    
    func showConversationFromRecord(with viewModel: RecordTableViewCellVM) {
        guard let data = viewModel.cellType.data as? GroupModel, let dataSource = DataAccess.shared.getGroupConversationDataSource(by: data.id), let messageModel = viewModel.matchResult.first else {
            return
        }

        let conversationVM = ConversationViewControllerVM.init(with: dataSource, backType: .toOriginal, highlightModel: messageModel)
        conversationVM.searchVM.output.searchString.accept(viewModel.keyString)
        self.goto.onNext(.conversation(vm: conversationVM))
    }
    
    func didSelectFriend(with vm: NameTableViewCellVM) {
        
        switch vm.cellType {
        case .contact(contact: let contact):
            guard let group = DataAccess.shared.getDirectConversation(vm.pramryKey), let dataSource = DataAccess.shared.getGroupConversationDataSource(by: group.id) else {
                self.createConversation(with: contact)
                return
            }
            let vm = ConversationViewControllerVM(with: dataSource)
            self.goto.onNext(.conversation(vm: vm))
        case .contactDetail(contact: let contact):
            let data = FriendModel.convertContactToFriend(contact: contact)
            let friendVm = ChatDetailViewControllerVM.init(data: data, style: .friendListToPerson)
            self.goto.onNext(.chatDetail(vm: friendVm))
        case .group(group: let group):
            guard let dataSource = DataAccess.shared.getGroupConversationDataSource(by: group.id) else { return }
            let vm = ConversationViewControllerVM(with: dataSource)
            self.goto.onNext(.conversation(vm: vm))
        case .groupDetail(group: let group):
            let data = FriendModel.convertGroupToFriend(group: group)
            let groupVm = ChatDetailViewControllerVM.init(data: data, style: .friendListToGroup)
            self.goto.onNext(.chatDetail(vm: groupVm))
        case .blocked(blocked: let model):
            let friendModel = FriendModel.converBlockedToFriend(blocked: model)
            let vm = ChatDetailViewControllerVM.init(data: friendModel, style: .blockedListToPerson)
            self.goto.onNext(.chatDetail(vm: vm))
            
        default:
            break
        }
    }
    
    func didSelectGroup(with vm: NameTableViewCellVM) {
        guard let model = vm.cellType.data as? GroupModel, let dataSource = DataAccess.shared.getGroupConversationDataSource(by: model.id) else { return }

        let vm = ConversationViewControllerVM(with: dataSource)
        self.goto.onNext(.conversation(vm: vm))
    }
    
    func didSelectRecord(with vm: RecordTableViewCellVM) {
        let matchCount = vm.matchResult.count
        guard matchCount > 0 else { return }
        
        guard matchCount > 1 else {
            self.showConversationFromRecord(with: vm)
            return
        }
        
        guard let data = vm.cellType.data as? GroupModel else { return }

        // For, 將聊天室的 messageDataSource 傳進第二層ListVC (第一層ListVC為聊天室超過2個以上訊息符合搜索條件)
        guard let dataSource = DataAccess.shared.getGroupConversationDataSource(by: data.id) else { return }
        
        let cellViewModels = vm.matchResult.compactMap { message -> MessageTableViewCellVM? in
            guard let trans = vm.transceivers[message.userID] else { return nil }
            let messageVM = MessageTableViewCellVM.init(with: .message(message: message, transceiver: trans))
            _ = messageVM.isFitSearchContent(key: vm.keyString)
            return messageVM
        }

        let vm = ListViewControllerVM.init(list: cellViewModels, type: .messageList, groupData: data, dataSource: dataSource)
        self.goto.onNext(.list(vm: vm))
    }

    func didSelectMessage(with vm: MessageTableViewCellVM) {
        guard let dataSource = self.dataSource, let messageModel = vm.cellType.data as? MessageModel else { return }
        
        let conversationVM = ConversationViewControllerVM.init(with: dataSource, backType: .toOriginal, highlightModel: messageModel)
        conversationVM.searchVM.output.searchString.accept(vm.keyString)
        self.goto.onNext(.conversation(vm: conversationVM))
    }
}

// MARK: - Conversation functions
extension ListViewControllerVM {

    func createConversation(with contact: ContactModel) {
        DataAccess.shared.createDirectConversation(with: contact.id, displayName: contact.display).subscribe { [unowned self] info in
            guard let dataSource = DataAccess.shared.getGroupConversationDataSource(by: info.id) else { return }
            let conversationVM = ConversationViewControllerVM.init(with: dataSource)
            self.goto.onNext(.conversation(vm: conversationVM))
        } onError: { _ in
            // TODO: when error cause do something
        }.disposed(by: self.disposeBag)

    }
    
    func getConversationViewModel(at indexPath: IndexPath) -> ConversationViewControllerVM? {
        guard let cellVM = self.cellViewModel(in: indexPath) as? RecordTableViewCellVM,
              let model = cellVM.cellType.data as? GroupModel,
              let dataSource = DataAccess.shared.getGroupConversationDataSource(by: model.id) else {
            return nil
        }

        return ConversationViewControllerVM(with: dataSource)
    }
}
