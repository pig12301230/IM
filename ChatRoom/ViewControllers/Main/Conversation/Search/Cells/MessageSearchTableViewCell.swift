//
//  MessageSearchTableViewCell.swift
//  ChatRoom
//
//  Created by Saffi Peng on 2021/7/5.
//

import UIKit

class MessageSearchTableViewCell<T: MessageSearchTableViewCellVM>: NameTableViewCell<T> {

    private lazy var lblTime: UILabel = {
        let lbl = UILabel.init()
        lbl.textAlignment = .right
        lbl.font = .regularParagraphSmallLeft
        lbl.theme_textColor = Theme.c_07_neutral_400.rawValue
        return lbl
    }()

    private lazy var lblMessage: UILabel = {
        let lbl = UILabel.init()
        lbl.textAlignment = .left
        lbl.font = .regularParagraphMediumLeft
        lbl.theme_textColor = Theme.c_10_grand_2.rawValue
        return lbl
    }()

    override func setupViews() {
        super.setupViews()

        self.contentView.addSubview(self.lblTime)
        self.contentView.addSubview(self.lblMessage)

        self.avatarImage.layer.cornerRadius = 24
        self.avatarImage.snp.updateConstraints { (make) in
            make.width.height.equalTo(48)
        }

        self.nameStackView.snp.remakeConstraints { (make) in
            make.top.equalToSuperview().offset(12)
            make.leading.equalTo(self.avatarImage.snp.trailing).offset(12)
            make.height.equalTo(24)
        }

        self.lblTime.snp.makeConstraints { (make) in
            make.leading.greaterThanOrEqualTo(self.lblName.snp.trailing).offset(4)
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalTo(self.lblName)
        }

        self.lblMessage.snp.makeConstraints { (make) in
            make.top.equalTo(self.nameStackView.snp.bottom).offset(4)
            make.leading.equalTo(self.nameStackView)
            make.trailing.lessThanOrEqualToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-12)
            make.height.equalTo(20)
        }
    }

    override func bindViewModel() {
        super.bindViewModel()

        self.viewModel.updateName.bind(to: self.lblName.rx.text).disposed(by: self.disposeBag)
        self.viewModel.updateTime.bind(to: self.lblTime.rx.text).disposed(by: self.disposeBag)
        self.viewModel.attributedMessage.bind(to: self.lblMessage.rx.attributedText).disposed(by: self.disposeBag)
    }
}
