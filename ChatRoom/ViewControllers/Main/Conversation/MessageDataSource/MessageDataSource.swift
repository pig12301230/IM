//
//  MessageDataSource.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/6/16.
//

import Foundation
import RxSwift
import RxCocoa


class MessageDataSource {

    struct Input {
        let newMessage: BehaviorRelay<MessageModel?> = BehaviorRelay(value: nil)
        let updateMessage: BehaviorRelay<MessageModel?> = BehaviorRelay(value: nil)
        let deleteMessage: BehaviorRelay<MessageModel?> = BehaviorRelay(value: nil)
        let lastReadMessage: BehaviorRelay<MessageModel?> = BehaviorRelay(value: nil)
    }

    struct Output {
        let reloadSection = PublishRelay<Int>()
        let memberCount: BehaviorRelay<Int> = BehaviorRelay(value: 0)
        let transceiversListUpdate = PublishSubject<Void>()
        let updateReadStatus = PublishRelay<String>()
        let otherUnread: BehaviorRelay<Int> = BehaviorRelay(value: 0)
        
        let updateMessageData = PublishRelay<[MessageViewModel]>()
        let updateAnnouncements: BehaviorRelay<[AnnouncementModel]> = BehaviorRelay(value: [])
    }
    private lazy var operactionQueue: OperationQueue = {
        let operation = OperationQueue.init()
        operation.maxConcurrentOperationCount = 1
        return operation
    }()
    private var disposeBag = DisposeBag()

    let currentContentType: BehaviorRelay<ConversationContentType> = BehaviorRelay(value: .nature)
    let messageUpdate = PublishRelay<Void>()

    let dataManager = DataAccessManager.shared
    let input = Input()
    let output = Output()

    private(set) var group: GroupModel!
    private(set) var transceivers: [TransceiverModel] = []
    private(set) var transciversDict = [String: TransceiverModel]()
    
    private let messageQueue = DispatchQueue.init(label: "com.chat.message.data.source.queue")
    private(set) var _messages: [MessageModel] = []
    private(set) var messages: [MessageModel] {
        get {
            return messageQueue.sync {
                _messages
            }
        }
        set {
            self.messageQueue.async(flags: .barrier) {
                self._messages = newValue
            }
        }
    }
    
    private(set) var _messageItems: [MessageViewModel] = [] {
        didSet {
            self.output.updateMessageData.accept(_messageItems)
        }
    }
    private(set) var messageItems: [MessageViewModel] {
        get {
            return messageQueue.sync {
                _messageItems
            }
        }
        set {
            self.messageQueue.async(flags: .barrier) {
                self._messageItems = newValue
            }
        }
    }
    
    private var _successMessageItems: [MessageViewModel] = []
    private var successMessageItems: [MessageViewModel] {
        get {
            return messageQueue.sync {
                _successMessageItems
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
                _failureMessageItems
            }
        }
        set {
            self.messageQueue.async(flags: .barrier) {
                self._failureMessageItems = newValue
            }
        }
    }
    
    private(set) var unreadIndexPath: IndexPath?
    private(set) var lastReadMessage: MessageModel? // 聊天室內最後一則被讀的訊息
    private(set) var unreadLastMessage: MessageModel?
    var isReading: Bool = false
    private var isFinishPreload: Bool = false
    private var updateLastViewSuccess: Bool = false

    // For, Search
    var searchResource: [TextMessageCellVM] = []
    var searchResults: [TextMessageCellVM] = []

    init(group: GroupModel) {
        self.group = group
        
        self.fetchTransceiversData()
        // 綁定 data manager observer
        self.bindGroupObserver()
        
        self.initBinding()
    }

    func updateGroup(to group: GroupModel) {
        self.group = group

        // TODO: 更新訊息？
    }
    
    func updateTransceiver(by memberID: String) {
        guard let model = DataAccessManager.shared.getDatabaseUserPersonalSetting(memberID: memberID) else {
           return
        }
        
        if let index = self.transceivers.firstIndex(where: { $0.userID == memberID }) {
            self.transceivers[index].display = model.nickname ?? self.transceivers[index].nickname
            transciversDict[memberID] = self.transceivers[index]
        }
    }
    
    func updateTransceivers(to transceivers: [TransceiverModel]) {
        let personalSettingsDict = self.fetchPersonalSettingsDict()
        let newTrans = transceivers.map { transceiver -> TransceiverModel in
            var newTran = transceiver
            if let nickname = personalSettingsDict[newTran.userID]?.nickname {
                newTran.display = nickname ?? newTran.nickname
            }
            return newTran
        }
        self.transceivers = newTrans
        self.transciversDict = newTrans.toDictionary { $0.userID }
        
        let count = transceivers.filter { $0.isMember == true }.count
        self.output.memberCount.accept(count)
        if self.isFinishPreload {
            self.fetchMessageData()
        }
        
        self.output.transceiversListUpdate.onNext(())
    }

    func prepearResendImageMessage(_ model: MessageModel) {
        var messageModel = model
        messageModel.messageStatus = .uploading
        guard let section = self.messageItems.firstIndex(where: { $0.model?.id == messageModel.id }) else {
            return
        }

        var lastMessage: MessageModel?
        if section > 0, self.messageItems.count > section - 1 {
            lastMessage = self.messageItems[section - 1].model
        }

        if let newSection = self.convertSectionModel(with: messageModel, preMessage: lastMessage) {
            self.messageItems[section] = newSection
            if let failureSection = self.failureMessageItems.firstIndex(where: { $0.model?.id == messageModel.id }) {
                self.failureMessageItems[failureSection] = newSection
            }
        }

        self.output.reloadSection.accept(section)
    }

    func updateImageMessageFractionCompleted(_ messageID: String, fractionCompleted: Double) {
        guard let section = self.messageItems.first(where: { $0.model?.id == messageID }) else {
            return
        }

        if let index = self.messageItems.firstIndex(where: { $0.model?.id == messageID }) {
            self.output.reloadSection.accept(index)
        }
        if let imageCellVM = section.cellModel as? ImageMessageCellVM {
            imageCellVM.updateFractionCompleted(fractionCompleted)
        }
    }

    /**
     處理 message 上傳成功後的 data 行為
     */
    func updateMessageProcessComplete(success: Bool, message: MessageModel, originalID: String, isResend: Bool) {
        guard var originalIndex = self.messageItems.firstIndex(where: { $0.model?.id == originalID }) else {
            return
        }

        if isResend, !success {
            // 重新發送且失敗, 只針對 section 做 reload
            self.output.reloadSection.accept(originalIndex)
            return
        }

        var newIndex = self.getRowIndex(message: message, originalID: originalID)
        var lastMessage: MessageModel?
        if newIndex > 0, self.messageItems.count > newIndex - 1 {
            lastMessage = self.messageItems[newIndex - 1].model
        }

        guard let sectionItem = self.convertSectionModel(with: message, preMessage: lastMessage) else {
            return
        }

        if success {
            self.failureMessageItems.removeAll(where: { $0.model?.id == originalID })

            if let dateTimeItem = self.createDateTime(lastMessage: lastMessage, message: message) {
                // 加入dateTimeItem
                self.messageItems.insert(dateTimeItem, at: originalIndex)
                self.successMessageItems.append(dateTimeItem)
                // 更新index
                originalIndex += 1
                newIndex += 1
            }

            if self.successMessageItems.count > originalIndex {
                self.successMessageItems[originalIndex] = sectionItem
            } else {
                self.successMessageItems.append(sectionItem)
            }
        } else {
            let failedIndex = originalIndex - self.successMessageItems.count
            if self.failureMessageItems.count > failedIndex {
                self.failureMessageItems[failedIndex] = sectionItem
            } else {
                self.failureMessageItems.removeAll(where: { $0.model?.id == originalID })
                self.failureMessageItems.append(sectionItem)
            }
        }

        self.messageItems = self.successMessageItems + self.failureMessageItems
    }

    func updateLastView() {
        guard let lastSuccess = self.unreadLastMessage, self.isReading else {
            return
        }
        
        self.updateLastViewMessage(lastSuccess, groupInfo: self.group)
    }

    func getIndexPath(by messageModel: MessageModel) -> IndexPath? {
        guard let index = self.messageItems.firstIndex(where: { $0.model?.id == messageModel.id }) else {
            return nil
        }
        return IndexPath(row: index, section: 0)
    }
    
    func setAllMessageRead(_ reading: Bool = false) {
        self.isReading = reading
        guard let indexPath = self.unreadIndexPath, self.updateLastViewSuccess else {
            return
        }
        
        self.unreadIndexPath = nil
        self.successMessageItems.remove(at: indexPath.row)
        self.messageItems.remove(at: indexPath.row)
    }
    
    func fetchTransceiversData() {
        guard let transceivers = DataAccessManager.shared.getGroupTransceivers(by: group.id, onlyMember: false) else { return }
        self.updateTransceivers(to: transceivers)
    }
    
    func fetchPersonalSettingsDict() -> [String: UserPersonalSettingModel] {
        return DataAccessManager.shared.getDatabasePersonalSettings()
    }
}

// MARK: - Init
private extension MessageDataSource {
    func fetchMessageData() {
        // get Messages
        Observable.combineLatest(dataManager.getGroupMessages(by: group.id), dataManager.getGroupFailureMessages(by: group.id)).subscribeSuccess { [weak self] success, failure in
            guard let self = self else { return }
            self.unreadLastMessage = success.last
            self.messages = success + failure
            self.setupMessages(success: success, failure: failure)
            // 準備Message Search Resource
            self.prepareSearchResource()
        }.disposed(by: self.disposeBag)
    }
    
    func bindGroupObserver() {
        let obs = dataManager.getGroupObserver(by: group.id)
        
        // message preload finished
        obs.messagePreloadFinish.subscribeSuccess { [unowned self] isFinish in
            guard isFinish else { return }
            self.isFinishPreload = isFinish
            
            guard !self.transceivers.isEmpty else {
                return
            }
            
            self.fetchMessageData()
        }.disposed(by: self.disposeBag)
        
        // transceiver list change
        obs.transceivers.subscribeSuccess { [unowned self] trans in
            self.updateTransceivers(to: trans)
        }.disposed(by: self.disposeBag)
        
        // 刪除對話紀錄
        obs.clearAllMessages.subscribeSuccess { [unowned self] _ in
            self.clearMessage()
        }.disposed(by: self.disposeBag)
        
        obs.groupObserver.subscribeSuccess { [unowned self] groupModel in
            self.group = groupModel
        }.disposed(by: self.disposeBag)

        obs.lastRead.observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] lastReadID in
            LogHelper.print(.debug, item: " get last read ID change to == ", lastReadID)
            guard let lastReadMessage = self.messageItems.first(where: { $0.model?.id == lastReadID })?.model, lastReadMessage.userID == UserData.shared.userID else {
                return
            }
            self.input.lastReadMessage.accept(lastReadMessage)
        }.disposed(by: disposeBag)

        obs.otherUnread.bind(to: self.output.otherUnread).disposed(by: self.disposeBag)
        
        obs.announcements.bind(to: self.output.updateAnnouncements).disposed(by: disposeBag)
    }

    func initBinding() {
        self.input.newMessage.subscribeSuccess { [weak self] message in
            guard let self = self, let message = message else { return }
            self.processMessage(model: message, action: .add)
        }.disposed(by: self.disposeBag)

        self.input.updateMessage.subscribeSuccess { [weak self] message in
            guard let self = self, let message = message else {
                return
            }
            self.processMessage(model: message, action: .update)
        }.disposed(by: self.disposeBag)

        self.input.deleteMessage.subscribeSuccess { [weak self] message in
            guard let self = self, let message = message else {
                return
            }
            self.processMessage(model: message, action: .delete)
        }.disposed(by: self.disposeBag)

        self.input.lastReadMessage.subscribeSuccess { [weak self] message in
            guard let self = self, let message = message else {
                return
            }
            self.lastReadMessage = message

            var startUpdate = false
            for item in self.messageItems.reversed() where ((item.type == .text || item.type == .image || item.type == .recommend) && !item.cellModel.withRead) {
                // 從已讀那筆messageItem開始更新read狀態(已讀那筆messageItem不一定是聊天室最後一筆訊息)
                if !startUpdate {
                    startUpdate = item.model?.id == message.id
                }
                if startUpdate {
                    item.cellModel.updateReadStatus(true)
                    self.output.updateReadStatus.accept(item.model?.id ?? "")
                }
            }
        }.disposed(by: self.disposeBag)
        
        DataAccessManager.shared.nicknameUpdateObserver.subscribeSuccess { [unowned self] memberID in
            self.updateTransceiver(by: memberID)
        }.disposed(by: disposeBag)
    }
}

// MARK: - process message model
private extension MessageDataSource {
    
    func processMessage(model: MessageModel, action: DataAction) {
        switch action {
        case .delete:
            operactionQueue.addOperation(self.deleteMessage(model))
        case .update:
            operactionQueue.addOperation(self.updateMessage(model))
        case .add:
            operactionQueue.addOperation(self.addMessage(model))
        default:
            break
        }
    }
    
    func deleteMessage(_ message: MessageModel) -> BlockOperation {
        return BlockOperation {
            guard let section = self.messageItems.firstIndex(where: { $0.model?.id == message.id }) else {
                return
            }

            self.failureMessageItems.removeAll(where: { $0.model?.id == message.id })

            self.messages.removeAll(where: { $0.id == message.id })
            self.messageItems.remove(at: section)
        }
    }
    
    func updateMessage(_ message: MessageModel) -> BlockOperation {
        return BlockOperation {
            self.messages = self.messages.map { $0.id == message.id ? message : $0 }
            self.messageUpdate.accept(())
        }
    }
    
    func addMessage(_ message: MessageModel) -> BlockOperation {
        return BlockOperation {
            let rowIndex: Int = self.getRowIndex(message: message)
            var lastMessage: MessageModel?
            if rowIndex > 0, self.messageItems.count > rowIndex - 1 {
                lastMessage = self.messageItems[rowIndex - 1].model
            }
            
            guard let addItem = self.convertSectionModel(with: message, preMessage: lastMessage) else { return }
            var unread: MessageViewModel?
            
            switch message.messageStatus {
            case .success:
                self.unreadLastMessage = message
                self.successMessageItems.insert(addItem, at: rowIndex)
                
                if self.isReading == false, self.unreadIndexPath == nil {
                    // 需要加上 unread
                    unread = self.createUnread(unreadType: .show(messageID: ""), lastMessage: nil)
                    if let tag = unread {
                        self.updateLastViewSuccess = false
                        self.unreadIndexPath = IndexPath(row: rowIndex, section: 0)
                        self.successMessageItems.insert(tag, at: rowIndex)
                    }
                }
            case .failed:
                let failedIndex = rowIndex - self.successMessageItems.count
                self.failureMessageItems.insert(addItem, at: failedIndex)
            default:
                // 加在清單的最後面
                self.failureMessageItems.append(addItem)
            }
            
            var newMessages = [MessageViewModel]()
            if let tag = unread {
                newMessages = [tag, addItem]
            } else {
                newMessages = [addItem]
            }
            
            self.messages.append(message)
            self.messageItems.insert(contentsOf: newMessages, at: rowIndex)
            self.messageUpdate.accept(())
            
        }
    }
}

// MARK: - Parse [MessageModel] to [MessageSectionModel]
private extension MessageDataSource {
    func getSectionModel(by messages: [MessageModel], needSeparate: Bool = true) -> [MessageViewModel] {
        var items = [MessageViewModel]()
        let unreadType = self.getUnreadType(messages)
        var lastMessage: MessageModel?

        for message in messages {
            if needSeparate, let dateTimeSection = self.createDateTime(lastMessage: lastMessage, message: message) {
                items.append(dateTimeSection)
            }

            if needSeparate, let unreadSection = self.createUnread(unreadType: unreadType, lastMessage: lastMessage) {
                self.unreadIndexPath = IndexPath(row: items.count, section: 0)
                self.updateLastViewSuccess = false
                items.append(unreadSection)
            }

            if let addItem = self.convertSectionModel(with: message, preMessage: lastMessage) {
                items.append(addItem)
            }

            lastMessage = message
        }
        return items
    }
}

private extension MessageDataSource {
    func clearMessage() {
        self.messageItems.removeAll()
        self.successMessageItems.removeAll()
        self.failureMessageItems.removeAll()
        self.messageItems.removeAll()
        self.searchResource.removeAll()
        self.searchResults.removeAll()
        self.unreadIndexPath = nil
        self.lastReadMessage = nil
        self.unreadLastMessage = nil
    }

    func setupMessages(success successMessages: [MessageModel], failure failureMessages: [MessageModel]) {
        self.lastReadMessage = successMessages.first { $0.id == self.group.lastReadID }

        self.successMessageItems = self.getSectionModel(by: successMessages)
        self.failureMessageItems = self.getSectionModel(by: failureMessages, needSeparate: false)
        
        self.messageItems = self.successMessageItems + self.failureMessageItems
    }

    func parseSender(by userID: String) -> MessageSenderType {
        let myUserID = (UserData.shared.getData(key: .userID) as? String) ?? ""
        return myUserID == userID ? .me : .others
    }

    func updateLastViewMessage(_ lastMessage: MessageModel, groupInfo: GroupModel) {
        DataAccessManager.shared.updateLastViewMessage(message: lastMessage, groupInfo: groupInfo) { [weak self] group in
            guard let self = self, let group = group else {
                return
            }
            self.unreadLastMessage = nil
            self.updateLastViewSuccess = true

            self.group = group
            if group.lastMessage?.id == lastMessage.id {
                self.input.lastReadMessage.accept(lastMessage)
            }
        }
    }

    func parseUsername(userID: String) -> String {
        return transciversDict[userID]?.display ?? ""
    }

    func getRowIndex(message: MessageModel, originalID: String = "") -> Int {
        var rowIndex: Int = self.messageItems.count
        if message.messageStatus == .success {
            if let index = self.successMessageItems.firstIndex(where: { $0.timestamp > message.timestamp }) {
                rowIndex = index
            } else if !originalID.isEmpty, let index = self.successMessageItems.firstIndex(where: { $0.model?.id == originalID }) {
                rowIndex = index
            } else {
                rowIndex = self.successMessageItems.count
            }
        } else if message.messageStatus == .failed {
            if let index = self.failureMessageItems.firstIndex(where: { $0.timestamp > message.timestamp }) {
                rowIndex = self.successMessageItems.count + index
            } else if !originalID.isEmpty, let index = self.failureMessageItems.firstIndex(where: { $0.model?.id == originalID }) {
                rowIndex = self.successMessageItems.count + index
            }
        }

        return rowIndex
    }

    func convertSectionModel(with message: MessageModel, preMessage: MessageModel?) -> MessageViewModel? {
        let viewType = self.parseViewType(by: message.messageType)
        var item: MessageViewModel?
        switch viewType {
        case .groupStatus:
            item = self.createGroupStatus(type: message.messageType, message: message)
        case .text, .image, .recommend:
            item = self.createMessage(viewType: viewType, lastMessage: preMessage, message: message)
        default:
            break
        }
        return item
    }
}

// MARK: - Create mark sections: Unread
private extension MessageDataSource {
    func parseViewType(by messageType: MessageType) -> MessageViewType {
        switch messageType {
        case .text: return .text
        case .image: return .image
        case .recommend: return .recommend
        default:
            return .groupStatus
        }
    }
}
