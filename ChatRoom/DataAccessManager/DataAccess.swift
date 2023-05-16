//
//  DataAccess.swift
//  ChatRoom
//
//  Created by ZoeLin on 2022/3/3.
//

import Foundation
import RxSwift
import RxCocoa
import RealmSwift
import Kingfisher
import Alamofire

// swiftlint:disable file_length

enum UserAccessStatus {
    case noAccess
    case success
    case invalid
}

enum DataAction {
    case none, add, delete, update
}

class DataAccess {
    struct UserInfo {
        let id: BehaviorRelay<String> = BehaviorRelay(value: "")
        let nickname: BehaviorRelay<String> = BehaviorRelay(value: "")
        let socialAccount: BehaviorRelay<String> = BehaviorRelay(value: "")
        let avatarThumbnail: BehaviorRelay<UIImage?> = BehaviorRelay(value: UIImage.init(named: "avatarsPhoto"))
        let avatar: BehaviorRelay<UIImage?> = BehaviorRelay(value: nil)
        
        mutating func reset() {
            self = UserInfo()
        }
    }
    
    class UploadImageCache {
        var model: MessageModel
        var task: UploadRequest?
        var disposeBag: DisposeBag = DisposeBag()
        var timer: Timer?
        init(_ messageModel: MessageModel) {
            model = messageModel
        }
    }

    class GroupObserver {
        let unread: BehaviorRelay<Int> = BehaviorRelay(value: 0)
        let draftObserver = PublishSubject<MessageModel?>()
        let announcements: BehaviorRelay<[AnnouncementModel]> = BehaviorRelay(value: [])
        let unOpenedHongBao: BehaviorRelay<UnOpenedHongBaoModel?> = .init(value: nil)
        let otherUnread: BehaviorRelay<Int> = BehaviorRelay(value: 0)
        let transceiverDict: BehaviorRelay<[String: TransceiverModel]> = BehaviorRelay(value: [:])
        let groupObserver = PublishRelay<GroupModel>()
        let lastRead: BehaviorRelay<String?> = .init(value: nil)
        let lastViewed: BehaviorRelay<String?> = .init(value: nil)
        let lastEffectiveMessageID: BehaviorRelay<String?> = .init(value: nil)
        let rolePermission: BehaviorRelay<UserRoleModel?> = .init(value: nil)
        let localGroupImagesConfigs: BehaviorRelay<[ImageViewerConfig]> = BehaviorRelay(value: [])
        let fetchUnopendHongBao = PublishSubject<Void>()
        
         func updateTransceiverSettings(with personalSettings: [UserPersonalSettingModel]) {
             let transDictIds = transceiverDict.value.keys
             let groupContainsPerson = personalSettings.filter { transDictIds.contains($0.id) }
             guard !groupContainsPerson.isEmpty else { return }
             
             var dict = transceiverDict.value
             groupContainsPerson.forEach {
                 updateTransceiverNickname($0.id, nickname: $0.nickname, to: &dict)
             }
             transceiverDict.accept(dict)
         }

         private func updateTransceiverNickname(_ id: String, nickname: String?, to dict: inout [String: TransceiverModel]) {
             guard var transceiver = dict[id] else { return }
             transceiver.display = nickname ?? transceiver.nickname
             dict[id] = transceiver
         }
    }
    private(set) var userInfo: UserInfo = UserInfo()
    let sevenDaysAgo: String = Date.init().dateBefore(days: 7).toString(format: Date.Formatter.yearToDay.rawValue)
    let now: String = Date.init().toString(format: Date.Formatter.yearToDay.rawValue)
    
    let lastReadingConversation = BehaviorRelay<String>(value: "")
    let blockedListUpdate = PublishSubject<Void>()
    let contactListUpdate = PublishSubject<Void>()
    let groupListLoadedFinished = PublishSubject<Void>()
    let nicknameUpdateObserver = PublishSubject<String>()
    let memoUpdateObserver = PublishSubject<String>()
    private(set) var userPersonalSetting = BehaviorRelay<[String: UserPersonalSettingModel]>(value: [:])
    let groupListInfoObserver = PublishSubject<(DataAction, GroupModel)>()
    let dismissGroup = PublishSubject<String>()
    
    var totalUnread: Int = 0 {
        didSet {
            unread.accept(totalUnread)
            DispatchQueue.main.async {
                UIApplication.shared.applicationIconBadgeNumber = self.totalUnread
            }
        }
    }    

    let unread: BehaviorRelay<Int> = BehaviorRelay(value: 0)
    
    var uploadCacheDict = [String: UploadImageCache]()
    var groupDataSource = [String: ConversationDataSource]()
    private(set) var groupsRecord: [String: RecordModel] = [:]

    private let groupsObserverQueue = DispatchQueue(label: "com.singleton.groupsobserver.queue")
    private(set) var _groupsObserver: [String: GroupObserver] = [:]
    private(set) var groupsObserver: [String: GroupObserver] {
        get {
            groupsObserverQueue.sync {
                _groupsObserver
            }
        }
        set (newValue) {
            groupsObserverQueue.async(flags: .barrier) {
                self._groupsObserver = newValue
            }
        }
    }
    
    private(set) var disposeBag = DisposeBag()
    let processQueue = DispatchQueue.global(qos: .default)
    // FOR, pre load message, and members, image etc...
    let backgroundQueue = DispatchQueue.global(qos: .background)

    // init all necessary class
    let realmDAO = RealmDAO.init()
    let socket = SocketClient.init()

    static let shared = DataAccess()
    static let conversationPageSize: Int = 200
    
    private init() {
        // socket.delegate implement at DataAccessManager
        // upload cache operate at DataAccessManager
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForegroundNotification), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        NetworkManager.isConnected.subscribeSuccess { isConnected in
            guard isConnected == false else { return }
            self.uploadCacheDict.keys.forEach {
                self.stopUploadTask(modelID: $0)
                self.setupUploadTaskToFailure(modelID: $0)
            }
        }.disposed(by: self.disposeBag)
        
        initBinding()
        resetSendingMessageStatus()
        
    }
    
    private func release() {
        disposeBag = DisposeBag()
        // TODO: invalidate all `Realm NotificationToken`
    }
    
    private func initBinding() {
        userPersonalSetting.subscribeSuccess { [unowned self] dict in
            let observes = groupsObserver.values
            let settings = dict.compactMap {
                $0.1
            }
            observes.forEach {
                $0.updateTransceiverSettings(with: settings)
            }
        }.disposed(by: disposeBag)
    }
    
    @objc private func applicationWillEnterForegroundNotification() {
        // MARK: - 同步進入背景期間的資訊
        self.refreshChatListNeededInformation()
        // TODO: fetch other info of current scene
    }
    
    func initData() {
        initConversationDataSources()
        initUserSettingInfo()
    }

    func initConversationDataSources() {
        realmDAO.getModels(type: GroupModel.self, predicateFormat: "hidden = false") { groups in
            guard let groups = groups else { return }
            groups.forEach {
                let dataSource = ConversationDataSource(group: $0)
                self.groupDataSource[$0.id] = dataSource
            }

            self.groupListLoadedFinished.onNext(())
        }
    }
    
    func getGroupObserver(by groupID: String) -> GroupObserver {
        guard let observer = groupsObserver[groupID] else {
            let observer = GroupObserver.init()
            // setNewGroupObserver
            groupsObserver[groupID] = observer
            fetchDatabaseTransceiverModel(groupID)
            return observer
        }
        
        return observer
    }
    
    func getGroupRecord(by groupID: String) -> RecordModel {
        guard let record = groupsRecord[groupID] else {
            guard let rModel = realmDAO.immediatelyModel(type: RecordModel.self, id: groupID) else {
                let rlmRecord = RLMRecord()
                rlmRecord.groupID = groupID
                let record = RecordModel(with: rlmRecord)
                realmDAO.update([rlmRecord])
                groupsRecord[groupID] = record
                return record
            }
            groupsRecord[groupID] = rModel
            return rModel
        }
        
        return record
    }
    
    func getFile(by fileID: String) -> FileModel? {
        let file = self.realmDAO.immediatelyModel(type: FileModel.self, id: fileID)
        return file
    }
    
    /**
     logout
     */
    func logout() {
        socket.disconnect()
        release()
        UserData.shared.clearData(key: .token)
        UserData.shared.clearData(key: .refreshToken)
        UserData.shared.clearData(key: .expiresIn)
        UserData.shared.clearData(key: .userID)
        userInfo.reset()
        clearAllGroupDataSource()
    }
    
    /**
    更新 group record 的 checked message 資訊
     - Parameters:
       - groupID:
       - messageID: 最新確認過的 message.id
     */
    func updateGroupLastCheckedMessage(_ groupID: String, messageID: String) {
        var record = getGroupRecord(by: groupID)
        guard record.checkedLastMessage < messageID else { return }

        record.checkedLastMessage = messageID
        groupsRecord[groupID] = record
        realmDAO.update([record.convertToDBObject()])
    }
    
    private func fetchDatabaseTransceiverModel(_ groupID: String) {
        realmDAO.getModels(type: TransceiverModel.self, predicateFormat: "groupID = '\(groupID)'") { transceiverList in
            guard let transceiverList = transceiverList else { return }
            self.updateGroupTransceivers(groupID: groupID, transceivers: transceiverList)
        }
    }
    
    func sendingMessageObserver(with model: MessageModel, action: DataAction) {
        guard let newDataSource = self.getGroupConversationDataSource(by: model.groupID) else { return }
        if action == .delete {
            self.deleteMessageHandleGroupImage(groupID: model.groupID, message: model)
            newDataSource.input.deleteMessage.onNext(model)
        } else if action == .add {
            self.addMessageHandleGroupImage(groupID: model.groupID, message: model)
        }
        newDataSource.input.updateMessage.onNext((model, action))
    }
}

// MARK: - General function
extension DataAccess {
    func sortDictByAtoZ0To9<T: DataPotocol>(list: [T]) -> [String: [T]] {
        var alphabetsDict = [String: [T]]()
        var digitsDict = [String: [T]]()
        var othersDict = [String: [T]]()
        for (key, value) in self.getDataPrefixDict(list: list) {
            if key.isAlphabet() {
                alphabetsDict[key] = value
            } else if key.isDigit() {
                digitsDict[key] = value
            } else {
                othersDict[key] = value
            }
        }
        
        let digits = digitsDict.sorted(by: { $0.0 < $1.0 }).reduce(into: [], { $0 += $1.value })
        let others = othersDict.sorted(by: { $0.0 < $1.0 }).reduce(into: [], { $0 += $1.value })
        
        let otherType = digits + others
        if otherType.count > 0 {
            alphabetsDict["#"] = otherType
        }
        
        return alphabetsDict
    }
    
    func sortListByAtoZ0To9<T: DataPotocol>(list: [T]) -> [T] {
        var alphabetsDict = [String: [T]]()
        var digitsDict = [String: [T]]()
        var othersDict = [String: [T]]()
        for (key, value) in self.getDataPrefixDict(list: list) {
            if key.isAlphabet() {
                alphabetsDict[key] = value
            } else if key.isDigit() {
                digitsDict[key] = value
            } else {
                othersDict[key] = value
            }
        }
        
        let alphabets = alphabetsDict.sorted(by: { $0.0.uppercased() < $1.0.uppercased() }).reduce(into: [], { $0 += $1.value })
        let digits = digitsDict.sorted(by: { $0.0 < $1.0 }).reduce(into: [], { $0 += $1.value })
        let others = othersDict.sorted(by: { $0.0 < $1.0 }).reduce(into: [], { $0 += $1.value })
        
        return alphabets + digits + others
    }
    
    private func getDataPrefixDict<T: DataPotocol>(list: [T]) -> [String: [T]] {
        var dict = [String: [T]]()
        for contact in list {
            var prefix = String(contact.display.prefix(1)).uppercased()
            if prefix.isIncludeChinese() {
                prefix = String(prefix.convertChineseToPinYin().prefix(1)).uppercased()
            }
            
            if dict[prefix] == nil {
                dict[prefix] = [contact]
                continue
            }
            dict[prefix]?.append(contact)
        }
        
        return dict
    }
}

// MARK: - Chat list, Conversation
extension DataAccess {
    func fetchChatListNeededInformation() {
        initData()
        // TODO: update draft message.status -> failed and isDraft -> false
        refreshContactAndBlockedList()
        fetchChatList()
    }
    
    func refreshChatListNeededInformation() {
        initUserSettingInfo()
        refreshContactAndBlockedList()
        fetchChatList()
    }
    
    func refetchChatList() {
        initUserSettingInfo()
        fetchChatList()
    }
    
    func fetchChatList() {
        ApiClient.getUserGroupsPart()
            .flatMap { [unowned self] data -> Observable<[(RUserGroupPart, RGroupLastMessage?)]> in
                let parts = (data.dms ?? []) + (data.groups ?? [])
                guard !parts.isEmpty else {
                    return Observable.just([])
                }
                return Observable.zip(parts.map { getGroupLastMessage(part: $0) })
            }
            .flatMap { [unowned self] groupsInfo -> Observable<[RUserGroups]> in
                guard !groupsInfo.isEmpty else {
                    return Observable.just([])
                }
                return Observable.zip(groupsInfo.map { generateGroup(info: $0) })
                    .map { groups -> [RUserGroups] in
                        var newGroups: [RUserGroups]
                        newGroups = groups.compactMap { $0 }
                        return newGroups
                    }
            }
            .subscribe { groups in
                self.parserGroups(groups) {
                    self.groupListLoadedFinished.onNext(())
                }
            }
            .disposed(by: disposeBag)
    }
    
    /**
     取得群組聊天的 group info
     - Paramaters:
        - sortedByAZ09: 是否要按照 A-Z, 0-9 的排序
        - includeHidden: 是否讀取 hidden flag = true 的 GM
        - resetHidden: 是否將 model 的 hidden flag 重設
     */
    func getGroupConversation(sortedByAZ09: Bool = false, includeHidden: Bool = false, resetHidden: Bool = false) -> [GroupModel] {
        var format = String(format: "type = 2")
        format += includeHidden ? "" : " AND hidden = false"
        guard var groupConversation = self.realmDAO.immediatelyModels(type: GroupModel.self, predicateFormat: format) else {
            return []
        }
        
        if resetHidden {
            groupConversation = groupConversation.map {
                var model = $0
                model.hidden = false
                self.resetConversationHiddenStatus(model)
                return model
            }
        }
        
        guard sortedByAZ09 else {
            return groupConversation
        }
        
        return self.sortListByAtoZ0To9(list: groupConversation)
    }
    
    /**
     取得一對一聊天的 group info (打開聊天室, 預設會把 hidden flag reset 為 false)
     - Paramaters:
        - userID: 對象的 userID
        - includeHidden: 是否讀取 hidden flag = true 的 DM
        - resetHidden: 是否將 model 的 hidden flag 重設
     */
    func getDirectConversation(_ userID: String, includeHidden: Bool = false, resetHidden: Bool = true) -> GroupModel? {
        // dm conversation name combine from two user's ID
        var format = String(format: "name CONTAINS '%@' AND type = 1", userID)
        format += includeHidden ? "" : " AND hidden = false"
        guard let directConversation = self.realmDAO.immediatelyModels(type: GroupModel.self, predicateFormat: format), var conversation = directConversation.first else {
            return nil
        }
        
        if resetHidden {
            conversation.hidden = false
            self.resetConversationHiddenStatus(conversation)
        }
        
        return conversation
    }
    
    /**
     取得按照 A-Z(A-Z), 0-9(#) 的排序 群組聊天的 group info Dictionary
     - Paramaters:
        - includeHidden: 是否讀取 hidden flag = true 的 GM
        - resetHidden: 是否將 model 的 hidden flag 重設
     */
    func getGroupConversationsortedByAZ09Dict(includeHidden: Bool = false, resetHidden: Bool = false) -> [String: [GroupModel]] {
        var format = String(format: "type = 2")
        format += includeHidden ? "" : " AND hidden = false"
        guard var groupConversation = self.realmDAO.immediatelyModels(type: GroupModel.self, predicateFormat: format) else {
            return [:]
        }
        
        if resetHidden {
            groupConversation = groupConversation.map {
                var model = $0
                model.hidden = false
                self.resetConversationHiddenStatus(model)
                return model
            }
        }
        
        return self.sortDictByAtoZ0To9(list: groupConversation)
    }
    
    
    func resetConversationHiddenStatus(_ conversationModel: GroupModel) {
        processQueue.async {
            let rlmModel = conversationModel.convertToDBObject()
            rlmModel.hidden = false
            self.realmDAO.update([rlmModel], policy: .modified)
        }
    }
    
    /**
     取得使用者自己與自己的 Direct Message Conversation info
     - Paramaters:
        - id: 使用者 ID
     */
    func getSelfDMConversation(id: String) -> GroupModel? {
        let format = "name = '\(id)_\(id)' AND type = 1"
        return realmDAO.immediatelyModels(type: GroupModel.self, predicateFormat: format)?.first
    }

    func getConversationModelsFromChatList(complete: @escaping ([GroupModel]) -> Void) {
        self.realmDAO.getModels(type: GroupModel.self, predicateFormat: "hidden = false") { result in
            guard let groups = result else {
                DispatchQueue.main.async {
                    complete([])
                }
                return
            }
            
            DispatchQueue.main.async {
                complete(groups)
            }
        }
    }
}

extension DataAccess {
    private func getGroupLastMessage(part: RUserGroupPart) -> Observable<(RUserGroupPart, RGroupLastMessage?)> {
        return Observable.create { [unowned self] observer -> Disposable in
            if let group = self.getGroup(groupID: part.id), group.timestamp == part.updateAt {
                observer.onNext((part, nil))
                observer.onCompleted()
            } else {
                ApiClient.getGroupLastMessage(groupID: part.id)
                    .subscribe { [weak self] lastMsg in
                        guard let self = self, let lastMsg = lastMsg else {
                            observer.onNext((part, nil))
                            observer.onCompleted()
                            return
                        }
                        let id = TransceiverModel.uniqueID(part.id, lastMsg.lastMessage.userID)
                        if !self.realmDAO.checkExist(type: RLMTransceiver.self, by: id) && part.type == .group {
                            self.fetchGroupMembers(groupID: part.id, memberIDs: [lastMsg.lastMessage.userID])
                        }
                        observer.onNext((part, lastMsg))
                        observer.onCompleted()
                    } onError: { _ in
                        observer.onNext((part, nil))
                        observer.onCompleted()
                    }.disposed(by: self.disposeBag)
            }
            return Disposables.create()
        }
    }
    
    /**
     compare all groups' hidden status, stay hidden or show at chat list
     - returns: all visible group
     */
    func getVisiblyAndCompareGroupsStatus(_ uGroups: [RUserGroups]) -> [RLMGroup] {
        let hiddenList: [String] = realmDAO.immediatelyModels(type: GroupModel.self, predicateFormat: "hidden = true")?.compactMap { $0.id } ?? []
        
        let records: [RecordModel] = realmDAO.immediatelyModels(type: RecordModel.self) ?? []
        var visibleGroups = [RLMGroup]()
        var hiddenGroups = [RLMGroup]()
        
        // clear record before setup
        groupsRecord.removeAll()
        uGroups.forEach { group in
            // hidden == true, 但有更新的訊息進來時, hidden ( true -> false) AND Show on chat list
            if hiddenList.contains(group.id) {
                if let record = records.first(where: { $0.groupID == group.id }), record.deleteTime == 0 {
                    let rlm = RLMGroup.init(with: group)
                    rlm.hidden = false
                    rlm.latestSyncTimestamp = record.deleteTime
                    visibleGroups.append(rlm)
                } else {
                    let rlm = RLMGroup.init(with: group)
                    rlm.hidden = true
                    rlm.lastMessage = nil
                    hiddenGroups.append(rlm)
                }
            } else {
                visibleGroups.append(RLMGroup.init(with: group))
            }
        }
        
        if !hiddenGroups.isEmpty {
            // update hidden groups
            realmDAO.update(hiddenGroups, policy: .modified)
        }
        
        return visibleGroups
    }
}

// swiftlint:enable file_length
