//
//  MessageTextView.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/5/31.
//

import UIKit

class MessageTextView: UITextView {

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)

        self.setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        self.backgroundColor = .clear
        self.font = .regularParagraphLargeLeft
        self.theme_textColor = Theme.c_10_grand_1.rawValue
        self.textAlignment = .left
        self.isScrollEnabled = false
        self.isEditable = false
        self.textContainer.lineFragmentPadding = 0
        self.textContainer.lineBreakMode = .byCharWrapping
        self.setLineSpacing(0.0, lineHeightMultiple: 1.0)
    }
    
    override var canBecomeFirstResponder: Bool {
        return false
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        // 點擊 URL才會外開瀏覽器
        guard super.point(inside: point, with: event) else { return false }
        let startIndex = layoutManager.characterIndex(for: point, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        guard startIndex < self.attributedText.length - 1 else { return false }
        
        return attributedText.attribute(.link, at: startIndex, effectiveRange: nil) != nil
    }
}
