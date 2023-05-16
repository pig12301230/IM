//
//  TitleArrowTableViewCell.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/6/30.
//

import UIKit

class TitleArrowTableViewCell: TitleTableViewCell {
    lazy var arrowRightImageView: UIImageView = {
        let view = UIImageView.init(image: UIImage.init(named: "iconArrowsChevronRight"))
        view.contentMode = .scaleAspectFit
        view.theme_tintColor = Theme.c_07_neutral_500.rawValue
        return view
    }()
    
    override func setupViews() {
        super.setupViews()
        
        contentView.addSubview(self.arrowRightImageView)
        
        self.arrowRightImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.height.width.equalTo(24)
            make.centerY.equalToSuperview()
        }
        
        self.lblSubTitle.snp.remakeConstraints { make in
            make.trailing.equalTo(self.arrowRightImageView.snp.leading).offset(-16)
            make.height.equalTo(20)
            make.centerY.equalToSuperview()
        }
    }
    
    override func setupConfig(_ config: SettingCellConfig) {
        super.setupConfig(config)
        self.arrowRightImageView.isHidden = config.hiddenArrowRight
    }
}
