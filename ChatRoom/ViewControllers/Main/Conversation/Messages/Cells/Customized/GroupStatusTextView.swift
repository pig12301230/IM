//
//  GroupStatusTextView.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/6/29.
//

import UIKit

class GroupStatusTextView: UITextView {

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)

        self.setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        self.theme_backgroundColor = Theme.c_07_neutral_900_10.rawValue
        self.font = .midiumParagraphSmallLeft
        self.theme_textColor = Theme.c_10_grand_2.rawValue
        self.textAlignment = .center
        self.isScrollEnabled = false
        self.isEditable = false
        self.textContainerInset = UIEdgeInsets(top: 3, left: 12, bottom: 3, right: 12)
        self.textContainer.lineFragmentPadding = 0
        self.textContainer.lineBreakMode = .byTruncatingTail
        self.textContainer.maximumNumberOfLines = 1
        self.layer.cornerRadius = 12
    }
}
