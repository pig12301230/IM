//
//  MessageSearchViewControllerVM.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/7/4.
//

import RxSwift
import RxCocoa

class MessageSearchViewControllerVM: ListViewControllerVM {

    let loading: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    let selectedMessage: BehaviorRelay<MessageModel?> = BehaviorRelay(value: nil)
    let resetSearch = PublishRelay<Void>()

    private(set) var conversationSectionVM: TitleSectionViewModel!
    private(set) var dataSource: ConversationDataSource!
    private(set) var searchVM: SearchNavigationViewVM!
    
    var transceiverDict: [String: TransceiverModel] {
        dataSource.input.transceiverDict.value
    }

    override init() {
        super.init()
    }

    convenience init(searchVM: SearchNavigationViewVM, dataSource: ConversationDataSource) {
        self.init()
        self.searchVM = searchVM
        self.dataSource = dataSource
        self.initBinding()
    }

    override func didSelectRow(at indexPath: IndexPath) {
        guard let cellVM = self.cellViewModel(in: indexPath) as? MessageSearchTableViewCellVM else {
            PRINT("did select row do Action Error", cate: .error)
            return
        }

        self.didSelectSearchedMessage(with: cellVM)
    }

    func didSelectSearchedMessage(with vm: MessageSearchTableViewCellVM) {
        // 切頁
        self.dataSource.input.currentContentType.accept(.highlightMessage)
        // Scroll to message
        self.selectedMessage.accept(vm.message)
    }

    override var emptyType: EmptyView.EmptyType {
        return .noSearchResults
    }

    func initBinding() {
        self.searchVM.output.searchString.skip(2).distinctUntilChanged().subscribeSuccess { [unowned self] searchText in
            self.updateSectionSearchText(text: searchText)
        }.disposed(by: self.disposeBag)

        self.dataSource.output.searchingResult.subscribeSuccess { [unowned self] result in
            PRINT("searching result", cate: .thread)
            let newResult: [MessageSearchTableViewCellVM] = result.sorted { $0.id < $1.id }.compactMap { message in
                guard let transceiver = self.transceiverDict[message.userID] else { return nil }
                return MessageSearchTableViewCellVM(with: .messageRecord(message: message, transceiver: transceiver))
            }

            self.conversationSectionVM = TitleSectionViewModel(with: TitleSectionViewModel.SectionType.searchMessage, cellVMs: newResult, sorted: true)
            self.conversationSectionVM.searchText(with: self.searchVM.output.searchString.value)
            self.sortedSectionVM = [self.conversationSectionVM]
            self.setupEmptyView(type: self.emptyType)
            self.reloadData.onNext(())
            self.loading.accept(false)
        }.disposed(by: disposeBag)
    }

    func updateSectionSearchText(text: String) {
        loading.accept(true)
        if let sectionVM = self.conversationSectionVM {
            sectionVM.searchText(with: text)
        }
        
        self.dataSource.searchingMessage(text: text)
    }
}
