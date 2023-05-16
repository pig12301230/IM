//
//  IconTitleArrowTableViewCell.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/6/30.
//

import UIKit

class IconTitleArrowTableViewCell: TitleArrowTableViewCell {
    
    private lazy var iconImageView: UIImageView = {
        let view = UIImageView.init()
        view.layer.cornerRadius = 18
        view.clipsToBounds = true
        view.theme_backgroundColor = Theme.c_01_primary_700.rawValue
        view.contentMode = .center
        return view
    }()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.iconImageView.image = nil
    }
    
    override func setupConfig(_ config: SettingCellConfig) {
        super.setupConfig(config)
        self.iconImageView.image = UIImage.init(named: config.icon)?.reSizeImage(toSize: CGSize(width: 16, height: 16))
    }
    
    override func setupViews() {
        super.setupViews()
        
        contentView.addSubview(self.iconImageView)
        
        self.iconImageView.snp.makeConstraints { make in
            make.leading.equalTo(16)
            make.centerY.equalToSuperview()
            make.height.width.equalTo(36)
        }
        
        self.arrowRightImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.height.width.equalTo(24)
            make.centerY.equalToSuperview()
        }
        
        self.lblTitle.snp.remakeConstraints { make in
            make.leading.equalTo(self.iconImageView.snp.trailing).offset(8)
            make.centerY.equalTo(self.iconImageView)
            make.trailing.equalTo(self.lblSubTitle.snp.leading).offset(-4)
        }
    }
}
