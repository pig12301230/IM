//
//  ConversationDataSource.swift
//  ChatRoom
//
//  Created by ZoeLin on 2022/3/8.
//

import Foundation
import RxSwift
import RxCocoa

struct MessagesPageModel: DiffAware {
    typealias DiffId = String
    var diffIdentifier: DiffId {
        return first + "_" + last
    }
    static func compareContent(_ a: MessagesPageModel, _ b: MessagesPageModel) -> Bool {
        return a.diffIdentifier == b.diffIdentifier
    }
    
    var first: String
    var last: String
    var next: String?
    var containUnread: Bool
    var containTemporary: Bool = false
    var pageSize: Int
    var data: [MessageModel] {
        didSet {
            self.pageSize = data.count
            if let first = data.first {
                self.first = first.diffIdentifier
            }
            
            if let last = data.last {
                self.last = last.diffIdentifier
            }
        }
    }
}

enum UnreadType {
    case all(before: String?)
    case after(from: String)
    
    var lastViewed: String? {
        switch self {
        case .after(from: let lastViewedID):
            return lastViewedID
        default: return nil
        }
    }
}

class ConversationDataSource {
    static let defaultPreparePageCount: Int = 2
    
    struct GroupDetailInfo {
        let settingOnCount: BehaviorRelay<Int> = BehaviorRelay(value: 4)
        let blocksCount: BehaviorRelay<Int> = BehaviorRelay(value: 0)
        let adminIds: BehaviorRelay<[String]> = BehaviorRelay(value: [])
    }
    
    struct Input {
        let group: BehaviorRelay<GroupModel>
        let replaceMessage = PublishSubject<(MessageModel, String)>()
        let updateMessage = PublishSubject<(MessageModel, DataAction)>()
        let deleteMessage = PublishSubject<MessageModel>()
        let announcements: BehaviorRelay<[AnnouncementModel]> = BehaviorRelay(value: [])
        let currentContentType: BehaviorRelay<ConversationContentType> = BehaviorRelay(value: .nature)
        let transceiverDict: BehaviorRelay<[String: TransceiverModel]> = BehaviorRelay(value: [:])
        let isReading: BehaviorRelay<Bool> = BehaviorRelay(value: false)
        let rolePermission: BehaviorRelay<UserRoleModel?> = .init(value: nil)
        let fetchUnopenedHongBao = PublishSubject<Void>()
    }
    
    struct Output {
        let deleteMessage = PublishSubject<MessageModel>()
        let pageChanged = PublishSubject<(MessagesPageModel, DataAction)>()
        let replaceMessageModel = PublishSubject<(MessageModel, String)>()
        let searchingResult = PublishSubject<[MessageModel]>()
        let getEmptyPage = PublishSubject<Void>()
        let allTransceivers: BehaviorRelay<[TransceiverModel]> = BehaviorRelay(value: [])
        let othersUnread: BehaviorRelay<Int> = BehaviorRelay(value: 0)
        let unread: BehaviorRelay<Int> = BehaviorRelay(value: 0)
        let updateMessageReadStats = PublishRelay<String>()
        let deleteModels = PublishSubject<[MessageModel]>()
        let floatingViewHidden: BehaviorRelay<Bool> = BehaviorRelay(value: true)
    }
    
    private(set) var isFetching: Bool = false
    let input: Input
    let output = Output()
    private(set) var detail: GroupDetailInfo?
    
    private let messagePageDataQueue = DispatchQueue.init(label: "com.chat.message.page.data.source.queue")
    private let messageProcessQueue = DispatchQueue.init(label: "com.chat.message.process.data.source.queue")
    var group: GroupModel {
        return input.group.value
    }
    private(set) var noPreviousFromDatabase: Bool = false
    private(set) var noPreviousFromServer: Bool = false
    
    private(set) var newestFloatingHongBaoMsgID: String?
    
    private var disposeBag = DisposeBag()
    private let operationQueue: OperationQueue = {
        let operate = OperationQueue()
        operate.maxConcurrentOperationCount = 2
        return operate
    }()
    
    private(set) var _messagePageData = [MessagesPageModel]()
    private(set) var messagePageData: [MessagesPageModel] {
        get {
            return messagePageDataQueue.sync {
                _messagePageData
            }
        }
        
        set {
            self.messagePageDataQueue.async(flags: .barrier) {
                let diffCount = self._messagePageData.count != newValue.count
                self._messagePageData = newValue.sortedAndUpdate(removeDuplicate: diffCount)
            }
        }
    }
    
    private(set) var unreadType: UnreadType = .all(before: nil)
    
    private(set) var _failurePage: MessagesPageModel?
    private(set) var failurePage: MessagesPageModel? {
        get {
            return messagePageDataQueue.sync {
                _failurePage
            }
        }
        set {
            self.messagePageDataQueue.async(flags: .barrier) {
                self._failurePage = newValue
            }
        }
    }
    
    private var bottomMessage: String? {
        return messagePageDataQueue.sync {
            _messagePageData.last?.data.filter { !$0.deleted }.last?.id
        }
    }
    
    func getBottomMessageID() -> String? {
        guard let groupLastMsg = group.lastMessage?.id else { return nil }
        guard let currentBottomMsg = DataAccess.shared.getGroupObserver(by: group.id).lastEffectiveMessageID.value else {
            return groupLastMsg
        }
        
        if isDeletedMessage(messageID: groupLastMsg) || !DataAccess.shared.isExistMessageInDatabase(by: groupLastMsg) {
            return currentBottomMsg
        }

        return groupLastMsg > currentBottomMsg ? groupLastMsg : currentBottomMsg
    }
    
    func isDeletedMessage(messageID: String) -> Bool {
        return DataAccess.shared.isDeletedMessage(by: messageID, at: group.id)
    }
    
    init(group: GroupModel) {
        input = Input(group: BehaviorRelay(value: group))
        if !group.lastViewedID.isEmpty, !group.lastViewedID.isBlank {
            unreadType = .after(from: group.lastViewedID)
        }
        
        initBinding()
        fetchFailureMessages()
    }
    
    func getConversationTransceiver(memberID: String) -> TransceiverModel? {
        input.transceiverDict.value[memberID]
    }
    
    /**
     取得 group 成員清單 (不包含, 已離開或已被踢除的成員)
     - Returns: all transceiver those isMember == true
     */
    func getConversationTransceivers() -> [TransceiverModel] {
        output.allTransceivers.value.filter { $0.isMember }
    }
    
    /**
     取得 group 成員清單 (包含, 已離開或已被踢除的成員)
     - Returns: all transceiver those were in the group
     */
    func getConversationAllTransceiversIncludeLeft() -> [TransceiverModel] {
        output.allTransceivers.value
    }
    
    /**
     release all operation, signal, data
     */
    func release() {
        clearPageData()
        disposeBag = DisposeBag()
        operationQueue.cancelAllOperations()
    }
    
    func clearPageData() {
        messagePageData.removeAll()
    }
    
    func resetFetchPreviousStatus() {
        self.noPreviousFromDatabase = false
        self.noPreviousFromServer = false
    }
    
    func getPageIndex(with identifier: String) -> Int? {
        let index = messagePageData.sorted(by: { $0.first < $1.first }).firstIndex(where: { $0.data.contains(where: { $0.id == identifier }) })
        return index
    }

    func getPageDataIndex(direction: MessageDirection, at page: MessagesPageModel) -> Int? {
        let pages = messagePageData
        guard let compare = pages.first(where: { $0.first == page.first }) else { return nil }
        switch direction {
        case .previous:
            return pages.firstIndex { $0.next == compare.first }
        case .after:
            return pages.lastIndex { $0.first == compare.next }
        }
    }
    
    func getPageDataIndexes(with messageID: String, position: LocatePosition) -> [Int]? {
        guard let index = getPageIndex(with: messageID) else { return nil }

        switch position {
        case .bottom:
            var currentDataCount: Int = 0
            var indexs: [Int] = []
            for i in 0...index {
                currentDataCount += messagePageData[index - i].data.count
                indexs.insert(index - i, at: 0)
                if currentDataCount >= DataAccess.conversationPageSize {
                    return indexs
                }
            }
            return indexs.isEmpty ? [index] : indexs
        case .searchingMessage, .targetMessage, .unread:
            return [index]
        }
    }
    
    func getNewPageAndUpdateMessageStatus(message: MessageModel, originalID: String, isResend: Bool) -> MessagesPageModel? {
        var pageInfo: MessagesPageModel?
        var replaceIndex: Int?
        
        if isResend {
            pageInfo = failurePage
        } else {
            guard let pageIndex = getPageIndex(with: originalID) else {
                return nil
            }
            pageInfo = messagePageData[pageIndex]
            replaceIndex = pageIndex
        }
        
        guard let page = pageInfo, var updatedPage = getUpdatedPageInfo(pageInfo: page, message: message, originalID: originalID) else {
            //TODO: 如果 message是 tmp 應該更新至 failurePage
            if message.id.contains("tmp") {
                let newFailurePage = updateFailurePage(message: message)
                self.failurePage = newFailurePage
                //TODO: remove temp messageData
                if let index = getPageIndex(with: originalID),
                   let dataIndex = self.messagePageData[index].data.firstIndex(where: { $0.diffIdentifier == originalID }) {
                    self.messagePageData[index].data.remove(at: dataIndex)
                    if self.messagePageData[index].data.isEmpty {
                        self.output.pageChanged.onNext((self.messagePageData[index], .delete))
                    }
                }
                return self.failurePage
            }
            return nil
        }
        
        // update page to cache list
        if isResend {
            let data = updatedPage.data.filter { $0.messageStatus != .success }
            updatedPage.data = data
            if updatedPage.data.contains(where: { $0.messageStatus == .failed }) {
                failurePage = updatedPage
            } else {
                failurePage = nil
                /// clear data because failurePage = nil
                /// so need that listener won't continue use failure page
                updatedPage.data.removeAll()
            }
            
            if var lastPage = messagePageData.last {
                let combineData = (lastPage.data + [message]).removeDuplicateElement().sorted(by: { $0.diffIdentifier < $1.diffIdentifier })
                lastPage.data = combineData
                lastPage.first = combineData.first?.diffIdentifier ?? lastPage.first
                lastPage.last = combineData.last?.diffIdentifier ?? lastPage.last
                messagePageData[messagePageData.count - 1] = lastPage
                self.output.pageChanged.onNext((lastPage, .update))
            } else {
                messagePageData.append(updatedPage)
                self.output.pageChanged.onNext((updatedPage, .add))
            }
        } else if let pageIndex = replaceIndex {
            messagePageData[pageIndex] = updatedPage
            if pageIndex >= 1 {
                messagePageData[pageIndex - 1].next = updatedPage.first
            }
        }
        
        return updatedPage
    }
    
    private func updateFailurePage(message: MessageModel) -> MessagesPageModel {
        guard var failurePage = failurePage else {
            let page = MessagesPageModel(first: message.id, last: message.id, containUnread: false, pageSize: 1, data: [message])
            return page
        }
        failurePage.data.append(message)
        failurePage.last = message.diffIdentifier
        failurePage.pageSize = failurePage.data.count
        return failurePage
    }
    
    private func getUpdatedPageInfo(pageInfo: MessagesPageModel, message: MessageModel, originalID: String) -> MessagesPageModel? {
        var pageInfo = pageInfo
        var pageData = pageInfo.data
        guard let dataIndex = pageData.firstIndex(where: { $0.diffIdentifier == originalID }) else { return nil }
        
        let originalModel = pageData[dataIndex]
        guard !MessageModel.compareContent(originalModel, message) else { return nil }
        
        pageData[dataIndex] = message
        pageData.sort { $0.diffIdentifier < $1.diffIdentifier }
        
        let containsTemporaryMessage = pageData.contains { $0.messageStatus.isTemporaryMessage }
        pageInfo.containTemporary = containsTemporaryMessage
        if let first =  pageData.first?.id {
            pageInfo.first = first
        }
        if let last = pageData.last?.id {
            pageInfo.last = last
        }
        
        if pageInfo.next == originalID {
            pageInfo.next = message.diffIdentifier
        }
        
        pageInfo.data = pageData
        return pageInfo
    }
    
    func checkDBData(groupID: String, messageID: String, time: Int, direction: MessageDirection = .previous, fetchTimes: Int = 1) {
        self.fetchDB(groupID: groupID, messageID: messageID, time: time, direction: direction, fetchTimes: fetchTimes)
    }
    
    /**
     抓取前面的訊息
     */
    func fetchPreviousMessages(previousFrom: MessagesPageModel, times: Int = 1) {
        let time = previousFrom.data.first?.timestamp ?? group.createTime
        operationQueue.addOperation {
            self.fetchDB(groupID: self.group.id, messageID: previousFrom.first, time: time, direction: .previous, fetchTimes: times)
        }
    }
    
    func fetchAfterMessages(afterFrom: MessagesPageModel, times: Int = 1) {
        operationQueue.addOperation {
            let time = afterFrom.data.last?.timestamp ?? self.group.timestamp
            self.fetchDB(groupID: self.group.id, messageID: afterFrom.last, time: time, direction: .after, fetchTimes: times)
        }
    }
    
    func searchingMessage(text: String? = nil) {
        guard let searching = text else { return }
        DataAccess.shared.searchDatabase(by: searching, at: group.id) { result in
            self.output.searchingResult.onNext(result ?? [])
        }
    }
    
    func fetchPageMessages(from messageID: String) {
        operationQueue.addOperation {
            let unreadFetchCount = max(0, self.group.unreadCount - DataAccess.conversationPageSize - 1)
            let overOnePage = unreadFetchCount > DataAccess.conversationPageSize
            let after = overOnePage ? 100 : unreadFetchCount == 0 ? 102 : unreadFetchCount
                
            DataAccess.shared.fetchMessages(groupID: self.group.id, messageID: messageID, direction: .previous, limit: 99) { [weak self] (previousModels, _) in
                guard let self = self else { return }
                let nextMessageID = previousModels?.last?.id ?? messageID
                var previousModel: [MessageModel] = []
                if let previousModels = previousModels, !previousModels.isEmpty {
                    previousModel = previousModels
                } else if let messageModel = DataAccess.shared.getMessage(by: messageID) {
                    previousModel = [messageModel]
                }
                    
                DataAccess.shared.fetchMessages(groupID: self.group.id, messageID: nextMessageID, direction: .after, limit: 99) { (models, _) in
                    self.operationQueue.addOperation {
                        var allAfterModels: [MessageModel] = []
                        if let models = models {
                            allAfterModels = Array(models.prefix(after))
                        }
                        self.handleFetchedPage(previous: previousModel, unreadAfter: allAfterModels)
                    }
                }
            }
        }
    }
    
    /**
     傳送圖片訊息
     - Parameters:
     - image: 圖片
     - uploadProgress: 更新進度的 callback
     - complete: 完成上傳的 callback
     */
    func sendImageMessage(_ draftMessage: MessageModel, complete: @escaping (MessageModel, String) -> Void) {
        DataAccess.shared.sendImage(draftMessage: draftMessage) { model, originalID in
            complete(model, originalID)
        }
    }
    
    func createImageMessage(imageFileName: String, index: Int) {
        DataAccess.shared.addDraftMessageAndSendImage(groupID: self.group.id, imageFileName: imageFileName, index: "_\(index)")
    }
    
    func resendImageMessage(with deleteModel: MessageModel, imageFileName: String, index: Int = 0) {
        DataAccess.shared.deleteFailureMessage(deleteModel)
        DataAccess.shared.addDraftMessageAndSendImage(groupID: self.group.id, imageFileName: imageFileName, index: "_\(index)")
    }
    
    func setReadMessage(_ readID: String) {
        guard readID > group.lastViewedID, input.isReading.value else { return }
        PRINT("set group \(group.id) read message \(readID)")
        DataAccess.shared.setReadMessage(readID, groupID: group.id)
    }
    
    // 重新設置 messagePageData資料,根據資料數量決定,保留最後一兩頁
    func resetPages() {
        guard let lastPageSize = messagePageData.last?.data.count, lastPageSize < DataAccess.conversationPageSize else {
            messagePageData = messagePageData.suffix(1)
            return
        }
        messagePageData = messagePageData.suffix(2)
    }
    
    func isMessageDataContinuous(page: MessagesPageModel, currentMessage: String, direction: MessageDirection, completion: @escaping (Bool) -> Void) {
        DataAccess.shared.fetchMessages(groupID: group.id, messageID: currentMessage, direction: direction, limit: 10) { serverModels in
            guard let models = serverModels, !models.isEmpty else {
                completion(false)
                return
            }
            let compareID = direction == .previous ? page.last : page.first
            
            let isContinuous = models.contains(where: { $0.id == compareID }) || page.data.contains(where: { $0.id == currentMessage })
            completion(isContinuous)
        }
    }
    
    func getHongBaoContent(by messageID: String, completion: @escaping (HongBaoContent?) -> Void) {
        DataAccess.shared.getHongBaoContent(by: messageID, groupID: group.id) { content in
            completion(content)
        }
    }
    
    func updateFloatingViewHidden(hidden: Bool) {
        self.output.floatingViewHidden.accept(hidden)
    }
    
    func setFloatingHongBaoMsgID(with messageID: String) {
        self.newestFloatingHongBaoMsgID = messageID
    }
}

private extension ConversationDataSource {
    /**
     observer signal
     */
    func initBinding() {
        DataAccess.shared.getGroupObserver(by: group.id).transceiverDict.bind(to: input.transceiverDict).disposed(by: disposeBag)
        DataAccess.shared.getGroupObserver(by: group.id).transceiverDict.map { Array($0.values) }.bind(to: output.allTransceivers).disposed(by: disposeBag)
        DataAccess.shared.getGroupObserver(by: group.id).groupObserver.bind(to: input.group).disposed(by: disposeBag)
        DataAccess.shared.getGroupObserver(by: group.id).announcements.bind(to: input.announcements).disposed(by: disposeBag)
        DataAccess.shared.getGroupObserver(by: group.id).rolePermission.bind(to: input.rolePermission).disposed(by: disposeBag)
        DataAccess.shared.getGroupObserver(by: group.id).fetchUnopendHongBao.bind(to: input.fetchUnopenedHongBao).disposed(by: disposeBag)
        DataAccess.shared.getGroupObserver(by: group.id).unread.bind(to: output.unread).disposed(by: disposeBag)
        DataAccess.shared.unread.map { $0 }.bind(to: output.othersUnread).disposed(by: disposeBag)
        DataAccess.shared.getGroupObserver(by: group.id).lastRead.subscribeSuccess { [unowned self] id in
            guard let id = id else { return }
            output.updateMessageReadStats.accept(id)
        }.disposed(by: disposeBag)
        DataAccess.shared.getGroupObserver(by: group.id).lastViewed.skip(1).subscribeSuccess { [weak self] messageID in
            guard let self = self else { return }
            guard let messageID = messageID else { return }
            self.unreadType = .after(from: messageID)
        }.disposed(by: disposeBag)
        DataAccess.shared.lastReadingConversation.withPrevious(startWith: "").subscribeSuccess { [unowned self] seed, newValue in
            guard !seed.isEmpty else {
                self.resetPages()
                return
            }
            guard newValue != group.id, seed == group.id else { return }
            input.isReading.accept(false)
        }.disposed(by: disposeBag)
        
        input.group.distinctUntilChanged { $0.groupType }.subscribeSuccess { [unowned self] groupModel in
            // 目前需求來說應該是不會發生改變 group.type 的情況, 先預留...
            guard groupModel.groupType == .dm else {
                detail = GroupDetailInfo()
                return
            }
            detail = nil
        }.disposed(by: disposeBag)
        
        input.updateMessage.subscribe { [weak self] model, action in
            guard let self = self else { return }
            self.updateMessage(message: model, action: action)
        }.disposed(by: disposeBag)
        
        input.isReading.skip(1).subscribeSuccess { [unowned self] isReadingNow in
            guard isReadingNow else {
                let readingGroupID = DataAccess.shared.lastReadingConversation.value
                guard readingGroupID != group.id else {
                    return
                }
                PRINT("end reading conversation id = \(group.id)")
                endReadingConversation()
                return
            }
            
            PRINT("start reading conversation id = \(group.id)")
            startReadingConversation()
        }.disposed(by: disposeBag)
        
        input.replaceMessage.subscribe { [weak self] model, originalID in
            guard let self = self else { return }
            self.replaceMessage(from: originalID, message: model)
        }.disposed(by: disposeBag)
    }
    
    // MARK: - fetch data
    func fetchDB(groupID: String, messageID: String, time: Int, direction: MessageDirection, fetchTimes: Int) {
        guard fetchTimes > 0 else { return }
        DataAccess.shared.getMessages(groupID: groupID, messageID: messageID, direction: direction) { [weak self] models, _ in
            guard let self = self else { return }
            guard let models = models, !models.isEmpty else {
                if direction == .previous {
                    self.noPreviousFromDatabase = true
                }
                self.fetchServer(groupID: groupID, messageID: messageID, direction: direction, fetchTimes: fetchTimes) { serverModels in
                    // 如果Server沒資料, 再打一次 currentTime 重新抓一次
                    guard serverModels != nil else {
                        let timestamp = Int(Date.init().timeIntervalSince1970 * 1000)
                        self.fetchServer(groupID: groupID, time: timestamp, direction: direction, fetchTimes: fetchTimes) { latestModels in
                            guard let lastData = latestModels?.last else { return }
                            self.refetchDB(groupID: groupID, messageID: messageID, direction: direction, serverMessage: lastData)
                        }
                        return
                    }
                    // refresh Page data
                    guard let firstMessage = serverModels?.first else { return }
                    self.refetchDB(groupID: groupID, messageID: messageID, direction: direction, serverMessage: firstMessage)
                }
                return
            }
            if direction == .previous {
                self.noPreviousFromDatabase = models.count < DataAccess.conversationPageSize
            }
            // server和 DB 比對
            self.operationQueue.addOperation {
                var dbModels = models
                if !models.filter { $0.id != messageID }.isEmpty {
                    dbModels = models.filter { $0.id != messageID }
                }
                
                self.handlePageInfo(messageModels: dbModels, messageID: messageID, direction: direction)
                self.fetchServer(groupID: groupID, messageID: messageID, direction: direction, fetchTimes: fetchTimes) { serverModels in
                    // if diff refresh Page data
                    if let serverModels = serverModels {
                        let diff = serverModels.difference(from: dbModels)
                        let modelsDiff = dbModels.filter { model in
                            return !serverModels.contains { $0.id == model.id }
                            }
                        
                        let checkIsDeleteDiff = diff.filter { !DataAccess.shared.isExistMessageInDatabase(by: $0.id) }
                        // 有checkIsDeleteDiff重新抓一次, 多檢查 local delete的問題
                        if !modelsDiff.isEmpty {
                            let firstID = modelsDiff.first?.id ?? ""
                            self.removePagesData(models: modelsDiff)
                            self.handlePageInfo(messageModels: modelsDiff, messageID: firstID, direction: direction)
                        }
                        if !checkIsDeleteDiff.isEmpty {
                            self.refetchDB(groupID: groupID, messageID: messageID, direction: direction)
                            return
                        }
                        guard !diff.isEmpty else { return }
                        
                        // 有Diff
                        guard let first = serverModels.first else {
                            self.refetchDB(groupID: groupID, messageID: messageID, direction: direction)
                            return
                        }
                        self.refetchDB(groupID: groupID, messageID: messageID, direction: direction, serverMessage: first)
                    }
                }
            }
        }
    }
    
    func fetchServer(groupID: String, time: Int, direction: MessageDirection, fetchTimes: Int, completion: @escaping ([MessageModel]?) -> Void) {
        guard fetchTimes > 0 else { return }
        DataAccess.shared.fetchMessages(groupID: groupID, timestamp: time, direction: direction) { [weak self] (models, _) in
            guard let self = self else { return }
            guard let models = models, !models.isEmpty else {
                completion(nil)
                return
            }
            // 確認 message_delete的 targetID 是否有清除
            models.forEach { message in
                if message.messageType == .unsend {
                    DataAccess.shared.deleteMessageInDatabase(by: message.targetID)
                }
            }
            self.noPreviousFromServer = models.count < DataAccess.conversationPageSize
            completion(models)
        }
    }
    
    func fetchServer(groupID: String, messageID: String, direction: MessageDirection, fetchTimes: Int, completion: @escaping ([MessageModel]?) -> Void) {
        guard fetchTimes > 0 else { return }
        // 暫時增加一點數字 給點Range做比對 主要是 大量訊息可能會造成的誤差
        // TODO: 之後優化時會調整修正
        let deviation: Int = 10
        DataAccess.shared.fetchMessages(groupID: groupID, messageID: messageID, direction: direction, limit: DataAccess.conversationPageSize + deviation) { [weak self] (models, _) in
            guard let self = self else { return }
            guard let models = models, !models.isEmpty else {
                completion(nil)
                return
            }
            // 確認 message_delete的 targetID 是否有清除
            models.forEach { message in
                if message.messageType == .unsend {
                    DataAccess.shared.deleteMessageInDatabase(by: message.targetID)
                }
            }
            if direction == .previous {
                self.noPreviousFromServer = models.count < DataAccess.conversationPageSize
            }
            completion(models.sorted { $0.diffIdentifier < $1.diffIdentifier })
        }
    }
    
    private func refetchDB(groupID: String, messageID: String, direction: MessageDirection, serverMessage: MessageModel? = nil) {
        DataAccess.shared.getMessages(groupID: groupID, messageID: messageID, direction: direction) { [weak self] models, _ in
            // 若DB 資料為空, 重新fetchDB
            guard let self = self else { return }
            guard let models = models, !models.isEmpty else {
                guard let serverMessage = serverMessage else { return }
                self.fetchDB(groupID: groupID, messageID: messageID, time: serverMessage.timestamp, direction: direction, fetchTimes: 1)
                return
            }
            var dbModels = models
            if !models.filter { $0.id != messageID }.isEmpty {
                dbModels = models.filter { $0.id != messageID }
            }
            
            //若 DB資料只有messageID, DB沒更多資料但Server仍有 重新fetchDB
            if let serverMessage = serverMessage, dbModels.isEmpty && self.noPreviousFromDatabase && !self.noPreviousFromServer {
                self.fetchDB(groupID: groupID, messageID: messageID, time: serverMessage.timestamp, direction: direction, fetchTimes: 1)
                return
            }
            
            self.handlePageInfo(messageModels: dbModels, messageID: messageID, direction: direction)
        }
    }
    
    func removePagesData(models: [MessageModel]) {
        var newMessagePageData = messagePageData
        for model in models {
            if let pageIndex = newMessagePageData.firstIndex(where: { $0.data.contains(model) }) {
                if let dataIndex = newMessagePageData[pageIndex].data.firstIndex(where: { $0.id == model.id }) {
                    newMessagePageData[pageIndex].data.remove(at: dataIndex)
                    if newMessagePageData[pageIndex].data.isEmpty {
                        newMessagePageData.remove(at: pageIndex)
                    }
                }
            }
        }
        messagePageData = newMessagePageData
        self.output.deleteModels.onNext(models)
    }
    
    func fetchFailureMessages() {
        DataAccess.shared.getFailureMessages(groupID: group.id) { [weak self] failureMessages in
            guard let self = self else { return }
            guard let first = failureMessages.first, let last = failureMessages.last else {
                self.failurePage = nil
                return
            }
            
            self.failurePage = MessagesPageModel(first: first.diffIdentifier, last: last.diffIdentifier, next: nil, containUnread: false, pageSize: failureMessages.count, data: failureMessages)
        }
    }
    
    func handlePageInfo(messageModels: [MessageModel], messageID: String, direction: MessageDirection) {
        guard let first = messageModels.first else {
            self.output.getEmptyPage.onNext(())
            return
        }
        let recordModel = DataAccess.shared.getGroupRecord(by: self.group.id)
        if messageModels.contains(where: { $0.timestamp < recordModel.deleteTime }) {
            self.noPreviousFromDatabase = true
        }
        let newMessageModels = messageModels.filter { !$0.deleted && $0.timestamp > recordModel.deleteTime && !$0.isBlocked }
        handleMessageTransceiver(models: newMessageModels)
        let next: String? = direction == .previous ? messageID : nil
        newPageInfo(with: newMessageModels, next: next)
        
        guard direction == .after, let previousIndex = messagePageData.firstIndex(where: { $0.last == messageID }) else { return }
        var previousPage = messagePageData[previousIndex]
        previousPage.next = first.diffIdentifier
        updatePagesInfo(page: previousPage, pageIndex: previousIndex)
    }
    
    func newPageInfo(with models: [MessageModel], next: String? = nil) {
        
        guard let first = models.first else { return }
        
        let frontRepeatIndex = messagePageData.firstIndex(where: { first.id >= $0.first && first.id <= $0.last })
        
        var newModels = models
        if let front = frontRepeatIndex {
            let frontPage = messagePageData[front]
            newModels.removeAll { $0.diffIdentifier <= frontPage.last }
            let data = models.filter({ $0.diffIdentifier <= frontPage.last && $0.diffIdentifier >= frontPage.first })
            if !data.isEmpty {
                compressRepeatData(at: front, models: data, next: front == messagePageData.count - 1 ? nil : next)
            }
        }
        
        guard !newModels.isEmpty else { return }
        
        let behindRepeatIndex = messagePageData.firstIndex(where: { $0.data.isIntersects(newModels) })
        
        if let behind = behindRepeatIndex {
            let behindPage = messagePageData[behind]
            let data = newModels.filter { $0.diffIdentifier >= behindPage.first }
            if !data.isEmpty {
                compressRepeatData(at: behind, models: data, next: behind == messagePageData.count - 1 ? nil : next)
            }
            newModels.removeAll { $0.diffIdentifier >= behindPage.first }
        }
        guard !newModels.isEmpty else { return }
        guard let first = newModels.first, let last = newModels.last else { return }
        
        // 檢查是否可以壓縮至同一頁
        self.zippableData(models: newModels) { isZippable in
            guard !isZippable else { return }
            var page = MessagesPageModel(first: first.diffIdentifier, last: last.diffIdentifier, next: next, containUnread: false, pageSize: newModels.count, data: newModels)
            let containsTemporaryMessage = models.contains { $0.messageStatus.isTemporaryMessage }
            page.containTemporary = containsTemporaryMessage
            self.updatePagesInfo(page: page)
        }
    }
    
    /*
    檢查前後的Page data數量, 是否足夠放入新資料
    若都沒有,新增Page
    */
    func zippableData(models: [MessageModel], completion: @escaping (Bool) -> Void) {
        guard let first = models.first, let last = models.last else {
            completion(false)
            return
        }

        if let zippableFrontIndex = messagePageData.lastIndex(where: { $0.last > first.diffID && $0.first < last.diffIdentifier }), !first.diffID.contains("tmp") {
            let zippableFrontPage = messagePageData[zippableFrontIndex]
            if zippableFrontPage.data.count + models.count <= DataAccess.conversationPageSize {
                isMessageDataContinuous(page: zippableFrontPage, currentMessage: first.id, direction: .previous) { [weak self] isContinuous in
                    guard let self = self else {
                        completion(false)
                        return
                    }
                    if isContinuous {
                        self.compressRepeatData(at: zippableFrontIndex, models: models)
                    }
                    completion(isContinuous)
                }
            } else {
                completion(false)
            }
        } else if let zippableBehindIndex = messagePageData.firstIndex(where: { last.diffID < $0.first }), !last.diffID.contains("tmp") {
            let zippableBehindPage = messagePageData[zippableBehindIndex]
            if zippableBehindPage.data.count + models.count <= DataAccess.conversationPageSize {
                isMessageDataContinuous(page: zippableBehindPage, currentMessage: last.id, direction: .after) { [weak self] isContinuous in
                    guard let self = self else {
                        completion(false)
                        return
                    }
                    if isContinuous {
                        self.compressRepeatData(at: zippableBehindIndex, models: models)
                    }
                    completion(isContinuous)
                }
            } else {
                completion(false)
            }
        } else {
            completion(false)
        }
    }
    
    func compressRepeatData(at pageIndex: Int, models: [MessageModel], next: String? = nil) {
        var newPages = messagePageData
        var page = newPages[pageIndex]
        
        let newPageData = (models.filter { $0.deleted != true && $0.isBlocked != true } + page.data.filter { $0.deleted != true && $0.isBlocked != true }).removeDuplicateElement().sorted { $0.diffIdentifier < $1.diffIdentifier }
        page.data = newPageData
        page.first = newPageData.first?.diffIdentifier ?? page.first
        page.last = newPageData.last?.diffIdentifier ?? page.last

        newPages[pageIndex] = page
        messagePageData = newPages
        output.pageChanged.onNext((page, .update))
    }
    
    func updatePagesInfo(page: MessagesPageModel, pageIndex: Int? = nil) {
        let originalCount = messagePageData.count
        var newPages = messagePageData
        
        guard let pageIndex = pageIndex else {
            // add new page
            newPages.removeAll { MessagesPageModel.compareContent($0, page) }
            newPages.append(page)
            
            messagePageData = newPages
            
            let isEqual = newPages.count == originalCount
            guard isEqual else {
                output.pageChanged.onNext((page, .add))
                return
            }
            output.pageChanged.onNext((page, .update))
            return
        }
        var newPageInfo = newPages[pageIndex]
        newPageInfo.data = page.data
        newPageInfo.containTemporary = page.data.contains(where: { $0.id.contains("tmp") })
        guard let first = newPageInfo.data.first, let last = newPageInfo.data.last else { return }
        newPageInfo.first = first.id
        newPageInfo.last = last.id
        newPageInfo.next = page.next
        if pageIndex >= 1 {
            newPages[pageIndex - 1].next = first.id
        }
        newPages.remove(at: pageIndex)
        newPages.insert(newPageInfo, at: pageIndex)
        messagePageData = newPages
        output.pageChanged.onNext((newPageInfo, .update))
    }
    
    func handleMessageTransceiver(models: [MessageModel]) {
        let currentTransceiverDict = input.transceiverDict.value
        var unknownUsers: [String] = []
        models.forEach { message in
            if currentTransceiverDict[message.userID] == nil {
                unknownUsers.append(message.userID)
            }
            if let target = message.targetUser, currentTransceiverDict[target] == nil {
                unknownUsers.append(target)
            }
        }
        
        guard !unknownUsers.isEmpty else { return }
        DataAccess.shared.fetchGroupMembers(groupID: group.id, memberIDs: unknownUsers)
    }
    
    func endFetchMessage() {
        
    }
    
    /**
     取得指定 page.index 的前後 page.index list
     - Parameters:
     - centerIndex: 指定的 page.index
     - limit: page.index list 的上限
     - Returns: [page.index] list
     */
    func getPagesIndexes(centerIndex: Int, max limit: Int = ConversationInteractor.limitPage) -> [Int] {
        let pages = messagePageData
        
        var indexes = [Int]()
        indexes.append(centerIndex)
        var comparePage: MessagesPageModel = pages[centerIndex]
        var pageIndex = centerIndex - 1
        
        let limitPrevious: Int = Int(ceil(Double(limit / 2)))
        while pageIndex >= 0, indexes.count <= limitPrevious {
            let previous = pages[pageIndex]
            if previous.next == comparePage.first {
                comparePage = previous
                indexes.append(pageIndex)
            } else {
                break
            }
            pageIndex -= 1
        }
        
        pageIndex = centerIndex + 1
        comparePage = pages[centerIndex]
        let total = pages.count
        while pageIndex < total, indexes.count < limit {
            let after = pages[pageIndex]
            if after.first == comparePage.next {
                comparePage = after
                indexes.append(pageIndex)
            } else {
                break
            }
            pageIndex += 1
        }
        return indexes.sorted(by: <)
    }
    
    /**
     處理 unread page data
     - Parameters:
     - previous: group.lastViewID 前的 message data
     - unreadAfter: group.lastViewID 及之後的 message data
     - nextMessageID: 是否有超過一頁 DataAccess.conversationPageSize + lastMessage
     */
    func handleFetchedPage(previous: [MessageModel], unreadAfter: [MessageModel]) {
        messageProcessQueue.async { [weak self] in
            guard let self = self else { return }
            let allMessages = (previous + unreadAfter).removeDuplicateElement().sorted { $0.diffIdentifier < $1.diffIdentifier }.filter { !$0.isBlocked }
            let messageID = allMessages.first?.id ?? ""
            self.handlePageInfo(messageModels: allMessages, messageID: messageID, direction: .previous)
        }
    }
    
    /**
     替換掉 message
     - Parameters:
     - originalID: 原本的 cache messageID
     - message: 新的 Message.model
     */
    func replaceMessage(from originalID: String, message: MessageModel) {
        if let pageIndex = messagePageData.firstIndex(where: { pageInfo in pageInfo.data.contains { $0.diffIdentifier == originalID } }) {
            guard let page = getUpdatedPageInfo(pageInfo: messagePageData[pageIndex], message: message, originalID: originalID) else { return }
            output.replaceMessageModel.onNext((message, originalID))
            updatePagesInfo(page: page, pageIndex: pageIndex)
        } else {
            operationQueue.addOperation(updateMessage(message))
        }
    }
    
    // MARK: - update data
    func updateMessage(message: MessageModel, action: DataAction) {
        switch action {
        case .delete:
            operationQueue.addOperation(deleteMessage(message))
        case .update:
            operationQueue.addOperation(updateMessage(message))
        case .add:
            operationQueue.addOperation(addMessages(message))
        default:
            break
        }
    }
    
    // MARK: - messages operation, delete, update, insert
    func deleteMessage(_ message: MessageModel) -> BlockOperation {
        return BlockOperation {
            // 確認是否為 failureMessage
            self.output.deleteMessage.onNext(message)
            
            if var failPage = self.failurePage,
               let index = failPage.data.firstIndex(where: { $0.diffIdentifier == message.id }) {
                failPage.data.remove(at: index)
                self.failurePage?.data = failPage.data
                self.output.pageChanged.onNext((failPage, .update))
            }
            
            guard let index = self.getPageIndex(with: message.diffIdentifier) else {
                return
            }
            
            // 清空相關的 threadMessage
            self.messagePageData = self.messagePageData.map { pageData in
                var newPageData = pageData
                var newData = pageData.data
                newData = newData.map { data in
                    var new = data
                    if new.threadID == message.id {
                        new.threadMessage = []
                    }
                    return new
                }
                newPageData.data = newData
                return newPageData
            }
            
            var pageInfo = self.messagePageData[index]
            var newData = pageInfo.data
            newData.removeAll { $0.id == message.id }
            newData = newData.sorted(by: { $0.diffIdentifier < $1.diffIdentifier })
            
            guard let first = newData.first, let last = newData.last else {
                // 刪除 Message 後 沒有其他資料, 直接刪除 Page
                pageInfo.data = []
                self.output.pageChanged.onNext((pageInfo, .delete))
                self.messagePageData.remove(at: index)
                return
            }
            
            pageInfo.first = first.diffIdentifier
            pageInfo.last = last.diffIdentifier
            pageInfo.data = newData
            pageInfo.containTemporary = pageInfo.data.contains(where: { $0.id.contains("tmp") })
            
            self.messagePageData[index] = pageInfo
            if index >= 1 {
                self.messagePageData[index - 1].next = pageInfo.first
            }
            self.output.pageChanged.onNext((pageInfo, .update))
        }
    }
    
    func updateMessage(_ message: MessageModel) -> BlockOperation {
        return BlockOperation {
            guard let pageIndex = self.getPageIndex(with: message.diffIdentifier) else {
                // 抓不到可更新的message 就不做更新
                return
            }
            
            var pageInfo = self.messagePageData[pageIndex]
            var data = pageInfo.data
            // TODO: if can't find do?????
            guard let dataIndex = data.firstIndex(where: { $0.diffIdentifier == message.diffIdentifier }) else { return }
            if message.messageStatus == .failed {
                data.remove(at: dataIndex)
                pageInfo.data = data
                self.messagePageData[pageIndex] = pageInfo
                self.output.pageChanged.onNext((pageInfo, .update))
                
                let failurePage = self.updateFailurePage(message: message)
                self.failurePage = failurePage
                self.output.pageChanged.onNext((failurePage, .update))
                return
            }
            
            data[dataIndex] = message
            pageInfo.data = data
            self.messagePageData[pageIndex] = pageInfo
            self.output.pageChanged.onNext((pageInfo, .update))
        }
    }
    
    func addMessages(_ models: MessageModel...) -> BlockOperation {
        return addMessages(models)
    }
    
    func addMessages(_ models: [MessageModel]) -> BlockOperation {
        return BlockOperation {
            let sortedModels = models.sorted { $0.id < $1.id }
            if let last = sortedModels.last, !last.id.contains("tmp") && last.id > self.group.lastViewedID {
                self.setReadMessage(last.id)
            }
            
            guard let firstModel = models.first else { return }
            let pageData = self.messagePageData
            //TODO: get correct index if not in pageIndex
            var pageIndex: Int = pageData.count - 1
            if let index = self.getPageIndex(with: firstModel.diffIdentifier) {
                pageIndex = index
            } else if let insertIndex = self.messagePageData.firstIndex(where: { firstModel.diffIdentifier >= $0.first.diffIdentifier && firstModel.diffIdentifier <= $0.last.diffIdentifier }) {
                pageIndex = insertIndex
            }
            
            guard pageIndex >= 0 else {
                self.newPageInfo(with: models)
                return
            }
            
            var pageInfo = pageData[pageIndex]
            let containsTemporaryMessage = models.contains { $0.messageStatus.isTemporaryMessage }
            // && firstModel.messageType != .unsend
            if firstModel.messageType != .unsend && pageInfo.pageSize >= DataAccess.conversationPageSize {
                pageInfo.next = firstModel.diffIdentifier
                self.messagePageData[pageIndex] = pageInfo
                self.output.pageChanged.onNext((pageInfo, .update))
                self.newPageInfo(with: models)
                return
            }
            let newData = (pageInfo.data + models).removeDuplicateElement().sorted { $0.diffIdentifier < $1.diffIdentifier }
            guard let first = newData.first, let last = newData.last else { return }
            pageInfo.containTemporary = containsTemporaryMessage
            
            if pageIndex == pageData.count - 1 {
                pageInfo.next = nil
            }
            //TODO: next should set
            pageInfo.data = newData
            pageInfo.first = first.diffIdentifier
            pageInfo.last = last.diffIdentifier
            
            if pageIndex >= 1 {
                self.messagePageData[pageIndex - 1].next = first.diffIdentifier
            }
            self.messagePageData[pageIndex] = pageInfo
            
            self.output.pageChanged.onNext((pageInfo, .update))
        }
    }
}

// MARK: stop reading
private extension ConversationDataSource {
    /**
     停止讀取對話
     */
    func endReadingConversation() {
        resetPages()
    }
    
    /**
     開始讀取對話
     */
    func startReadingConversation() {
        guard let lastMessageId = group.lastMessage?.diffID else { return }
        setReadMessage(lastMessageId)
    }
    
    /**
     丟棄較舊的 page data, 減少 cache data 數量
     */
    func dropOlderPages() {
        var pages = messagePageData
        let total = pages.count
        
        guard total > ConversationDataSource.defaultPreparePageCount else { return }
        let prepareCount = DataAccess.conversationPageSize * ConversationDataSource.defaultPreparePageCount
        var pageDataCount: Int = 0
        var index = total
        var page: MessagesPageModel!
        while pageDataCount < prepareCount && index >= 1 {
            index -= 1
            page = pages[index]
            pageDataCount += page.pageSize
        }
        
        pages.removeAll(where: { $0.first < page.first })
        messagePageData = updateMessagePagesUnreadStatus(pages)
    }
    
    func updateMessagePagesUnreadStatus(_ originalPageData: [MessagesPageModel]) -> [MessagesPageModel] {
        return originalPageData.map {
            var model = $0
            model.containUnread = checkContainUnread(first: model.first, last: model.last)
            return model
        }
    }
    
    func checkContainUnread(first: String, last: String) -> Bool {
        group.lastViewedID >= first && last <= group.lastViewedID
    }
}
