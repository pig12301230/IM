//
//  MemberDescriptionTableViewCell.swift
//  ChatRoom
//
//  Created by ZoeLin on 2022/1/24.
//

import UIKit

class MemberDescriptionTableViewCell: MemberTableViewCell {
    
    private lazy var lblDescription: UILabel = {
        let lbl = UILabel.init()
        lbl.font = .regularParagraphMediumLeft
        lbl.theme_textColor = Theme.c_10_grand_2.rawValue
        return lbl
    }()
    
    override func setupViews() {
        super.setupViews()
        contentView.addSubview(self.lblDescription)
        
        self.lblTitle.snp.remakeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(12)
            make.bottom.equalTo(self.snp.centerY).offset(-2)
            make.top.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        self.lblDescription.snp.makeConstraints { make in
            make.top.equalTo(lblTitle.snp.bottom).offset(4)
            make.leading.trailing.equalTo(lblTitle)
            make.bottom.equalToSuperview().offset(-12)
        }
        
    }
        
    override func setupConfig(_ config: CellConfig) {
        super.setupConfig(config)
        self.lblDescription.text = config.description
    }
}
