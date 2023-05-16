//
//  NameTableViewCellVM.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/5/3.
//

import UIKit
import RxSwift
import RxCocoa

protocol SearchContentProtocol {
    func isFitSearchContent(key: String) -> Bool
    func setupSearchContentColor(key: String)
    func setupCompareString(_ compare: String)
    var compareString: String { get set }
    var keyString: String { get set }
}

protocol CellTypeProtocol {
    var cellType: NameCellType { get set }
}

enum NameCellType {
    // 好友
    case contact(contact: ContactModel)
    // 好友詳情
    case contactDetail(contact: ContactModel)
    // 群組
    case group(group: GroupModel)
    case groupDetail(group: GroupModel)
    // 單一則訊息
    case message(message: MessageModel, transceiver: TransceiverModel)
    // 聊天記錄
    case record(group: GroupModel)
    // 訊息紀錄
    case messageRecord(message: MessageModel, transceiver: TransceiverModel)
    // 黑名單
    case blocked(blocked: BlockedContactModel)
    
    var data: DataPotocol {
        switch self {
        case .contact(contact: let contact), .contactDetail(contact: let contact):
            return contact
        case .blocked(blocked: let blocked):
            return blocked
        case .group(group: let group), .groupDetail(group: let group):
            return group
        case .message(message: let message, transceiver: _):
            return message
        case .record(group: let group):
            return group
        case .messageRecord(message: let message, _):
            return message
        }
    }
    
    var primaryKey: String {
        self.data.id
    }
    
    var updateAt: Int {
        switch self {
        case .record(group: let group):
            return group.lastMessage?.timestamp ?? group.timestamp
        default:
            return self.data.timestamp
        }
    }
    
    var iconThumbnail: String {
        switch self {
        case .contact(contact: let contact), .contactDetail(contact: let contact):
            return contact.iconThumbnail
        case .blocked(blocked: let blocked):
            return blocked.iconThumbnail
        case .group(group: let group), .groupDetail(group: let group), .record(group: let group):
            return group.iconThumbnail
        case .message(message: _, transceiver: let transceiver), .messageRecord( _, transceiver: let transceiver):
            return transceiver.avatarThumbnail
        }
    }
}

class NameTableViewCellVM: BaseTableViewCellVM, CellTypeProtocol, SearchContentProtocol {
    
    let attributedName: BehaviorRelay<NSAttributedString?> = BehaviorRelay(value: nil)
    let avatarImage: BehaviorRelay<String?> = BehaviorRelay(value: nil)
    let countString: BehaviorRelay<String> = BehaviorRelay(value: "")
    
    private(set) var nameMutableAttributedString: NSMutableAttributedString = NSMutableAttributedString.init(string: "")
    var compareString: String
    var keyString: String
    
    var pramryKey: String {
        return cellType.primaryKey
    }
    
    var updateAt: Int {
        return cellType.updateAt
    }
    
    let cellTypeQueue = DispatchQueue.init(label: "com.chat.list.cell.type.queue")
    var _cellType: NameCellType
    var cellType: NameCellType {
        get {
            return cellTypeQueue.sync {
                _cellType
            }
        }
        set {
            cellTypeQueue.async(flags: .barrier) {
                self._cellType = newValue
            }
        }
    }
    
    init(with type: NameCellType) {
        _cellType = type
        self.keyString = ""
        self.compareString = ""
        super.init()
        self.cellIdentifier = "NameTableViewCell"
        
        switch type {
        case .contact, .contactDetail, .blocked:
            self.setupCompareString(type.data.display)
            self.avatarImage.accept(type.iconThumbnail)
        case .group(group: let group), .groupDetail(group: let group):
            self.countString.accept(String(format: "(%ld)", group.memberCount))
            self.setupCompareString(type.data.display)
            self.avatarImage.accept(type.iconThumbnail)
        case .message(message: let message, transceiver: let transceiver):
            self.setupCompareString(message.display)
            self.attributedName.accept(NSAttributedString.init(string: transceiver.display))
            self.avatarImage.accept(transceiver.avatarThumbnail)
        default:
            break
        }
    }
    
    func setupNameMutableAttributedString(with message: String?) {
        guard let message = message else {
            return
        }
        
        self.nameMutableAttributedString = NSMutableAttributedString.init(string: message)
        self.nameMutableAttributedString.recoverColor(to: Theme.c_10_grand_1.rawValue.toColor())
        self.attributedName.accept(self.nameMutableAttributedString)
    }
    
    // MARK: - protpcol
    func isFitSearchContent(key: String) -> Bool {
        self.keyString = key
        self.setupSearchContentColor(key: key)
        return self.compareString.localizedCaseInsensitiveContains(key)
    }
    
    func setupSearchContentColor(key: String) {
        self.nameMutableAttributedString.recoverColor(to: Theme.c_10_grand_1.rawValue.toColor())
        if key.count > 0 {
            self.nameMutableAttributedString.setColorToAllRange(color: Theme.c_01_primary_0_500.rawValue.toColor(), forText: key)
        }
        
        self.attributedName.accept(self.nameMutableAttributedString)
    }
    
    func setupCompareString(_ compare: String) {
        self.compareString = compare
        self.setupNameMutableAttributedString(with: self.compareString)
    }
    
    func updateGroupMemberCount(_ memberCount: Int) {
        self.countString.accept(String(format: "(%ld)", memberCount))
    }
}

extension NameTableViewCellVM: Hashable {
    static func == (lhs: NameTableViewCellVM, rhs: NameTableViewCellVM) -> Bool {
        return lhs.updateAt == rhs.updateAt && lhs.pramryKey == rhs.pramryKey
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.pramryKey)
    }
}
