//
//  ConversationBaseCell.swift
//  ChatRoom
//
//  Created by Saffi Peng on 2021/7/20.
//

import UIKit
import RxSwift

protocol ConversationCellEventProtocol {
    var longPress: PublishSubject<UILongPressGestureRecognizer> { get }
    var doubleTap: PublishSubject<UITapGestureRecognizer> { get }
}

class ConversationBaseCell<T: ConversationBaseCellVM>: BaseTableViewCell<T>, ConversationCellEventProtocol {
    let longPress = PublishSubject<UILongPressGestureRecognizer>()
    let doubleTap = PublishSubject<UITapGestureRecognizer>()
    
    lazy var containerView: UIView = {
        let view = UIView()
        return view
    }()

    override func setupViews() {
        super.setupViews()
        selectionStyle = .none
        backgroundColor = .clear

        contentView.addSubview(containerView)

        self.containerView.snp.makeConstraints { make in
            make.leading.equalTo(8)
            make.top.equalTo(4)
            make.trailing.bottom.equalToSuperview()
        }
    }
}
