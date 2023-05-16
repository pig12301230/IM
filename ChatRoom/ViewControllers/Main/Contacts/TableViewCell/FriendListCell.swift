//
//  FriendListCell.swift
//  ChatRoom
//
//  Created by Andy Yang on 2021/5/31.
//

import UIKit
import RxSwift

class FriendListCell<T: FriendListCellVM>: BaseTableViewCell<T> {
    
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
    
    private lazy var lblCount: UILabel = {
        let label = UILabel()
        label.font = .midiumParagraphLargeLeft
        label.theme_textColor = Theme.c_10_grand_1.rawValue
        return label
    }()
    
    private lazy var separator: UIView = {
        let view = UIView.init()
        view.theme_backgroundColor = Theme.c_07_neutral_900_10.rawValue
        return view
    }()
    
    override func setupViews() {
        super.setupViews()
        selectionStyle = .none
        theme_backgroundColor = Theme.c_07_neutral_50.rawValue
        
        contentView.addSubview(imgAvatar)
        contentView.addSubview(lblName)
        contentView.addSubview(lblCount)
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
            $0.trailing.equalTo(lblCount.snp.leading)
        }
        
        lblCount.snp.makeConstraints {
            $0.centerY.equalTo(lblName)
            $0.height.equalTo(24)
            $0.width.equalTo(0)
            $0.trailing.lessThanOrEqualToSuperview().offset(-16)
        }
        
        separator.snp.makeConstraints {
            $0.leading.equalTo(lblName)
            $0.trailing.equalTo(-16)
            $0.height.equalTo(1)
            $0.bottom.equalToSuperview()
        }
    }
    
    override func bindViewModel() {
        super.bindViewModel()
        
        viewModel.avatarImage.observe(on: MainScheduler.instance).subscribeSuccess { [weak self] (imageStr) in
            guard let strongSelf = self, let url = URL(string: imageStr) else {
                self?.imgAvatar.image = UIImage(named: "avatarsPhoto")
                return
            }
            strongSelf.imgAvatar.kf.setImage(with: url,
                                             placeholder: UIImage(named: "avatarsPhoto"))
        }.disposed(by: disposeBag)
        
        viewModel.name.observe(on: MainScheduler.instance).subscribeSuccess { [weak self] (name) in
            guard let self = self else { return }
            self.lblName.attributedText = name
        }.disposed(by: disposeBag)
        
        viewModel.count.distinctUntilChanged().observe(on: MainScheduler.instance).subscribeSuccess { [weak self] (count) in
            guard let self = self else { return }
            self.updateCountLabel(count)
        }.disposed(by: self.disposeBag)
    }
 
    override func updateViews() {
        super.updateViews()
        viewModel.setupViews()
    }
    
    func updateCountLabel(_ string: String) {
        self.lblCount.text = string
        let width = ceil(string.size(font: .midiumParagraphLargeLeft, maxSize: CGSize.init(width: 100, height: 24)).width)
        self.lblCount.snp.updateConstraints { make in
            make.width.equalTo(width)
        }
    }
    
    func updateSeparator(fullyFilled: Bool = false) {
        if fullyFilled == true {
            separator.snp.updateConstraints {
                $0.trailing.equalToSuperview()
            }
        }
    }
}
