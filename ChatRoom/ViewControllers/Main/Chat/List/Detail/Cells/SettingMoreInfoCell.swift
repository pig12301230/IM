//
//  SettingMoreInfoCell.swift
//  ChatRoom
//
//  Created by ZoeLin on 2022/1/19.
//

import UIKit

class SettingMoreInfoCell<T: SettingMoreInfoCellVM>: SettingMoreCell<T> {
    
    lazy var lblInfo: UILabel = {
        let lbl = UILabel()
        lbl.theme_textColor = Theme.c_07_neutral_400.rawValue
        lbl.font = .midiumParagraphMediumRight
        lbl.textAlignment = .right
        return lbl
    }()
    
    override func setupViews() {
        super.setupViews()
        self.addSubview(lblInfo)        

        self.lblInfo.snp.makeConstraints { make in
            make.trailing.equalTo(moreImageView.snp.leading).offset(-16)
            make.centerY.equalToSuperview()
        }
    }
    
    override func bindViewModel() {
        super.bindViewModel()
        self.viewModel.info.bind(to: self.lblInfo.rx.text).disposed(by: disposeBag)
    }
}
