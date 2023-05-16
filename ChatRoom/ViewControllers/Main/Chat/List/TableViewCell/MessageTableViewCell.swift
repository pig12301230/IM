//
//  MessageTableViewCell.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/5/27.
//

import UIKit

class MessageTableViewCell: NameTableViewCell<MessageTableViewCellVM> {
    
    lazy var lblMessage: UILabel = {
        let lbl = UILabel.init()
        lbl.textAlignment = .left
        lbl.font = .regularParagraphMediumLeft
        lbl.theme_textColor = Theme.c_10_grand_2.rawValue
        return lbl
    }()
    
    override func setupViews() {
        super.setupViews()
        
        self.contentView.addSubview(self.lblMessage)
        
        self.avatarImage.snp.updateConstraints { (make) in
            make.width.height.equalTo(48)
        }
        
        self.avatarImage.layer.cornerRadius = 24
        
        self.nameStackView.snp.remakeConstraints { (make) in
            make.leading.equalTo(self.avatarImage.snp.trailing).offset(12)
            make.top.equalToSuperview().offset(12)
            make.height.equalTo(24)
        }
        
        self.lblMessage.snp.makeConstraints { (make) in
            make.leading.equalTo(self.nameStackView)
            make.height.equalTo(20)
            make.top.equalTo(self.nameStackView.snp.bottom).offset(4)
            make.bottom.equalToSuperview().offset(-12)
            make.trailing.lessThanOrEqualToSuperview().offset(-16)
        }
    }
    
    override func bindViewModel() {
        super.bindViewModel()
        
        self.viewModel.attributedMessage.bind(to: self.lblMessage.rx.attributedText).disposed(by: self.disposeBag)
    }
}
