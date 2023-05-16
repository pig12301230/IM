//
//  DataAccess+contact.swift
//  ChatRoom
//
//  Created by Winston_Chuang on 2023/3/23.
//

import Foundation

extension DataAccess {
    func refreshContactAndBlockedList() {
        refreshContactList()
        refreshBlockedList()
    }

    func refreshContactList() {
        fetchContactsPart()
    }

    func refreshBlockedList() {
        fetchBlockedList()
    }
    
    /*
     取得分享連結
     */
    func fetchShareLink(completion: ((ShareInfoModel?) -> Void)? = nil) {
        ApiClient.getShareLink().subscribe { share in
            completion?(ShareInfoModel.init(with: share))
        } onError: { _ in
            completion?(nil)
        }.disposed(by: self.disposeBag)
    }
}

// MARK: - 好友名單
extension DataAccess {
    func isFriend(with userID: String) -> Bool {
        return self.realmDAO.checkExist(type: RLMContact.self, by: userID)
    }
    /**
     搜索連絡人
     */
    func fetchNewUserContact(_ searchStr: String, completion: ((ContactModel?) -> Void)? = nil) {
        ApiClient.searchNewContact(searchStr: searchStr).subscribe { userInfo in
            completion?(ContactModel(with: RLMContact(with: userInfo, display: nil)))
        } onError: { _ in
            completion?(nil)
        }.disposed(by: disposeBag)
    }
    
    func getContacts(sortedByAZ09: Bool = false, complete: @escaping([ContactModel]) -> Void) {
        realmDAO.getModels(type: ContactModel.self) { contacts in
            guard let contacts = contacts, sortedByAZ09 else {
                DispatchQueue.main.async {
                    complete(contacts ?? [])
                }
                return
            }
            
            let sorted = self.sortListByAtoZ0To9(list: contacts)
            DispatchQueue.main.async {
                complete(sorted)
            }
        }
    }
    
    /*
     解除好友
     */
    func removeContact(contactID: String, completion: ((Bool) -> Void)? = nil) {
        let groupModel = self.realmDAO.immediatelyModels(type: GroupModel.self, predicateFormat: "name contains'\(contactID)'")?.filter({ $0.groupType == .dm
        }).first

        ApiClient.removeContact(contactID: contactID)
            .subscribe(onError: { _ in
                completion?(false)
            }, onCompleted: { [weak self] in
                completion?(true)
                guard let self = self else { return }
                self.refreshContactList()
                guard let gModel = groupModel else { return }
                self.clearGroupMessages(groupID: gModel.id)
            }).disposed(by: disposeBag)
    }

    /**
     新增至好友名單
     */
    func fetchAddUserContact(_ userName: String, takeoverError: Bool = false, completion: ((Bool) -> Void)? = nil) {
        ApiClient.addContact(userName: userName, takeoverError: takeoverError)
            .subscribe(onError: { _ in
                completion?(false)
            }, onCompleted: {
                self.refreshContactList()
                completion?(true)
            }).disposed(by: disposeBag)
    }
    
    // MARK: - auto fetch
    
    func fetchContactsPart() {
        ApiClient.getContactsPart().subscribe { [weak self] contacts in
            guard let self = self else { return }
            self.realmDAO.clearTable(type: RLMContact.self) {
                let dict = self.getUserPersonalSettingDict()
                var rlmObjects = contacts.filter { $0.deleteAt == 0 }
                        .compactMap { RLMContact(with: $0, display: dict[$0.id]?.nickname) }
                guard let userInfo = UserData.shared.userInfo else { return }
                let contactMe = RLMContact(with: userInfo)
                rlmObjects.append(contactMe)
                self.realmDAO.update(rlmObjects) {
                    self.contactListUpdate.onNext(())
                }
            }

            // update each user blocked status at Database transceiver table
            let userIDs = contacts.compactMap { $0.id }
            self.backgroundQueue.async {
                self.updateTransceiversBlockStatus(from: userIDs, to: false)
            }
        } onError: { _ in
            
        }.disposed(by: disposeBag)
    }
}

// MARK: - 黑名單
extension DataAccess {
    func isBlockedUser(with userID: String) -> Bool {
        return self.realmDAO.checkExist(type: RLMBlockedContact.self, by: userID)
    }
    /*
     加入黑名單
     */
    func fetchBlockUser(userID: String, completion: ((Bool) -> Void)? = nil) {
        ApiClient.block(userID: userID).subscribe(onError: { _ in
            completion?(false)
        }, onCompleted: { [weak self] in
            guard let self = self else {
                completion?(false)
                return
            }
            self.refreshContactList()
            self.refreshBlockedList()
            completion?(true)
        })
        .disposed(by: disposeBag)
    }
    
    /*
     解除黑名單
     */
    func fetchUnBlockUser(userID: String, completion: ((Bool) -> Void)? = nil) {
        ApiClient.removeBlock(userID: userID)
            .subscribe(onError: { _ in
                completion?(false)
            }, onCompleted: { [weak self] in
                guard let self = self else {
                    completion?(false)
                    return
                }
                self.refreshContactList()
                self.removeLocalBlockedContact(contactID: userID) {
                    completion?(true)
                }
            }).disposed(by: disposeBag)
    }
    
    func fetchBlockedList() {
        ApiClient.getBlockedList().subscribe { [weak self] (userInfos) in
            guard let self = self else { return }
            self.processQueue.async {
                self.realmDAO.clearTable(type: RLMBlockedContact.self) {
                    let dict = self.getUserPersonalSettingDict()
                    let rlmObjects = userInfos.compactMap { RLMBlockedContact(with: $0, display: dict[$0.id]?.nickname) }
                    self.realmDAO.update(rlmObjects) {
                        self.blockedListUpdate.onNext(())
                    }
                }
            }
            
            let userIDs = userInfos.compactMap { $0.id }
            self.backgroundQueue.async {
                self.updateTransceiversBlockStatus(from: userIDs, to: true)
            }
        } onError: { _ in
            
        }.disposed(by: disposeBag)
    }
    
    /*
     從 database 黑名單中移除
     */
    func removeLocalBlockedContact(contactID: String, completion: (() -> Void)?) {
        let isExist = self.realmDAO.checkExist(type: RLMBlockedContact.self, by: contactID)
        self.realmDAO.delete(type: RLMBlockedContact.self, by: contactID) {
            completion?()
            if isExist {
                self.blockedListUpdate.onNext(())
            }
        }
    }
    
    func getBlockedList(compelete: @escaping ([String: [BlockedContactModel]]) -> Void) {
        self.processQueue.async {
            self.realmDAO.getModels(type: BlockedContactModel.self) { models in
                guard let models = models else {
                    compelete([:])
                    return
                }
                
                let sorted = self.sortDictByAtoZ0To9(list: models)
                DispatchQueue.main.async {
                    compelete(sorted)
                }
            }
        }
    }
    
    func getBlocked(userID: String) -> BlockedContactModel? {
        return self.realmDAO.immediatelyModel(type: BlockedContactModel.self, id: userID)
    }
    
    /**
     update transceiver's blocked status
     - Parameters:
        - userID: transceiver.useID
        - to: blocked status
     */
    private func updateTransceiversBlockStatus(from blockedIDs: [String], to blocked: Bool) {
        for userID in blockedIDs {
            realmDAO.getModels(type: TransceiverModel.self, predicateFormat: "userID = '\(userID)' AND blocked != \(blocked)") { [unowned self] transceivers in
                guard let models = transceivers, models.count > 0 else {
                    return
                }
                
                // only update dmGroup
                for model in models {
                    updateDirectMessageTransceiversBlockStatus(transceiver: model, to: blocked)
                }
            }
        }
    }
    
    private func updateDirectMessageTransceiversBlockStatus(transceiver: TransceiverModel, to blocked: Bool) {
        let dmGroupFormat = "_id = '\(transceiver.groupID)' AND type = \(GroupType.dm.rawValue)"
        if realmDAO.checkExist(type: GroupModel.DBObject.self, predicateFormat: dmGroupFormat) {
            let realmModel = transceiver.convertToDBObject()
            realmModel.blocked = blocked
            realmDAO.update([realmModel], policy: .modified)
        }
    }
}
