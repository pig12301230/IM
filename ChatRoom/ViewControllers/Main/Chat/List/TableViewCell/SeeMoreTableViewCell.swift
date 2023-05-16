//
//  SeeMoreTableViewCell.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/5/3.
//

import UIKit

class SeeMoreTableViewCell: UITableViewCell {
    private lazy var lblTitle: UILabel = {
        let lbl = UILabel.init()
        lbl.textAlignment = .left
        lbl.font = .midiumParagraphMediumLeft
        lbl.theme_textColor = Theme.c_07_neutral_400.rawValue
        lbl.text = Localizable.seeMore
        return lbl
    }()
    
    private lazy var actionImageView: UIImageView = {
        let iView = UIImageView.init(image: UIImage.init(named: "iconArrowsChevronRight"))
        iView.contentMode = .scaleAspectFit
        iView.theme_tintColor = Theme.c_07_neutral_500.rawValue
        return iView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupViews()
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        self.selectionStyle = .none
        self.contentView.theme_backgroundColor = Theme.c_07_neutral_50.rawValue
        self.contentView.addSubview(self.lblTitle)
        self.contentView.addSubview(self.actionImageView)
        
        self.lblTitle.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.top.equalToSuperview().offset(12)
            make.height.equalTo(20)
        }
        
        self.actionImageView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-16)
        }
    }
}
