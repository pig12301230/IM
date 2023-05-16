//
//  DataAccess+datasource.swift
//  ChatRoom
//
//  Created by ZoeLin on 2022/3/8.
//

import Foundation
import RxSwift

enum DataSource {
    case database
    case server
}

// MARK: - ConversationDataSource 相關
extension DataAccess {
    
    func clearAllGroupDataSource() {
        groupDataSource.keys.map { groupID in
            clearGroupConversationDataSource(by: groupID)
        }
    }
    
    func clearGroupConversationDataSource(by groupID: String) {
        groupDataSource[groupID]?.release()
        groupDataSource[groupID] = nil
    }
    
    func clearDataSourcePageData(by groupID: String) {
        groupDataSource[groupID]?.clearPageData()
    }
    
    func getGroupConversationDataSource(by groupID: String) -> ConversationDataSource? {
        guard let group = groupDataSource[groupID] else {
            guard let model = realmDAO.immediatelyModel(type: GroupModel.self, id: groupID) else { return nil }
            return getGroupConversationDataSource(groupModel: model)
        }
        return group
    }
    
    func getGroupConversationDataSource(groupModel: GroupModel) -> ConversationDataSource {
        // if not existed, create new one
        guard let dataSource = groupDataSource[groupModel.id] else {
            let dataSource = ConversationDataSource(group: groupModel)
            groupDataSource[groupModel.id] = dataSource
            return dataSource
        }
        dataSource.input.group.accept(groupModel)
        return dataSource
    }
    
    func createDirectConversation(with contactID: String, displayName: String, isHidden: Bool = false) -> Observable<GroupModel> {
        return Observable<GroupModel>.create { observer in
            ApiClient.createDirectGroup(contactID).subscribe { [weak self] info in
                guard let self = self else {
                    return
                }
                self.processQueue.async {
                    self.createDirectConversation(info, name: displayName, isHidden: isHidden) { group in
                        observer.onNext(group)
                        observer.onCompleted()
                    }
                }
            } onError: { error in
                observer.onError(error)
            }.disposed(by: self.disposeBag)
            return Disposables.create()
        }
    }
    
    private func createDirectConversation(_ group: RUserGroups, name: String, isHidden: Bool, complete: @escaping (GroupModel) -> Void) {
        let isExist = self.realmDAO.checkExist(type: RLMGroup.self, by: group.id)
        
        let rlmGroup = RLMGroup.init(with: group)
        rlmGroup.displayName = name
        
        // 只有當 conversation 是新建立的 group 時, 才吃 hidden 設定, FOR 黑名單
        if !isExist {
            rlmGroup.hidden = isHidden
        }
        
        self.realmDAO.update([rlmGroup], policy: .all) {
            self.handleSuccessCreateGroup(group: group)
            let model = GroupModel.init(with: rlmGroup)
            let observerAction: DataAction = isExist ? .update : .add
            self.sendingGroupObserver(with: model, action: observerAction)
            complete(model)
        }
    }
    
    /**
     搜索 DB 中的 Messages, 立即返回
     - Parameters:
       - searchingKey: 搜索的 key
       - groupID: 搜索的聊天室 ID
     - Returns: 搜索到的 messages list
     */
    func searchDatabaseMessages(by searchingKey: String, at groupID: String) -> [MessageModel] {
        let format = "groupID = '\(groupID)' AND type = 'text' AND message contains[c]'\(searchingKey)'"
        return realmDAO.immediatelyModels(type: MessageModel.self, predicateFormat: format) ?? []
    }

    /**
     搜索 DB 中的 Messages, 非同步透過 result block 回傳結果
     - Parameters:
       - searchingKey: 搜索的 key
       - groupID: 搜索的聊天室 ID
       - result: 對搜索到的結果做處理的 block
     */
    func searchDatabase(by searchingKey: String, at groupID: String, result: @escaping ([MessageModel]?) -> Void) {
        // contains[c] for options 'caseInsensitive'
        let format = "groupID = '\(groupID)' AND type = 'text' AND message contains[c]'\(searchingKey)'"
        realmDAO.getModels(type: MessageModel.self, predicateFormat: format, complete: result)
    }
}

// MARK: - Pin Message
extension DataAccess {
    func getGroupPins(groupID: String) {
        ApiClient.getGroupPins(groupID: groupID).subscribe(onNext: { [weak self] messages in
            guard let self = self else { return }
            let rlmAnnouncements = messages.map { RLMAnnouncement(groupID: groupID,
                                                                  message: RLMAnnouncementMessage(with: $0),
                                                                  pinAt: $0.pinAt) }

            let announcementModels = rlmAnnouncements.map { AnnouncementModel(with: $0) }
            let deleteFormat = String(format: "groupID = '%@'", groupID)
            self.realmDAO.delete(type: RLMAnnouncement.self, predicateFormat: deleteFormat) {
                self.realmDAO.update(rlmAnnouncements)
            }
            
            self.getGroupObserver(by: groupID).announcements.accept(announcementModels)
        }).disposed(by: disposeBag)
    }
    
    func pinMessage(groupID: String, messageID: String, completed: ((Bool) -> Void)? = nil) {
        // 效仿Android， 設定公告後的行為,是根據socket event更新 DB
        ApiClient.pinMessage(groupID: groupID, messageID: messageID)
            .subscribe(onError: { _ in
                completed?(false)
            }, onCompleted: {
                completed?(true)
            }).disposed(by: disposeBag)
    }
    
    func unpinMessages(groupID: String, completed: ((Bool) -> Void)? = nil) {
        // 效仿Android， 刪除公告後的行為,是根據socket event更新 DB
        ApiClient.unpinAllMessages(groupID: groupID)
            .subscribe(onError: { _ in
                completed?(false)
            }, onCompleted: {
                completed?(true)
            }).disposed(by: disposeBag)
    }
    
    func unpinMessage(groupID: String, messageID: String, completed: ((Bool) -> Void)? = nil) {
        // 效仿Android， 刪除公告後的行為,是根據socket event更新 DB
        ApiClient.unpinMessage(groupID: groupID, messageID: messageID)
            .subscribe(onError: { _ in
                completed?(false)
            }, onCompleted: {
                completed?(true)
            }).disposed(by: disposeBag)
    }
}

// MARK: - HongBao Red Envelope
extension DataAccess {
    func fetchUserHongBao(campaignID: String) -> Observable<UserHongBaoModel?> {
        return Observable.create { observer -> Disposable in
            ApiClient.getUserHongBao(campaignID: campaignID)
                .subscribe(onNext: { hongBao in
                    let model = UserHongBaoModel(with: hongBao)
                    observer.onNext(model)
                    observer.onCompleted()
                }, onError: { _ in
                    // TODO: error handle
                    observer.onNext(nil)
                    observer.onCompleted()
                }).disposed(by: self.disposeBag)
            return Disposables.create()
        }
    }
    
    func fetchUnOpenedHongBaoInfo(groupID: String) -> Observable<UnOpenedHongBaoModel?> {
        return Observable.create { observer -> Disposable in
            ApiClient.getGroupHongBaoNumbers(groupID: groupID)
                .subscribe(onNext: { info in
                    observer.onNext(UnOpenedHongBaoModel(with: info))
                    observer.onCompleted()
                }, onError: { _ in
                    observer.onNext(nil)
                    observer.onCompleted()
                }).disposed(by: self.disposeBag)
            return Disposables.create()
        }
    }
    
    func fetchHongBaoStatus(campaignID: String) -> Observable<HongBaoClaimStatus?> {
        return Observable.create { observer -> Disposable in
            ApiClient.getHongBaoClaimStatus(campaignID: campaignID)
                .subscribe(onNext: { claimStatus in
                    observer.onNext(HongBaoClaimStatus(with: claimStatus))
                    observer.onCompleted()
                }, onError: { _ in
                    observer.onNext(nil)
                    observer.onCompleted()
                }).disposed(by: self.disposeBag)
            return Disposables.create()
        }
    }
    
    func getHongBaoContent(by messageID: String, groupID: String, completion: @escaping(HongBaoContent?) -> Void) {
        guard let message = self.realmDAO.immediatelyModel(type: MessageModel.self, id: messageID) else {
            ApiClient.getGroupMessage(groupID: groupID, messageID: messageID)
                .subscribe { [weak self] message in
                    guard let self = self else { return }
                    self.processQueue.async {
                        self.processReceivedMessage(message: message) { model in
                            guard let content = model.hongBaoContent else {
                                completion(nil)
                                return
                            }
                            completion(content)
                        }
                    }
                } onError: { _ in
                    completion(nil)
                }.disposed(by: disposeBag)
            
            return
        }
        completion(message.hongBaoContent)
    }
}

//MARK: Emoji
extension DataAccess {
    /**
     對訊息按 emoji
     */
    func handleEmojiDidTap(model: MessageModel, emojiType: EmojiType) {
        if let emojiModel = self.realmDAO.immediatelyModel(type: EmojiContentModel.self, id: model.diffID) {
            var newEmojiModel = emojiModel
            // 先更新 DB，避免 API成功後存進 DB過程中受到 socket然後拿舊的 my_active來更新 DB
            if emojiModel.my_active == emojiType.rawValue {
                newEmojiModel.removeDBEmoji(emojiName: emojiType.dbName)
            } else {
                if let dbEmojiName = EmojiType(rawValue: emojiModel.my_active)?.dbName {
                    newEmojiModel.removeDBEmoji(emojiName: dbEmojiName)
                }
                newEmojiModel.addDBEmoji(emojiName: emojiType.dbName)
            }

            newEmojiModel.my_active = emojiType.rawValue == emojiModel.my_active ? "" : emojiType.rawValue
            self.realmDAO.update([newEmojiModel.convertToDBObject()])

            let originalEmoji = emojiModel.my_active
            
            // call add/remove API
            if emojiModel.my_active == emojiType.rawValue {
                self.removeMessageEmoji(model: model, emojiType: emojiType) { actionSuccess in
                    if !actionSuccess {
                        //reset
                        self.updateEmojiFile(messageModel: model, emojiType: EmojiType(rawValue: originalEmoji))
                        if let dbEmojiName = EmojiType(rawValue: emojiModel.my_active)?.dbName {
                            newEmojiModel.addDBEmoji(emojiName: dbEmojiName)
                        }
                    }
                    let dbObject = newEmojiModel.convertToDBObject()
                    var messageModel = model
                    messageModel.emojiContent = EmojiContentModel(with: dbObject)
                    self.sendingMessageObserver(with: messageModel, action: .update)
                    self.realmDAO.update([dbObject])
                }
            } else {
                self.addMessageEmoji(model: model, emojiType: emojiType) { actionSuccess in
                    if !actionSuccess {
                        //reset
                        self.updateEmojiFile(messageModel: model, emojiType: EmojiType(rawValue: originalEmoji))
                        newEmojiModel.removeDBEmoji(emojiName: emojiType.dbName)
                        newEmojiModel.my_active = originalEmoji
                        if let dbEmojiName = EmojiType(rawValue: emojiModel.my_active)?.dbName {
                            newEmojiModel.addDBEmoji(emojiName: dbEmojiName)
                        }
                    }
                    let dbObject = newEmojiModel.convertToDBObject()
                    var messageModel = model
                    messageModel.emojiContent = EmojiContentModel(with: dbObject)
                    self.sendingMessageObserver(with: messageModel, action: .update)
                    self.realmDAO.update([dbObject])
                }
            }
        } else {
            // 先更新 DB
            var emojiContentModel = EmojiContentModel(with: RLMEmoji.init())
            emojiContentModel.id = model.diffID
            emojiContentModel.my_active = emojiType.rawValue
            emojiContentModel.addDBEmoji(emojiName: emojiType.dbName)
            self.realmDAO.update([emojiContentModel.convertToDBObject()])
            
            self.addMessageEmoji(model: model, emojiType: emojiType) { actionSuccess in
                if !actionSuccess {
                    // reset DB
                    emojiContentModel.my_active = ""
                    emojiContentModel.removeDBEmoji(emojiName: emojiType.dbName)
                }
                let dbObject = emojiContentModel.convertToDBObject()
                var messageModel = model
                messageModel.emojiContent = emojiContentModel
                self.sendingMessageObserver(with: messageModel, action: .update)
                self.realmDAO.update([dbObject])
            }
        }
    }
    
    /**
     add message emoji
     */
    func addMessageEmoji(model: MessageModel, emojiType: EmojiType, completion: @escaping (Bool) -> Void) {
        ApiClient.addMessageEmoji(messageID: model.id, emojiCode: emojiType.rawValue)
            .subscribe(onError: { error in
                print("### error: ", error)
                completion(false)
            }, onCompleted: {
                completion(true)
            }).disposed(by: disposeBag)
    }
    
    /**
     remove message emoji
     */
    func removeMessageEmoji(model: MessageModel, emojiType: EmojiType, completion: @escaping (Bool) -> Void) {
        ApiClient.removeMessageEmoji(messageID: model.id)
            .subscribe(onError: { _ in
                completion(false)
            }, onCompleted: {
                completion(true)
            }).disposed(by: disposeBag)
    }
    
    /**
     取得該則訊息自己按過的 emoji
     */
    func getMessageEmojiBySelf(model: MessageModel, completion: @escaping (String?) -> Void) {
        ApiClient.getMessageEmojiBySelf(messageId: model.id).subscribe { rEmoji in
            completion(rEmoji.emoji)
        } onError: { _ in
            if let emojiModel = self.realmDAO.immediatelyModels(type: EmojiContentModel.self, predicateFormat: "_id = \(model.diffID)")?.first {
                completion(emojiModel.my_active)
            } else {
                completion(nil)
            }
        }.disposed(by: disposeBag)
    }
    
    func shouldUpdateEmojiFile(rMessage: RMessage) -> Bool {
        guard let dbEmojiModel = self.realmDAO.immediatelyModel(type: EmojiContentModel.self, id: rMessage.diffID) else {
            return true
        }
        
        if rMessage.emojiContent.isEmpty {
            return dbEmojiModel.totalCount != 0
        }
        
        for content in rMessage.emojiContent {
            guard let dbName = EmojiType(rawValue: content.emoji)?.dbName else { return true }
            if let dbEmoji = dbEmojiModel.emojiArray.first(where: { $0.emoji_name == dbName }) {
                if dbEmoji.count != content.count { return true }
            } else {
                return true
            }
        }
        return false
    }
    
    func updateEmojiFile(rmessage: RMessage) {
        if !rmessage.emojiContent.isEmpty {
            let rlmEmoji = RLMEmoji(diffID: rmessage.diffID, with: rmessage.emojiContent)
            if let emojiModel = self.realmDAO.immediatelyModel(type: EmojiContentModel.self, id: rmessage.diffID) {
                rlmEmoji.my_active = emojiModel.my_active
            }
            self.realmDAO.update([rlmEmoji])
        } else {
            if let emojiModel = self.realmDAO.immediatelyModel(type: EmojiContentModel.self, id: rmessage.diffID) {
                let rlmEmoji = emojiModel.resetAllEmojiAndConvertToDBObject()
                self.realmDAO.update([rlmEmoji])
            }
        }
    }
    
    func updateEmojiFile(messageModel: MessageModel, emojiType: EmojiType?) {
        if var emojiModel = self.realmDAO.immediatelyModel(type: EmojiContentModel.self, id: messageModel.diffID) {
            emojiModel.my_active = emojiType?.rawValue ?? ""
            self.realmDAO.update([emojiModel.convertToDBObject()])
        } else {
            let model = RLMEmoji.init()
            model._id = messageModel.diffID
            model.my_active = emojiType?.rawValue ?? ""
            self.realmDAO.update([model])
        }
    }
    
    func getMessageEmojiContent(diffID: String, completion:  @escaping (EmojiContentModel?) -> Void) {
        self.realmDAO.getModel(type: EmojiContentModel.self, id: diffID) { model in
            guard let model = model else {
                completion(nil)
                return
            }
            completion(model)
        }
    }
    
    func getMessageEmojiContent(messageID: String) -> EmojiContentModel? {
        return self.realmDAO.immediatelyModel(type: EmojiContentModel.self, id: messageID)
    }
    /**
     從 `Server` 取得訊息的EmojiList
     */
    
    func fetchEmojiList(messageID: String, completion: @escaping ([EmojiDetailModel]?) -> Void) {
        ApiClient.getMessageEmojiList(messageID: messageID).subscribe(onNext: { [weak self] emojiList in
            guard let self = self else {
                completion(nil)
                return
            }
            // remove 不存在的
            let format = "messageID = '\(messageID)'"
            let current = self.realmDAO.immediatelyModels(type: EmojiDetailModel.self, predicateFormat: format) ?? []
            let notExistData = current.filter { model in !emojiList.list.contains(where: { model.userID == $0.userID }) }
            
            notExistData.forEach { model in
                let id = "\(model.messageID)_\(model.userID)"
                self.realmDAO.delete(type: RLMEmojiDetail.self, by: id)
            }
            
            // update DB
            let rlmEmojiDetailModels = emojiList.list.map { RLMEmojiDetail(content: $0) }
            let emojiDetailModels = rlmEmojiDetailModels.map { EmojiDetailModel(with: $0) }
            self.realmDAO.update(rlmEmojiDetailModels) {
                completion(emojiDetailModels)
            }
        }, onError: { _ in
            // error 目前不處理
            completion(nil)
        })
        .disposed(by: disposeBag)
    }
    
    /**
     從 `Database` 取得訊息的EmojiList
     */
    
    func getEmojiList(messageID: String, completion: @escaping ([EmojiDetailModel]) -> Void) {
        let format = "messageID = '\(messageID)'"
        self.realmDAO.getModels(type: EmojiDetailModel.self, predicateFormat: format) { lists in
            completion(lists ?? [])
        }
    }
}

// MARK: - PRIVATE handel data
private extension DataAccess {
    /**
     新增傳送前暫存的 message 至 database
     - Paramater:
        - model: message model
        - groupID: message 隸屬的 group.id
     */
    func addModel(model: MessageModel, to groupID: String) {
        self.sendingMessageObserver(with: model, action: .add)
        let rlmObject = model.convertToDBObject()
        let draft = RLMDraftMessage(by: rlmObject)
        self.realmDAO.update([draft])
    }
    
    func saveMessageToDatabase(_ messages: [RLMMessage], completion: (() -> Void)? = nil) {
        realmDAO.update(messages, completion: completion)
    }
    
    func updateModelAndDeleteCacheMessageAfterSuccess(_ model: MessageModel, by response: RMessage, complete: @escaping (MessageModel) -> Void) {
        self.processQueue.async {
            let originalID = model.id
            var messageModel = model
            messageModel.isDraft = false
            messageModel.updateByResponseObject(response)
            messageModel.messageStatus = .success
            
            self.realmDAO.delete(type: RLMDraftMessage.self, by: originalID)
            let rlmMessage = messageModel.convertToDBObject()
            self.addNewMessage(message: rlmMessage, increase: false, originalID: originalID)
            complete(messageModel)
        }
    }
    
    func updateDraftModelAfterFailure(_ model: MessageModel, complete: @escaping (MessageModel) -> Void) {
        self.processQueue.async {
            var messageModel = model
            messageModel.isDraft = false
            messageModel.messageStatus = .failed
            
            self.sendingMessageObserver(with: messageModel, action: .update)
            
            let rlmObject = messageModel.convertToDBObject()
            let draft = RLMDraftMessage(by: rlmObject)
            self.realmDAO.update([draft]) {
                complete(messageModel)
            }
            
            // 發送訊息失敗, 更新至 group.hasFailure 的狀態
            self.realmDAO.getModel(type: GroupModel.self, id: model.groupID) { [unowned self] groupModel in
                guard var newGroup = groupModel else {
                    return
                }
                
                newGroup.hasFailure = true
                self.realmDAO.update([newGroup.convertToDBObject()])
                
                self.sendingGroupObserver(with: newGroup, action: .update)
            }
        }
    }
}

// MARK: - Message 相關
extension DataAccess {
    func saveMessage(message: RMessage) {
        let rlmMsg = RLMMessage.init(with: message)
        self.addNewMessage(message: rlmMsg)
    }
    
    func addNewMessage(message: RLMMessage, increase: Bool = true, originalID: String? = nil) {
        let increaseCount = increase ? 1 : 0
        let observer = self.getGroupObserver(by: message.groupID)
        
        self.realmDAO.update([message]) { [weak self] in
            guard let self = self else { return }
            let action: DataAction = increase ? .add : .update
            if message.groupID != self.lastReadingConversation.value,
                message.userID != UserData.shared.userID {
                switch message.messageType {
                case .text, .image, .recommend, .groupCreate, .groupDisplayName, .hongBao:
                    observer.unread.accept(observer.unread.value + increaseCount)
                    self.totalUnread += increaseCount
                case .unsend:
                    if message.targetID > observer.lastRead.value ?? "" {
                        observer.unread.accept(observer.unread.value - increaseCount)
                        self.totalUnread -= increaseCount
                    }
                default:
                    break
                }
                
            }

            if !message.fileIDs.isEmpty {
                self.loadFile(message.groupID, messageID: message._id, fileIDs: message.fileIDs.toArray())
                    .subscribeSuccess { rlmMessage in
                        guard let rlmMessage = rlmMessage else {
                            let model = MessageModel.init(with: message)
                            self.sendingMessageSignal(with: model, action: action, originalID: originalID)
                            return
                        }
                        let model = MessageModel.init(with: rlmMessage)
                        self.sendingMessageSignal(with: model, action: action, originalID: originalID)
                    }.disposed(by: self.disposeBag)
            } else {
                let model = MessageModel.init(with: message)
                self.sendingMessageSignal(with: model, action: action, originalID: originalID)
            }
            
            switch message.messageType {
            case .text, .image, .recommend, .groupCreate, .groupDisplayName, .hongBao:
                observer.lastEffectiveMessageID.accept(message._id)
            case .unsend:
                if message.targetID == observer.lastEffectiveMessageID.value {
                    let id = self.getLastEffectiveMessage(groupID: message.groupID)?.id
                    observer.lastEffectiveMessageID.accept(id)
                }
            default:
                break
            }
        }
        
        guard var group = self.realmDAO.immediatelyModel(type: GroupModel.self, id: message.groupID) else {
            return
        }
        
        let groupAction: DataAction = group.hidden == true ? .add : .update
        
        if group.lastMessage == nil {
            group.lastMessage = MessageModel.init(with: message)
        } else if let last = group.lastMessage, (last.timestamp < message.timestamp || last.id < message._id) {
            switch message.messageType {
            case .text, .image, .recommend, .groupDisplayName, .groupCreate, .hongBao:
                group.lastMessage = MessageModel.init(with: message)
            default:
                break
            }
        }
        
        let format = String(format: "groupID = '%@' AND isDraft = false", group.id)
        group.hasFailure = self.realmDAO.checkExist(type: RLMDraftMessage.self, predicateFormat: format)
        
        if increase {
            group.unreadCount = observer.unread.value
        }
        
        group.hidden = false
        
        self.realmDAO.getModels(type: TransceiverModel.self, predicateFormat: "groupID = '\(group.id)'") { transceivers in
            guard let transceivers = transceivers else {
                return
            }
            group.memberCount = transceivers.filter({ $0.isMember == true }).count
            let rlmObject = group.convertToDBObject()
            
            self.realmDAO.update([rlmObject], policy: .modified) {
                self.sendingGroupObserver(with: group, action: groupAction)
            }
        }
    }
    
    // MARK: - Fetch/Get
    func fetchMessage(groupID: String, messageID: String, completion: @escaping(MessageModel?) -> Void) {
        ApiClient.getGroupMessage(groupID: groupID, messageID: messageID)
            .subscribe { [weak self] message in
                guard let self = self else { return }
                self.processQueue.async {
                    self.processReceivedMessage(message: message) { model in
                        completion(model)
                    }
                }
            } onError: { _ in
                completion(nil)
            }.disposed(by: disposeBag)
    }
    
    func fetchMessages(groupID: String, messageID: String, direction: MessageDirection, limit: Int = DataAccess.conversationPageSize, complete: @escaping ([MessageModel]?, DataSource) -> Void) {
        ApiClient.getGroupMessages(groupID: groupID, messageID: messageID, direction: direction, limit: limit).subscribe { [weak self] (messages) in
            guard let self = self else { return }
            self.processQueue.async {
                self.processReceivedMessages(groupID: groupID, messages: messages, complete: complete)
            }
            // TODO: load userID and targetID if not loaded
        } onError: { (error) in
            complete(nil, .server)
            PRINT("request ERROR \(groupID) messages == \(error)", cate: .request)
        }.disposed(by: disposeBag)
    }

    func fetchMessages(groupID: String, timestamp: Int, direction: MessageDirection, limit: Int = DataAccess.conversationPageSize, complete: @escaping ([MessageModel]?, DataSource) -> Void) {
        ApiClient.getGroupMessages(groupID: groupID, time: timestamp, direction: direction, limit: limit).subscribe { [unowned self] (messages) in
            self.processReceivedMessages(groupID: groupID, messages: messages, complete: complete)
        } onError: { (error) in
            complete(nil, .server)
            PRINT("request ERROR \(groupID) messages == \(error)", cate: .request)
        }.disposed(by: self.disposeBag)
    }
    
    func fetchMessages(groupID: String, messageID: String, direction: MessageDirection, limit: Int = DataAccess.conversationPageSize, complete: @escaping ([MessageModel]?) -> Void) {
        ApiClient.getGroupMessages(groupID: groupID, messageID: messageID, direction: direction, limit: limit).subscribe { messages in
            let models = messages.map { MessageModel(with: self.checkLocalDeleteAndUpdate(message: $0)) }
            complete(models)
        } onError: { (error) in
            complete(nil)
            PRINT("request ERROR \(groupID) messages == \(error)", cate: .request)
        }.disposed(by: disposeBag)
    }
    
    func getMessage(by messageID: String) -> MessageModel? {
        return self.realmDAO.immediatelyModel(type: MessageModel.self, id: messageID)
    }
    
    func getLastEffectiveMessage(groupID: String) -> MessageModel? {
        let format = "groupID = '\(groupID)' AND deleted = false AND (type = 'text' OR type = 'image' OR type = 'recommend' OR type = 'group_create' OR type = 'group_displayname' OR type = 'red_envelope' OR type = 'red_envelope_claim')"
        let messages = self.realmDAO.immediatelyModels(type: MessageModel.self, predicateFormat: format)?.filter { !$0.isBlocked }.sorted(by: { $0.id < $1.id })
        return messages?.last
    }
    
    func getMessage(messageID: String, completion: @escaping (MessageModel?) -> Void) {
        self.realmDAO.getModel(type: MessageModel.self, id: messageID) {
            completion($0)
        }
    }
    
    func isExistMessageInDatabase(by messageID: String) -> Bool {
        return realmDAO.checkExist(type: RLMMessage.self, by: messageID)
    }
    
    func deleteMessageInDatabase(by messageID: String) {
        guard let messageModel = self.realmDAO.immediatelyModel(type: MessageModel.self, id: messageID) else { return }

        self.removeDatabaseMessage(model: messageModel) {
            self.sendingMessageObserver(with: messageModel, action: .delete)
        }
    }
    
    // 更新訊息內的Thread Message
    func updateLocalThreadMessage(originID: String, threadMessage: MessageModel) {
        guard var originMessage = self.getMessage(by: originID) else { return }
        originMessage.threadMessage = [threadMessage]
        self.realmDAO.update([originMessage.convertToDBObject()])
    }
    
    func setReadMessage(_ messageID: String, groupID: String) {
        ApiClient.readMessage(groupID: groupID, messageID: messageID)
            .subscribe(onError: { error in
                PRINT("update read Message ERROR \(error), groupID = \(groupID), messageID = \(messageID)", cate: .request)
            }, onCompleted: { [weak self] in
                guard let self = self else { return }
                self.processQueue.async {
                    guard let dataSource = self.getGroupConversationDataSource(by: groupID) else { return }
                    var group = dataSource.group

                    group.lastViewedID = messageID
                    group.unreadCount = 0
                    self.realmDAO.update([group.convertToDBObject()]) {
                        self.getGroupObserver(by: groupID).groupObserver.accept(group)
                        self.getGroupObserver(by: groupID).unread.accept(0)
                        self.getGroupObserver(by: groupID).lastViewed.accept(messageID)
                    }
                }
            }).disposed(by: self.disposeBag)
    }
    /**
     重設傳送中的 message model 的狀態為 `傳送失敗`
     */
    func resetSendingMessageStatus() {
        self.processQueue.async {
            self.getDraftMessages(format: "isDraft = false") { [unowned self] messagesModels in
                let rlmResult: [RLMDraftMessage] = messagesModels.compactMap {
                    var model = $0
                    model.messageStatus = .failed
                    return RLMDraftMessage(by: model.convertToDBObject())
                }
                
                self.realmDAO.update(rlmResult, policy: .modified)
            }
        }
    }
    
    /**
     移除傳送失敗的 message
     */
    func deleteFailureMessage(_ model: MessageModel) {
        self.processQueue.async {
            self.realmDAO.delete(type: RLMDraftMessage.self, by: model.id)
            self.sendingMessageObserver(with: model, action: .delete)

            // 確認 Group 是否還有 failure message 在 DB 中
            let format = String(format: "groupID = '%@' AND isDraft = false", model.groupID)
            guard !self.realmDAO.checkExist(type: RLMDraftMessage.self, predicateFormat: format) else {
                return
            }
            
            // database 中已經沒有此 Group 的 failure message
            guard var groupModel = self.getGroupConversationDataSource(by: model.groupID)?.group else {
                return
            }
            
            // 將 hasFailure -> false
            // 發送 update observer
            groupModel.hasFailure = false
            self.sendingGroupObserver(with: groupModel, action: .update)
        }
    }

    func processReceivedMessage(message: RMessage, complete: @escaping (MessageModel) -> Void) {
        let rlmMessage = self.checkLocalDeleteAndUpdate(message: message)
        
        self.saveMessageToDatabase([rlmMessage]) {
            if rlmMessage.fileIDs.isEmpty {
                complete(MessageModel(with: rlmMessage))
            } else {
                self.loadFile(rlmMessage.groupID, messageID: rlmMessage._id, fileIDs: rlmMessage.fileIDs.toArray())
                    .subscribeSuccess { rlmMsg in
                        guard let rlmMsg = rlmMsg else {
                            complete(MessageModel(with: rlmMessage))
                            return
                        }
                        complete(MessageModel(with: rlmMsg))
                    }.disposed(by: self.disposeBag)
            }
        }
    }
    
    func processReceivedMessages(groupID: String, messages: [RMessage], complete: @escaping ([MessageModel]?, DataSource) -> Void) {
        let result = messages.sorted { $0.diffID < $1.diffID }
        var rlmMessages: [RLMMessage] = []
        var messageModels: [MessageModel] = []
        var filesDict: [String: [String]] = [:]
        var shouldFetchMemberIDs: [String] = []
        
        let withUrlFormat = String(format: "groupID = '%@' AND imageFileName != nil", groupID)
        let withUrlMessages = self.realmDAO.immediatelyModels(type: MessageModel.self, predicateFormat: withUrlFormat) ?? []

        result.forEach { message in
            // check transceiver
            // message sender
            let senderID = TransceiverModel.uniqueID(groupID, message.userID)
            if !self.realmDAO.checkExist(type: RLMTransceiver.self, by: senderID) {
                shouldFetchMemberIDs.append(message.userID)
            }
            if message.type == .inviteMember || message.type == .removeMember, !message.targetID.isEmpty {
                let targetSenderID = TransceiverModel.uniqueID(groupID, message.targetID)
                if !self.realmDAO.checkExist(type: RLMTransceiver.self, by: targetSenderID) {
                    shouldFetchMemberIDs.append(message.targetID)
                }
            }
            
            let rlmObject = self.checkLocalDeleteAndUpdate(message: message)
            
            if let urlMessage = withUrlMessages.first(where: { $0.id == message.id }) {
                rlmObject.imageFileName = urlMessage.imageFileName
            }
            
            if self.shouldUpdateEmojiFile(rMessage: message) {
                self.updateEmojiFile(rmessage: message)
            }
            
            rlmMessages.append(rlmObject)
            messageModels.append(MessageModel(with: rlmObject))

            if !message.fileIDs.isEmpty {
                filesDict[message.id] = message.fileIDs
            }
        }
        
        shouldFetchMemberIDs = shouldFetchMemberIDs.removeDuplicateElement()
        if !shouldFetchMemberIDs.isEmpty {
            self.fetchGroupMembersAndUpdate(groupID: groupID, memberIDs: shouldFetchMemberIDs) { }
        }
        
        if let lastMsg = rlmMessages.last {
            self.updateGroupLastCheckedMessage(groupID, messageID: lastMsg._id)
        }

        self.saveMessageToDatabase(rlmMessages) {
            complete(messageModels, .server)
        }
    }
    
    func getMessages(groupID: String, messageID: String, direction: MessageDirection, limit: Int = DataAccess.conversationPageSize, complete: @escaping ([MessageModel]?, DataSource) -> Void) {
        let format = "groupID = '\(groupID)'"
        
        realmDAO.getModels(type: MessageModel.self, predicateFormat: format, sortPath: "_id") { (messageModels: [MessageModel]?) in
            guard let models = messageModels else {
                complete(nil, .database)
                return
            }
            let sorted = models.sorted { $0.diffIdentifier < $1.diffIdentifier }.filter { direction == .after ? ($0.diffIdentifier >= messageID) : ($0.diffIdentifier <= messageID) }
                .filter { !$0.deleted && !$0.isBlocked }
            
            guard !sorted.isEmpty else {
                complete(nil, .database)
                return
            }
            guard sorted.count < limit else {
                guard direction == .after else {
                    complete(sorted.suffix(limit), .database)
                    return
                }
                
                complete(Array(sorted.prefix(limit)), .database)
                return
            }
            complete(sorted, .database)
        }
    }
    
    func sendingMessageSignal(with model: MessageModel, action: DataAction, originalID: String? = nil) {
        guard let originalID = originalID else {
            self.sendingMessageObserver(with: model, action: action)
            return
        }
        self.addMessageHandleGroupImage(groupID: model.groupID, message: model)
        guard let newDataSource = self.getGroupConversationDataSource(by: model.groupID) else { return }
        newDataSource.input.replaceMessage.onNext((model, originalID))
    }
    
    func sendMessage(_ content: String, groupID: String, complete: @escaping (MessageModel, String) -> Void ) {
        let model = self.convertTextMessageModel(content: content, groupID: groupID)
        self.addModel(model: model, to: groupID)
        self.sendMessage(with: model, complete: complete)
    }
    
    func sendMessage(with model: MessageModel, complete: @escaping (MessageModel, String) -> Void ) {
        self.processQueue.async {
            // 刪除暫存草稿 message
            self.deleteDraftMessage(with: model.groupID)
            
            let originalID = model.id
            ApiClient.sendMessage(type: model.messageType.rawValue, groupID: model.groupID, cid: model.cid, message: model.message, takeOver: true).subscribe { [unowned self] message in
                PRINT(message.id)
                self.updateModelAndDeleteCacheMessageAfterSuccess(model, by: message) { newModel in
                    complete(newModel, originalID)
                }
            } onError: { [unowned self] _ in
                self.updateDraftModelAfterFailure(model) { newModel in
                    complete(newModel, originalID)
                }
            }.disposed(by: self.disposeBag)
        }
    }
    
    func sendReplyMessage(_ content: String, replyMessage: MessageModel, complete: @escaping (MessageModel, String) -> Void ) {
        let model = self.convertReplyMessageModel(content: content, replyMessage: replyMessage)
        self.addModel(model: model, to: model.groupID)
        self.sendReplyMessage(with: model, complete: complete)
    }
        
    func sendReplyMessage(with model: MessageModel, complete: @escaping (MessageModel, String) -> Void ) {
        self.processQueue.async {
            // 刪除暫存草稿 message
            self.deleteDraftMessage(with: model.groupID)
            
            let originalID = model.id
            
            guard let replyID = model.threadID else {
                self.updateDraftModelAfterFailure(model) { newModel in
                    complete(newModel, originalID)
                }
                return
            }
            
            ApiClient.sendReplyMessage(message: model.message, cid: model.cid, replyID: replyID).subscribe { [unowned self] message in
                self.updateModelAndDeleteCacheMessageAfterSuccess(model, by: message) { newModel in
                    complete(newModel, originalID)
                }
            } onError: { [unowned self] _ in
                self.updateDraftModelAfterFailure(model) { newModel in
                    complete(newModel, originalID)
                }
            }.disposed(by: self.disposeBag)
        }
    }
    
    func sendImage(draftMessage: MessageModel, complete: ((MessageModel, String) -> Void)?) {
        guard let imageFileName = draftMessage.imageFileName else {
            return
        }
        var data: Data?
        let imageUrl = AppConfig.Device.localImageFilePath.appendingPathComponent(imageFileName, isDirectory: false)
        
        do {
            data = try Data(contentsOf: imageUrl)
        } catch {
            print(error.localizedDescription)
            return
        }
        guard let imageData = data else { return }
        self.sendImage(with: draftMessage, imageData: imageData, complete: complete)
    }
    
    func sendImage(with model: MessageModel, imageData: Data, complete: ((MessageModel, String) -> Void)?) {
        let originalID = model.id
        guard let cache = self.uploadCacheDict[originalID] else { return }
        self.uploadCacheDict.removeValue(forKey: originalID)
        // uploadRequest 先給 nil，目前後端不接受 cancel request
        ApiClient.sendImage(groupID: model.groupID, cid: model.cid, data: imageData, uploadRequest: nil).subscribe { [weak self] message in
            guard let self = self else { return }
            self.updateModelAndDeleteCacheMessageAfterSuccess(model, by: message) { newModel in
                complete?(newModel, originalID)
            }
        } onError: { [weak self] _ in
            guard let self = self, self.uploadCacheDict[originalID] != nil else {
                return
            }

            self.uploadCacheDict[originalID] = cache
            self.updateDraftModelAfterFailure(model) { newModel in
                complete?(newModel, originalID)
            }
        }.disposed(by: cache.disposeBag)
    }
    
    func addDraftMessageAndSendImage(groupID: String, imageFileName: String, index: String) {
        let model = self.convertImageMessageModel(imageFileName: imageFileName, groupID: groupID, index: index)
        self.addModel(model: model, to: groupID)
        var fractionCompleted: Double = 0
        let cache = UploadImageCache.init(model)
        self.uploadCacheDict[model.id] = cache
        DispatchQueue.main.async {
            cache.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] _ in
                guard let self = self else { return }
                guard self.uploadCacheDict[model.id] != nil else {
                    // has canceled sending from cell
                    cache.timer?.invalidate()
                    cache.timer = nil
                    return
                }
                
                guard fractionCompleted < 1 else {
                    self.sendImage(draftMessage: model, complete: nil)
                    cache.timer?.invalidate()
                    cache.timer = nil
                    return
                }
                fractionCompleted += 1.0 / 3.0
            })
            guard let timer = cache.timer else { return }
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    func resendImage(draftMessage: MessageModel, completion: @escaping (MessageModel, String) -> Void) {
        var fractionCompleted: Double = 0
        let cache = self.uploadCacheDict[draftMessage.id] ?? .init(draftMessage)
        self.uploadCacheDict[draftMessage.id] = cache
        DispatchQueue.main.async {
            cache.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                guard self.uploadCacheDict[draftMessage.id] != nil else {
                    // has send image from cell timer
                    cache.timer?.invalidate()
                    cache.timer = nil
                    return
                }
                
                guard fractionCompleted < 1 else {
                    self.sendImage(draftMessage: draftMessage) { newModel, originaoID in
                        completion(newModel, originaoID)
                    }
                    cache.timer?.invalidate()
                    cache.timer = nil
                    return
                }
                fractionCompleted += 1.0 / 3.0
                                
                guard let timer = cache.timer else { return }
                RunLoop.main.add(timer, forMode: .common)
            }
        }
    }
    
    func removeDatabaseMessage(model: MessageModel, completion: (() -> Void)? = nil) {
        self.realmDAO.delete(type: RLMMessage.self, by: model.id) {
            completion?()
        }
        self.realmDAO.delete(type: RLMThreadMessage.self, by: model.id)
        self.realmDAO.delete(type: RLMGMessage.self, by: model.id)
        self.realmDAO.delete(type: RLMTemplate.self, by: model.id)
        self.realmDAO.delete(type: RLMOption.self, by: model.id)
        self.realmDAO.delete(type: RLMAction.self, by: model.id)
        
        // Files
        let filesID = model.fileIDs
        for fileID in filesID {
            self.realmDAO.delete(type: RLMFiles.self, by: fileID)
        }
        
        // HongBao
        if let campaignID = model.hongBaoContent?.campaignID {
            self.realmDAO.delete(type: RLMHongBaoContent.self, by: campaignID)
            self.realmDAO.delete(type: RLMHongBaoStyle.self, by: campaignID)
        }
        // Emoji
        self.realmDAO.delete(type: RLMEmoji.self, by: model.id)
        let format = "messageID = '\(model.id)'"
        self.realmDAO.delete(type: RLMEmojiDetail.self, predicateFormat: format)
    }
    
    func cancelUpload(modelID: String) {
        // 因為後端目前都會接收無法 cancel task
        self.stopUploadTask(modelID: modelID)
        self.setupUploadTaskToFailure(modelID: modelID)
        
        self.realmDAO.delete(type: RLMDraftMessage.self, by: modelID)
        self.realmDAO.delete(type: RLMMessage.self, by: modelID)
    }

    func stopUploadTask(modelID: String) {
        guard let cache = self.uploadCacheDict[modelID] else {
            return
        }

        cache.disposeBag = DisposeBag()
        cache.task?.cancel()
    }

    func setupUploadTaskToFailure(modelID: String) {
        guard let cache = self.uploadCacheDict[modelID] else {
            return
        }

        self.uploadCacheDict[modelID] = nil
        self.updateDraftModelAfterFailure(cache.model) { [unowned self] newModel in
            self.sendingMessageObserver(with: newModel, action: .update)
        }
    }
    
    /**
     delete local message, update message.deleted flag from false to true
     */
    func deleteMessage(model: MessageModel) {
        self.realmDAO.getModel(type: MessageModel.self, id: model.id) { message in
            guard var message = message else { return }

            message.deleted = true
            let rlm = message.convertToDBObject()
            let rlmThread = message.convertToThreadDBObject()
            
            self.realmDAO.update([rlm], policy: .modified) {
                self.sendingMessageObserver(with: message, action: .delete)
            }
            
            self.realmDAO.update([rlmThread], policy: .modified)
        }
    }
    
    /**
     unsend message, 並刪除 local 資料
     */
    func unsendMessage(model: MessageModel) {
        ApiClient.unsendMessage(messageID: model.id)
            .subscribe(onError: { error in
                print("### error: ", error)
            }, onCompleted: { [weak self] in
                guard let self = self else { return }
                self.removeDatabaseMessage(model: model) {
                    self.sendingMessageObserver(with: model, action: .delete)
                }
            }).disposed(by: disposeBag)
    }
    
    
    func getFailureMessages(groupID: String, complete: @escaping ([MessageModel]) -> Void) {
        realmDAO.getDraftMessages(predicateFormat: "groupID = '\(groupID)' AND status = 'failed'") { failureMesages in
            let fMessages = failureMesages.compactMap { MessageModel(with: $0) }
            complete(fMessages)
        }
    }
    
    func isDeletedMessage(by messageID: String, at groupID: String) -> Bool {
        let messageModel = realmDAO.immediatelyModel(type: MessageModel.self, id: messageID)
        return messageModel?.deleted ?? false
    }
    
    // MARK: convert to MessageModel
    func convertTextMessageModel(content: String, groupID: String, userID: String = UserData.shared.userID ?? "") -> MessageModel {
        let date = Date.init()
        let time = Int(date.timeIntervalSince1970 * 1000)
        var model = MessageModel()
        let msgID = "tmp" + String(format: "%d", time)
        model.id = msgID
        model.cid = UUID().uuidString
        model.diffID = msgID
        model.message = content
        model.messageStatus = .sending
        model.timestamp = time
        model.createAt = date
        model.messageType = .text
        model.userID = userID
        model.groupID = groupID
        model.transceiverID = TransceiverModel.uniqueID(groupID, userID)
        return model
    }
    
    func convertReplyMessageModel(content: String, replyMessage: MessageModel) -> MessageModel {
        let date = Date.init()
        let time = Int(date.timeIntervalSince1970 * 1000)
        let userID = UserData.shared.userID ?? ""
        var model = MessageModel()
        let msgID = "tmp" + String(format: "%d", time)
        model.id = msgID
        model.cid = UUID().uuidString
        model.diffID = msgID
        model.message = content
        model.messageStatus = .sending
        model.timestamp = time
        model.createAt = date
        model.messageType = .text
        model.threadID = replyMessage.id
        model.threadMessage = [replyMessage]
        model.userID = userID
        model.groupID = replyMessage.groupID
        model.transceiverID = TransceiverModel.uniqueID(replyMessage.groupID, userID)
        return model
    }
    
    func convertImageMessageModel(imageFileName: String, groupID: String, index: String = "", userID: String = UserData.shared.userID ?? "") -> MessageModel {
        let date = Date.init()
        let time = Int(date.timeIntervalSince1970 * 1000)
        var model = MessageModel()
        let msgID = "tmp" + String(format: "%d", time) + index
        model.id = msgID
        model.cid = UUID().uuidString
        model.diffID = msgID
        model.messageStatus = .fakeSending
        model.timestamp = time
        model.createAt = date
        model.messageType = .image
        model.imageFileName = imageFileName
        model.userID = userID
        model.groupID = groupID
        model.transceiverID = TransceiverModel.uniqueID(groupID, userID)
        return model
    }

    func loadFile(_ groupID: String, messageID: String, fileIDs: [String]) -> Observable<RLMMessage?> {
        return Observable.create { [unowned self] observer -> Disposable in
            let newFileIds = fileIDs.filter({ !self.realmDAO.checkExist(type: RLMFiles.self, by: $0) })
            let oldFileIds = fileIDs.filter({ self.realmDAO.checkExist(type: RLMFiles.self, by: $0) })
            if newFileIds.isEmpty && oldFileIds.isEmpty {
                observer.onNext(nil)
                observer.onCompleted()
            } else {
                if !newFileIds.isEmpty {
                    let fileObservables = newFileIds.map({ ApiClient.getFile(groupID: groupID, fileID: $0) })
                    Observable.zip(fileObservables).subscribe { [weak self] files in
                        guard let self = self else { return }
                        guard let model = self.realmDAO.immediatelyModel(type: MessageModel.self, id: messageID) else { return }
                        let rlmFiles = files.compactMap { RLMFiles.init(with: $0) }
                        let rlmMessage = model.convertToDBObject()
                        rlmMessage.updateRLMFiles(rlmFiles)
                        self.realmDAO.update([rlmMessage], policy: .modified) {
                            observer.onNext(rlmMessage)
                            observer.onCompleted()
                        }
                    } onError: { _ in
                        observer.onNext(nil)
                        observer.onCompleted()
                    }.disposed(by: self.disposeBag)
                }
                
                if !oldFileIds.isEmpty {
                    let model = self.realmDAO.immediatelyModel(type: MessageModel.self, id: messageID)
                    let rlmMessage = model?.convertToDBObject()
                    observer.onNext(rlmMessage)
                    observer.onCompleted()
                }
            }
            return Disposables.create()
        }
    }
}
