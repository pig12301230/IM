//
//  AddMemberCell.swift
//  ChatRoom
//
//  Created by Winston_Chuang on 2022/1/19.
//

import Foundation
import UIKit
import RxSwift
import Kingfisher

class AddMemberCell: UITableViewCell {
    
    private lazy var imgAvatar: UIImageView = {
        let imgView = UIImageView(image: UIImage(named: "avatarsPhoto"))
        imgView.contentMode = .scaleAspectFill
        return imgView
    }()
    
    private lazy var lblName: UILabel = {
        let label = UILabel()
        label.font = .midiumParagraphLargeLeft
        label.theme_textColor = Theme.c_10_grand_1.rawValue
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    private lazy var imgSelected: UIImageView = {
        let imgView = UIImageView(image: UIImage(named: "avatarsPhoto"))
        imgView.contentMode = .scaleAspectFill

        return imgView
    }()
    
    private lazy var separator: UIView = {
        let view = UIView.init()
        view.theme_backgroundColor = Theme.c_07_neutral_900_10.rawValue
        return view
    }()
    
    private(set) var isExist: Bool = false
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        setCheckedImage()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imgAvatar.image = UIImage(named: "avatarsPhoto")
    }
    
    func setCheckedImage() {
        if isExist {
            imgSelected.image = UIImage(named: "checkboxCheckeddisableImage")
            return
        }
        imgSelected.image = isSelected ? UIImage(named: "checkboxCheckedImage") : UIImage(named: "checkboxActiveImage")
    }
    
    func setup(member: FriendModel, isExist: Bool, needCheckBox: Bool) {
        imgSelected.isHidden = !needCheckBox
        self.isExist = isExist
        if isExist {
            imgSelected.image = UIImage(named: "checkboxCheckeddisableImage")
        }
        lblName.attributedText = member.display()
        
        if let urlStr = member.thumbNail {
            imgAvatar.kf.setImage(with: URL(string: urlStr),
                                  placeholder: UIImage(named: "avatarsPhoto"))
        }
        setCheckedImage()
    }
    
    func setupViews() {
        selectionStyle = .none
        theme_backgroundColor = Theme.c_07_neutral_50.rawValue
        
        contentView.addSubview(imgAvatar)
        contentView.addSubview(lblName)
        contentView.addSubview(imgSelected)
        addSubview(separator)
        
        imgAvatar.snp.makeConstraints {
            $0.width.height.equalTo(36)
            $0.leading.equalTo(16)
            $0.centerY.equalToSuperview()
        }
        imgAvatar.roundSelf()
        
        lblName.snp.makeConstraints {
            $0.leading.equalTo(imgAvatar.snp.trailing).offset(12)
            $0.centerY.equalToSuperview()
            $0.height.equalTo(24)
        }
        
        imgSelected.snp.makeConstraints {
            $0.width.height.equalTo(24)
            $0.trailing.equalTo(-16)
            $0.centerY.equalToSuperview()
        }
        imgSelected.roundSelf()
        
        separator.snp.makeConstraints {
            $0.leading.equalTo(lblName)
            $0.trailing.equalTo(-16)
            $0.height.equalTo(1)
            $0.bottom.equalToSuperview()
        }
    }
}
