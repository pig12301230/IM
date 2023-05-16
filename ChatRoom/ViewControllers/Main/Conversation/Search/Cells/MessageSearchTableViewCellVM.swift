//
//  MessageSearchTableViewCellVM2.swift
//  ChatRoom
//
//  Created by Saffi Peng on 2021/7/5.
//

import RxCocoa
import RxSwift

class MessageSearchTableViewCellVM: NameTableViewCellVM {

    var disposeBag = DisposeBag()

    let updateName: BehaviorRelay<String> = BehaviorRelay(value: "")
    let updateTime: BehaviorRelay<String> = BehaviorRelay(value: "")
    let attributedMessage: BehaviorRelay<NSAttributedString?> = BehaviorRelay(value: nil)

    private(set) var message: MessageModel!
    private(set) var transceiver: TransceiverModel!

    override init(with type: NameCellType) {
        super.init(with: type)
        self.cellIdentifier = "MessageSearchTableViewCell"
        self.cellType = type

        switch type {
        case .messageRecord(let message, let transceiver):
            self.message = message
            self.transceiver = transceiver
            self.setupByData()
            self.setupCompareString(self.message.message)
        default:
            break
        }
    }

    func setupByData() {
        self.avatarImage.accept(self.transceiver.avatarThumbnail)
        self.updateName.accept(self.transceiver.display)

        self.setupNameMutableAttributedString(with: self.transceiver.display)
        self.setupMessage()

        let date = message.updateAt ?? Date(timeIntervalSince1970: TimeInterval(Double(message.timestamp) / 1000))
        let time = date.messageDateFormat(todayFormat: .symbolTime)
        self.updateTime.accept(time)
    }

    // MARK: - SearchContentProtocol
    override func isFitSearchContent(key: String) -> Bool {
        self.keyString = key

        guard key.count > 0 else {
            // recover color
            self.setupSearchContentColor(key: self.message.message)
            return false
        }

        // 處理字串
        self.setupSearchContentColor(key: key)
        return message.message.contains(key)
    }

    override func setupSearchContentColor(key: String) {
        let attributedString = NSMutableAttributedString(string: self.message.message)
        attributedString.recoverColor(to: Theme.c_10_grand_2.rawValue.toColor())
        attributedString.recoverFont(to: .regularParagraphMediumLeft)

        if key.count > 0 {
            attributedString.setColor(color: Theme.c_01_primary_0_500.rawValue.toColor(), forText: key)
            attributedString.setFont(font: .boldParagraphMediumLeft, forText: key)
        }

        self.attributedMessage.accept(attributedString)
    }
}

// MARK: - PRIVATE functions
private extension MessageSearchTableViewCellVM {
    func setupMessage() {
        self.compareString = self.message.message
        let attributedString = NSMutableAttributedString(string: self.message.message)
        attributedString.recoverColor(to: Theme.c_10_grand_2.rawValue.toColor())
        self.attributedMessage.accept(attributedString)
    }
}
