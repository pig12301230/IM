//
//  DataAccess+group.swift
//  ChatRoom
//
//  Created by ZoeLin on 2022/5/6.
//

import Foundation
import RxSwift

extension DataAccess {
    
    /**
     取得Database 特定ID group 的 info
     - Parameters:
        - id: 要取得 info 的 group.id
     */
    func getGroup(groupID: String) -> GroupModel? {
        guard let model = self.realmDAO.immediatelyModel(type: GroupModel.self, id: groupID), model.hidden == false else {
            return nil
        }
        return model
    }
    
    /**
     取得特定 group 的 info
     - Parameters:
        - id: 要取得 info 的 group.id
     */
    func fetchGroup(by id: String, completion: (() -> Void)? = nil) {
        let getGroupLastMessageObservable = ApiClient.getGroupLastMessage(groupID: id).catchAndReturn(nil)
        let getGroupInfoObservable = ApiClient.getGroupBy(groupID: id)
        Observable.zip(getGroupLastMessageObservable, getGroupInfoObservable)
            .subscribe { [weak self] (lastMsg, groupInfo) in
                guard let self = self else {
                    completion?()
                    return
                }
                self.processQueue.async {
                    var group = groupInfo
                    if let lastMesssage = lastMsg?.lastMessage {
                        group.lastMessage = lastMesssage
                    }
                    self.updateGroup(group)
                    
                    guard let memberPermission = group.memberPermission else {
                        completion?()
                        return
                    }
                    
                    if let userAuth = group.auth, let userID = UserData.shared.userID {
                        self.updateRoleToDatabase(userAuth, groupID: id, userID: userID) { [weak self] role in
                            guard let self = self else { return }
                            self.getGroupObserver(by: group.id).rolePermission.accept(role)
                        }
                    }
                    
                    self.updateGroupMemberPermissionToDatabase(memberPermission, groupID: group.id) { _ in
                        completion?()
                    }
                }
            } onError: { _ in
                // send signal or NOT
            }.disposed(by: self.disposeBag)
    }
    
    func generateGroup(info: (part: RUserGroupPart, lastMsg: RGroupLastMessage?)) -> Observable<RUserGroups?> {
        return Observable.create { [unowned self] observer -> Disposable in
            if let group = self.getGroup(groupID: info.part.id) {
                observer.onNext(RUserGroups(from: info.part, lastMessage: info.lastMsg, groupModel: group))
                observer.onCompleted()
            } else {
                ApiClient.getGroupBy(groupID: info.part.id)
                    .subscribe { group in
                        var newGroup = group
                        if let lastMsg = info.lastMsg {
                            newGroup.lastViewed = lastMsg.lastViewd
                            newGroup.unread = lastMsg.unread
                            newGroup.lastMessage = lastMsg.lastMessage
                        }
                        observer.onNext(newGroup)
                        observer.onCompleted()
                    } onError: { _ in
                        observer.onNext(nil)
                        observer.onCompleted()
                    }.disposed(by: disposeBag)
            }
            return Disposables.create()
        }
    }
    
    // MARK: - parser response data
    func parserGroups(_ uGroups: [RUserGroups], complete: @escaping () -> Void) {
        deleteNonExistenceGroup(uGroups)
        let lastMessages: [RLMGMessage] = uGroups
            .compactMap { group in
                guard let lastMessage = group.lastMessage else {
                    return nil
                }
                return RLMGMessage(with: lastMessage)
            }
            .filter { !$0._id.isEmpty }
        realmDAO.update(lastMessages)
        
        var visibleGroups = getVisiblyAndCompareGroupsStatus(uGroups)
        var unreadCount = 0

        visibleGroups.forEach { group in
            getGroupObserver(by: group._id).unread.accept(group.unreadCount)
            unreadCount += group.unreadCount
            
            var newGroup = GroupModel(with: group)
            var lastMessageID: String? = ""
            
            // 檢查 server回來的 last message 在 DB是否刪除，若刪除就用 DB的最新有效訊息當作 last message
            if let newLastMessageId = group.lastMessage?._id,
               let messageModel = self.realmDAO.immediatelyModel(type: MessageModel.self, id: newLastMessageId),
               !isEffectiveLastMessage(message: messageModel) {
                let lastMessage = self.getLastEffectiveMessage(groupID: group._id)
                newGroup.lastMessage = lastMessage
                lastMessageID = lastMessage?.id
            } else {
                lastMessageID = group.lastMessage?._id
            }
            _ = self.getGroupConversationDataSource(groupModel: newGroup)
            self.getGroupObserver(by: group._id).lastEffectiveMessageID.accept(lastMessageID)
            
            if let messageID = group.lastMessage?._id {
                deleteGroupOlderLastMessageDBData(groupID: group._id, messageID: messageID)
            }
            
            if group.groupType == .dm {
                // fetch dm member name
                if let userID = group.name.components(separatedBy: "_").filter({ $0 != UserData.shared.userInfo?.id }).first {
                    let id = TransceiverModel.uniqueID(group._id, userID)
                    if !self.realmDAO.checkExist(type: RLMTransceiver.self, by: id) {
                        fetchGroupMemberAndUpdate(groupID: group._id, memberID: userID) { }
                    }
                }
            }
        }
        // update total unread and send signal
        totalUnread = unreadCount

        realmDAO.getDraftMessages { [weak self] draftMessages in
            guard let self = self else { return }
            // if there is no draft message, save groups immediately.
            guard !draftMessages.isEmpty else {
                self.realmDAO.update(visibleGroups, completion: complete)
                return
            }
            
            let hasFailedMessageGroup: [String] = draftMessages.compactMap {
                guard $0.isDraft == false else { return nil }
                return $0.groupID
            }.removeDuplicateElement()
            
            // setup draft message content above last message to group
            // setup failure message status to group
            let draftMessagesDict = draftMessages.toDictionaryElements { $0.groupID }
            draftMessagesDict.forEach { (key, value: [RLMDraftMessage]) in
                if let (index, target) = visibleGroups.enumerated().first(where: { key == $0.1._id }) {
                    let new = target
                    new.hasFailure = hasFailedMessageGroup.contains(target._id)
                    new.draftContent = value.sorted(by: { $0.timestamp < $1.timestamp }).first?.message ?? ""
                    visibleGroups[index] = new
                }
            }
            
            self.realmDAO.update(visibleGroups, completion: complete)
        }
    }
        
    func handleSuccessCreateGroup(group: RUserGroups) {
        fetchGroupMembers(by: group.id)
        if group.type == .group {
            fetchGroup(by: group.id)
        }
    }
        
    /**
     發送 Group Action Observer
     - Paramater:
        - model: group model
        - action: 行爲 type (action == delete時, 會發送 clear messages 的訊號)
        - clearMessage: 是否要清除目前暫存的 Message List
     */
    func sendingGroupObserver(with model: GroupModel, action: DataAction, clearMessage: Bool = false) {
        self.groupListInfoObserver.onNext((action, model))

        self.getGroupObserver(by: model.id).groupObserver.accept(model)
        
        if action == .delete {
            self.dismissGroup.onNext(model.id)
        }
        
        if action == .delete || clearMessage {
            self.clearGroupConversationDataSource(by: model.id)
        }
    }
    
    func fetchLeaveGroup(_ groupID: String, _ memberID: String, completion: ((Bool, Error?) -> Void)? = nil) {
        self.deleteGroupMember(groupID, memberID) { isSuccess, error in
            guard isSuccess else {
                completion?(false, error)
                return
            }
            self.clearGroupConversationDataSource(by: groupID)
            self.deleteGroupDBData(groupID: groupID) {
                completion?(true, nil)
            }
        }
    }
    
    /**
     聊天列表 cell 左滑刪除
     */
    func deleteGroupMessages(groupID: String) {
        let format = String(format: "groupID = '%@'", groupID)
        // 草稿訊息, 失敗訊息也一併刪除
        self.realmDAO.delete(type: RLMDraftMessage.self, predicateFormat: format)
        
        // 清除Message相關資料
        if let messages = self.realmDAO.immediatelyModels(type: MessageModel.self, predicateFormat: format) {
            for message in messages {
                self.removeDatabaseMessage(model: message)
            }
        }
    }
    
    // 刪除群組內與訊息相關參數＆添加舊訊息回溯的最早時間標記
    func setupLastSyncTimeTo(groupID: String, needRecord: Bool = true, completion: (() -> Void)? = nil) {
        processQueue.async { [weak self] in
            guard let self = self else {
                completion?()
                return
            }
            let timestamp = Int(Date.init().timeIntervalSince1970 * 1000)
            
            if needRecord {
                let record = RLMRecord.init()
                record.groupID = groupID
                record.deleteTime = timestamp
                self.realmDAO.update([record])
            }
            
            self.realmDAO.getModel(type: GroupModel.self, id: groupID) { group in
                guard var group = group else {
                    completion?()
                    return
                }
                
                group.hidden = needRecord
                group.lastMessage = nil
                group.latestSyncTimestamp = timestamp
                
                if needRecord {
                    self.totalUnread -= group.unreadCount
                }
                
                // Save To database
                let rlmGroup = group.convertToDBObject()
                self.realmDAO.update([rlmGroup], policy: .modified) {
                    let action: DataAction = needRecord ? .delete : .update
                    self.sendingGroupObserver(with: group, action: action, clearMessage: true)
                    completion?()
                }
            }
        }
    }
    
    /**
     聊天室詳情刪除聊天記錄
     */
    func clearGroupMessages(groupID: String, completion: ((Bool) -> Void)? = nil) {
        ApiClient.clearGroupMessage(groupID: groupID).subscribe(onError: { _ in
            completion?(false)
        }, onCompleted: { [weak self] in
            guard let self = self else { return }
            self.deleteGroupMessages(groupID: groupID)
            self.clearDataSourcePageData(by: groupID)
            self.realmDAO.getModel(type: GroupModel.self, id: groupID) { group in
                guard var group = group else { return }
                group.hidden = true
                // update groupRecord.deleteMessageID, 才能持續 hidden group
                var record = self.getGroupRecord(by: groupID)
                record.deletedLastMessage = group.lastMessage?.id ?? ""
                record.deleteTime = group.lastMessage?.timestamp ?? 0
                self.realmDAO.update([group.convertToDBObject(), record.convertToDBObject()])
                completion?(true)
            }
        }).disposed(by: self.disposeBag)
    }
    
    // fetch group specific Message
    func fetchGroupMessageAndUpdate(groupID: String, messageID: String, completion: @escaping () -> Void) {
        ApiClient.getGroupMessage(groupID: groupID, messageID: messageID)
            .subscribeSuccess { [weak self] targetMessage in
                guard let self = self else {
                    completion()
                    return
                }
                let rlmMessage = RLMMessage.init(with: targetMessage)
                self.realmDAO.update([rlmMessage], policy: .all) {
                    completion()
                }
            }.disposed(by: disposeBag)
    }
    
    /**
    delete group's old last message, RLMGMessage table避免無限繁殖
     */
    func deleteGroupOlderLastMessageDBData(groupID: String, messageID: String) {
        processQueue.async { [weak self] in
            guard let self = self else { return }
            let format = "groupID = '\(groupID)' AND _id != '\(messageID)'"
            if self.realmDAO.checkExist(type: RLMGMessage.self, by: format) {
                self.realmDAO.delete(type: RLMGMessage.self, predicateFormat: format, completion: nil)
            }
        }
    }
}

// MARK: - Group 相關設定
extension DataAccess {
    /*
     上傳群組照片
     */
    func uploadGroupIcon(groupID: String, image: UIImage, completeThumbnail: @escaping (String?) -> Void) {
        guard let imageData = ImageProcessor.shared.getCompressionImageData(with: image) else {
            return completeThumbnail(nil)
        }
        
        ApiClient.uploadGroupIcon(groupID: groupID, imageData: imageData).subscribe { [weak self] iconInfo in
            completeThumbnail(iconInfo.icon_thumbnail)
            guard let self = self else {
                completeThumbnail(nil)
                return
            }
            self.realmDAO.getModel(type: GroupModel.self, id: groupID) { gModel in
                guard var gModel = gModel else {
                    return
                }
                
                gModel.iconThumbnail = iconInfo.icon_thumbnail
                gModel.icon = iconInfo.icon
                
                self.getGroupObserver(by: groupID).groupObserver.accept(gModel)
                self.realmDAO.update([gModel.convertToDBObject()], policy: .modified, completion: nil)
            }
        } onError: { _ in
            completeThumbnail(nil)
        }.disposed(by: self.disposeBag)
    }
    
    /**
     更新群組名稱
     */
    func setGroupDisplayName(groupID: String, name: String, complete: ((Bool) -> Void)? = nil) {
        ApiClient.updateGroup(groupID: groupID, displayName: name).subscribe { [weak self] model in
            guard let self = self else {
                complete?(false)
                return
            }
            complete?(true)
            self.realmDAO.getModel(type: GroupModel.self, id: groupID) { groupModel in
                guard var groupModel = groupModel else {
                    return
                }
                
                groupModel.display = model.displayName
                self.realmDAO.update([groupModel.convertToDBObject()])
            }
        } onError: { _ in
            complete?(false)
        }.disposed(by: disposeBag)
    }
    
    func setGroupNotify(groupID: String, mute: Bool, completion: ((Bool) -> Void)? = nil) {
        let notify = mute ? NotifyType.off : NotifyType.on
        ApiClient.updateGroupNotify(groupID: groupID, notify: notify).subscribe { [weak self] uGroup in
            guard let self = self else {
                completion?(false)
                return
            }
            self.processQueue.async {
                self.updateDBGroupNotify(groupID: groupID, group: uGroup)
            }
        } onError: { _ in
            completion?(false)
        }.disposed(by: self.disposeBag)
    }
    
    /**
     收到 group response, handle last sync time, and save info TO database
     */
    private func updateDBGroupNotify(groupID: String, group: RUserGroups) {
        self.realmDAO.getModel(type: GroupModel.self, id: groupID) { [unowned self] model in
            guard var groupModel = model else { return }
            groupModel.notifyType = group.notify
            self.sendingGroupObserver(with: groupModel, action: .update)
            let rlm = groupModel.convertToDBObject()
            self.realmDAO.update([rlm], policy: .modified)
        }
    }
}

// MARK: Group Images

extension DataAccess {
    func updateGroupImages(groupID: String, configs: [ImageViewerConfig]) {
        self.getGroupObserver(by: groupID).localGroupImagesConfigs.accept(configs)
    }
    
    func deleteMessageHandleGroupImage(groupID: String, message: MessageModel) {
        guard !message.fileIDs.isEmpty else { return }
        let configs = self.getGroupObserver(by: groupID).localGroupImagesConfigs.value
        message.fileIDs.forEach { fileId in
            if let index = configs.firstIndex(where: { $0.fileID == fileId }) {
                self.getGroupObserver(by: groupID).localGroupImagesConfigs.remove(at: index)
            }
        }
    }
    
    func addMessageHandleGroupImage(groupID: String, message: MessageModel) {
        guard !message.fileIDs.isEmpty else { return }
        let transDict = self.getGroupObserver(by: groupID).transceiverDict.value
        let nickName = transDict.first(where: { $0.key == message.userID })?.value.nickname ?? ""
        message.fileIDs.forEach { fileId in
            if let fileModel = self.realmDAO.immediatelyModel(type: FileModel.self, id: fileId) {
                let config = ImageViewerConfig(title: nickName, date: message.createAt, imageURL: fileModel.url, actionType: .viewAndDownload, fileID: message.fileIDs.first, messageId: message.diffID)
                self.getGroupObserver(by: groupID).localGroupImagesConfigs.append(element: config)
            }
        }
    }
    
    func fetchDatabaseGroupImage(_ groupID: String) {
        let format = String(format: "groupID = '%@' AND type = 'image' AND deleted = false", groupID)
        let transceivers = self.getGroupObserver(by: groupID).transceiverDict.value
        self.realmDAO.getDBModels(type: RLMGMessage.self, predicateFormat: format) { [weak self] rmessage in
            // 拿 last message image
            guard let self = self else { return }
            guard let lastMessage = rmessage?.first,
                  let imageUrl = self.getFile(by: lastMessage.fileIDs.first ?? "")?.url,
                  let transceiver = transceivers.first(where: { $0.key == lastMessage.userID })?.value
            else { return }
            
            let title = transceiver.nickname
            let config = ImageViewerConfig(title: title, date: lastMessage.createAt, imageURL: imageUrl, actionType: .viewAndDownload, fileID: lastMessage.fileIDs.first, messageId: lastMessage.diffID)
            self.getGroupObserver(by: groupID).localGroupImagesConfigs.append(element: config)
        }
        realmDAO.getModels(type: MessageModel.self, predicateFormat: format) { [weak self] imageMessageList in
            guard let self = self, let imageMessageList = imageMessageList else { return }
            var configs: [ImageViewerConfig] = []
            let transDict = self.getGroupObserver(by: groupID).transceiverDict.value
            imageMessageList.forEach { messageModel in
                guard let fileId = messageModel.fileIDs.first, let fileModel = self.realmDAO.immediatelyModel(type: FileModel.self, id: fileId) else { return }
                let nickname = transDict.first(where: { $0.key == messageModel.userID })?.value.nickname ?? ""
                configs.append(ImageViewerConfig(title: nickname,
                                                 date: messageModel.createAt,
                                                 imageURL: fileModel.url,
                                                 actionType: .viewAndDownload,
                                                 fileID: fileId,
                                                 messageId: messageModel.diffID))
            }
            self.updateGroupImages(groupID: groupID, configs: configs)
        }
    }
}

// MARK: Group Draft Message
extension DataAccess {
    
    /**
     儲存草稿
     - Paramater:
        - content: 草稿內文
        - groupID: 草稿隸屬的 group.id
     */
    func saveDraft(_ content: String, at groupID: String) {
        self.processQueue.async {
            self.updateGroupDraftContent(to: groupID, content: content)
        }
    }
    
    /**
     更新 group.draft
     - Paramaters:
        - groupID: 要更新的 group.id
        - content: content string
     */
    
    func updateGroupDraftContent(to groupID: String, content: String) {
        guard var groupModel = self.realmDAO.immediatelyModel(type: GroupModel.self, id: groupID) else {
            return
        }
        
        groupModel.draft = content
        self.sendingGroupObserver(with: groupModel, action: .update)
        self.realmDAO.update([groupModel.convertToDBObject()])
        
        guard !content.isEmpty else {
            // 刪除 daft, send observer
            self.deleDraftMessage(with: groupID)
            self.sendDraftMessage(to: groupID)
            return
        }
        
        // update draft model
        var draft = MessageModel()
        draft.id = MessageModel.getDraftID(with: groupID)
        draft.groupID = groupID
        draft.message = content
        
        self.sendDraftMessage(to: groupID, draft: draft)
        
        let rlmDraft = RLMDraftMessage.init(by: draft.convertToDBObject())
        rlmDraft.isDraft = true
        self.realmDAO.update([rlmDraft])
    }
    
    /**
     取得 self cache or 草稿 message
     Parameters:
      - predicateFormat: 要對 database 做的 query format
     */
    func getDraftMessages(format predicateFormat: String, complete: @escaping ([MessageModel]) -> Void) {
        self.processQueue.async {
            self.realmDAO.getDraftMessages(predicateFormat: predicateFormat) { messages in
                var result: [MessageModel] = messages.map { MessageModel.init(with: $0) }
                result.sort(by: { $0.timestamp < $1.timestamp })

                complete(result)
            }
        }
    }

    /**
     刪除 draft message
     - Paramaters:
        - draftID: 要刪除的 DraftMessage.id
        - updateGroupID: 清空 group.draft 的 groupID
     */
    func deleteDraftMessage(with groupID: String) {
        self.deleDraftMessage(with: groupID)
        self.updateGroupDraftContent(to: groupID, content: "")
    }
    
    private func deleDraftMessage(with groupID: String) {
        let draftID = MessageModel.getDraftID(with: groupID)
        self.realmDAO.delete(type: RLMDraftMessage.self, by: draftID)
    }
    
    private func sendDraftMessage(to groupID: String, draft: MessageModel? = nil) {
        self.getGroupObserver(by: groupID).draftObserver.onNext(draft)
    }
}

// MARK: - Group BlockList
extension DataAccess {
    /**
     取得群組黑名單列表
     */
    func fetchGroupBlocks(groupID: String) {
        ApiClient.getGroupBlocks(groupID: groupID).subscribe { [weak self] blocks in
            // 存進Database: BlackList
            guard let self = self else { return }
            let deleteFormat = String(format: "groupID = '%@'", groupID)
            self.realmDAO.delete(type: RLMBlackList.self, predicateFormat: deleteFormat) {
                let blocks = blocks.filter { $0.id != UserData.shared.userID }
                self.updateBlackListToDatabase(groupID: groupID, info: blocks)
            }
            let settings = self.getUserPersonalSettingDict()
            let blockedTransceivers: [RLMTransceiver] = blocks.map {
                let tran = RLMTransceiver.init(with: groupID, userID: $0.id, isMember: false, info: $0, display: settings[$0.id]?.nickname)
                tran.blocked = true
                return tran
            }

            let unblockedTransceivers = self.getGroupConversationDataSource(by: groupID)?.getConversationAllTransceiversIncludeLeft()
                    .filter { oriTransceiver in
                        !blockedTransceivers.contains(where: { $0.userID == oriTransceiver.userID })
                    }.map { oriTransceiver -> TransceiverModel in
                        var unblockedTrans = oriTransceiver
                        unblockedTrans.blocked = false
                        return unblockedTrans
                    } ?? []
            
            let allTransModel = unblockedTransceivers + blockedTransceivers.map { TransceiverModel(with: $0) }
            self.replaceGroupTransceivers(groupID: groupID, transceivers: allTransModel)
            self.getGroupConversationDataSource(by: groupID)?.detail?.blocksCount.accept(blocks.count)
            self.realmDAO.update(allTransModel.map { $0.convertToDBObject() })
        } onError: { _ in
            // TODO: error?
        }.disposed(by: self.disposeBag)
    }
    
    func getGroupBlockedTransceivers(by groupID: String) -> [TransceiverModel] {
        let format = String(format: "groupID = '%@'", groupID)
        guard let models = self.realmDAO.immediatelyModels(type: GroupBlackListModel.self, predicateFormat: format) else { return [] }
        
        guard let groupTransceivers = self.realmDAO.immediatelyModels(type: TransceiverModel.self, predicateFormat: format) else { return [] }
        
        return sortListByAtoZ0To9(list: groupTransceivers.filter { transceiver in
            models.contains(where: { $0.userID == transceiver.userID })
        })
    }
    
    func addGroupBlockedMembers(_ groupID: String, usersID: [String], completion: ((Bool) -> Void)? = nil) {
        ApiClient.addGroupBlockMember(groupID: groupID, memberID: usersID)
            .subscribe(onError: { _ in
                completion?(false)
            }, onCompleted: { [weak self] in
                completion?(true)
                guard let self = self else { return }

                // 更新 blocked member count
                self.modifyBlockedCount(groupID: groupID, count: usersID.count, action: .add)

                // 新增至 BlackList
                let models = usersID.map { RLMBlackList(groupID: groupID, userID: $0) }
                self.realmDAO.update(models)
                
                // update transceiver blocked
                let format = String(format: "groupID = '%@'", groupID)
                self.realmDAO.getModels(type: TransceiverModel.self, predicateFormat: format) { transceivers in
                    guard let transceivers = transceivers else { return }
                    let blockedUsers = transceivers.filter { usersID.contains($0.userID) }
                    let blockedMemberTrans: [RLMTransceiver] = blockedUsers.compactMap {
                        var model = $0
                        model.blocked = true
                        model.isMember = false
                        return model.convertToDBObject()
                    }
                    
                    self.realmDAO.update(blockedMemberTrans, policy: .modified) {
                        self.realmDAO.getModels(type: TransceiverModel.self, predicateFormat: "groupID = '\(groupID)'") { allModels in
                            self.replaceGroupTransceivers(groupID: groupID, transceivers: allModels ?? [])
                        }
                    }
                }
            }).disposed(by: disposeBag)
    }
    
    func removeGroupBlockedMember(_ groupID: String, userID: String, completion: ((Bool) -> Void)? = nil) {
        ApiClient.removeGroupBlockedMember(groupID: groupID, memberID: userID)
            .subscribe(onError: { _ in
                completion?(false)
            }, onCompleted: { [weak self] in
                completion?(true)
                guard let self = self else { return }
                // 更新 blocked member count
                self.modifyBlockedCount(groupID: groupID, count: 1, action: .delete)
                // update transceiver blocked
                let uniqueID = TransceiverModel.uniqueID(groupID, userID)
                self.realmDAO.delete(type: RLMBlackList.self, by: uniqueID)
                self.realmDAO.getModel(type: TransceiverModel.self, id: uniqueID) { transceiver in
                    guard let transceiver = transceiver else { return }
                    var model = transceiver
                    model.blocked = false
                    let realmModel = model.convertToDBObject()
                    self.realmDAO.update([realmModel], policy: .modified) {
                        self.realmDAO.getModels(type: TransceiverModel.self, predicateFormat: "groupID = '\(groupID)'") { allModels in
                            self.replaceGroupTransceivers(groupID: groupID, transceivers: allModels ?? [])
                        }
                    }
                }
            }).disposed(by: disposeBag)
    }
    
    func updateBlackListToDatabase(groupID: String, info: [RUserInfo]) {
        let models = info.map { RLMBlackList(groupID: groupID, info: $0) }
        self.realmDAO.update(models)
    }
    
    /**
     變更 group 的 blocked count
     - Parameters:
       - groupID:
       - count:
       - action: only modify when action is .add or .delete
     */
    private func modifyBlockedCount(groupID: String, count: Int, action: DataAction) {
        guard action == .delete || action == .add else { return }
        guard let blockCountObserver = self.getGroupConversationDataSource(by: groupID)?.detail?.blocksCount else {
            return
        }

        var blocked = blockCountObserver.value
        if action == .add {
            blocked += count
        } else if action == .delete {
            blocked -= count
        }
        blockCountObserver.accept(blocked)
    }
}

// MARK: - Role Permisssion
extension DataAccess {
    /**
     更新群組 role 為 member 的相關權限
     */
    
    func getGroupOwnerAndAdmins(groupID: String, ownerFirst: Bool = true, sortedByAZ09: Bool = true) -> [TransceiverModel] {
        guard let groupModel = self.getGroup(groupID: groupID) else { return [] }
        guard let allGroupTrans = self.realmDAO.immediatelyModels(type: TransceiverModel.self, predicateFormat: "groupID = '\(groupID)'") else { return [] }

        let adminsID = self.getGroupConversationDataSource(by: groupID)?.detail?.adminIds.value ?? []
        let admins = allGroupTrans.filter { adminsID.contains($0.userID) }
        var sortedAdmins = self.sortListByAtoZ0To9(list: admins)
        
        guard let owner = allGroupTrans.first(where: { $0.userID == groupModel.ownerID }) else { return sortedAdmins }
        sortedAdmins.insert(owner, at: 0)
        return sortedAdmins
    }
    
    func setGroupAdminPermissions(groupID: String, userID: String, parameter: [String: Any], complete: ((Bool) -> Void)? = nil) {
        ApiClient.updateGroupAmdin(groupID: groupID, userID: userID, parameter: parameter).subscribe { [weak self] permission in
            guard let self = self else {
                complete?(false)
                return
            }
            // update setting count
            var permissionModel = RolePermissionModel()
            permissionModel.update(by: permission, role: .member)
            self.parserPermissionSetting(groupID: groupID, permission: permissionModel)
            complete?(true)
            
            // update database
            let targetID = TransceiverModel.uniqueID(groupID, userID)
            self.realmDAO.getModel(type: UserRoleModel.self, id: targetID) { roleModel in
                guard var model = roleModel else { return }
                model.permission.update(by: permission, role: .admin)
                self.realmDAO.update([model.convertToDBObject()])
            }
        } onError: { _ in
            complete?(false)
        }.disposed(by: disposeBag)
    }
    
    func addGroupAdmin(groupID: String, userID: String, permissions: [String: Any], completed: ((Bool) -> Void)? = nil) {
        let parameter: [String: Any] = ["permissions": permissions, "user_id": userID]
        ApiClient.addGroupAdmin(groupID: groupID, parameter: parameter)
            .subscribe(onError: { _ in
                completed?(false)
            }, onCompleted: { [weak self] in
                guard let self = self else {
                    completed?(false)
                    return
                }
                self.fetchGroupAdminPermission(groupID: groupID, userID: userID) { userRole in
                    guard userRole != nil else {
                        completed?(false)
                        return
                    }
                    self.modifyGroupAdmins(groupID: groupID, userID: userID, action: .add)
                    completed?(true)
                }
            }).disposed(by: disposeBag)
    }
    
    func deleteGroupAdmin(groupID: String, userID: String, completed: ((Bool) -> Void)? = nil) {
        ApiClient.deleteGroupAdmins(groupID: groupID, userID: userID)
            .subscribe(onError: { _ in
                completed?(false)
            }, onCompleted: { [weak self] in
                completed?(true)
                guard let self = self else { return }
                self.modifyGroupAdmins(groupID: groupID, userID: userID, action: .delete)
                self.realmDAO.delete(type: UserRoleModel.DBObject.self, predicateFormat: "groupID = '\(groupID)' AND userID = '\(userID)'")
            }).disposed(by: disposeBag)
    }
    
    func fetchGroupAdminPermission(groupID: String, userID: String, completed: ((UserRoleModel?) -> Void)? = nil) {
        ApiClient.getGroupAdminPermission(groupID: groupID, userID: userID).subscribe { [weak self] auth in
            guard let self = self else { return }
            self.processQueue.async {
                self.updateRoleToDatabase(auth, groupID: groupID, userID: userID, completed: completed)
            }
        } onError: { _ in
            completed?(nil)
        }.disposed(by: self.disposeBag)
    }
    
    /**
     取得特定 group 中特定的 permission
     - Parameters:
        - groupID: 要取得 info 的 group.id
        - ownerID: 要取得 info 的 group.ownerID
     */
    func fetchGroupPermission(with groupID: String, ownerID: String, completed: ((UserRoleModel?) -> Void)? = nil) {
        self.fetchGroupAdminAndMemberRole(groupID: groupID, ownerID: ownerID)
            .subscribe { userRoles in
                let userRole = userRoles
                    .compactMap { $0 }
                    .first(where: { $0.userID == UserData.shared.userInfo?.id })
                completed?(userRole)
            } onError: { _ in
                completed?(nil)
            }.disposed(by: disposeBag)
    }
    
    /**
     更新群組 role 為 member 的相關權限
     */
    func setGroupMemberPermissions(groupID: String, parameter: [String: Any], complete: ((Bool) -> Void)? = nil) {
        ApiClient.setGroupMemberPermission(groupID: groupID, paramater: parameter).subscribe { [weak self] permission in
            guard let self = self else {
                complete?(false)
                return
            }
            complete?(true)
            var permissionModel = RolePermissionModel()
            permissionModel.update(by: permission, role: .member)
            permissionModel._id = groupID + "_member_role"
            // update database
            self.realmDAO.update([permissionModel.convertToDBObject()]) {
                // update setting count
                self.parserPermissionSetting(groupID: groupID, permission: permissionModel)
            }
        } onError: { _ in
            complete?(false)
        }.disposed(by: disposeBag)
    }
    
    
    func fetchGroupOwnerAdminList(groupID: String, ownerID: String) {
        ApiClient.getGroupAdmins(groupID: groupID)
            .subscribeSuccess { [weak self] admins in
                guard let self = self else { return }
                let adminList = admins.map { $0.id }
                self.updateGroupTransceiversRole(groupID: groupID, ownerID: ownerID, adminList: adminList)
            }.disposed(by: disposeBag)
    }
    
    /**
     抓取權限為 admin and member 的 權限設定
     - Parameters:
        - groupID: 要取得 info 的 group.id
        - ownerID: 所在 group 的 ownerID
     */
    
    func fetchGroupAdminAndMemberRole(groupID: String, ownerID: String) -> Observable<[UserRoleModel?]> {
        return ApiClient.getGroupAdmins(groupID: groupID)
            .catchAndReturn([])
            .map { admins -> [String] in
                var adminsList = admins.map { $0.id }
                self.getGroupConversationDataSource(by: groupID)?.detail?.adminIds.accept(adminsList)
                adminsList.append(ownerID)
                return adminsList
            }
            .flatMap { [weak self] adminsList -> Observable<[UserRoleModel?]> in
                guard let self = self else { return .just([]) }
                // 刪除DB 已經不是Admin的欄位
                let format = "groupID = '\(groupID)' AND type = 'admin'"
                _ = self.realmDAO.immediatelyModels(type: UserRoleModel.self, predicateFormat: format)?
                    .filter { role in
                        return !adminsList.contains(where: { $0 == role.userID })
                    }.map {
                        let id = $0.groupID + "_" + $0.userID
                        self.realmDAO.delete(type: RLMUserRole.self, by: id)
                        self.updateTransceiverRole(groupID: $0.groupID, userID: $0.userID, role: .member)
                    }
                return Observable.zip(adminsList.map { self.fetchGroupAdminPermission(groupID: groupID, userID: $0) })
            }
    }
    
    func fetchGroupAdminPermission(groupID: String, userID: String) -> Observable<UserRoleModel?> {
        return Observable.create { observer -> Disposable in
            ApiClient.getGroupAdminPermission(groupID: groupID, userID: userID).subscribe { [weak self] auth in
                guard let self = self else {
                    observer.onNext(nil)
                    observer.onCompleted()
                    return
                }
                self.processQueue.async {
                    self.updateRoleToDatabase(auth, groupID: groupID, userID: userID) { userRole in
                        observer.onNext(userRole)
                        observer.onCompleted()
                    }
                }
            } onError: { _ in
                observer.onNext(nil)
                observer.onCompleted()
            }.disposed(by: self.disposeBag)
            
            return Disposables.create()
        }
    }
    /**
     變更 group 的 admins (userID list)
     - Parameters:
       - groupID:
       - userID:
       - action: only modify when action is .add or .delete
     */
    private func modifyGroupAdmins(groupID: String, userID: String, action: DataAction) {
        guard action == .delete || action == .add else { return }
        let adminsObserver = self.getGroupConversationDataSource(by: groupID)?.detail?.adminIds
        guard let observer = adminsObserver else { return }
        var admins = observer.value
        if action == .delete {
            admins.removeAll { $0 == userID }
            self.updateTransceiverRole(groupID: groupID, userID: userID, role: .member)
        } else {
            admins.append(userID)
            self.updateTransceiverRole(groupID: groupID, userID: userID, role: .admin)
        }
        observer.accept(admins)
    }
    
    func getSelfGroupRole(groupID: String) -> UserRoleModel {
        guard let role = self.realmDAO.immediatelyModel(type: UserRoleModel.self, id: groupID + "_" + (UserData.shared.userInfo?.id ?? "")) else {
            return self.getGroupMemberRole(groupID: groupID)            
        }
        
        return role
    }
    
    func fetchSelfGroupRole(groupID: String) {
        ApiClient.getGroupBy(groupID: groupID)
            .subscribe(onNext: { [weak self] group in
                guard let self else { return }
                if let userAuth = group.auth, let userID = UserData.shared.userID {
                    self.updateRoleToDatabase(userAuth, groupID: groupID, userID: userID)
                }
            }).disposed(by: disposeBag)
    }
    
    func getGroupUserRole(targetID: String) -> UserRoleModel? {
        return self.realmDAO.immediatelyModel(type: UserRoleModel.self, id: targetID)
    }
    
    func getGroupMemberRole(groupID: String) -> UserRoleModel {
        let groupMemberID = groupID + "_member_role"
        guard let role = self.realmDAO.immediatelyModel(type: UserRoleModel.self, id: groupMemberID) else {
            // 抓不到先預設Member Role, 並重新打API更新
            fetchSelfGroupRole(groupID: groupID)
            return UserRoleModel(groupID: groupID,
                                 userID: UserData.shared.userInfo?.id ?? "",
                                 type: .member,
                                 permission: RolePermissionModel(with: .member))
        }
        return role
    }
    
    func updateRoleToDatabase(_ auth: RUserAuth, groupID: String, userID: String, completed: ((UserRoleModel) -> Void)? = nil) {
        // update to transceiver
        updateTransceiverRole(groupID: groupID, userID: userID, role: auth.role)
        guard let permission = auth.permissions, auth.role == .member else {
            let rlmModel = UserRoleModel.DBObject.init(with: groupID, userID: userID, auth: auth)
            self.realmDAO.update([rlmModel])
            completed?(UserRoleModel.init(with: rlmModel))
            return
        }
        
        self.updateGroupMemberPermissionToDatabase(permission, groupID: groupID, completed: completed)
    }
    
    func updateTransceiverRole(groupID: String, userID: String, role: PermissionType) {
        let uniqueID = TransceiverModel.uniqueID(groupID, userID)
        self.realmDAO.getModel(type: TransceiverModel.self, id: uniqueID) { [weak self] model in
            guard let self = self else { return }
            guard let rlmTransceiver = model?.convertToDBObject() else { return }
            rlmTransceiver.role = role.rawValue
            self.realmDAO.update([rlmTransceiver])
            self.updateGroupTransceivers(groupID: groupID, transceivers: [TransceiverModel.init(with: rlmTransceiver)])
        }
    }
    
    func updateGroupTransceiversRole(groupID: String, ownerID: String, adminList: [String]) {
        let format = "groupID = '\(groupID)'"
        self.realmDAO.getModels(type: TransceiverModel.self, predicateFormat: format) { transceivers in
            guard let transceivers = transceivers else { return }
            // update transceiver role
            let rlmTransceivers = transceivers.map { transceiver -> RLMTransceiver in
                var updateTransceiver = transceiver
                if transceiver.userID == ownerID {
                    updateTransceiver.role = .owner
                } else if adminList.contains(transceiver.userID) {
                    updateTransceiver.role = .admin
                } else {
                    updateTransceiver.role = .member
                }
                return updateTransceiver.convertToDBObject()
            }
            self.realmDAO.update(rlmTransceivers)
            let updated = rlmTransceivers.map { TransceiverModel(with: $0) }
            self.updateGroupTransceivers(groupID: groupID, transceivers: updated)
        }
    }
    
    func updateGroupMemberPermissionToDatabase(_ permission: RPermission, groupID: String, completed: ((UserRoleModel) -> Void)? = nil) {
        let groupMemberID = groupID + "_member_role"
        let rlmP = RLMPermission(with: groupMemberID, groupID: groupID, permission: permission)
        
        rlmP.updateTo(role: .member)
        let rlm = RLMUserRole()
        rlm._id = groupMemberID
        rlm.permission = rlmP
        rlm.groupID = groupID
        rlm.role = .member
        
        self.realmDAO.update([rlm]) {
            let role = UserRoleModel.init(with: rlm)
            self.parserPermissionSetting(groupID: groupID, permission: role.permission)
            completed?(role)
        }
    }
    
    func parserPermissionSetting(groupID: String, permission: RolePermissionModel) {
        var openCount: Int = 0
        if permission.sendMessages { openCount += 1 }
        if permission.sendImages { openCount += 1 }
        if permission.sendHyperlinks { openCount += 1 }
        if permission.inviteUsers { openCount += 1 }
        getGroupConversationDataSource(by: groupID)?.detail?.settingOnCount.accept(openCount)
    }
}

// MARK: Group Members, Transceivers 相關
extension DataAccess {
    /**
     新增成員到 group
     - Parameters:
       - groupID:
       - usersID: 欲新增的 user.id list
       - completion: operation result, true = success, false = failure
     */
    func addGroupMembers(_ groupID: String, _ usersID: [String], completion: ((Bool) -> Void)? = nil) {
        ApiClient.addGroupMember(groupID: groupID, memberID: usersID).subscribe(onError: { _ in
            completion?(false)
        }, onCompleted: { [weak self] in
            completion?(true)
            guard let self = self else { return }
            self.fetchGroupMembers(groupID: groupID, memberIDs: usersID)
        }).disposed(by: disposeBag)
    }
    
    func fetchGroupMember(by groupID: String, memberID: String, completion: @escaping (RUserInfo?) -> Void) {
        ApiClient.getGroupMember(groupID: groupID, memberID: memberID).subscribe { member in
            completion(member)
        } onError: { _ in
            completion(nil)
        }.disposed(by: disposeBag)
    }
    
    /**
     fetch group members
     - Parameters:
        - groupID
        - memberIDs: fetch member.userID list
     */
    func fetchGroupMembers(groupID: String, memberIDs: [String]) {
        let nonDuplicateMembersID = memberIDs.removeDuplicateElement()
        ApiClient.getGroupMembers(groupID: groupID, memberIDs: nonDuplicateMembersID).subscribeSuccess { [weak self] userInfos in
            guard let self = self else { return }
            self.processQueue.async {
                self.saveGroupMembers(groupID: groupID, members: userInfos)
            }
        }.disposed(by: disposeBag)
    }

    /**
     fetch group all members
     - Parameters:
        - by: groupID
     */
    func fetchGroupMembers(by groupID: String) {
        ApiClient.getGroupMembersBy(groupID: groupID).subscribe { [weak self] members in
            guard let self = self else { return }
            self.processQueue.async {
                self.saveGroupMembers(groupID: groupID, members: members)
            }
        } onError: { _ in
            // TODO: send signal or NOT
            PRINT("fetch groups members Fail", cate: .request)
        }.disposed(by: self.disposeBag)
    }
    
    func fetchGroupMemberAndUpdate(groupID: String, memberID: String, completion: @escaping () -> Void) {
        ApiClient.getGroupMember(groupID: groupID, memberID: memberID).subscribeSuccess { [weak self] member in
            guard let self = self else { return }
            let currentSetting = self.getUserPersonalSetting(with: memberID)
            let transceiver = RLMTransceiver.init(with: groupID, userID: memberID, info: member, display: currentSetting?.nickname)
            let model = TransceiverModel.init(with: transceiver)
            self.updateGroupTransceivers(groupID: groupID, transceivers: [model])
            self.realmDAO.update([transceiver], completion: completion)
        }.disposed(by: self.disposeBag)
    }
    
    func fetchGroupMembersAndUpdate(groupID: String, memberIDs: [String], completion: @escaping () -> Void) {
        ApiClient.getGroupMembers(groupID: groupID, memberIDs: memberIDs).subscribeSuccess { [weak self] membersInfo in
            guard let self = self else {
                completion()
                return
            }
            let transceivers = membersInfo.map { member -> RLMTransceiver in
                let currentSetting = self.getUserPersonalSetting(with: member.id)
                let transceiver = RLMTransceiver.init(with: groupID, userID: member.id, info: member, display: currentSetting?.nickname)
                return transceiver
            }
            self.updateGroupTransceivers(groupID: groupID, transceivers: transceivers.map { TransceiverModel.init(with: $0) })
            self.realmDAO.update(transceivers, completion: completion)
        }.disposed(by: disposeBag)
    }
    
    func deleteGroupMember(_ groupID: String, _ userID: String, completion: ((Bool, Error?) -> Void)? = nil) {
        ApiClient.deleteGroupMember(groupID: groupID, memberID: userID)
            .subscribe(onError: { error in
                completion?(false, error)
            }, onCompleted: { [weak self] in
                completion?(true, nil)
                guard let self = self else { return }
                let uniqueID = TransceiverModel.uniqueID(groupID, userID)
                self.realmDAO.getModel(type: TransceiverModel.self, id: uniqueID) { model in
                    guard var model = model else { return }
                    model.isMember = false
                    self.realmDAO.update([model.convertToDBObject()]) {
                        let format = "groupID = '\(groupID)'"
                        self.realmDAO.getModels(type: TransceiverModel.self, predicateFormat: format) { allModels in
                            self.replaceGroupTransceivers(groupID: groupID, transceivers: allModels ?? [])
                        }
                    }
                }
            }).disposed(by: disposeBag)
    }
    
    func saveGroupMembers(groupID: String, members: [RUserInfo]) {
        let settings = getUserPersonalSettingDict()
        let transceivers: [RLMTransceiver] = members.compactMap { info in
            let rlmTransceiver = RLMTransceiver.init(with: groupID,
                                                     userID: info.id,
                                                     isMember: info.leaveAt == nil,
                                                     info: info,
                                                     display: settings[info.id]?.nickname)
            let uniqueID = TransceiverModel.uniqueID(groupID, info.id)
            if let transciver = self.realmDAO.immediatelyModel(type: TransceiverModel.self, id: uniqueID) {
                rlmTransceiver.role = transciver.role.rawValue
            }
            return rlmTransceiver
        }
        let models: [TransceiverModel] = transceivers.compactMap { TransceiverModel.init(with: $0) }
        updateGroupTransceivers(groupID: groupID, transceivers: models)
        realmDAO.update(transceivers)
    }
}

// MARK: - PRIVATE update batabase
private extension DataAccess {
    
    func isEffectiveLastMessage(message: MessageModel) -> Bool {
        switch message.messageType {
        case .text, .image, .recommend, .groupCreate, .groupDisplayName, .hongBao:
            return !message.deleted
        default:
            return false
        }
    }
    
    func updateGroup(_ group: RUserGroups) {
        let isExist = self.realmDAO.checkExist(type: GroupModel.DBObject.self, by: group.id)
        // 如果是新的 group, 就去抓此 group 的詳情
        if !isExist {
            self.handleSuccessCreateGroup(group: group)
        }
        
        let action: DataAction = isExist ? .update : .add
        let rlmGroup = RLMGroup.init(with: group)
        if let group = self.realmDAO.immediatelyModel(type: GroupModel.self, id: group.id) {
            if let lastMsg = group.lastMessage {
                rlmGroup.lastMessage = lastMsg.convertToRLMGDBObject()
            }
            rlmGroup.draftContent = group.draft
            rlmGroup.unreadCount = group.unreadCount
            rlmGroup.lastViewedID = group.lastViewedID
        }
        
        if let record = self.realmDAO.immediatelyModel(type: RecordModel.self, id: group.id) {
            rlmGroup.hidden = record.deleteTime >= group.lastMessage?.createAt ?? 0
        }
        
        self.realmDAO.update([rlmGroup], policy: .modified) { [weak self]  in
            //TODO: refactor
            guard let self = self else { return }
            self.sendingGroupObserver(with: GroupModel.init(with: rlmGroup), action: action)
        }
    }
    
    /**
     delete no longer existed group
     */
    func deleteNonExistenceGroup(_ uGroups: [RUserGroups]) {
        if let dbGroups = realmDAO.immediatelyModels(type: GroupModel.self) {
            for group in dbGroups {
                // 不存在的Group
                if !uGroups.contains(where: { $0.id == group.id }) {
                    deleteGroupDBData(groupID: group.id)
                }
            }
        }
    }
    
    /**
    delete group's data, message data, transceiver data
     */
    func deleteGroupDBData(groupID: String, completion: (() -> Void)? = nil) {
        processQueue.async {
            let format = "groupID = '\(groupID)'"
            self.realmDAO.delete(type: RLMGroup.self, by: groupID, completion: completion)
            self.realmDAO.delete(type: RLMTransceiver.self, predicateFormat: format, completion: nil)
            self.realmDAO.delete(type: RLMRecord.self, predicateFormat: format)
            self.realmDAO.delete(type: RLMUserRole.self, predicateFormat: format)
            self.realmDAO.delete(type: RLMPermission.self, predicateFormat: format)
            self.deleteGroupMessages(groupID: groupID)
        }
    }
    
}
