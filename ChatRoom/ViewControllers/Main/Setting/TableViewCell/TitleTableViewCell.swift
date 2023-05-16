//
//  TitleTableViewCell.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/6/30.
//

import UIKit

class TitleTableViewCell: UITableViewCell, SettingCellProtocol {
    
    lazy var lblTitle: UILabel = {
        let lbl = UILabel.init()
        lbl.font = .boldParagraphLargeLeft
        lbl.textAlignment = .left
        lbl.theme_textColor = Theme.c_10_grand_1.rawValue
        return lbl
    }()
    
    lazy var lblSubTitle: UILabel = {
        let lbl = UILabel.init()
        lbl.font = .midiumParagraphMediumLeft
        lbl.textAlignment = .right
        lbl.theme_textColor = Theme.c_07_neutral_400.rawValue
        return lbl
    }()
    
    lazy var separatorView: UIView = {
        let view = UIView.init()
        view.theme_backgroundColor = Theme.c_07_neutral_900_10.rawValue
        return view
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.lblTitle.text = ""
        self.lblSubTitle.text = ""
    }
    
    func setupViews() {
        contentView.addSubview(self.lblTitle)
        contentView.addSubview(self.lblSubTitle)
        contentView.addSubview(self.separatorView)
        
        self.lblSubTitle.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(20)
            make.centerY.equalToSuperview()
        }
        
        self.lblTitle.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.trailing.equalTo(self.lblSubTitle.snp.leading).offset(-4)
        }
        
        self.separatorView.snp.makeConstraints { make in
            make.height.equalTo(1)
            make.leading.equalToSuperview().offset(16)
            make.bottom.trailing.equalToSuperview()
        }
    }
    
    func setupConfig(_ config: SettingCellConfig) {
        self.lblTitle.text = config.title
        self.lblSubTitle.text = config.subTitle
        
        self.separatorView.snp.updateConstraints { make in
            make.leading.equalToSuperview().offset(config.leading)
        }
    }
}
