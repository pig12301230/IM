//
//  MessageBaseLCell.swift
//  ChatRoom
//
//  Created by Saffi Peng on 2021/7/20.
//

import UIKit
import RxSwift

protocol MessageSenderOthers {
    var nameHidden: Bool { get set }
}

class MessageBaseLCell<T: MessageBaseCellVM>: ConversationBaseCell<T>, MessageSenderOthers {
    var nameHidden: Bool = false

    lazy var avatarView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "avatarsPhoto"))
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 18
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = true
        return imageView
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
    
    lazy var nameStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 4
        stackView.distribution = .equalSpacing
        stackView.alignment = .fill
        return stackView
    }()
    
    lazy var lblName: UILabel = {
        let label = UILabel()
        label.font = .boldParagraphTinyLeft
        label.theme_textColor = Theme.c_10_grand_1.rawValue
        label.textAlignment = .left
        return label
    }()
    
    lazy var lblDeletedUser: UILabel = {
        let lbl = UILabel()
        lbl.text = Localizable.accountHasBeenDeleted
        lbl.theme_textColor = Theme.c_10_grand_2.rawValue
        lbl.font = .boldParagraphTinyLeft
        lbl.setContentHuggingPriority(.required, for: .horizontal)
        lbl.setContentCompressionResistancePriority(.required, for: .horizontal)
        return lbl
    }()
    
    lazy var contentContainerView: UIView = {
        let view = UIView()
        return view
    }()

    lazy var lblDateTime: UILabel = {
        let label = UILabel()
        label.font = .regularParagraphTinyLeft
        label.theme_textColor = Theme.c_07_neutral_400.rawValue
        label.textAlignment = .left
        return label
    }()
    
    lazy var emojiBtn: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "iconIconSmile"), for: .normal)
        return button
    }()
    
    lazy var emojiFootView: EmojiFootView = {
        let footView = EmojiFootView()
        footView.isHidden = true
        return footView
    }()

    override func prepareForReuse() {
        super.prepareForReuse()
        self.resetViewSetting()
        self.roleIconView.isHidden = true
        self.roleIconImage.image = nil
        self.disposeBag = DisposeBag()
    }

    override func setupViews() {
        super.setupViews()

        containerView.addSubview(avatarView)
        containerView.addSubview(roleIconView)
        roleIconView.addSubview(roleIconImage)
        containerView.addSubview(nameStackView)
        
        nameStackView.addArrangedSubviews([lblName, lblDeletedUser])
        containerView.addSubview(contentContainerView)
        containerView.addSubview(lblDateTime)
        containerView.addSubview(emojiBtn)
        containerView.addSubview(emojiFootView)

        self.avatarView.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalToSuperview()
            make.width.height.equalTo(36)
        }
        
        self.roleIconView.snp.makeConstraints { make in
            make.bottom.equalTo(self.avatarView.snp.bottom)
            make.trailing.equalTo(self.avatarView.snp.trailing)
            make.width.height.equalTo(16)
        }
        
        self.roleIconImage.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(12)
        }

        self.nameStackView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalTo(avatarView.snp.trailing).offset(8)
            make.trailing.lessThanOrEqualToSuperview().offset(-8)
        }
        
        self.lblName.snp.makeConstraints { make in
            make.height.equalTo(14)
        }
        
        self.lblDeletedUser.snp.makeConstraints { make in
            make.height.equalTo(14)
        }
        
        self.contentContainerView.snp.makeConstraints { make in
            make.top.equalTo(lblName.snp.bottom)
            make.leading.equalTo(avatarView.snp.trailing)
            make.bottom.equalToSuperview().inset(12)
            make.width.lessThanOrEqualTo(MessageContentSize.maxWidth)
        }

        self.lblDateTime.snp.makeConstraints { make in
            make.leading.equalTo(contentContainerView.snp.trailing).offset(4)
            make.bottom.equalTo(contentContainerView)
            make.width.equalTo(50)
            make.height.equalTo(10)
        }
        
        self.emojiBtn.snp.makeConstraints { make in
            make.leading.equalTo(lblDateTime)
            make.top.equalTo(contentContainerView)
            make.width.height.equalTo(16)
        }
        
        self.emojiFootView.snp.makeConstraints { make in
            make.leading.equalTo(contentContainerView).offset(16)
            make.height.equalTo(24)
            make.top.equalTo(contentContainerView.snp.bottom).offset(-12)
        }
    }

    override func bindViewModel() {
        super.bindViewModel()

        self.contentContainerView.rx.longPress.bind(to: longPress).disposed(by: disposeBag)
        self.rx.doubleTap.bind(to: doubleTap).disposed(by: disposeBag)
        
        // Avatar
        self.viewModel.avatarHidden.bind(to: self.avatarView.rx.isHidden).disposed(by: self.disposeBag)
        self.viewModel.roleIcon
            .observe(on: MainScheduler.instance)
            .bind { [weak self] role in
            guard let self = self else { return }
            if self.viewModel.avatarHidden.value {
                self.roleIconView.isHidden = true
                return
            }
            switch role {
            case .owner:
                self.roleIconView.isHidden = false
                self.roleIconImage.image = UIImage(named: "icon_icon_crown_fill")
            case .admin:
                self.roleIconView.isHidden = false
                self.roleIconImage.image = UIImage(named: "icon_actions_star")
            default:
                self.roleIconView.isHidden = true
            }
        }.disposed(by: self.disposeBag)

        self.viewModel.avatarURL.observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] url in
            self.setAvatar(urlString: url)
        }.disposed(by: self.disposeBag)
        
        self.viewModel.isDeletedUser
            .observe(on: MainScheduler.instance)
            .subscribeSuccess { [weak self] isDeleted in
                guard let self = self else { return }
                self.avatarView.alpha = isDeleted ? 0.5 : 1
                self.avatarView.isUserInteractionEnabled = !isDeleted
                self.lblDeletedUser.isHidden = !isDeleted
            }.disposed(by: disposeBag)

        // Emoji
        self.viewModel.updateEmojiFootView.observe(on: MainScheduler.instance).subscribeSuccess { [weak self] (groupType, emojiContentModel) in
            guard let self = self, let groupType = groupType, let emojiContentModel = emojiContentModel else { return }
            self.emojiFootView.isHidden = emojiContentModel.totalCount == 0
            self.emojiFootView.config(emojiContentModel: emojiContentModel, type: groupType)
        }.disposed(by: self.disposeBag)

        // Name
        self.viewModel.name.bind(to: self.lblName.rx.text).disposed(by: self.disposeBag)
        self.viewModel.nameHidden.observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] hidden in
            self.nameStackView.isHidden = hidden
            self.updateContentView(with: hidden)
        }.disposed(by: self.disposeBag)
        
        // Time
        self.viewModel.dateTime.bind(to: self.lblDateTime.rx.text).disposed(by: self.disposeBag)
        
        // Emoji
        self.emojiFootView.rx.click
            .observe(on: MainScheduler.instance)
            .bind { [weak self] in
                guard let self = self else { return }
                self.viewModel.openEmojiList()
            }
            .disposed(by: disposeBag)
        
        // MARK: - click signal
        self.avatarView.rx.click.observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] _ in
            self.viewModel.showContactDetail()
        }.disposed(by: self.disposeBag)
        
        self.emojiBtn.rx.controlEvent(.touchUpInside).subscribeSuccess { [unowned self] in
            self.viewModel.showEmojiToolView()
        }.disposed(by: self.disposeBag)
        
        self.contentContainerView.rx.doubleTap.subscribeSuccess { [weak self] _ in
            guard let self = self else { return }
            self.viewModel.handleDoubleTap()
        }.disposed(by: self.disposeBag)
    }

    func resetViewSetting() {
        self.avatarView.isHidden = false
        self.emojiFootView.isHidden = true
        self.emojiFootView.subviews.forEach({ $0.removeFromSuperview() })
    }
}

// MARK: - Avatar
extension MessageBaseLCell {
    func setAvatar(urlString: String) {
        guard let url = URL(string: urlString) else {
            self.avatarView.image = UIImage(named: "avatarsPhoto")
            return
        }
        self.avatarView.kf.setImage(with: url, placeholder: UIImage(named: "avatarsPhoto"))
    }
}

// MARK: - Name
extension MessageBaseLCell {
    func updateContentView(with nameHidden: Bool) {
        self.nameHidden = nameHidden
        self.nameStackView.snp.remakeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalTo(avatarView.snp.trailing).offset(nameHidden ? 0 : 8)
            make.trailing.lessThanOrEqualToSuperview().offset(-8)
            make.height.equalTo(nameHidden ? 0 : 14)
        }
    }
}
