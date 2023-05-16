//
//  MessageBaseRCell.swift
//  ChatRoom
//
//  Created by Saffi Peng on 2021/7/20.
//

import UIKit
import RxSwift

class MessageBaseRCell<T: MessageBaseCellVM>: ConversationBaseCell<T> {

    lazy var btnResend: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "iconIconRetry"), for: .normal)
        button.theme_backgroundColor = Theme.c_07_neutral_50.rawValue
        button.imageEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        button.layer.cornerRadius = 16
        button.clipsToBounds = true
        button.isHidden = true
        return button
    }()

    lazy var contentContainerView: UIView = {
        let view = UIView()
        return view
    }()

    lazy var loadingClockView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "iconIconClock"))
        imageView.isHidden = true
        return imageView
    }()

    lazy var lblDateTime: UILabel = {
        let label = UILabel()
        label.font = .regularParagraphTinyLeft
        label.theme_textColor = Theme.c_07_neutral_400.rawValue
        label.textAlignment = .right
        return label
    }()

    lazy var lblStatus: UILabel = {
        let label = UILabel()
        label.font = .regularParagraphTinyLeft
        label.theme_textColor = Theme.c_07_neutral_400.rawValue
        label.textAlignment = .right
        label.text = Localizable.read
        label.isHidden = true
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
        self.disposeBag = DisposeBag()
    }

    override func setupViews() {
        super.setupViews()

        containerView.addSubview(btnResend)
        containerView.addSubview(contentContainerView)
        containerView.addSubview(loadingClockView)
        containerView.addSubview(lblDateTime)
        containerView.addSubview(lblStatus)
        containerView.addSubview(emojiBtn)
        containerView.addSubview(emojiFootView)

        self.btnResend.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-8)
            make.width.height.equalTo(32)
        }

        self.contentContainerView.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview()
//            make.bottom.equalToSuperview().inset(16)
            make.width.lessThanOrEqualTo(MessageContentSize.maxWidth)
        }

        self.loadingClockView.snp.makeConstraints { make in
            make.trailing.equalTo(contentContainerView.snp.leading).offset(-4)
            make.bottom.equalTo(contentContainerView)
            make.width.height.equalTo(10)
        }

        self.lblDateTime.snp.makeConstraints { make in
            make.trailing.equalTo(loadingClockView.snp.leading)
            make.bottom.equalTo(contentContainerView)
            make.width.equalTo(50)
            make.height.equalTo(10)
        }

        self.lblStatus.snp.makeConstraints { make in
            make.leading.trailing.width.height.equalTo(lblDateTime)
            make.bottom.equalTo(lblDateTime.snp.top)
        }
        
        self.emojiBtn.snp.makeConstraints { make in
            make.trailing.equalTo(contentContainerView.snp.leading).offset(-4)
            make.top.equalToSuperview()
            make.width.height.equalTo(16)
        }
        
        self.emojiFootView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(8)
            make.height.equalTo(24)
            make.top.equalTo(contentContainerView.snp.bottom).offset(-12)
            make.bottom.equalToSuperview()
        }
    }

    override func bindViewModel() {
        super.bindViewModel()

        self.contentContainerView.rx.longPress.bind(to: longPress).disposed(by: disposeBag)
        self.rx.doubleTap.bind(to: doubleTap).disposed(by: disposeBag)
        // Time＆Read
        self.viewModel.dateTime.bind(to: self.lblDateTime.rx.text).disposed(by: self.disposeBag)
        self.viewModel.isRead.observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] isRead in
            self.lblStatus.isHidden = !isRead
        }.disposed(by: self.disposeBag)

        // MessageStatus
        self.viewModel.isFailure.observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] failure in
            self.updateStatus(with: failure)
        }.disposed(by: self.disposeBag)

        self.viewModel.isLoading.observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] loading in
            self.updateLoading(with: loading)
        }.disposed(by: self.disposeBag)
        
        // Emoji
        self.viewModel.updateEmojiFootView.observe(on: MainScheduler.instance).subscribeSuccess { [weak self] (groupType, emojiContentModel) in
            guard let self = self, let groupType = groupType, let emojiContentModel = emojiContentModel else { return }
            self.emojiFootView.isHidden = emojiContentModel.totalCount == 0
            self.emojiFootView.config(emojiContentModel: emojiContentModel, type: groupType)
        }.disposed(by: self.disposeBag)
        
        self.emojiFootView.rx.click
            .observe(on: MainScheduler.instance)
            .bind { [weak self] in
                guard let self = self else { return }
                self.viewModel.openEmojiList()
            }
            .disposed(by: disposeBag)
        
        // MARK: - click signal
        self.btnResend.rx.controlEvent(.touchUpInside).subscribeSuccess { [unowned self] in
            self.viewModel.doResendAction()
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
        self.btnResend.isHidden = true
        self.loadingClockView.isHidden = true
        self.emojiFootView.isHidden = true
        self.emojiFootView.subviews.forEach({ $0.removeFromSuperview() })
    }
}

// MARK: - Message Status
extension MessageBaseRCell {
    func updateStatus(with failure: Bool) {
        self.btnResend.isHidden = !failure
//            self.lblStatus.isHidden = failure
        self.lblDateTime.isHidden = failure

        self.contentContainerView.snp.remakeConstraints { make in
            make.top.equalToSuperview()
            make.trailing.equalTo(failure ? -48 : 0)
            make.bottom.equalToSuperview().offset(-12)
            make.width.lessThanOrEqualTo(MessageContentSize.maxWidth)
        }
    }

    func updateLoading(with loading: Bool) {
        self.loadingClockView.isHidden = !loading
        self.loadingClockView.snp.updateConstraints { make in
            make.width.equalTo(loading ? 10 : 0)
        }
    }
}
