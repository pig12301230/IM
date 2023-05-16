//
//  ReplyTextMessageLCell.swift
//  ChatRoom
//
//  Created by Winston_Chuang on 2022/3/4.
//

import UIKit
import RxSwift

class ReplyTextMessageLCell<T: ReplyTextMessageCellVM>: MessageBaseLCell<T> {
    
    private lazy var bgImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.setShadow(offset: CGSize(width: 0, height: 1), radius: 8, opacity: 1, color: Theme.c_08_black_10.rawValue.toCGColor())
        return imageView
    }()
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.distribution = .fill
        
        return stackView
    }()
    
    private lazy var replyContentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.distribution = .fill
        return stackView
    }()
    
    private lazy var replyMessageView: UIView = {
        let view = UIView()
        return view
    }()
    
    private lazy var deletedMessageView: UIView = {
        let view = UIView()
        return view
    }()
    
    private lazy var lblRecommandTitle: UILabel = {
        let label = UILabel()
        label.font = .midiumParagraphMediumLeft
        label.theme_textColor = Theme.c_08_black.rawValue
        label.numberOfLines = 2
        label.textAlignment = .left
        return label
    }()
    
    private lazy var lblExpert: UILabel = {
        let label = UILabel()
        label.theme_backgroundColor = Theme.c_09_white.rawValue
        label.font = .midiumParagraphTinyCenter
        label.textColor = .blue
        label.numberOfLines = 1
        label.textAlignment = .center
        label.text = Localizable.followPro
        return label
    }()
    
    private lazy var recommandView: UIView = {
        let view = UIView()
        return view
    }()
    
    private lazy var replyAvatarImgView: UIImageView = {
        let imgView = UIImageView()
        imgView.image = UIImage(named: "avatarsPhoto")
        imgView.contentMode = .scaleAspectFill
        return imgView
    }()
    
    private lazy var lblReplySender: UILabel = {
        let label = UILabel()
        label.font = .midiumParagraphMediumLeft
        label.theme_textColor = Theme.c_08_black.rawValue
        label.textAlignment = .left
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        
        return label
    }()
    
    private lazy var lblReplyContent: UILabel = {
        let label = UILabel()
        label.font = .midiumParagraphSmallLeft
        label.theme_textColor = Theme.c_08_black_33.rawValue
        label.textAlignment = .left
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    private lazy var replyImg: UIImageView = {
        let imgView = UIImageView()
        imgView.image = UIImage(named: "avatarsPhoto")
        imgView.contentMode = .scaleAspectFit
        return imgView
    }()
    
    private lazy var lblRemovedContent: UILabel = {
        let label = UILabel()
        label.font = .midiumParagraphSmallLeft
        label.theme_textColor = Theme.c_08_black_33.rawValue
        label.textAlignment = .left
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        
        label.text = Localizable.messageRetracted
        return label
    }()
    
    private lazy var splitView: UIView = {
        let view = UIView()
        view.theme_backgroundColor = Theme.c_07_neutral_100.rawValue

        return view
    }()
    
    private lazy var textView: MessageTextView = {
        let textView = MessageTextView()
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 20, bottom: 8, right: 12)
        return textView
    }()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.contentView.layoutIfNeeded()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.replyImg.image = nil
        self.replyAvatarImgView.image = nil
        self.lblRemovedContent.text = Localizable.messageRetracted
    }
    
    override func setupViews() {
        super.setupViews()
        stackView.addArrangedSubviews([replyMessageView, deletedMessageView, splitView, textView])
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(scrollToMessage))
        replyMessageView.addGestureRecognizer(tapGesture)
        recommandView.addSubviews([lblExpert, lblRecommandTitle])
        replyContentStackView.addArrangedSubviews([lblReplySender, recommandView, lblReplyContent])
        replyMessageView.addSubviews([replyAvatarImgView, replyContentStackView, replyImg])
        deletedMessageView.addSubview(lblRemovedContent)
        
        contentContainerView.addSubview(bgImageView)
        contentContainerView.addSubview(stackView)
        
        deletedMessageView.isHidden = true
        recommandView.isHidden = true
        replyMessageView.isHidden = false
        
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        replyMessageView.snp.makeConstraints { make in
            make.width.equalTo(MessageContentSize.maxWidth)
        }
        
        deletedMessageView.snp.makeConstraints { make in
            make.height.equalTo(34)
            make.width.equalTo(MessageContentSize.maxWidth)
        }
        
        splitView.snp.makeConstraints { make in
            make.height.equalTo(1)
        }
        
        bgImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        lblRemovedContent.snp.makeConstraints { make in
            make.height.equalTo(18)
            make.top.equalTo(8)
            make.leading.equalTo(20)
            make.bottom.equalTo(-8)
            make.trailing.equalTo(-12)
        }
        
        replyAvatarImgView.snp.makeConstraints { make in
            make.top.equalTo(12)
            make.leading.equalTo(20)
            make.height.width.equalTo(24)
        }
        replyAvatarImgView.clipsToBounds = true
        replyAvatarImgView.layer.cornerRadius = 12
        
        replyContentStackView.snp.makeConstraints { make in
            make.top.equalTo(8)
            make.leading.equalTo(replyAvatarImgView.snp.trailing).offset(8)
            make.trailing.equalTo(replyImg.snp.leading)
            make.bottom.lessThanOrEqualTo(-8)
        }
        
        lblReplySender.snp.makeConstraints { make in
            make.height.equalTo(20)
        }
        
        lblReplyContent.snp.makeConstraints { make in
            make.height.equalTo(18)
        }
        
        lblExpert.snp.makeConstraints { make in
            make.width.equalTo(56)
            make.height.equalTo(20)
            make.top.leading.equalToSuperview()
            make.bottom.lessThanOrEqualTo(0)
        }
        lblExpert.clipsToBounds = true
        lblExpert.layer.cornerRadius = 10
        
        lblRecommandTitle.snp.makeConstraints { make in
            make.leading.equalTo(lblExpert.snp.trailing).offset(4)
            make.top.bottom.trailing.equalToSuperview()
        }
        
        replyImg.snp.makeConstraints { make in
            make.width.height.equalTo(60)
            make.top.equalTo(8)
            make.trailing.equalTo(-12)
            make.bottom.lessThanOrEqualTo(-8)
        }
        
        textView.snp.makeConstraints { make in
            make.height.equalTo(40)
        }
    }
    
    override func bindViewModel() {
        super.bindViewModel()
        
        self.viewModel.config
            .observe(on: MainScheduler.instance)
            .subscribeSuccess { [unowned self] config in
                self.updateBackgroundImage(by: config.order)
            }.disposed(by: self.disposeBag)
        
        // Thread Message View
        self.viewModel.deletedMessage
            .observe(on: MainScheduler.instance)
            .subscribeSuccess { [unowned self] messageID in
                guard var threadMessage = self.viewModel.threadMessage.value else {
                    viewModel.threadMessage.accept(nil)
                    return
                }
                if messageID == threadMessage.id {
                    if DataAccess.shared.isExistMessageInDatabase(by: messageID) {
                        threadMessage.deleted = true
                        viewModel.threadMessage.accept(threadMessage)
                    } else {
                        viewModel.threadMessage.accept(nil)
                    }
                }
            }.disposed(by: disposeBag)
        
        self.viewModel.threadMessage
            .observe(on: MainScheduler.instance)
            .subscribeSuccess { [unowned self] message in
                updateReplyContent(by: message)
            }.disposed(by: self.disposeBag)
        
        // Text Message
        self.viewModel.attributedMessage
            .observe(on: MainScheduler.instance)
            .subscribeSuccess { [unowned self] attrMessage in
                self.textView.attributedText = attrMessage
            }.disposed(by: self.disposeBag)
        
        self.viewModel.textHeight
            .observe(on: MainScheduler.instance)
            .subscribeSuccess { [unowned self] height in
                self.textView.snp.remakeConstraints { make in
                    make.height.equalTo(height)
                }
            }.disposed(by: self.disposeBag)
    }
    
    override func updateViews() {
        super.updateViews()
        self.textView.snp.remakeConstraints { make in
            make.height.equalTo(self.viewModel.textHeight.value)
        }
        
        guard let viewMoedl = viewModel else { return }
        if let threadMessage = viewMoedl.threadMessage.value {
            let type = threadMessage.deleted ? nil : threadMessage.messageType
            self.resetConstraints(with: type)
        } else {
            self.resetConstraints(with: nil)
        }
    }
    
    @objc private func scrollToMessage() {
        guard let threadID = viewModel.threadMessage.value?.id else { return }
        viewModel.scrollToMessage.onNext(threadID)
    }
    
    private func resetConstraints(with type: MessageType?) {
        replyMessageView.isHidden = (type == nil)
        deletedMessageView.isHidden = (type != nil)
        recommandView.isHidden = (type != .recommend)
        
        replyImg.snp.updateConstraints { make in
            make.width.height.equalTo((type == .image) ? 60 : 0)
        }
    }
    
    private func updateReplyContent(by message: MessageModel?) {

        if let message = message {
            
            if message.deleted {
                lblRemovedContent.text = Localizable.messageDeleted
                self.resetConstraints(with: nil)
                return
            }
            
            if let url = URL(string: viewModel.threadSender?.avatarThumbnail ?? "") {
                replyAvatarImgView.kf.setImage(with: url, placeholder: UIImage(named: "avatarsPhoto"))
            } else {
                replyAvatarImgView.image = UIImage(named: "avatarsPhoto")
            }
            
            lblReplySender.text = viewModel.threadSender?.display
            if message.messageType == .text {
                lblReplyContent.text = message.message
            } else if message.messageType == .image {
                lblReplyContent.text = Localizable.messageReplyPicture
                if let fileID = viewModel.getFileID(by: message.id).first,
                   let url = self.viewModel.getFileUrl(by: fileID) {
                    replyImg.kf.setImage(with: url, placeholder: UIImage(named: "iconIconPicture"))
                }
            } else if message.messageType == .recommend {
                guard let template = message.template, let option = template.option else {
                    return
                }
                lblRecommandTitle.text = template.game
                lblReplyContent.text = String(format: Localizable.templatePeriodNumberIOS, template.num, template.betType, option.text)
            } else {
                // 不該出現的狀態
            }
            self.resetConstraints(with: message.messageType)
        } else {
            self.resetConstraints(with: nil)
            guard let threadID = self.viewModel.baseModel.message.threadID else {
                replyMessageView.isHidden = true
                deletedMessageView.isHidden = false
                return
            }
            viewModel.refetchThreadMessage(groupID: self.viewModel.baseModel.message.groupID, messageID: threadID)
        }
    }
    
    private func updateBackgroundImage(by order: MessageOrder) {
        let imageName = (order == .first ? "receive_bubble_pointer.9" : "receive_bubble.9")
        let capInset = UIEdgeInsets(top: 26, left: 16, bottom: 12, right: 8)
        let bgImage = UIImage(named: imageName)?.resizableImage(withCapInsets: capInset, resizingMode: .stretch)
        self.bgImageView.image = bgImage
    }
}
