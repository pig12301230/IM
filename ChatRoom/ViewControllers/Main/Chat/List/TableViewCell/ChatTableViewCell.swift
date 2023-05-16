//
//  ChatTableViewCell.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/5/3.
//

import UIKit

class ChatTableViewCell: RecordTableViewCell<ChatTableViewCellVM> {
    
    private lazy var lblTime: UILabel = {
        let lbl = UILabel.init()
        lbl.textAlignment = .right
        lbl.font = .regularParagraphSmallLeft
        lbl.theme_textColor = Theme.c_07_neutral_400.rawValue
        return lbl
    }()

    private lazy var lblUnreadCount: UILabel = {
        let lbl = UILabel.init()
        lbl.layer.cornerRadius = 12
        lbl.layer.backgroundColor = Theme.c_01_primary_0_500.rawValue.toCGColor()
        lbl.textAlignment = .center
        lbl.theme_textColor = Theme.c_09_white.rawValue
        lbl.font = .boldParagraphSmallLeft
        return lbl
    }()
    
    private lazy var lblDeletedUser: UILabel = {
        let lbl = UILabel()
        lbl.text = Localizable.accountHasBeenDeleted
        lbl.textAlignment = .left
        lbl.theme_textColor = Theme.c_10_grand_2.rawValue
        lbl.font = .midiumParagraphSmallLeft
        lbl.setContentHuggingPriority(.required, for: .horizontal)
        lbl.setContentCompressionResistancePriority(.required, for: .horizontal)
        return lbl
    }()
    
    private lazy var statusImage: UIImageView = {
        let iView = UIImageView.init(image: UIImage.init(named: "iconIconVoiceCancel"))
        return iView
    }()
    
    private lazy var failureImage: UIImageView = {
        let iView = UIImageView.init(image: UIImage.init(named: "iconIconAlertError"))
        return iView
    }()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.failureImage.isHidden = true
    }
    
    override func setupViews() {
        super.setupViews()
        
        self.contentView.addSubview(self.lblTime)
        self.contentView.addSubview(self.lblUnreadCount)
        self.nameStackView.addArrangedSubviews([self.lblDeletedUser, self.statusImage])
        self.contentView.addSubview(self.failureImage)
        
        self.statusImage.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.nameStackView)
            make.width.height.equalTo(16)
        }
        
        self.lblTime.snp.makeConstraints { (make) in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalTo(self.nameStackView)
            make.width.equalTo(0)
        }
        
        self.nameStackView.snp.remakeConstraints { (make) in
            make.leading.equalTo(self.avatarImage.snp.trailing).offset(12)
            make.top.equalToSuperview().offset(12)
            make.height.equalTo(24)
            make.trailing.lessThanOrEqualTo(self.lblTime.snp.leading).offset(-4)
        }
        
        self.lblUnreadCount.snp.makeConstraints { (make) in
            make.trailing.equalTo(self.lblTime)
            make.centerY.equalTo(self.lblMessage)
            make.width.equalTo(24)
            make.height.equalTo(24)
        }
        
        self.lblMessage.snp.makeConstraints { (make) in
            make.trailing.lessThanOrEqualTo(self.lblUnreadCount.snp.leading).offset(-4)
        }
        
        self.failureImage.snp.makeConstraints { (make) in
            make.center.equalTo(self.lblUnreadCount)
            make.width.height.equalTo(24)
        }
    }
    
    override func bindViewModel() {
        super.bindViewModel()
        
        self.viewModel.unreadWidth.subscribeSuccess { [unowned self] (width) in
            self.lblUnreadCount.snp.updateConstraints { (make) in
                make.width.equalTo(width)
            }
        }.disposed(by: self.disposeBag)
        
        self.viewModel.isDeletedUser.subscribeSuccess { [weak self] isDeleted in
            guard let self = self else { return }
            self.lblDeletedUser.isHidden = !isDeleted
            self.avatarImage.alpha = isDeleted ? 0.5 : 1
        }.disposed(by: self.disposeBag)
        
        self.viewModel.isMute.map { return !$0 }.bind(to: self.statusImage.rx.isHidden).disposed(by: self.disposeBag)
        
        self.viewModel.updateTime.subscribeSuccess { [unowned self] string in
            self.lblTime.text = string
            let width = ceil(string.size(font: .midiumParagraphLargeLeft, maxSize: CGSize.init(width: 100, height: 24)).width)
            self.lblTime.snp.updateConstraints { make in
                make.width.equalTo(width)
            }
        }.disposed(by: self.disposeBag)
        
        self.viewModel.unreadCount.distinctUntilChanged().subscribeSuccess { [unowned self] count in
            self.lblUnreadCount.isHidden = count == 0 || !self.viewModel.keyString.isEmpty
            self.lblUnreadCount.text = count > 999 ? "999+" : "\(count)"
        }.disposed(by: self.disposeBag)
     
        self.viewModel.showFailure.map({ !$0 }).distinctUntilChanged().bind(to: self.failureImage.rx.isHidden).disposed(by: self.disposeBag)
    }
}
