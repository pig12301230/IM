//
//  RecordTableViewCellVM.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/5/3.
//

import RxCocoa
import RxSwift

protocol RecordCellProtocol {
    var matchResult: [MessageModel] { get set }
    var transceivers: [String: TransceiverModel] { get set }
}

class RecordTableViewCellVM: NameTableViewCellVM, RecordCellProtocol {
    
    let attributedMessage: BehaviorRelay<NSAttributedString?> = BehaviorRelay(value: nil)
    private(set) var messageMutableAttributedString: NSMutableAttributedString = NSMutableAttributedString.init(string: "")
    var disposeBag = DisposeBag()
    // RecordCellProtocol
    var matchResult: [MessageModel] = []
    var transceivers: [String: TransceiverModel] = [:]
    private var lastMessage: MessageModel?
    
    override init(with type: NameCellType) {
        super.init(with: type)
        self.cellIdentifier = "RecordTableViewCell"
        switch type {
        case .record(group: let group):
            self.transceivers = DataAccess.shared.getGroupObserver(by: group.id).transceiverDict.value
            self.lastMessage = group.lastMessage
            self.initBinding(group)
            self.setupCompareString(group.display)
            guard transceivers.count > 0 else { return }
            self.setupByData(group)
        default:
            break
        }
    }
    
    func initBinding(_ group: GroupModel) {
        let groupObserver = DataAccess.shared.getGroupObserver(by: group.id)
        
        groupObserver.lastEffectiveMessageID
            .observe(on: MainScheduler.instance)
            .filter { _ in group.draft.isEmpty }
            .subscribeSuccess { [weak self] id in
                guard let self = self else { return }
                guard let id = id else { return }
                DataAccess.shared.getMessage(messageID: id) { message in
                    self.lastMessage = message
                    self.setMessage(message: self.lastMessage ?? group.lastMessage, type: group.groupType)
                }
            }.disposed(by: disposeBag)
        
        groupObserver.transceiverDict
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribeSuccess { [weak self] transceiverDict in
                guard let self = self else { return }
                self.transceivers = transceiverDict
                if case .record(group: let groupModel) = self.cellType, self.transceivers.count > 0 {
                    self.setupByData(groupModel)
                }
            }.disposed(by: disposeBag)
        
        DataAccess.shared.nicknameUpdateObserver
            .subscribeSuccess { [weak self] memberID in
                guard let self = self else { return }
                guard self.transceivers[memberID] != nil else { return }
                self.updateTransceiverNickname(by: memberID)
                if case .record(group: let groupModel) = self.cellType {
                    self.setupByData(groupModel)
                }
            }.disposed(by: disposeBag)
    }
    
    func updateTransceiverNickname(by memberID: String) {
        guard let model = DataAccess.shared.getUserPersonalSetting(with: memberID),
              let nickname = model.nickname else {
           return
        }
        transceivers[memberID]?.display = nickname
    }
    
    func setupByData(_ data: GroupModel) {
        self.cellType = .record(group: data)
        if data.groupType == .dm {
            var displayName = data.display
            let selfUserID = UserData.shared.userID ?? ""
            let selfKey = selfUserID + "_" + selfUserID
            if data.name == selfKey, let selfTrans = self.transceivers.values.first(where: { $0.userID == selfUserID }) {
                displayName = selfTrans.display
                self.avatarImage.accept(selfTrans.avatarThumbnail)
            } else if let otherTrans = self.transceivers.values.first(where: { $0.userID != selfUserID }) {
                displayName = getTransceiverPersonalName(memberID: otherTrans.userID) ?? otherTrans.display
                self.avatarImage.accept(otherTrans.avatarThumbnail)
            }
            self.setupNameMutableAttributedString(with: displayName)
        } else {
            // TODO: update member count if someone leave?
            self.countString.accept(String(format: "(%ld)", data.memberCount))
            self.setupNameMutableAttributedString(with: data.display)
            self.avatarImage.accept(data.iconThumbnail)
        }
        
        guard data.draft.isEmpty else { return }
        self.setMessage(message: self.lastMessage ?? data.lastMessage, type: data.groupType)
    }
    
    private func setMessage(message: MessageModel?, type: GroupType) {
        guard let message = message else {
            self.setupMessage("")
            return
        }
        
        guard message.messageType == .image || message.messageType == .text || message.messageType == .recommend || message.messageType == .hongBao else {
            // 狀態訊息
            let statusString = message.messageType.getGroupStatus(allUser: transceivers, messageModel: message)
            self.setupMessage(statusString)
            return
        }
        
        var prefix: String = ""
        
        if type == .group {
            if message.userID == UserData.shared.userID {
                prefix = UserData.shared.userInfo?.nickname ?? ""
            } else if let display = self.transceivers[message.userID]?.display {
                prefix = display
            } else {
                // 若 transceivers 找不到 message.userID, 重新抓一次 group member
                DataAccess.shared.fetchGroupMemberAndUpdate(groupID: message.groupID, memberID: message.userID) { [weak self] in
                    guard let self = self else { return }
                    self.transceivers = DataAccess.shared.getGroupObserver(by: message.groupID).transceiverDict.value
                    self.setMessage(message: message, type: type)
                }
                return
            }
            prefix += ": "
        }
        
        var messageString = message.message
        if message.messageType == .image {
            messageString = Localizable.picture
        } else if message.messageType == .recommend {
            messageString = Localizable.followPro
        } else if message.messageType == .hongBao {
            messageString = Localizable.redEnvelopeMessage
        }
        self.setupMessage(prefix + messageString)
    }
    
    // MARK: - protocol
    override func isFitSearchContent(key: String) -> Bool {
        self.keyString = key
        self.matchResult.removeAll()
        
        guard !key.isEmpty else {
            // recover color
            setupSearchContentColor(key: key, message: self.compareString)
            return true
        }

        matchResult = DataAccess.shared.searchDatabaseMessages(by: key, at: pramryKey)
        let resultCount = matchResult.count
        guard resultCount > 0 else { return false }
        guard resultCount > 1 else {
            // 處理字串
            setupSearchContentColor(key: key, message: matchResult.first?.message ?? self.compareString)
            return true
        }
        
        let str = String(format: Localizable.aboutMessageRecord, "\(resultCount)")
        PRINT("count string == \(str)")
        setupSearchContentColor(key: "", message: str)
        return true
    }
    
    override func setupSearchContentColor(key: String) {
        self.messageMutableAttributedString.recoverColor(to: Theme.c_10_grand_2.rawValue.toColor())
        
        if key.count > 0 {
            self.messageMutableAttributedString.setColorToAllRange(color: Theme.c_01_primary_0_500.rawValue.toColor(), forText: key)
        }
        
        self.attributedMessage.accept(self.messageMutableAttributedString)
    }
    
    func setupSearchContentColor(key: String, message: String) {
        self.messageMutableAttributedString = NSMutableAttributedString.init(string: message)
        self.setupSearchContentColor(key: key)
    }
    
    private func getTransceiverPersonalName(memberID: String) -> String? {
        DataAccess.shared.getUserPersonalSetting(with: memberID)?.nickname
    }
}

private extension RecordTableViewCellVM {
    
    func setupMessage(_ message: String) {
        let newMessageSplits = message.split(separator: "\n")
        var newMessage: String
        if let first = newMessageSplits.first {
            newMessage = String(first)
            if newMessageSplits.count > 1 {
                newMessage += "...\n"
            }
        } else {
            newMessage = message
        }
        
        self.compareString = newMessage
        guard keyString.isEmpty else { return }
        
        self.messageMutableAttributedString = NSMutableAttributedString.init(string: newMessage)
        self.messageMutableAttributedString.recoverColor(to: Theme.c_10_grand_2.rawValue.toColor())
        self.attributedMessage.accept(self.messageMutableAttributedString)
    }
}
