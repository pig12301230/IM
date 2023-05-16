//
//  AnnouncementView.swift
//  ChatRoom
//
//  Created by Winston_Chuang on 2022/2/24.
//

import Foundation
import UIKit
import RxSwift

class AnnouncementView: BaseViewModelView<AnnouncementViewModel> {
    
    private lazy var backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.distribution = .fill
        stackView.axis = .vertical
        stackView.backgroundColor = .clear
        stackView.clipsToBounds = true
        stackView.layer.cornerRadius = 8
        return stackView
    }()
    
    private lazy var announceIcon: UIImageView = {
        let imgView = UIImageView()
        imgView.tintColor = Theme.c_07_neutral_800.rawValue.toColor()
        imgView.image = UIImage(named: "iconIconAnnouncement")?.withRenderingMode(.alwaysTemplate)
        return imgView
    }()
    
    private lazy var lblMessage: UILabel = {
        let label = UILabel()
        label.font = .midiumParagraphMediumLeft
        label.theme_textColor = Theme.c_10_grand_1.rawValue
        label.numberOfLines = 1
        return label
    }()
    
    private lazy var expandBtn: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(named: "iconArrowsChevronDown"), for: .normal)
        return btn
    }()
    
    private lazy var expandBottomView: UIView = {
        let view = UIView()
        view.theme_backgroundColor = Theme.c_07_neutral_50.rawValue
        return view
    }()
    
    private lazy var collapseBtn: UIButton = {
       let btn = UIButton()
        btn.setImage(UIImage(named: "iconArrowsChevronUp"), for: .normal)
        return btn
    }()
    
    private lazy var collapseView: UIView = {
        let view = UIView()
        view.theme_backgroundColor = Theme.c_07_neutral_50.rawValue
        return view
    }()
    
    private lazy var expandView: UIStackView = {
        let stackView = UIStackView()
        stackView.distribution = .fill
        stackView.axis = .vertical
        stackView.backgroundColor = Theme.c_07_neutral_100.rawValue.toColor()
        stackView.spacing = 1
        return stackView
    }()
    
    override func setupViews() {
        addSubview(backgroundView)
        backgroundView.addSubview(stackView)
        
        stackView.addArrangedSubviews([collapseView, expandView])
        collapseView.addSubviews([announceIcon, lblMessage, expandBtn])
        expandBottomView.addSubview(collapseBtn)
        
        let collapseTapGesture = UITapGestureRecognizer(target: self, action: #selector(collapse))
        backgroundView.addGestureRecognizer(collapseTapGesture)
        
        let scrollTapGesture = UITapGestureRecognizer(target: self, action: #selector(scrollTo))
        collapseView.addGestureRecognizer(scrollTapGesture)
        
        expandBtn.addTarget(self, action: #selector(expand), for: .touchUpInside)
        collapseBtn.addTarget(self, action: #selector(collapse), for: .touchUpInside)
        
        backgroundView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        collapseBtn.snp.makeConstraints {
            $0.width.height.equalTo(24)
            $0.top.equalTo(8)
            $0.trailing.equalTo(-16)
            $0.bottom.equalTo(-8)
        }
        
        announceIcon.snp.makeConstraints {
            $0.width.height.equalTo(24)
            $0.top.leading.equalTo(16)
            $0.bottom.equalTo(-16)
        }
        
        lblMessage.snp.makeConstraints {
            $0.centerY.equalTo(announceIcon.snp.centerY)
            $0.leading.equalTo(announceIcon.snp.trailing).offset(16)
            $0.trailing.equalTo(expandBtn.snp.leading).offset(-23)
        }
        
        expandBtn.snp.makeConstraints {
            $0.width.height.equalTo(24)
            $0.trailing.equalTo(-16)
            $0.centerY.equalToSuperview()
        }
        
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
    }
    
    override func bindViewModel() {
        viewModel.announcements.subscribeSuccess { [unowned self] announcements in
            guard !announcements.isEmpty else {
                viewModel.isExpand.accept(false)
                return
            }
            
            expandView.removeAllArrangedSubviews()
            for announcement in announcements {
                if let message = announcement.message {
                    let transceiver = self.viewModel.transceivers.first(where: { $0.userID == message.userID })
                    let messageView = AnnounceMessageView(message: message,
                                                          messageSender: transceiver?.display,
                                                          hasPermission: viewModel.hasPermission)
                    expandView.addArrangedSubview(messageView)
                    
                    messageView.scrollToMessage
                        .bind(to: viewModel.scrollToMessage)
                        .disposed(by: disposeBag)
                    messageView.unpinMessage
                        .bind(to: viewModel.unpinMessage)
                        .disposed(by: disposeBag)
                }
            }
            
            self.expandView.addArrangedSubview(expandBottomView)
            
            expandBottomView.snp.makeConstraints { make in
                make.height.equalTo(40)
            }
            
            guard let announcement = announcements.first,
                  let message = announcement.message else {
                      return
                  }
            var content: String
            switch message.messageType {
            case .image:
                content = Localizable.messageReplyPicture
            case .recommend:
                content = Localizable.followBetMessage
            default:
                content = message.message.replacingOccurrences(of: "\n", with: " ")
            }
            lblMessage.text = content
        }.disposed(by: disposeBag)
        
        viewModel.isExpand
            .subscribeSuccess { [unowned self] isExpand in
                if isExpand {
                    announceIcon.snp.remakeConstraints {
                        $0.width.height.equalTo(0)
                    }
                } else {
                    announceIcon.snp.remakeConstraints {
                        $0.width.height.equalTo(24)
                        $0.top.leading.equalTo(16)
                        $0.bottom.equalTo(-16)
                    }
                }
                expandView.isHidden = !isExpand
                collapseView.isHidden = isExpand
            }.disposed(by: disposeBag)
    }
    
    @objc func collapse() {
        viewModel.isExpand.accept(false)
    }
    
    @objc func expand() {
        viewModel.isExpand.accept(true)
    }
    
    @objc func scrollTo() {
        guard let announcement = viewModel.announcements.value.first,
              let message = announcement.message else {
                  return
              }
        viewModel.scrollToMessage.onNext(message.id)
    }
}

class AnnounceMessageView: UIView {
    private var announceMessageView: UIView = {
        let view = UIView()
        view.theme_backgroundColor = Theme.c_07_neutral_50.rawValue
        return view
    }()
    
    private var announceIcon: UIImageView = {
        let imgView = UIImageView()
        imgView.tintColor = Theme.c_07_neutral_800.rawValue.toColor()
        imgView.image = UIImage(named: "iconIconAnnouncement")?.withRenderingMode(.alwaysTemplate)
        
        return imgView
    }()
    
    private var lblMessage: UILabel = {
        let label = UILabel()
        label.theme_textColor = Theme.c_10_grand_1.rawValue
        label.font = .boldParagraphMediumLeft
        label.numberOfLines = 1
        return label
    }()
    
    private var lblUserName: UILabel = {
        let label = UILabel()
        label.theme_textColor = Theme.c_10_grand_2.rawValue
        label.font = .midiumParagraphSmallLeft
        label.numberOfLines = 1
        return label
    }()
    
    private var unpinBtn: UIButton = {
        let button = UIButton()
        button.setTitle(Localizable.doNotShowAgain, for: .normal)
        button.setTitleColor(Theme.c_01_primary_0_500.rawValue.toColor(), for: .normal)
        button.titleLabel?.font = .boldParagraphMediumLeft
        return button
    }()
    
    let scrollToMessage: PublishSubject<String> = .init()
    let unpinMessage: PublishSubject<String> = .init()
    private var message: MessageModel!
    private var hasPermission: Bool!
    
    init(message: MessageModel, messageSender: String?, hasPermission: Bool) {
        super.init(frame: .zero)
        self.message = message
        self.hasPermission = hasPermission
        
        var content: String
        switch message.messageType {
        case .image:
            content = Localizable.messageReplyPicture
        case .recommend:
            content = Localizable.followBetMessage
        default:
            content = message.message.replacingOccurrences(of: "\n", with: " ")
        }
        lblMessage.text = content
        lblUserName.text = messageSender ?? ""
        
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func scrollTo() {
        scrollToMessage.onNext(message.id)
    }
    
    @objc func unpin() {
        unpinMessage.onNext(message.id)
    }
    
    private func setupView() {
        addSubview(announceMessageView)
        let gesture = UITapGestureRecognizer(target: self, action: #selector(scrollTo))
        announceMessageView.addGestureRecognizer(gesture)
        announceMessageView.addSubviews([announceIcon, lblMessage, lblUserName, unpinBtn])
        unpinBtn.addTarget(self, action: #selector(unpin), for: .touchUpInside)
        unpinBtn.isHidden = !self.hasPermission
        
        announceMessageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        announceIcon.snp.makeConstraints { make in
            make.width.height.equalTo(24)
            make.top.leading.equalTo(16)
        }
        
        lblMessage.snp.makeConstraints { make in
            make.top.equalTo(18)
            make.leading.equalTo(announceIcon.snp.trailing).offset(8)
            make.trailing.equalTo(-48)
            make.height.equalTo(20)
        }
        
        lblUserName.snp.makeConstraints { make in
            make.top.equalTo(lblMessage.snp.bottom)
            make.leading.equalTo(48)
            make.trailing.equalTo(-48)
            make.height.equalTo(18)
        }
        
        unpinBtn.snp.makeConstraints { make in
            make.top.equalTo(lblUserName.snp.bottom).offset(4)
            make.leading.equalTo(48)
            make.bottom.equalTo(-8)
            make.height.equalTo(20)
        }
        
        if !hasPermission {
            lblUserName.snp.remakeConstraints {
                $0.top.equalTo(lblMessage.snp.bottom)
                $0.leading.equalTo(48)
                $0.trailing.equalTo(-48)
                $0.bottom.equalTo(-16)
                $0.height.equalTo(18)
            }
            
            unpinBtn.snp.remakeConstraints {
                $0.height.equalTo(0)
            }
        }
    }
}
