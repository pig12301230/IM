//
//  HongBaoMessageLCell.swift
//  ChatRoom
//
//  Created by Winston_Chuang on 2022/12/21.
//

import UIKit
import RxSwift
import Lottie

class HongBaoMessageLCell<T: HongBaoMessageCellVM>: MessageBaseLCell<T> {
    private lazy var hongBaoView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 4
        view.clipsToBounds = true
        return view
    }()
    
    private lazy var hongBaoTopView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    private lazy var hongBaoBottomView: UIView = {
        let view = UIView()
        view.theme_backgroundColor = Theme.c_09_white.rawValue
        return view
    }()
    
    private lazy var backgroundImgView: UIImageView = {
        let imgView = UIImageView()
        imgView.image = UIImage(named: "chat_bubble_envelope_x_new_envelope_bg")
        imgView.contentMode = .scaleAspectFill
        return imgView
    }()
    
    private lazy var hongBaoIcon: UIImageView = {
        let imgView = UIImageView()
        imgView.image = UIImage(named: "chat_bubble_envelope_x_icon_red_envelope_normal")
        imgView.contentMode = .scaleAspectFill
        return imgView
    }()
    
    private lazy var hongBaoLoadingPlaceholder: AnimationView = {
        let animationView = AnimationView(name: "red_envelope_placeholder")        
        animationView.loopMode = .loop
        animationView.play()
        return animationView
    }()
    
    private lazy var hongBaoBackgroundSkeleton: AnimationView = {
        let animationView = AnimationView(name: "red_envelope_skeleton")
        animationView.loopMode = .loop
        animationView.contentMode = .scaleToFill
        animationView.play()
        return animationView
    }()
    
    private lazy var lblHongBaoDescription: EdgeInsetsLabel = {
        let lbl = EdgeInsetsLabel()
        lbl.numberOfLines = 3
        lbl.lineBreakMode = .byTruncatingTail
        lbl.font = .midiumParagraphMediumLeft
        lbl.theme_textColor = Theme.c_09_white.rawValue
        return lbl
    }()
    
    private lazy var ruleBtn: UIButton = {
        let btn = UIButton()
        btn.setTitle(Localizable.checkRedEnvelopeTip, for: .normal)
        btn.theme_backgroundColor = Theme.c_09_white_25.rawValue
        btn.setTitleColor(Theme.c_09_white.rawValue.toColor(), for: .normal)
        btn.titleLabel?.font = .boldParagraphSmallCenter
        btn.clipsToBounds = true
        btn.layer.cornerRadius = 14
        return btn
    }()
    
    private lazy var lblOpen: UILabel = {
        let lbl = UILabel()
        lbl.font = .midiumParagraphMediumLeft
        lbl.theme_textColor = Theme.c_05_warning_700.rawValue
        return lbl
    }()
    
    private lazy var lblExpiredTime: UILabel = {
        let lbl = UILabel()
        lbl.font = .midiumParagraphSmallRight
        lbl.theme_textColor = Theme.c_07_neutral_400.rawValue
        return lbl
    }()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.hongBaoIcon.image = UIImage(named: "chat_bubble_envelope_x_icon_red_envelope_normal")
        self.backgroundImgView.image = UIImage(named: "chat_bubble_envelope_x_new_envelope_bg")
        self.backgroundImgView.backgroundColor = .clear
        self.lblHongBaoDescription.text = ""
        self.lblOpen.text = ""
        self.lblExpiredTime.text = String(format: Localizable.redEnvelopPeriod, "")
        self.removeSingleLoading()
    }
    
    override func setupViews() {
        super.setupViews()
        self.backgroundColor = .clear
        contentContainerView.addSubview(hongBaoView)
        hongBaoView.addSubviews([hongBaoTopView, hongBaoBottomView])
        hongBaoTopView.addSubviews([backgroundImgView, hongBaoIcon, lblHongBaoDescription])
        hongBaoBottomView.addSubviews([lblOpen, lblExpiredTime])
        
        hongBaoView.snp.makeConstraints { make in
            let edgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 0, right: 0)
            make.edges.equalTo(edgeInsets)
        }
        
        hongBaoTopView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(88)
        }
        
        hongBaoBottomView.snp.makeConstraints { make in
            make.top.equalTo(hongBaoTopView.snp.bottom)
            make.trailing.leading.bottom.equalToSuperview()
            make.height.equalTo(36)
        }
        
        backgroundImgView.snp.makeConstraints { make in
            make.width.equalTo(256)
            make.height.equalTo(88)
            make.edges.equalToSuperview()
        }
        
        hongBaoIcon.snp.makeConstraints { make in
            make.top.leading.equalTo(8)
            make.bottom.equalTo(-8)
            make.width.height.equalTo(72)
        }
        
        lblHongBaoDescription.snp.makeConstraints { make in
            make.top.equalTo(8)
            make.leading.equalTo(hongBaoIcon.snp.trailing)
            make.trailing.equalTo(-8)
        }
        
        // TODO: 第二階段
//        ruleBtn.snp.makeConstraints { make in
//            make.width.equalTo(80)
//            make.height.equalTo(28)
//            make.top.equalTo(lblHongBaoDescription.snp.bottom).offset(4)
//            make.bottom.trailing.equalTo(-8)
//        }
        
        lblOpen.snp.makeConstraints { make in
            make.top.leading.equalTo(8)
            make.bottom.equalTo(-8)
        }
        
        lblExpiredTime.snp.makeConstraints { make in
            make.top.equalTo(6)
            make.trailing.equalTo(-8)
            make.bottom.equalTo(-6)
        }
    }

    override func bindViewModel() {
        super.bindViewModel()
        
        self.hongBaoView.rx.click
            .throttle(.microseconds(300), scheduler: MainScheduler.instance)
            .bind { [weak self] in
                guard let self = self else { return }
                self.viewModel.clickHongBao()
            }
            .disposed(by: self.disposeBag)
        
        self.viewModel.content
            .compactMap { $0 }
            .bind { [weak self] content in
                guard let self = self else { return }
                self.updateView(content: content)
            }.disposed(by: disposeBag)
    }
    
    private func hideRuleBtn() {
        ruleBtn.snp.updateConstraints { make in
            make.height.equalTo(0)
        }
        ruleBtn.isHidden = true
    }
    
    private func setupSingleLoading() {
        self.hongBaoTopView.addSubview(hongBaoLoadingPlaceholder)
        self.hongBaoTopView.insertSubview(hongBaoBackgroundSkeleton, belowSubview: self.hongBaoIcon)
        self.hongBaoIcon.image = nil
        self.backgroundImgView.image = nil
        self.backgroundImgView.theme_backgroundColor = Theme.c_07_neutral_300.rawValue
        
        hongBaoBackgroundSkeleton.snp.makeConstraints { make in
            make.width.equalTo(backgroundImgView.snp.width)
            make.height.equalTo(backgroundImgView.snp.height)
        }
        
        hongBaoLoadingPlaceholder.snp.makeConstraints { make in
            make.width.equalTo(backgroundImgView.snp.width)
            make.height.equalTo(backgroundImgView.snp.height)
        }
    }
    
    private func removeSingleLoading() {
        hongBaoBackgroundSkeleton.removeFromSuperview()
        hongBaoLoadingPlaceholder.removeFromSuperview()
    }
    
    private func setSingleLoadingError() {
        self.backgroundImgView.theme_backgroundColor = Theme.c_07_neutral_300.rawValue
        self.backgroundImgView.image = nil
        self.hongBaoIcon.image = UIImage(named: "chat_bubble_envelope_x_icon_red_envelope_error")
    }
    
    private func updateView(content: HongBaoContent) {
        // 設定紅包樣式
        switch content.type {
        case .lucky: //客製化紅包
            guard let style = content.style else {
                // 顯示error的畫面
                setSingleLoadingError()
                break
            }
            
            switch style.selectStyle {
            case .single:
                if let strUrl = content.style?.backgroundImage {
                    setupSingleLoading()
                    ImageProcessor.shared.downloadImage(urlString: strUrl) { [weak self] result in
                        guard let self = self else { return }
                        self.removeSingleLoading()
                        switch result {
                        case .success(let value):
                            self.backgroundImgView.image = value.image
                            self.backgroundImgView.backgroundColor = .clear
                            self.hongBaoIcon.image = nil
                        case .failure:
                            self.hongBaoIcon.image = UIImage(named: "chat_bubble_envelope_x_icon_red_envelope_error")
                        }
                    }
                } else {
                    self.setSingleLoadingError()
                }
            case .custom:
                self.hongBaoIcon.image = UIImage(named: style.icon.imageName) ?? content.type.image
                self.backgroundImgView.image = UIImage(named: style.backgroundColor.imageName) ?? UIImage(named: "image_new_envelope_bg")
            }
        default:
            self.hongBaoIcon.image = content.type.image
            self.backgroundImgView.image = UIImage(named: "chat_bubble_envelope_x_new_envelope_bg")
        }
        
        self.lblHongBaoDescription.text = content.description
        self.lblExpiredTime.text = String(format: Localizable.redEnvelopPeriod, content.expiredDate.toString(format: Date.Formatter.yearToMinutes.rawValue))
        self.lblOpen.text = content.type.openedText
        
        self.lblHongBaoDescription.snp.remakeConstraints { make in
            make.leading.equalTo(hongBaoIcon.snp.trailing)
            make.trailing.equalTo(-8)
            if self.lblHongBaoDescription.maxNumberOfLines < 2 {
                make.centerY.equalToSuperview()
            } else {
                make.top.equalTo(8)
            }
        }
        // TODO: 第二階段
//        if content.type != .minesweeper {
//            hideRuleBtn()
//        }
    }
}
