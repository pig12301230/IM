//
// Created by ZoeLin on 2022/3/11.
//

import Foundation
import RxSwift
import RxCocoa

enum ConversationUpdateType {
    case reload(target: String?)
    case diff(target: String?)
    case scroll(target: String?)
}

class ConversationInteractor {
    static let limitPage: Int = 5
    
    let messageViewModelUpdated = PublishSubject<Bool>()
    let reloadMessages = PublishSubject<Void>()
    let updatedTargetAt = BehaviorSubject<ConversationUpdateType?>(value: nil)
    let replaceMessage = PublishSubject<(String, MessageViewModel)>()
    let getEmptyPage = BehaviorSubject<Void?>(value: nil)
    
    let dataSource: ConversationDataSource
    var disposeBag = DisposeBag()
    let floatingViewHidden: BehaviorRelay<Bool> = BehaviorRelay(value: true)
    private(set) var transceiversDict: BehaviorRelay<[String: TransceiverModel]> = .init(value: [:])
    private(set) var unreadIndex: Int?
    private(set) var toTargetID: String?
    private(set) var targetMessageID: String? {
        didSet {
            if targetMessageID == nil {
                toTargetID = nil
            }
        }
    }
    
    var unreadCount: BehaviorRelay<Int> {
        dataSource.output.unread
    }
    
    var group: GroupModel {
        dataSource.group
    }
    
    let updateMessageData = PublishSubject<[MessageViewModel]>()
    
    private let messageQueue = DispatchQueue.init(label: "com.chat.message.conversation.interactor")
    
    var messageItems: [MessageViewModel] {
        successMessageItems + failureMessageItems
    }
    
    private var _successMessageItems: [MessageViewModel] = []
    private var successMessageItems: [MessageViewModel] {
        get {
            return messageQueue.sync {
                _successMessageItems.filter { $0.model?.deleted != true }
            }
        }
        set {
            self.messageQueue.async(flags: .barrier) {
                self._successMessageItems = newValue
            }
        }
    }
    
    private var _failureMessageItems: [MessageViewModel] = []
    private var failureMessageItems: [MessageViewModel] {
        get {
            return messageQueue.sync {
                _failureMessageItems.filter { $0.model?.deleted != true }
            }
        }
        set {
            self.messageQueue.async(flags: .barrier) {
                self._failureMessageItems = newValue
            }
        }
    }
    
    private var _failureMessageModels: [MessageModel] = []
    private var failureMessageModels: [MessageModel] {
        get {
            return messageQueue.sync {
                _failureMessageModels
            }
        }
        set {
            self.messageQueue.async(flags: .barrier) {
                self._failureMessageModels = newValue
            }
        }
    }
    
    private var _displayPages = [MessagesPageModel]()
    private var displayPages: [MessagesPageModel] {
        get {
            return messageQueue.sync {
                _displayPages
            }
        }
        set {
            self.messageQueue.async(flags: .barrier) {
                var diffCount = self._displayPages.count != newValue.count
                // 檢查 suffix時 displayPage 是否不同
                if self._displayPages.count >= ConversationInteractor.limitPage && newValue.count >= ConversationInteractor.limitPage && newValue.last?.data.count == self._displayPages.last?.data.count {
                    let maxSize = min(self._displayPages.count, newValue.count)
                    for i in 0...maxSize - 1 {
                        if self._displayPages[i].diffIdentifier != newValue[i].diffIdentifier {
                            diffCount = true
                        }
                    }
                }
                self._displayPages = newValue.sortedAndUpdate(removeDuplicate: diffCount)
            }
        }
    }
    private var _originalDisplayPages = [MessagesPageModel]()
    private var originalDisplayPages: [MessagesPageModel] {
        get {
            return messageQueue.sync {
                _originalDisplayPages
            }
        }
        set {
            self.messageQueue.async(flags: .barrier) {
                self._originalDisplayPages = newValue.sortedAndUpdate()
            }
        }
    }
    
    private let toTargetOperationQueue: OperationQueue = {
        let operate = OperationQueue()
        operate.maxConcurrentOperationCount = 1
        return operate
    }()
    
    private let updateMessageQueue: OperationQueue = {
        let operate = OperationQueue()
        operate.maxConcurrentOperationCount = 1
        return operate
    }()
    
    private let operationQueue: OperationQueue = {
        let operate = OperationQueue()
        operate.maxConcurrentOperationCount = 1
        return operate
    }()
    
    private var firstTimeLastViewedID: String?
    private(set) var firstTimeUnreadCount: Int?
    private(set) var listeningMessage: String?
    private(set) var currentItemCount: Int = 0
    private(set) var listener: [String] = []
    private(set) var lastReceivedMessage: MessageModel?
    
    init(dataSource: ConversationDataSource, target: String? = nil) {
        self.dataSource = dataSource
        initBinding()
        firstTimeLastViewedID = dataSource.input.group.value.lastViewedID
        firstTimeUnreadCount = dataSource.group.unreadCount
        DataAccess.shared.totalUnread -= dataSource.group.unreadCount
        DataAccess.shared.lastReadingConversation.accept(group.id)
        DataAccess.shared.fetchDatabaseGroupImage(group.id)
        setupFailureMessage()
        
        if let target = target {
            locate(to: .targetMessage(messageID: target))
        } else {
            if !dataSource.messagePageData.isEmpty {
                displayPages = dataSource.messagePageData.suffix(2)
            }
            updateMessageViewModels(.bottom)
            checkDBData(dataSource)
        }
    }
    
    deinit {
        PRINT(" class \(type(of: self)) deinit ", cate: .deinit)
    }
    
    func dispose() {
        self.operationQueue.cancelAllOperations()
        self.disposeBag = DisposeBag()
    }
    
    func leaveSearching() {
        let pageDiff = diff(old: displayPages, new: originalDisplayPages)
        guard !pageDiff.isEmpty else {
            messageViewModelUpdated.onNext(false)
            return
        }
        displayPages = originalDisplayPages
        updateMessageViewModels(nil)
    }
    
    func locate(to position: LocatePosition) {
        var targetID: String?
        
        switch position {
        case .unread:
            targetID = firstTimeLastViewedID
            listeningMessage = targetID
        case .bottom:
            targetID = dataSource.getBottomMessageID()
        case .searchingMessage(let messageID), .targetMessage(let messageID):
            targetID = messageID
            listeningMessage = messageID
        }
        
        guard let targetID = targetID else { return }
        toTargetID = targetID
        guard !isDeletedMessage(messageID: targetID) else { return }
        
        // 如果 targetMessage 已經存在於 displayPages
        
        if isInDisplayPage(id: targetID) {
            if let targetItem = successMessageItems.first(where: { $0.diffIdentifier == targetID })?.model {
                guard !targetItem.deleted else { return }
                updatedTargetAt.onNext(.scroll(target: toTargetID))
                return
            } else if targetID.contains("tmp") {
                //TODO: 待優化
                updateMessageViewModels()
                updatedTargetAt.onNext(.scroll(target: toTargetID))
                return
            }
        }
        dataSource.resetFetchPreviousStatus()
        // 先檢查是否存在於 dataSouce, 直接從 server拿
        guard let targetPageIndex = dataSource.getPageDataIndexes(with: targetID, position: position), !targetPageIndex.isEmpty else {
            listeningMessage = targetID
            displayPages = []
            dataSource.fetchPageMessages(from: targetID)
            return
        }
        
        // 不存在於 displayPage時, 直接從dataSource拿
        let pageData = targetPageIndex.compactMap { dataSource.messagePageData[$0] }
        let pageDiff = diff(old: displayPages, new: pageData)
        guard !pageDiff.isEmpty else {
            updatedTargetAt.onNext(.scroll(target: toTargetID))
            return
        }
        
        originalDisplayPages = pageData
        displayPages = pageData
        updateMessageViewModels(position, reload: true)
    }
    
    private func getPageIndex(with identifier: String) -> Int? {
        guard displayPages.count != 0 else {
            return 0
        }
        
        return displayPages.firstIndex(where: { $0.first <= identifier && $0.last >= identifier })
    }
    
    func getMessageID(index: Int) -> String? {
        if index < currentItemCount {
            for item in successMessageItems[index..<min(successMessageItems.count, currentItemCount)] {
                if let model = item.model {
                    return model.id
                }
            }
            for item in successMessageItems[0..<index].reversed() {
                if let model = item.model {
                    return model.id
                }
            }
        }
        return nil
    }
    
    func prefetchData(direction: MessageDirection) {
        guard let currentPage = direction == .after ?  displayPages.last : displayPages.first else {
            return
//            fatalError(" interactor can't find message page data ERROR!! ")
        }
        
        guard direction == .previous else {
            guard let lastPage = displayPages.sorted { $0.last < $1.last }.last else { return }
            operationQueue.addOperation {
                self.prefetchAfter(lastPage)
            }
            return
        }
        
        guard let firstPage = displayPages.sorted { $0.first < $1.first }.first else { return }
        operationQueue.addOperation {
            self.prefetchPrevious(firstPage)
        }
    }
    
    func isInDisplayPage(id: String) -> Bool {
        return self.displayPages.contains(where: { $0.first <= id && $0.last >= id })
    }
    
    //TODO: 之後要重新確認邏輯
    private func prefetchPrevious(_ page: MessagesPageModel) {
//        guard let firIndex = dataSource.getPageDataIndex(direction: .previous, at: page) else {
            dataSource.fetchPreviousMessages(previousFrom: page)
//            updatePageData(by: page, direction: .previous)
//            return
//        }
//
//        let firstPage = dataSource.messagePageData[firIndex]
//        guard let secIndex = dataSource.getPageDataIndex(direction: .previous, at: firstPage) else {
//            dataSource.fetchPreviousMessages(previousFrom: firstPage)
//            updatePageData(by: firstPage, direction: .previous)
//            return
//        }
//
//        let secondPage = dataSource.messagePageData[secIndex]
//        updatePageData(by: firstPage, secondPage, direction: .previous)
    }
    
    //TODO: 之後要重新確認邏輯
    private func prefetchAfter(_ page: MessagesPageModel) {
//        guard let firstIndex = dataSource.getPageDataIndex(direction: .after, at: page) else {
            dataSource.fetchAfterMessages(afterFrom: page)
//            return
//        }
//
//        let firstPage = dataSource.messagePageData[firstIndex]
//        guard let secondIndex = dataSource.getPageDataIndex(direction: .after, at: firstPage) else {
//            updatePageData(by: firstPage, direction: .after)
//            dataSource.fetchAfterMessages(afterFrom: firstPage)
//            return
//        }
//        let secondPage = dataSource.messagePageData[secondIndex]
//        updatePageData(by: firstPage, secondPage, direction: .after)
    }
    private func removePagesData(models: [MessageModel]) {
        var newDisplayPages = displayPages
        for model in models {
            if let pageIndex = newDisplayPages.firstIndex(where: { $0.data.contains(model) }) {
                if let dataIndex = newDisplayPages[pageIndex].data.firstIndex(where: { $0.id == model.id }) {
                    newDisplayPages[pageIndex].data.remove(at: dataIndex)
                    if newDisplayPages[pageIndex].data.isEmpty {
                        newDisplayPages.remove(at: pageIndex)
                    }
                }
            }
        }
        
        displayPages = newDisplayPages
        updateMessageViewModels()
    }

    private func updatePageData(by pages: MessagesPageModel..., direction: MessageDirection) {
        displayPages = (displayPages + pages).removeDuplicateDiff()
        if displayPages.count >= ConversationInteractor.limitPage {
            switch direction {
            case .previous:
                displayPages = Array(displayPages.prefix(ConversationInteractor.limitPage))
                dataSource.resetFetchPreviousStatus()
            case .after:
                displayPages = displayPages.suffix(ConversationInteractor.limitPage)
                dataSource.resetFetchPreviousStatus()
            }
        }
        updateMessageViewModels()
    }
    
    private func updateMessageViewModels(_ position: LocatePosition? = nil, reload: Bool = false) {
        let queue = position == nil ? updateMessageQueue : toTargetOperationQueue
        updateMessageQueue.cancelAllOperations()
        
        queue.addOperation {
            if let page = self.dataSource.failurePage {
                let failureResult = self.getMessageViewModels(by: page.data, needSeparate: false)
                self.failureMessageItems = failureResult
            } else {
                self.failureMessageItems = []
            }
            
            let models = self.displayPages.reduce(into: [], { $0 += $1.data.filter { $0.deleted != true } }).removeDuplicateDiff()
            let newResult = self.getMessageViewModels(by: models, needSeparate: true)
            self.currentItemCount = newResult.count + self.failureMessageItems.count
            self.successMessageItems = newResult
            
            guard let position = position else {
                guard reload else {
                    self.messageViewModelUpdated.onNext(true)
                    return
                }
                
                self.updatedTargetAt.onNext(.reload(target: nil))
                return
            }
            
            var target: String?
            switch position {
            case .unread:
                target = self.firstTimeLastViewedID
            case .bottom:
                target = self.messageItems.last?.model?.id ?? self.dataSource.getBottomMessageID()
            case .searchingMessage(let targetID), .targetMessage(let targetID):
                target = targetID
            }
            guard reload else {
                self.updatedTargetAt.onNext(.diff(target: target))
                return
            }
            
            self.updatedTargetAt.onNext(.reload(target: target))
        }
    }
    
    private func setupFailureMessage() {
        failureMessageModels = dataSource.failurePage?.data ?? []
        guard let page = dataSource.failurePage else {
            failureMessageItems = []
            return
        }
        
        operationQueue.addOperation {
            let vmResult = self.getMessageViewModels(by: page.data, needSeparate: false)
            self.failureMessageItems = vmResult
            self.updateMessageViewModels()
        }
    }
    
    private func checkDBData(_ dataSource: ConversationDataSource) {
        guard let messageID = dataSource.input.group.value.lastMessage?.id, let time = dataSource.input.group.value.lastMessage?.timestamp else {
            self.getEmptyPage.onNext(())
            return
        }
        dataSource.checkDBData(groupID: group.id, messageID: messageID, time: time, direction: .previous)
        dataSource.fetchPageMessages(from: messageID)
    }
    
    func isNoPreviousData() -> Bool? {
        return dataSource.noPreviousFromDatabase && dataSource.noPreviousFromServer
    }
    
    func endReading() {
        dataSource.input.isReading.accept(false)
    }
    
    func startReading() {
        dataSource.input.isReading.accept(true)
    }
    
    func setReadMessage(with messageId: String) {
        dataSource.setReadMessage(messageId)
    }
    
    func isReachRealLastPage() -> Bool {
        // 用來判斷滑到底是否為所有資料的最後 display page
        guard let lastId = self.dataSource.messagePageData.last?.first else { return false }
        return self.messageItems.contains(where: { $0.diffIdentifier == lastId })
    }
    
    func clearMessage() {
        displayPages = []
        originalDisplayPages = []
        self.updateMessageViewModels()
    }
    
    func resetListeningMessage() {
        self.listeningMessage = nil
        self.toTargetID = nil
    }
    
    func getHongBaoContent(by messageID: String, completion: @escaping (HongBaoContent?) -> Void) {
        dataSource.getHongBaoContent(by: messageID) { content in
            completion(content)
        }
    }
    
    func updateFloatingViewHidden(hidden: Bool) {
        dataSource.updateFloatingViewHidden(hidden: hidden)
    }
    
    func setFloatingHongBaoMsgID(with messageID: String) {
        dataSource.setFloatingHongBaoMsgID(with: messageID)
    }
    
    func checkLastFloatingHongBaoIdEqual(newId: String) -> Bool {
        return dataSource.newestFloatingHongBaoMsgID == newId
    }
}

private extension  ConversationInteractor {
    func initBinding() {

        dataSource.input.transceiverDict
            .debounce(.microseconds(300), scheduler: MainScheduler.instance)
            .subscribeSuccess { [weak self] dict in
                guard let self = self else { return }
                let oriIdDisplay = self.transceiversDict.value.values.compactMap { $0.id + $0.display }
                let newIdDisplay = dict.values.compactMap { $0.id + $0.display }
                guard oriIdDisplay != newIdDisplay else { return }
                self.transceiversDict.accept(dict)
                // refresh view
                self.updateMessageTransceiver()
            }.disposed(by: disposeBag)
        
        dataSource.output.deleteModels.subscribeSuccess { [weak self] models in
            guard let self = self else { return }
            self.removePagesData(models: models)
        }.disposed(by: disposeBag)

        dataSource.output.replaceMessageModel.subscribeSuccess { [weak self] messageModel, originalID in
            guard let self = self else { return }
            guard let pageIndex = self.getPageIndex(with: originalID) else { return }
            guard let messageIndex = self.displayPages[pageIndex].data.firstIndex(where: { $0.id == originalID }) else { return }
            self.displayPages[pageIndex].data[messageIndex] = messageModel
            self.updateMessageViewModels()
        }.disposed(by: disposeBag)
        
        dataSource.output.pageChanged.subscribeSuccess { [unowned self] (pageInfo, action) in
            guard pageInfo.diffIdentifier != dataSource.failurePage?.diffIdentifier else {
                setupFailureMessage()
                return
            }
            guard let listener = self.listeningMessage, pageInfo.first <= listener, pageInfo.last >= listener else {
                self.handlePageAction(pageInfo, action: action)
                return
            }
            let pageDiff = diff(old: displayPages, new: [pageInfo])
            guard !pageDiff.isEmpty else {
                toTargetID = listener
                updatedTargetAt.onNext(.scroll(target: toTargetID))
                return
            }
            if action == .add {
                displayPages.append(pageInfo)
                displayPages = displayPages.removeDuplicateDiff()
            } else if action == .update, let index = getPageIndex(with: pageInfo.first), displayPages.count > index {
                displayPages[index] = pageInfo
            } else {
                displayPages = [pageInfo]
            }
            toTargetID = listener
            updateMessageViewModels(.targetMessage(messageID: listener), reload: true)
        }.disposed(by: disposeBag)
        
        dataSource.output.deleteMessage.subscribeSuccess { [weak self] message in
            guard let self = self else { return }
            // TODO: update displayPage data first, last
            for (index, displayPage) in self.displayPages.enumerated() {
                var data = displayPage.data
                if let dataIndex = displayPage.data.firstIndex(where: { $0.diffIdentifier == message.id }) {
                    data.remove(at: dataIndex)
                    self.displayPages[index].data = data
                    
                    if self.displayPages[index].data.isEmpty {
                        if index >= 1 {
                            self.displayPages[index - 1].next = nil
                        }
                        self.displayPages.remove(at: index)
                        return
                    }
                    if message.id == self.displayPages[index].first {
                        self.displayPages[index].first = self.displayPages[index].data.first?.id ?? ""
                        if index >= 1 {
                            self.displayPages[index - 1].next = self.displayPages[index].first
                        }
                    } else if message.id == self.displayPages[index].last {
                        self.displayPages[index].last = self.displayPages[index].data.last?.id ?? ""
                        if index == self.displayPages.count - 1 {
                            self.displayPages[index].next = nil
                        }
                    }
                }
            }
        }.disposed(by: disposeBag)
        
        dataSource.output.getEmptyPage.bind(to: self.getEmptyPage).disposed(by: disposeBag)
        
        dataSource.output.floatingViewHidden.bind(to: self.floatingViewHidden).disposed(by: disposeBag)
        
        NetworkManager.websocketStatus
            .skip(1)
            .distinctUntilChanged()
            .bind { [weak self] status in
                guard let self = self else { return }
                switch status {
                case .connected:
                    //TODO: 可優化成只抓斷線到重連的時間內資料
                    //重新同步資料, 從收到的最後一則往後抓
                    let message = self.lastReceivedMessage ?? self.dataSource.input.group.value.lastMessage
                    guard let message = message else { return }
                    self.dataSource.checkDBData(groupID: self.group.id,
                                                messageID: message.id,
                                                time: message.timestamp,
                                                direction: .after)
                    self.lastReceivedMessage = nil
                case .disconnected:
                    self.lastReceivedMessage = self.dataSource.input.group.value.lastMessage
                default:
                    break
                }
            }.disposed(by: self.disposeBag)
    }
    
    /**
     取得 table view cell needs item (message view model)
     - Parameters:
     - messages: message data list
     - needSeparate: 是否需要分隔戳記 (time or unread)
     - Returns: message view model list ( contains timeItem, messageItem, unreadItem)
     */
    func getMessageViewModels(by messages: [MessageModel], needSeparate: Bool = true) -> [MessageViewModel] {
        var items = [MessageViewModel]()
        var previousMessage: MessageModel?
        guard needSeparate else {
            for message in messages {
                if let addItem = convertMessageViewModel(with: message, preMessage: previousMessage) {
                    if let target = targetMessageID, message.id == target {
                        toTargetID = targetMessageID
                    }
                    items.append(addItem)
                }
                previousMessage = message
            }
            return items
        }
        
        for message in messages {
            if let dateItem = createDateTime(lastMessage: previousMessage, message: message) {
                items.append(dateItem)
            }
            
            if let addItem = convertMessageViewModel(with: message, preMessage: previousMessage) {
                if let target = targetMessageID, message.id == target {
                    toTargetID = targetMessageID
                }
                items.append(addItem)
            }
            
            if message.id == firstTimeLastViewedID && firstTimeUnreadCount ?? 0 > 0 {
                
                unreadIndex = max(items.count - 1, 0)
                let vm = MessageViewModel(type: .unread, model: nil, status: .success, cellModel: UnreadCellVM(), timestamp: message.timestamp)
                items.append(vm)
            } else {
                unreadIndex = nil
            }
            
            previousMessage = message
        }
        return items
    }
    
    func convertMessageViewModel(with message: MessageModel, preMessage: MessageModel?) -> MessageViewModel? {
        let viewType = message.messageType.viewType
        var item: MessageViewModel?
        switch viewType {
        case .groupStatus:
            item = createGroupStatus(type: message.messageType, message: message)
        case .text, .image, .recommend, .hongBao:
            item = createMessage(message: message, previousMessage: preMessage)
        default:
            break
        }
        return item
    }
    
    func handlePageAction(_ page: MessagesPageModel, action: DataAction) {
        var pageData = displayPages.removeDuplicateDiff()

        if page.containTemporary && action == .add {
            locate(to: .bottom)
            pageData.append(page)
            displayPages = pageData
            return
        }
        
        if pageData.isEmpty {
            pageData.append(page)
            displayPages = pageData
            updateMessageViewModels()
            return
        }
        //TODO: 邏輯待確認
        if let index = pageData.firstIndex(where: { $0.first == page.first || $0.last == page.last }) {
            // 在目前的 display list 中
            if index >= 1 {
                pageData[index - 1].next = page.first
            }
            pageData[index] = page
            displayPages = pageData
            updateMessageViewModels()
        } else {
            // check shoud insert to displayPage or not
            // 找出 displayPage messagePage 對應index
            let messageData = self.dataSource.messagePageData
            if let first = pageData.first,
               let convertFirstIndex = dataSource.getPageIndex(with: first.first), convertFirstIndex > 0 {
                dataSource.isMessageDataContinuous(page: messageData[convertFirstIndex - 1],
                                                   currentMessage: first.first,
                                                   direction: .previous) { [weak self] isContinuous in
                    guard let self = self, convertFirstIndex > 0 else { return }
                    let state = action == .update ? page.diffIdentifier == messageData[convertFirstIndex - 1].diffIdentifier : true
                    if isContinuous && state {
                        self.updatePageData(by: page, direction: .previous)
                    }
                }
            }
            
            if let last = displayPages.sorted { $0.last < $1.last }.last,
                let convertLastIndex = dataSource.getPageIndex(with: last.first) {
                if convertLastIndex < messageData.count - 1 {
                    dataSource.isMessageDataContinuous(page: messageData[convertLastIndex + 1],
                                                       currentMessage: last.last,
                                                       direction: .after) { [weak self] isContinuous in
                        guard let self = self, convertLastIndex < messageData.count - 1 else { return }
                        let state = action == .update ? page.diffIdentifier == messageData[convertLastIndex + 1].diffIdentifier : true
                        if isContinuous && state {
                            self.updatePageData(by: page, direction: .after)
                        }
                    }
                }
            }
        }
    }
}

// MARK: send and resend message (text, image)
extension ConversationInteractor {
    
    func getBottomMessage() -> String? {
        return dataSource.getBottomMessageID()
    }
    
    func isDeletedMessage(messageID: String) -> Bool {
        return dataSource.isDeletedMessage(messageID: messageID)
    }
    /**
     發送文字訊息
     - Parameter content: 文字內容
     */
    func sendTextMessage(_ content: String) {
        DataAccess.shared.sendMessage(content, groupID: group.id) { [weak self] model, originalID in
            guard let self = self else { return }
            PRINT("upload message == \(content) id == \(model.id)")
            self.operationQueue.addOperation {
                self.updateMessageProcessComplete(message: model, originalID: originalID, isResend: false)
            }
        }
    }
    
    func sendReplyTextMessage(content: String, replyMessage: MessageModel) {
        DataAccess.shared.sendReplyMessage(content, replyMessage: replyMessage) { [weak self] model, originalID in
            guard let self = self else { return }
            PRINT("upload reply message == \(content) id == \(model.id)")
            self.operationQueue.addOperation {
                self.updateMessageProcessComplete(message: model, originalID: originalID, isResend: false)
            }
        }
    }
    
    func sendImageMessage(_ url: URL) {
        self.sendImage(url: url)
    }
    
    func createImageMessage(imageFileName: String, index: Int) {
        dataSource.createImageMessage(imageFileName: imageFileName, index: index)
    }

    private func sendImage(url: URL) {
        let format = String(format: "imageFileName = '%@'", url.lastPathComponent)
        DataAccess.shared.getDraftMessages(format: format) { [weak self] models in
            guard let self = self, let model = models.first else { return }
            self.dataSource.sendImageMessage(model, complete: { messageModel, originalID in
                PRINT("send image complete = \(messageModel.id)")
                self.operationQueue.addOperation {
                    self.updateMessageProcessComplete(message: messageModel, originalID: originalID, isResend: false)
                }
            })
        }
    }
        
    /**
     重新發訊訊息 (text, images)
     - Parameter model: 欲重新發送的 message model
     */
    func resendMessage(_ model: MessageModel) {
        switch model.messageType {
        case .text:
            let isReplyMessage = !(model.threadID ?? "").isEmpty
            
            if isReplyMessage {
                DataAccess.shared.sendReplyMessage(with: model) { [weak self] model, originalID in
                    guard let self = self else { return }
                    PRINT("resend reply message text == \(model.message)")
                    self.operationQueue.addOperation {
                        self.updateMessageProcessComplete(message: model, originalID: originalID, isResend: true)
                    }
                }
            } else {
                DataAccess.shared.sendMessage(with: model) { [weak self] model, originalID in
                    guard let self = self else { return }
                    PRINT("resend message text == \(model.message)")
                    self.operationQueue.addOperation {
                        self.updateMessageProcessComplete(message: model, originalID: originalID, isResend: true)
                    }
                }
            }
        case .image:
            guard let imageFileName = model.imageFileName else { return }
            dataSource.resendImageMessage(with: model, imageFileName: imageFileName)
        default: break
        }
    }
    
    private func updateMessageProcessComplete(message: MessageModel, originalID: String, isResend: Bool) {
        let newPageModel = dataSource.getNewPageAndUpdateMessageStatus(message: message, originalID: originalID, isResend: isResend)
        dataSource.setReadMessage(message.id)
        guard let newPage = newPageModel else { return }
        //TODO: update displayPages should update ID
        
        var originalPageData: [MessageModel]!
        if isResend {
            // if no more Message can resend, then reFetch page info
            guard !newPage.data.isEmpty else {
                failureMessageItems.removeAll()
                failureMessageModels.removeAll()
                locate(to: .bottom)
                return
            }
            originalPageData = failureMessageModels
        } else if let pageIndex = getPageIndex(with: originalID), !message.diffIdentifier.contains("tmp") {
            if displayPages.count > 0 {
                originalPageData = displayPages[pageIndex].data
                displayPages[pageIndex] = newPage
                if pageIndex >= 1 {
                    displayPages[pageIndex - 1].next = newPage.first
                }
            } else {
                originalPageData = []
                displayPages.append(newPage)
            }
        } else if let pageIndex = getPageIndex(with: message.diffIdentifier) {
            if displayPages.count > 0 {
                originalPageData = displayPages[pageIndex].data
                displayPages[pageIndex] = newPage
                if pageIndex >= 1 {
                    displayPages[pageIndex - 1].next = newPage.first
                }
            } else {
                originalPageData = []
                displayPages.append(newPage)
            }
        } else {
            originalPageData = []
        }
        
        guard !originalPageData.isEmpty else { return }
        
        guard let dataIndex = originalPageData.firstIndex(where: { $0.diffID == originalID }) else {
            return
        }
        
        let minIndex = max(0, dataIndex - 1)
        let originalResult = getMessageViewModels(by: Array(originalPageData[minIndex...dataIndex]))
        originalPageData[dataIndex] = message
        let newResult = getMessageViewModels(by: Array(originalPageData[minIndex...dataIndex]))
        
        guard !isResend else {
            // update failure list when isResend == true
            guard let messageVM = newResult.last else { return }
            var items = failureMessageItems
            if let messageVMIndex = items.firstIndex(where: { $0.diffIdentifier == originalID }) {
                items[messageVMIndex] = messageVM
                failureMessageItems = items.sorted(by: { $0.diffIdentifier < $1.diffIdentifier })
            }
            failureMessageModels = newPage.data.sorted(by: { $0.diffIdentifier < $1.diffIdentifier })
            messageViewModelUpdated.onNext(true)
            return
        }
        
        guard message.messageType == .text else {
            for messageVM in newResult {
                if let messageVMIndex = successMessageItems.firstIndex(where: { $0.diffIdentifier == originalID }) {
                    successMessageItems[messageVMIndex] = messageVM
                } else if let messageVMIndex = failureMessageItems.firstIndex(where: { $0.diffIdentifier == originalID }) {
                    failureMessageItems[messageVMIndex] = messageVM
                }
                
                replaceMessage.onNext((originalID, messageVM))
            }
            return
        }
        
        let diff = diff(old: originalResult, new: newResult)
        
        
        // diff.count == 1 means only the change belongs message's diff
        guard !diff.isEmpty, diff.count != 1 else {
            guard let messageVM = newResult.last else { return }
            if let messageVMIndex = successMessageItems.firstIndex(where: { $0.diffIdentifier == originalID }) {
                successMessageItems[messageVMIndex] = messageVM
            }
            replaceMessage.onNext((originalID, messageVM))
            return
        }
        updateMessageViewModels()
    }
    
    private func updateMessageTransceiver() {
        _ = self.successMessageItems.map {
            if case .groupStatus = $0.type,
               let vm = $0.cellModel as? GroupStatusCellVM,
               let model = $0.model {
                let status = model.messageType.getGroupStatus(allUser: transceiversDict.value,
                                                              messageModel: model)
                vm.updateGroupStatus(status)
            }
            guard let model = $0.model, let transceiver = transceiversDict.value[model.userID] else { return }
            $0.cellModel.updateTransceiver(transceiver)
        }
        reloadMessages.onNext(())
    }
}

extension ConversationInteractor {
    func createDateTime(lastMessage: MessageModel?, message: MessageModel) -> MessageViewModel? {
        guard let time = getDateTime(lastMessage: lastMessage, message: message) else {
            return nil
        }
        
        let dateTimeVM = DateTimeCellVM(dateTime: time)
        return MessageViewModel(type: .dateTime(forModelID: message.diffIdentifier), model: nil, status: message.messageStatus, cellModel: dateTimeVM, timestamp: message.timestamp)
    }
    
    func getDateTime(lastMessage: MessageModel?, message: MessageModel) -> String? {
        let msgTime = message.createAt ?? Date(timeIntervalSince1970: TimeInterval(Double(message.timestamp) / 1000))
        
        guard message.messageType != .groupCreate, message.messageType != .groupDisplayName else {
            return msgTime.toLocaleString(format: .yearToSymbolTime)
        }
        
        guard let lastMessage = lastMessage else {
            return msgTime.messageDateFormat()
        }
        
        let lastMsgTime = lastMessage.createAt ?? Date(timeIntervalSince1970: TimeInterval(Double(lastMessage.timestamp) / 1000))
        let lastTimeString = lastMsgTime.toLocaleString(format: .yearToDay)
        let timeString = msgTime.toLocaleString(format: .yearToDay)
        return lastTimeString == timeString ? nil : msgTime.messageDateFormat()
    }
}

// MARK: - Create mark sections: Unread
extension ConversationInteractor {
    
    func getUnreadMessageStartAt(_ messages: [MessageModel]) -> String? {
        guard !messages.isEmpty else { return nil }
        guard let lastMessageID = group.lastMessage?.id, !lastMessageID.isEmpty else { return nil }
        
        var startIndex: Int?
        switch dataSource.unreadType {
        case .all(before: let firstID):
            if let readMessageIndex = messages.firstIndex(where: { $0.id == firstID }) {
                startIndex = max(0, readMessageIndex - 1)
            }
        case .after(from: let lastViewed):
            if let readMessageIndex = messages.firstIndex(where: { $0.id == lastViewed }) {
                startIndex = readMessageIndex + 1
            }
        }
        
        guard let startIndex = startIndex, let receivedMessage = messages[startIndex...].first(where: { $0.userID != UserData.shared.userID }) else { return nil }
        return receivedMessage.id
    }
}

// MARK: - Create mark sections: Group Status
extension ConversationInteractor {
    
    func createGroupStatus(type: MessageType, message: MessageModel) -> MessageViewModel {
        let status = type.getGroupStatus(allUser: transceiversDict.value, messageModel: message)
        let groupStatusVM = GroupStatusCellVM(type: type, groupStatus: status)
        return MessageViewModel(type: .groupStatus, model: message, status: message.messageStatus, cellModel: groupStatusVM, timestamp: message.timestamp)
    }
}

// MARK: - Message sections
extension ConversationInteractor {
    func createMessage(message: MessageModel, previousMessage: MessageModel?) -> MessageViewModel {
        let viewType = message.messageType.viewType
        let sender: MessageSenderType = message.userID == UserData.shared.userID ? .me : .others
        var order: MessageOrder {
            // 失敗的訊息使用 nth 的 UI
            guard message.messageStatus != .failed else { return .nth }
            guard let lastMessage = previousMessage, lastMessage.userID == message.userID else { return .first }
            guard lastMessage.messageType == .text || lastMessage.messageType == .image else { return .first }
            guard message.messageType == .text || message.messageType == .image else { return .first }
            guard message.localeTimeString == lastMessage.localeTimeString else { return .first }
            // 1. userID 與 previousMessage.userID 相同
            // 2. 兩則訊息類別皆為 text or image
            // 3. 兩則訊息 locale time 相同
            // 滿足以上三點 order 為 nth (第 n 筆)
            return .nth
        }
        
        var isRead: Bool {
            guard sender == .me else { return false }
            if group.groupType == .dm {
                guard let selfID = UserData.shared.userID else { return false }
                    
                return !message.blockUserIDs.contains(selfID)
            } else {
                return message.id <= group.lastReadID
            }
        }
        
        let isFailure = message.messageStatus == .failed
        let transceiver = transceiversDict.value[message.userID] ?? nil
        let config = MessageContentConfig(groupType: group.groupType, sender: sender, order: order, isFailure: isFailure)
        let model = MessageBaseModel(message: message, transceiver: transceiver, config: config)
        
        var messageVM: MessageContentCellProtocol {
            switch viewType {
            case .text:
                if (model.message.threadID ?? "").isEmpty {
                    return TextMessageCellVM(model: model, withRead: isRead)
                } else {
                    let senderID = model.message.threadMessage.first?.userID ?? ""
                    let sender = transceiversDict.value[senderID]
                    return ReplyTextMessageCellVM(model: model, withRead: isRead, threadSender: sender)
                }
            case .image:
                if let thumbURL = DataAccess.shared.getFile(by: message.fileIDs.first ?? "")?.thumbURL,
                   let imageUrl = URL(string: thumbURL) {
                    return ImageMessageCellVM(model: model, withRead: isRead, imageType: .url(imageUrl))
                } else if let imageFileName = message.imageFileName {
                    let imageUrl = AppConfig.Device.localImageFilePath.appendingPathComponent(imageFileName, isDirectory: false)
                    return ImageMessageCellVM(model: model, withRead: isRead, imageType: .localImage(imageUrl))
                } else if let urlString = DataAccess.shared.getFile(by: message.fileIDs.first ?? "")?.url,
                          let imageUrl = URL(string: urlString) {
                    return ImageMessageCellVM(model: model, withRead: isRead, imageType: .url(imageUrl))
                } else {
                    return ImageMessageCellVM(model: model, withRead: isRead, imageType: .needToGetFile(message.fileIDs.first ?? ""))
                }
            case .hongBao:
                return HongBaoMessageCellVM(model: model, withRead: isRead)
            case .recommend:
                return RecommandMessageCellVM(model: model, withRead: isRead)
            default: //never happen
                return MessageBaseCellVM(model: model, withRead: isRead)
            }
        }
        return MessageViewModel(type: viewType, model: message, status: message.messageStatus, cellModel: messageVM, timestamp: message.timestamp)
    }
    
}
