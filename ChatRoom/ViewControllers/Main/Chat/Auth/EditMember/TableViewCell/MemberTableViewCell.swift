//
//  MemberTableViewCell.swift
//  ChatRoom
//
//  Created by ZoeLin on 2022/1/24.
//

import UIKit
import Kingfisher

class MemberTableViewCell: UITableViewCell, SettingCellProtocol {
    typealias CellConfig = MemberTableViewCellVM
    
    lazy var iconImageView: UIImageView = {
        let image = UIImageView.init()
        image.contentMode = .scaleAspectFill
        return image
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
    
    lazy var lblTitle: UILabel = {
        let lbl = UILabel.init()
        lbl.font = .midiumParagraphLargeLeft
        lbl.textAlignment = .left
        lbl.theme_textColor = Theme.c_10_grand_1.rawValue
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
        self.iconImageView.image = nil
        self.roleIconImage.image = nil
        self.roleIconView.isHidden = true
    }
    
    func setupViews() {
        contentView.addSubview(self.iconImageView)
        contentView.addSubview(self.roleIconView)
        roleIconView.addSubview(self.roleIconImage)
        contentView.addSubview(self.lblTitle)
        contentView.addSubview(self.separatorView)
        
        self.iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(36)
        }
        
        self.roleIconView.snp.makeConstraints { make in
            make.bottom.equalTo(iconImageView.snp.bottom)
            make.trailing.equalTo(iconImageView.snp.trailing)
            make.width.height.equalTo(16)
        }
        
        self.roleIconImage.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(12)
        }
        
        self.lblTitle.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-16)
        }
        
        self.separatorView.snp.makeConstraints { make in
            make.height.equalTo(1)
            make.leading.equalToSuperview().offset(16)
            make.bottom.trailing.equalToSuperview()
        }
        
        self.iconImageView.roundSelf()
    }
    
    func setupConfig(_ config: CellConfig) {
        config.attributedName.bind(to: self.lblTitle.rx.attributedText).disposed(by: self.rx.reuseBag)
        
        self.separatorView.snp.updateConstraints { make in
            make.leading.equalToSuperview().offset(config.leading)
        }
        
        setupRoleIcon(config)
        
        guard !config.icon.isEmpty, let url = URL(string: config.icon) else {
            self.iconImageView.image = UIImage.init(named: config.iconPlaceholder)
            return
        }
        
        self.iconImageView.kf.setImage(with: url, placeholder: UIImage(named: config.iconPlaceholder))
    }
    
    private func setupRoleIcon(_ config: CellConfig) {
        if config.editType == .member {
            switch config.transceiver?.role {
            case .owner:
                self.roleIconView.isHidden = false
                self.roleIconImage.image = UIImage(named: "icon_icon_crown_fill")
            case .admin:
                self.roleIconView.isHidden = false
                self.roleIconImage.image = UIImage(named: "icon_actions_star")
            default:
                self.roleIconView.isHidden = true
            }
        } else {
            self.roleIconView.isHidden = true
        }
    }
}
