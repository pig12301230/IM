//
//  DataAccess+socket.swift
//  ChatRoom
//
//  Created by Winston_Chuang on 2023/3/27.
//

import Foundation

// MARK: - Socket Delegate
extension DataAccess: SocketClientDelegate {
    
    /**
     When one of user read the message in group, the user who send the message will receive
     */
    func groupRead(with info: RSocketReadInfo) {
        guard var group = self.realmDAO.immediatelyModel(type: GroupModel.self, id: info.groupID) else {
            return
        }
                
        group.lastReadID = info.lastRead

        let rlmObject = group.convertToDBObject()
        self.realmDAO.update([rlmObject], policy: .modified) {
            self.sendingGroupObserver(with: group, action: .update)
            let observer = self.getGroupObserver(by: group.id)
            observer.unread.accept(group.unreadCount)
            observer.lastRead.accept(info.lastRead)
        }
    }
    
    /**
     When user itself get add to group
     */
    func groupAdd(with info: RSocketInfo) {
        self.fetchGroup(by: info.groupID)
    }
    
    /**
     When user itself get remove from group
     被踢出群族 or 自行離開
     */
    func groupLeft(with info: RSocketInfo) {
        self.dismissGroup.onNext(info.groupID)
        self.realmDAO.delete(type: RLMGroup.self, by: info.groupID)
        
        let format = String(format: "groupID = '%@'", info.groupID)
        
        // 刪除 group transceivers
        self.realmDAO.delete(type: RLMTransceiver.self, predicateFormat: format) {
            PRINT("delete group Transceivers success", cate: .database)
        }
        
        // 刪除 group message
        self.realmDAO.delete(type: RLMMessage.self, predicateFormat: format) {
            PRINT("delete group Messages success", cate: .database)
        }
    }
    
    /**
     When one of user change the group display name
     */
    func groupDisplay(with info: RSocketGroupDisplay) {
        self.realmDAO.getModel(type: GroupModel.self, id: info.groupID) { [unowned self] model in
            guard var model = model else {
                return
            }
            
            model.display = info.displayName
            let rlm = model.convertToDBObject()
            self.realmDAO.update([rlm], policy: .modified)
            self.sendingGroupObserver(with: model, action: .update)
        }
    }
    
    /**
     When one of user change the group icon
     */
    func groupIcon(with info: RSocketGroupIcon) {
        self.realmDAO.getModel(type: GroupModel.self, id: info.groupID) { [unowned self] model in
            guard var model = model else {
                return
            }
            
            model.icon = info.icon
            model.iconThumbnail = info.iconThumbnail
            let rlm = model.convertToDBObject()
            self.realmDAO.update([rlm], policy: .modified)
            self.sendingGroupObserver(with: model, action: .update)
        }
    }
    
    /**
     When user get add to group
     */
    func memberAdd(with info: RSocketInfo) {
        let transceiverKey = TransceiverModel.uniqueID(info.groupID, info.userID)
        self.fetchGroup(by: info.groupID)
        guard !realmDAO.checkExist(type: RLMTransceiver.self, by: transceiverKey) else {
            // 更改已存在的 transceiver isMember flag
            updateGroupTransceiver(transceiverID: transceiverKey, isMember: true, atGroup: info.groupID)
            return
        }

        // fetch group's transceiver from server
        self.fetchGroupMembers(groupID: info.groupID, memberIDs: [info.userID])
    }
    
    /**
     When user get remove from group
     */
    func memberLeft(with info: RSocketInfo) {
        let transceiverKey = TransceiverModel.uniqueID(info.groupID, info.userID)
        updateGroupTransceiver(transceiverID: transceiverKey, isMember: false, atGroup: info.groupID)
        self.fetchGroup(by: info.groupID)
    }
    
    func message(with message: RMessage) {
        let rlmMessage = RLMMessage.init(with: message)
        let messageModel = MessageModel.init(with: rlmMessage)
        
        if let targetID = messageModel.targetMessage {
            if !self.realmDAO.checkExist(type: RLMMessage.self, by: targetID) {
                // fetch group specific Message
                if message.type == .unsend {
                    processQueue.async {
                        self.receiveMessage(message)
                    }
                } else {
                    fetchGroupMessageAndUpdate(groupID: message.groupID, messageID: targetID) {
                        self.processQueue.async {
                            self.receiveMessage(message)
                        }
                    }
                }
                // will DO receive message after fetch target message
                return
            } else if message.type == .unsend {
                // 若是撤回訊息的targetID存在, 要刪除local資料
                processQueue.async {
                    self.receiveMessage(message)
                    self.deleteMessageInDatabase(by: targetID)
                }
                return
            }
        } else if let targetID = messageModel.targetUser {
            let transceiverKey = TransceiverModel.uniqueID(message.groupID, targetID)
            if !self.realmDAO.checkExist(type: RLMTransceiver.self, by: transceiverKey) {
                // fetch target user information
                self.fetchGroupMemberAndUpdate(groupID: message.groupID, memberID: targetID) { [weak self] in
                    guard let self = self else { return }
                    self.processQueue.async {
                        self.receiveMessage(message)
                    }
                }
                // will DO receive message after fetch target user
                return
            }
        }
        
        processQueue.async {
            self.receiveMessage(message)
        }
    }
    
    /**
     When one of user change the group permission ( only member role )
     */
    func groupPermission(with group: RSocketGroup) {
        // fetch group detail, and update permission to database
        self.fetchGroup(by: group.groupID)
    }
    
    /**
     When group pins added or deleted
     */
    func groupPins(with info: RSocketGroupMessage) {
        // fetch group pins, and update to database
        self.getGroupPins(groupID: info.groupID)
    }
    
    /**
    When messages has been unsend
    */
    func messageDelete(with info: RSocketGroupMessage) {
        guard let messageModel = self.realmDAO.immediatelyModel(type: MessageModel.self, id: info.messageID) else { return }

        self.removeDatabaseMessage(model: messageModel) {
            self.sendingMessageObserver(with: messageModel, action: .delete)
        }
    }
    
    /**
    When receive HongBao opened
    */
    func receiveHongBao(with info: RSocketHongBaoClaim) {
        // 更新未領取的紅包數量
        if info.hongBaoContent.amount == 0 || info.hongBaoContent.recipient == UserData.shared.userID {
            let observer = self.getGroupObserver(by: info.groupID)
            observer.fetchUnopendHongBao.onNext(())
        }
    }
}

// MARK: - Handle response data
extension DataAccess {
    func checkLocalDeleteAndUpdate(message: RMessage) -> RLMMessage {
        let message = RLMMessage(with: message)
        // 檢查此訊息是否被本地刪除
        if let dbMessage = self.realmDAO.immediatelyModel(type: MessageModel.self, id: message._id) {
            message.deleted = dbMessage.deleted
        }
        // 檢查此訊息的是否有ThreadMessage及有無被本地刪除
        if let threadID = message.threadID,
           let dbThread = self.realmDAO.immediatelyModel(type: MessageModel.self, id: threadID) {
            message.threadMessage?.deleted = dbThread.deleted
        }
        
        return message
    }
}

private extension DataAccess {
    func receiveMessage(_ message: RMessage) {
        // check transceiver
        let transceiverKey = TransceiverModel.uniqueID(message.groupID, message.userID)
        if !self.realmDAO.checkExist(type: RLMTransceiver.self, by: transceiverKey) {
            // fetch target user information
            self.fetchGroupMemberAndUpdate(groupID: message.groupID, memberID: message.userID) { [weak self] in
                guard let self = self else { return }
                self.processQueue.async {
                    self.receiveMessage(message)
                }
            }
            return
        }
        
        var format: String
        if message.cid.isEmpty {
            format = "_id = '\(message.id)'"
        } else {
            format = "cid = '\(message.cid)'"
        }
        
        // 檢查是否需要更新 EmojiFile
        
        let shouldUpdateEmojiFile = self.shouldUpdateEmojiFile(rMessage: message)
        if shouldUpdateEmojiFile {
            self.updateEmojiFile(rmessage: message)
        }
        
        // 更新會領取紅包數量狀態
        if message.type == .hongBao {
            self.getGroupObserver(by: message.groupID).fetchUnopendHongBao.onNext(())
        }
        
        //檢查DB是否已有存在訊息
        guard !self.realmDAO.checkExist(type: MessageModel.DBObject.self, predicateFormat: format) else {
            let rlmMessage = checkLocalDeleteAndUpdate(message: message)
            self.sendingMessageObserver(with: MessageModel.init(with: rlmMessage), action: .update)
            self.realmDAO.update([rlmMessage])
            return
        }
        //檢查草稿訊息是否有存在訊息
        //處理socket event 比API早回傳的狀況
        guard !self.realmDAO.checkExist(type: RLMDraftMessage.self, predicateFormat: format) else {
            let rlmMessage = RLMMessage.init(with: message)
            self.sendingMessageObserver(with: MessageModel.init(with: rlmMessage), action: .update)
            self.realmDAO.update([rlmMessage])
            return
        }
        
        self.realmDAO.getModel(type: RecordModel.self, id: message.groupID) { record in
            guard let record = record else {
                // database 中沒有這筆資料, 且沒有刪除過 group 的紀錄時直接存至 databsase
                self.saveMessage(message: message)
                return
            }
            
            // 如果收到的訊息 create time 在 delete time 之前, 就不儲存至 database
            if message.createAt > record.deleteTime {
                self.saveMessage(message: message)
            }
        }
    }
}
