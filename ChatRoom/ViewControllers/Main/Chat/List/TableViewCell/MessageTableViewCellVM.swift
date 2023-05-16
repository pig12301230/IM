//
//  MessageTableViewCellVM.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/5/27.
//

import Foundation
import RxCocoa

class MessageTableViewCellVM: NameTableViewCellVM {
    
    let attributedMessage: BehaviorRelay<NSAttributedString?> = BehaviorRelay(value: nil)
    private(set) var messageMutableAttributedString: NSMutableAttributedString = NSMutableAttributedString.init(string: "")
    
    override init(with type: NameCellType) {
        super.init(with: type)
        self.cellIdentifier = "MessageTableViewCell"
    }
    
    override func setupCompareString(_ compare: String) {
        super.setupCompareString(compare)
        self.setupMessage(compare)
    }
    
    override func setupSearchContentColor(key: String) {
        self.messageMutableAttributedString.recoverColor(to: Theme.c_10_grand_1.rawValue.toColor())
        if key.count > 0 {
            self.messageMutableAttributedString.setColorToAllRange(color: Theme.c_01_primary_0_500.rawValue.toColor(), forText: key)
        }
        
        self.attributedMessage.accept(self.messageMutableAttributedString)
    }
    
    private func setupMessage(_ message: String) {
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
        
        self.messageMutableAttributedString = NSMutableAttributedString.init(string: newMessage)
        self.messageMutableAttributedString.recoverColor(to: Theme.c_10_grand_2.rawValue.toColor())
        self.attributedMessage.accept(self.messageMutableAttributedString)
    }
}
