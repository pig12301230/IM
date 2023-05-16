//
//  TextMessageCellVM.swift
//  ChatRoom
//
//  Created by Saffi Peng on 2021/7/19.
//

import Foundation
import RxSwift
import RxCocoa

class TextMessageCellVM: MessageBaseCellVM {

    let attributedMessage: BehaviorRelay<NSAttributedString> = BehaviorRelay(value: NSAttributedString(string: ""))

    let textHeight: BehaviorRelay<CGFloat> = BehaviorRelay(value: 40)

    override init(model: MessageBaseModel, withRead: Bool) {
        super.init(model: model, withRead: withRead)
        self.cellIdentifier = (model.config.sender == .me ? "TextMessageRCell" : "TextMessageLCell")

        self.adjustTextHeight(with: model.message.message)
        self.config.accept(model.config)
        self.updateView(model: model)
        let attrMessage = self.setupMessage(key: "")
        self.attributedMessage.accept(attrMessage)
    }

    // MARK: - MessageContentCellProtocol
    override func updateMessageStatus(_ status: MessageStatus) {
        super.updateMessageStatus(status)

        var newConfig = self.baseModel.config
        newConfig.isFailure = status == .failed
        self.config.accept(newConfig)
    }

    override func updateReadStatus(_ read: Bool) {
        super.updateReadStatus(read)
        self.isRead.accept(read)
    }
    
    func adjustTextHeight(with text: String) {
        let maxSize = CGSize(width: (MessageContentSize.maxWidth - MessageContentSize.horizontalMargin), height: 3000)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 1.0
        let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.regularParagraphLargeLeft, .paragraphStyle: paragraphStyle]
        let textSize = text.size(attributes: attributes, maxSize: maxSize)
        // fix: 訊息為多行文字時，最後一行文字會消失的情況 (16: 訊息font size)
        let fittedHeight = max(textSize.height + 16, 40)

        self.textHeight.accept(fittedHeight)
    }
}

// MARK: - SearchContentProtocol
extension TextMessageCellVM: SearchContentProtocol {
    func isFitSearchContent(key: String) -> Bool {
        self.keyString = key

        guard key.count > 0 else {
            // recover color
            self.setupSearchContentColor(key: key)
            return false
        }
        // 處理字串
        self.setupSearchContentColor(key: key)
        return self.baseModel.message.message.contains(key)
    }

    func setupSearchContentColor(key: String) {
        let attrString = setupMessage(key: key)
        self.attributedMessage.accept(attrString)
    }

    func setupCompareString(_ compare: String) {

    }
}

// MARK: - setup content functions
extension TextMessageCellVM {
    func setupMessage(key: String) -> NSMutableAttributedString {
        self.compareString = self.baseModel.message.message
        
        let attributedString = NSMutableAttributedString(string: self.baseModel.message.message )
        attributedString.recoverColor(to: Theme.c_10_grand_1.rawValue.toColor())
        attributedString.recoverFont(to: .regularParagraphLargeLeft)
        attributedString.recoverBackgroundColor(to: Theme.transparent.rawValue.toColor())

        // 設置Link Style
        if let ranges = self.baseModel.message.message.checkContainLink(), !ranges.isEmpty {
            self.setupLink(attrString: attributedString, ranges: ranges)
        }

        // 設置Highlight Style
        if key.count > 0 {
            self.setupHighlight(attrString: attributedString, key: key)
        }

        return attributedString
    }

    func setupLink(attrString: NSMutableAttributedString, ranges: [String.TapableString]) {
        _ = ranges.compactMap {
            attrString.setColor(color: Theme.c_03_tertiary_0_500.rawValue.toColor(), range: $0.range)
            attrString.setFont(font: .regularParagraphLargeLeft, for: $0.range)
            attrString.setUnderLine(style: .single, for: $0.range)
            attrString.setLink(url: $0.url, for: $0.range)
        }
    }

    func setupHighlight(attrString: NSMutableAttributedString, key: String) {
        attrString.setColor(color: Theme.c_08_black.rawValue.toColor(), forText: key)
        attrString.setFont(font: .boldParagraphLargeLeft, forText: key)
        attrString.setBackgroundColor(color: Theme.c_05_warning_300.rawValue.toColor(), forText: key)
    }
}
