//
//  NameTableViewCell.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/5/3.
//

import UIKit
import RxSwift
import Kingfisher

class NameTableViewCell<T: NameTableViewCellVM>: BaseTableViewCell<T> {
    
    lazy var avatarImage: UIImageView = {
        let iView = UIImageView.init(image: UIImage.init(named: "avatarsPhoto"))
        iView.backgroundColor = .lightGray
        iView.contentMode = .scaleAspectFill
        iView.layer.cornerRadius = 18
        iView.clipsToBounds = true
        return iView
    }()
    
    lazy var nameStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.distribution = .fill
        stackView.axis = .horizontal
        stackView.spacing = 4
        stackView.alignment = .fill
        return stackView
    }()
    
    lazy var lblName: UILabel = {
        let lbl = UILabel.init()
        lbl.font = .midiumParagraphLargeLeft
        lbl.theme_textColor = Theme.c_10_grand_1.rawValue
        lbl.lineBreakMode = .byTruncatingTail
        return lbl
    }()
    
    lazy var lblCount: UILabel = {
        let lbl = UILabel.init()
        lbl.font = .midiumParagraphLargeLeft
        lbl.theme_textColor = Theme.c_10_grand_1.rawValue
        return lbl
    }()
    
    private lazy var separatorView: UIView = {
        let view = UIView.init()
        view.theme_backgroundColor = Theme.c_07_neutral_900_10.rawValue
        return view
    }()
    
    override func setupViews() {
        super.setupViews()
        self.selectionStyle = .none
        self.theme_backgroundColor = Theme.c_07_neutral_50.rawValue
        
        self.contentView.addSubview(self.avatarImage)
        self.contentView.addSubview(self.nameStackView)
        self.nameStackView.addArrangedSubviews([self.lblName, self.lblCount])
        self.contentView.addSubview(self.separatorView)
        
        self.avatarImage.snp.makeConstraints { (make) in
            make.height.width.equalTo(36)
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.top.greaterThanOrEqualToSuperview().offset(12)
        }
        
        self.avatarImage.layer.cornerRadius = 18
        
        self.lblCount.snp.makeConstraints { (make) in
            make.height.equalTo(24)
            make.width.equalTo(0)
        }
        
        self.nameStackView.snp.makeConstraints { make in
            make.leading.equalTo(self.avatarImage.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
            make.height.equalTo(24)
            make.trailing.lessThanOrEqualToSuperview().offset(-16)
        }
        
        self.lblName.snp.makeConstraints { (make) in
            make.height.equalTo(24)
        }
        
        self.separatorView.snp.makeConstraints { (make) in
            make.leading.equalTo(self.nameStackView)
            make.trailing.bottom.equalToSuperview()
            make.height.equalTo(1)
        }
    }
    
    override func bindViewModel() {
        super.bindViewModel()
        
        self.viewModel.avatarImage.observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] (image) in
            guard let imageString = image, let url = URL(string: imageString) else {
                return
            }
            
            let r = ImageResource(downloadURL: url, cacheKey: imageString)
            self.avatarImage.kf.setImage(with: r, placeholder: UIImage.init(named: "avatarsPhoto"))
        }.disposed(by: self.disposeBag)
        
        self.viewModel.attributedName.bind(to: self.lblName.rx.attributedText).disposed(by: self.disposeBag)
        
        self.viewModel.countString.distinctUntilChanged().observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] string in
            self.updateCountLabel(string)
        }.disposed(by: self.disposeBag)
    }
    
    override func updateViews() {
        super.updateViews()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.avatarImage.kf.cancelDownloadTask()
        self.avatarImage.image = UIImage.init(named: "avatarsPhoto")
        self.lblName.text = ""
        self.lblCount.text = ""
    }
    
    func updateCountLabel(_ string: String) {
        self.lblCount.text = string
        let width = ceil(string.size(font: .midiumParagraphLargeLeft, maxSize: CGSize.init(width: 100, height: 24)).width)
        self.lblCount.snp.updateConstraints { make in
            make.width.equalTo(width)
        }
    }
}
