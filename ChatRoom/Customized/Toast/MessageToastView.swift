//
//  MessageToastView.swift
//  ChatRoom
//
//  Created by Andy Yang on 2021/7/7.
//

import UIKit

class MessageToastView: ToastView {

    private lazy var message: UILabel = {
        let label = UILabel()
        label.font = .regularParagraphMediumLeft
        label.theme_textColor = Theme.c_09_white.rawValue
        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byCharWrapping
        return label
    }()
    
    override func setupViews() {
        self.theme_backgroundColor = Theme.c_08_black_75.rawValue
        self.layer.cornerRadius = 4
        self.clipsToBounds = true

        addSubview(message)

        message.snp.makeConstraints {
            $0.leading.equalTo(16)
            $0.trailing.equalTo(-16)
            $0.centerY.equalToSuperview()
        }
    }

    override func bindViewModel() {
        viewModel.message.bind(to: message.rx.text).disposed(by: disposeBag)
    }
}
