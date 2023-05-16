//
//  AddAsFriendView.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/7/13.
//

import UIKit

class AddAsFriendView: BaseViewModelView<AddAsFriendViewVM> {
    
    private lazy var avatarImageView: UIImageView = {
        let iView = UIImageView.init()
        iView.contentMode = .scaleAspectFill
        iView.layer.cornerRadius = 48
        iView.clipsToBounds = true
        return iView
    }()
    
    private lazy var lblHint: UILabel = {
        let lbl = UILabel.init()
        lbl.font = .midiumParagraphSmallLeft
        lbl.theme_textColor = Theme.c_10_grand_1.rawValue
        lbl.text = Localizable.addFriendHint
        return lbl
    }()
    
    private lazy var btnAgreeAdd: UIButton = {
        let btn = UIButton.init(type: .custom)
        btn.setImage(UIImage(named: "iconIconUserAdd"), for: .normal)
        btn.setImage(UIImage(named: "iconIconUserAdd"), for: .highlighted)
        btn.titleEdgeInsets = UIEdgeInsets.init(top: 0, left: 8, bottom: 0, right: 0)
        btn.contentHorizontalAlignment = .center
        btn.setTitle(Localizable.agreeAdd, for: .normal)
        btn.titleLabel?.font = .boldParagraphMediumLeft
        btn.theme_backgroundColor = Theme.c_09_white.rawValue
        btn.theme_tintColor = Theme.c_01_primary_0_500.rawValue
        btn.theme_setTitleColor(Theme.c_01_primary_0_500.rawValue, forState: .normal)
        btn.layer.cornerRadius = 4
        btn.clipsToBounds = true
        return btn
    }()
    
    private lazy var btnBlock: UIButton = {
        let btn = UIButton.init(type: .custom)
        btn.setImage(UIImage(named: "iconIconStop"), for: .normal)
        btn.setImage(UIImage(named: "iconIconStop"), for: .highlighted)
        btn.titleEdgeInsets = UIEdgeInsets.init(top: 0, left: 8, bottom: 0, right: 0)
        btn.contentHorizontalAlignment = .center
        btn.setTitle(Localizable.addBlacklist, for: .normal)
        btn.titleLabel?.font = .boldParagraphMediumLeft
        btn.theme_backgroundColor = Theme.c_09_white.rawValue
        btn.theme_tintColor = Theme.c_07_neutral_400.rawValue
        btn.theme_setTitleColor(Theme.c_07_neutral_400.rawValue, forState: .normal)
        btn.layer.cornerRadius = 4
        btn.clipsToBounds = true
        return btn
    }()
    
    override func setupViews() {
        super.setupViews()
        self.theme_backgroundColor = Theme.c_07_neutral_100.rawValue
        self.addSubview(self.avatarImageView)
        self.addSubview(self.lblHint)
        self.addSubview(self.btnAgreeAdd)
        self.addSubview(self.btnBlock)
        
        self.avatarImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.height.width.equalTo(96)
            make.top.equalToSuperview().offset(16)
        }
        
        self.lblHint.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(self.avatarImageView.snp.bottom).offset(4)
            make.height.equalTo(18)
        }
        
        self.btnAgreeAdd.snp.makeConstraints { make in
            make.trailing.equalTo(self.snp.centerX).offset(-8)
            make.leading.equalToSuperview().offset(16)
            make.height.equalTo(48)
            make.top.equalTo(self.lblHint.snp.bottom).offset(16)
        }
        
        self.btnBlock.snp.makeConstraints { make in
            make.leading.equalTo(self.snp.centerX).offset(8)
            make.trailing.equalToSuperview().offset(-16)
            make.top.height.equalTo(self.btnAgreeAdd)
        }
    }
    
    override func bindViewModel() {
        super.bindViewModel()
        self.viewModel.avatarThumbnail.bind(to: self.avatarImageView.rx.image).disposed(by: self.disposeBag)
        self.btnBlock.rx.controlEvent(.touchUpInside).bind(to: self.viewModel.showBlockConfirm).disposed(by: self.disposeBag)
        self.btnAgreeAdd.rx.controlEvent(.touchUpInside).bind(to: self.viewModel.acceptFriend).disposed(by: self.disposeBag)
    }
}
