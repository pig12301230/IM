//
//  EmojiTableViewCell.swift
//  ChatRoom
//
//  Created by Winston_Chuang on 2022/11/23.
//

import UIKit
import RxSwift
import Kingfisher

class EmojiTableViewCell: UITableViewCell {
    
    lazy var avatarImage: UIImageView = {
        let iView = UIImageView.init(image: UIImage.init(named: "avatarsPhoto"))
        iView.backgroundColor = .lightGray
        iView.contentMode = .scaleAspectFill
        iView.layer.cornerRadius = 18
        iView.clipsToBounds = true
        return iView
    }()
    
    lazy var roleIconView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 8
        view.clipsToBounds = true
        view.theme_backgroundColor = Theme.c_01_primary_0_500.rawValue
        view.isHidden = true
        return view
    }()
    
    lazy var roleIconImage: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.theme_backgroundColor = Theme.c_01_primary_0_500.rawValue
        return imageView
    }()
    
    lazy var lblName: UILabel = {
        let lbl = UILabel.init()
        lbl.font = .midiumParagraphLargeLeft
        lbl.theme_textColor = Theme.c_10_grand_1.rawValue
        lbl.lineBreakMode = .byTruncatingTail
        return lbl
    }()
    
    lazy var emojiIcon: UIImageView = {
        let icon = UIImageView.init()
        icon.backgroundColor = .darkGray
        return icon
    }()
    
    private lazy var separatorView: UIView = {
        let view = UIView.init()
        view.theme_backgroundColor = Theme.c_07_neutral_900_10.rawValue
        return view
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
        self.theme_backgroundColor = Theme.c_07_neutral_50.rawValue
        
        self.contentView.addSubview(self.avatarImage)
        self.contentView.addSubview(self.roleIconView)
        roleIconView.addSubview(self.roleIconImage)
        self.contentView.addSubview(self.lblName)
        self.contentView.addSubview(self.emojiIcon)
        self.contentView.addSubview(self.separatorView)
        
        self.avatarImage.snp.makeConstraints { (make) in
            make.height.width.equalTo(36)
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.top.greaterThanOrEqualToSuperview().offset(12)
        }
        
        self.avatarImage.layer.cornerRadius = 18
        
        self.roleIconView.snp.makeConstraints { make in
            make.bottom.equalTo(avatarImage.snp.bottom)
            make.trailing.equalTo(avatarImage.snp.trailing)
            make.width.height.equalTo(16)
        }
        
        self.roleIconImage.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(12)
        }
        
        self.lblName.snp.makeConstraints { (make) in
            make.leading.equalTo(self.avatarImage.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
            make.height.equalTo(24)
        }
        
        self.emojiIcon.snp.makeConstraints { make in
            make.top.equalTo(18)
            make.trailing.equalTo(-16)
            make.bottom.equalTo(-18)
            make.width.height.equalTo(24)
        }
        
        self.emojiIcon.layer.cornerRadius = 12
        
        self.separatorView.snp.makeConstraints { (make) in
            make.leading.equalTo(self.lblName)
            make.bottom.equalToSuperview()
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(1)
        }
    }
    
    func setup(detail: EmojiDetailModel?) {
        guard let detail = detail else {
            return
        }

        self.lblName.text = detail.nickname
        
        if let url = URL(string: detail.avatarThumbnail) {
            let resouce = ImageResource(downloadURL: url, cacheKey: detail.avatarThumbnail)
            self.avatarImage.kf.setImage(with: resouce, placeholder: UIImage.init(named: "avatarsPhoto"))
        }
        
        //setup roleIcon
        switch detail.userRole {
        case .admin:
            roleIconView.isHidden = false
            self.roleIconImage.image = UIImage(named: "icon_actions_star")
        case .owner:
            roleIconView.isHidden = false
            self.roleIconImage.image = UIImage(named: "icon_icon_crown_fill")
        default:
            roleIconView.isHidden = true
        }
        
        if let emojiType = EmojiType(rawValue: detail.emojiCode) {
            self.emojiIcon.image = UIImage(named: emojiType.imageName)
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.avatarImage.kf.cancelDownloadTask()
        self.avatarImage.image = UIImage.init(named: "avatarsPhoto")
        self.roleIconImage.image = nil
        self.roleIconView.isHidden = true
        self.lblName.text = ""
    }
}
