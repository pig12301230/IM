//
//  UnreadCell.swift
//  ChatRoom
//
//  Created by Saffi Peng on 2021/7/20.
//

import UIKit
import RxSwift

class UnreadCell<T: UnreadCellVM>: ConversationBaseCell<T> {

    private lazy var lblUnread: UILabel = {
        let label = UILabel()
        label.theme_backgroundColor = Theme.c_07_neutral_900_10.rawValue
        label.font = .midiumParagraphSmallLeft
        label.theme_textColor = Theme.c_10_grand_2.rawValue
        label.textAlignment = .center
        label.layer.cornerRadius = 12
        label.clipsToBounds = true
        label.text = Localizable.belowUnread
        return label
    }()

    override func setupViews() {
        super.setupViews()

        containerView.addSubview(lblUnread)

        self.lblUnread.snp.makeConstraints { make in
            make.top.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(24)
        }
    }
}
