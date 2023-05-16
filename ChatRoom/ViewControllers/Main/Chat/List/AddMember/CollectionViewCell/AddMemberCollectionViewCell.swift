//
//  AddMemberCollectionViewCell.swift
//  ChatRoom
//
//  Created by Winston_Chuang on 2022/1/20.
//

import Foundation
import UIKit

class AddMemberCollectionViewCell: UICollectionViewCell {
    private lazy var lblName: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.font = .regularParagraphSmallCenter
        label.theme_textColor = Theme.c_10_grand_1.rawValue
        return label
    }()
    
    private lazy var avatarImg: UIImageView = {
        let imgView = UIImageView()
        imgView.image = UIImage(named: "avatarsPhoto")
        imgView.contentMode = .scaleAspectFill
        return imgView
    }()
    
    private lazy var crossImg: UIImageView = {
        let imgView = UIImageView()
        imgView.image = UIImage(named: "buttonCrossCircleFill")
        return imgView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        avatarImg.image = UIImage(named: "avatarsPhoto")
        crossImg.isHidden = false
    }
    
    func setupMember(member: FriendModel) {
        lblName.text = member.displayName
        if let urlStr = member.thumbNail {
            avatarImg.kf.setImage(with: URL(string: urlStr),
                                  placeholder: UIImage(named: "avatarsPhoto"))
        }
    }
    
    func hideDeleteBtn() {
        crossImg.isHidden = true
    }
    
    func setupViews() {
        self.contentView.addSubviews([lblName, avatarImg, crossImg])
        
        avatarImg.snp.makeConstraints { make in
            make.width.height.equalTo(44)
            make.top.equalToSuperview().offset(12)
            make.centerX.equalToSuperview()
        }
        avatarImg.roundSelf()
        
        lblName.snp.makeConstraints { make in
            make.top.equalTo(avatarImg.snp.bottom).offset(2)
            make.bottom.equalToSuperview().offset(-8)
            make.width.equalTo(60)
            make.height.equalTo(18)
            make.trailing.leading.equalToSuperview()
        }
        
        crossImg.snp.makeConstraints { make in
            make.width.height.equalTo(20)
            make.top.equalToSuperview().offset(8)
            make.trailing.equalToSuperview().offset(-4)
        }
        crossImg.roundSelf()
    }
}
