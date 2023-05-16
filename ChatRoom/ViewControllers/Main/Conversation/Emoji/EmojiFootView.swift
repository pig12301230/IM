//
//  EmojiFootView.swift
//  ChatRoom
//
//  Created by ERay_Peng on 2022/11/22.
//

import Foundation
import RxSwift

class EmojiFootView: UIView {
    private lazy var stackView: UIStackView = {
        let sView = UIStackView()
        sView.axis = .horizontal
        sView.distribution = .fill
        return sView
    }()
    
    private lazy var lblCount: UILabel = {
        let lbl = UILabel()
        lbl.font = .boldParagraphSmallLeft
        lbl.textAlignment = .center
        lbl.lineBreakMode = .byCharWrapping
        return lbl
    }()
    
    func config(emojiContentModel: EmojiContentModel, type: GroupType) {
        guard emojiContentModel.totalCount > 0 else { return }
        self.layer.cornerRadius = 12
        self.theme_backgroundColor = Theme.c_09_white.rawValue
        
        self.addSubview(stackView)
        
        stackView.snp.makeConstraints { make in
            make.leading.top.bottom.trailing.equalToSuperview().inset(4)
        }
        
        self.stackView.spacing = type == .dm ? 3 : -3
        self.stackView.removeAllArrangedSubviews()
        let totalCount = emojiContentModel.getTotalEmojiCount()
        self.lblCount.text = String(totalCount)
        self.lblCount.isHidden = type != .group
        var validEmojiContents = emojiContentModel.emojiArray.sorted(by: { $0.count > $1.count })
        validEmojiContents = Array(validEmojiContents.filter({ $0.count > 0 }).prefix(2))
        
        var emojiTypes: [EmojiType] = []
        if type == .dm, validEmojiContents.count == 1, let emoji = validEmojiContents.first, emoji.count > 1 {
            validEmojiContents.append(emoji)
        }
        emojiTypes = validEmojiContents.sorted(by: { $0.count > $1.count }).compactMap({ EmojiType($0.emoji_name) })

        for emojiType in emojiTypes {
            let image = UIImage(named: emojiType.imageName)
            let imageView: UIImageView = UIImageView(image: image)
            imageView.snp.makeConstraints { make in
                make.width.height.equalTo(16)
            }
            self.stackView.addArrangedSubview(imageView)
        }
        if let view = self.stackView.arrangedSubviews.last {
            self.stackView.setCustomSpacing(3, after: view)
        }
        
        self.stackView.addArrangedSubview(lblCount)
        
        stackView.arrangedSubviews.forEach({ stackView.sendSubviewToBack($0) })
    }
}
