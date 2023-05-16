//
//  ReplyMessageView.swift
//  ChatRoom
//
//  Created by Winston_Chuang on 2022/3/3.
//

import Foundation
import UIKit

class ReplyMessageView: BaseViewModelView<ReplyMessageViewVM> {
    
    private lazy var replyIcon: UIImageView = {
        let imgView = UIImageView()
        imgView.image = UIImage(named: "iconIconArrowReply")?.withRenderingMode(.alwaysTemplate)
        imgView.tintColor = Theme.c_07_neutral_800.rawValue.toColor()
        return imgView
    }()
    
    private lazy var messageImg: UIImageView = {
        let imgView = UIImageView()
        return imgView
    }()
    
    private lazy var lblMessageSender: UILabel = {
        let label = UILabel()
        label.font = .boldParagraphMediumLeft
        label.theme_textColor = Theme.c_10_grand_1.rawValue
        label.textAlignment = .left
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        
        return label
    }()
    
    private lazy var lblMessage: UILabel = {
        let label = UILabel()
        label.font = .midiumParagraphSmallLeft
        label.theme_textColor = Theme.c_10_grand_2.rawValue
        label.textAlignment = .left
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        
        label.text = ""
        return label
    }()
    
    private lazy var closeBtn: UIButton = {
        let button = UIButton()
        button.theme_tintColor = Theme.c_07_neutral_500.rawValue
        button.setImage(UIImage(named: "iconIconCross"), for: .normal)
        return button
    }()
    
    override func setupViews() {
        super.setupViews()
        self.theme_backgroundColor = Theme.c_07_neutral_50.rawValue
        self.clipsToBounds = true
        self.layer.cornerRadius = 8
        
        self.addSubviews([replyIcon, messageImg, lblMessageSender, lblMessage, closeBtn])
        
        replyIcon.snp.makeConstraints { make in
            make.width.height.equalTo(24)
            make.top.leading.equalTo(16)
        }
        
        messageImg.snp.makeConstraints { make in
            make.width.height.equalTo(40)
            make.top.equalTo(16)
            make.leading.equalTo(replyIcon.snp.trailing).offset(8)
        }
        
        lblMessageSender.snp.makeConstraints { make in
            make.top.equalTo(18)
            make.leading.equalTo(messageImg.snp.trailing).offset(8)
            make.height.equalTo(20)
        }
        
        lblMessage.snp.makeConstraints { make in
            make.top.equalTo(lblMessageSender.snp.bottom)
            make.leading.equalTo(messageImg.snp.trailing).offset(8)
            make.height.equalTo(18)
            make.width.equalTo(lblMessageSender.snp.width)
        }
        
        closeBtn.snp.makeConstraints { make in
            make.width.height.equalTo(24)
            make.top.equalTo(16)
            make.trailing.equalTo(-16)
            make.leading.equalTo(lblMessageSender.snp.trailing).offset(8)
        }
    }
    
    override func bindViewModel() {
        closeBtn.rx.click.bind(to: self.viewModel.closeReplyMessage).disposed(by: disposeBag)
        
        self.viewModel.deleteMessage.subscribeSuccess { [weak self] deletedID in
            guard let self = self else { return }
            if deletedID == self.viewModel.replyMessage.value?.id {
                self.viewModel.replyMessage.accept(nil)
            }
        }.disposed(by: disposeBag)
        
        self.viewModel.replyMessage.subscribeSuccess { [unowned self] message in
            guard let message = message else {
                self.isHidden = true
                return
            }
            self.isHidden = false
            if let senderName = self.viewModel.transceivers.first(where: { $0.userID == message.userID })?.display {
                lblMessageSender.text = String(format: Localizable.replyNameIOS, senderName)
            }
            
            switch message.messageType {
            case .text:
                lblMessage.text = message.message
                
                messageImg.snp.updateConstraints {
                    $0.width.equalTo(0)
                }
            case .image:
                lblMessage.text = Localizable.messageReplyPicture
                if let fileID = message.fileIDs.first,
                   let url = self.viewModel.getFileUrl(by: fileID) {
                    messageImg.kf.setImage(with: url)
                }
                
                messageImg.snp.updateConstraints {
                    $0.width.equalTo(40)
                }
            case .recommend:
                lblMessage.text = message.template?.game
                
                messageImg.snp.updateConstraints {
                    $0.width.equalTo(0)
                }
            default:
                // 不合理的 type 先藏起
                self.viewModel.replyMessage.accept(nil)
            }
        }.disposed(by: disposeBag)
    }
    
}
