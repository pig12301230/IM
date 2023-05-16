//
//  HongBaoView.swift
//  ChatRoom
//
//  Created by Winston_Chuang on 2022/12/26.
//

import Foundation
import UIKit
import RxSwift

class HongBaoView: BaseViewModelView<HongBaoViewVM> {

    private lazy var backgroundImg: UIImageView = {
        let imgView = UIImageView()
        imgView.image = UIImage(named: "envelope_popup_main")
        imgView.contentMode = .scaleAspectFill
        return imgView
    }()

    //MARK: - Sender View
    private lazy var senderStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 9
        return stackView
    }()

    private lazy var senderAvatar: UIImageView = {
        let imgView = UIImageView()
        imgView.contentMode = .scaleAspectFill
        imgView.layer.cornerRadius = 48
        imgView.clipsToBounds = true
        imgView.image = UIImage(named: "avatarsPhoto")
        return imgView
    }()

    private lazy var lblSenderName: UILabel = {
        let lbl = UILabel()
        lbl.font = .midiumParagraphLargeCenter
        lbl.theme_textColor = Theme.c_09_white.rawValue
        lbl.textAlignment = .center
        return lbl
    }()

    //MARK: - Send ContentView
    //TODO: 第二階段 新增掃雷
    private lazy var sendContentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 8
        return stackView
    }()

    private lazy var lblSendTitle: UILabel = {
        let lbl = UILabel()
        lbl.font = .boldParagraphLargeCenter
        lbl.theme_textColor = Theme.c_09_white_66.rawValue
        lbl.textAlignment = .center
        return lbl
    }()

    private lazy var sendImage: UIImageView = {
        let imgView = UIImageView()
        imgView.contentMode = .scaleAspectFill
        imgView.image = UIImage(named: "chat_bubble_envelope_x_icon_red_envelope_normal")
        return imgView
    }()

    private lazy var lblSendDescription: UILabel = {
        let lbl = UILabel()
        lbl.font = .boldParagraphGiantCenter
        lbl.theme_textColor = Theme.c_09_white.rawValue
        lbl.textAlignment = .center
        return lbl
    }()

    //MARK: - Result View
    private lazy var resultStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 8
        return stackView
    }()

    private lazy var lblResultTitle: UILabel = {
        let lbl = UILabel()
        lbl.font = .boldParagraphLargeCenter
        lbl.theme_textColor = Theme.c_09_white.rawValue
        lbl.textAlignment = .center
        return lbl
    }()

    private lazy var lblResultAmount: UILabel = {
        let lbl = UILabel()
        lbl.font = .boldParagraphGiantCenter.withSize(36)
        lbl.theme_textColor = Theme.c_09_white.rawValue
        lbl.textAlignment = .center
        return lbl
    }()

    private lazy var resultImage: UIImageView = {
        let imgView = UIImageView()
        imgView.contentMode = .scaleAspectFill
        imgView.image = UIImage(named: "chat_bubble_envelope_x_img_red_envelope_winning_2")
        return imgView
    }()

    private lazy var lblResultDescription: UILabel = {
        let lbl = UILabel()
        lbl.font = .boldParagraphLargeCenter
        lbl.theme_textColor = Theme.c_09_white_66.rawValue
        lbl.textAlignment = .center
        return lbl
    }()

    //MARK: - Bottom Button
    private lazy var openBtn: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(named: "envelope_button_open"), for: .normal)
        return btn
    }()

    private lazy var closeBtn: UIButton = {
        let btn = UIButton()
        btn.theme_backgroundColor = Theme.c_09_white_50.rawValue
        btn.setImage(UIImage(named: "iconIconCross"), for: .normal)
        btn.theme_tintColor = Theme.c_09_white.rawValue
        btn.clipsToBounds = true
        btn.layer.cornerRadius = 16
        return btn
    }()


    override func setupViews() {
        super.setupViews()
        self.theme_backgroundColor = Theme.c_06_danger_700.rawValue
        self.roundCorners(corners: [.layerMaxXMinYCorner, .layerMinXMinYCorner], radius: 24)
        self.addSubviews([backgroundImg, closeBtn])

        backgroundImg.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        closeBtn.snp.makeConstraints { make in
            make.width.height.equalTo(32)
            make.centerX.equalToSuperview()
            make.bottom.equalTo(self.safeAreaLayoutGuide.snp.bottom).offset(-8)
        }
    }

    override func bindViewModel() {
        super.bindViewModel()
        closeBtn.rx.tap.bind(to: viewModel.closeHongBaoView).disposed(by: disposeBag)
        openBtn.rx.click.throttle(.milliseconds(500), scheduler: MainScheduler.instance).bind { [weak self] in
            guard let self = self else { return }
            self.viewModel.openHongBao()
        }.disposed(by: disposeBag)

        viewModel.userHongBao.bind { [weak self] hongBao in
            guard let self = self else { return }
            if let hongBao = hongBao {
                self.removeSenderView()
                self.setupResultView(hongBao: hongBao)
            } else {
                self.removeResultView()
            }
        }.disposed(by: disposeBag)

        viewModel.setupSenderView.bind { [weak self] content in
            guard let self = self, let content = content else { return }
            self.removeResultView()
            self.setupSenderView(content: content)
        }.disposed(by: disposeBag)
    }

    private func setupResultView(hongBao: UserHongBaoModel) {
        self.addSubview(resultStackView)
        resultStackView.addArrangedSubviews([lblResultTitle, lblResultAmount, resultImage, lblResultDescription])

        resultStackView.snp.makeConstraints { make in
            make.top.equalTo(132)
            make.leading.equalTo(16)
            make.trailing.equalTo(-16)
            make.bottom.lessThanOrEqualTo(closeBtn.snp.top).offset(-16)
        }

        resultImage.snp.makeConstraints { make in
            make.width.height.equalTo(216)
        }

        resultStackView.setCustomSpacing(24, after: lblResultAmount)
        resultStackView.setCustomSpacing(24, after: resultImage)
        
        resultImage.image = hongBao.status.image
        let shouldHideAmount = (hongBao.amount.isEmpty || Double(hongBao.amount) == 0) && hongBao.status == .opened
        lblResultAmount.isHidden = shouldHideAmount
        lblResultTitle.isHidden = shouldHideAmount
        
        switch hongBao.type {
        case .lucky:
            lblResultTitle.text = hongBao.description
        default:
            lblResultTitle.text = hongBao.status.title
        }
        
        lblResultAmount.text = hongBao.status.amount ?? hongBao.amount
        lblResultDescription.text = hongBao.status.resultDescription
    }

    private func removeResultView() {
        resultStackView.removeFromSuperview()
    }

    private func setupSenderView(content: HongBaoContent) {
        self.addSubviews([senderStackView, openBtn])
        senderStackView.addArrangedSubviews([senderAvatar, lblSenderName])

        senderStackView.snp.makeConstraints { make in
            make.top.equalTo(64)
            make.centerX.equalToSuperview()
            make.leading.greaterThanOrEqualTo(16)
            make.trailing.lessThanOrEqualTo(-16)
        }

        senderAvatar.snp.makeConstraints { make in
            make.width.height.equalTo(96)
        }

        openBtn.snp.makeConstraints { make in
            make.height.equalTo(58)
            make.width.equalTo(144)
            make.centerX.equalToSuperview()
            make.bottom.equalTo(closeBtn.snp.top).offset(-48)
        }

        self.setupSendContentView(content: content)

        guard let senderID = content.senderID, let groupID = content.groupID else { return }

        guard let transceiver = DataAccess.shared.getGroupTransceiver(by: groupID, memberID: senderID) else { return }
        lblSenderName.text = transceiver.display

        if let url = URL(string: transceiver.avatarThumbnail) {
            self.senderAvatar.kf.setImage(with: url, placeholder: UIImage(named: "avatarsPhoto"))
        }
    }

    private func removeSenderView() {
        senderStackView.removeFromSuperview()
        openBtn.removeFromSuperview()
        sendContentStackView.removeFromSuperview()
    }

    private func setupSendContentView(content: HongBaoContent) {
        self.addSubview(sendContentStackView)
        sendContentStackView.addArrangedSubviews([lblSendTitle, sendImage, lblSendDescription])

        sendContentStackView.snp.makeConstraints { make in
            make.top.equalTo(senderStackView.snp.bottom).offset(23)
            make.leading.equalTo(16)
            make.trailing.equalTo(-16)
            make.bottom.lessThanOrEqualTo(openBtn.snp.top).offset(-16)
        }

        sendImage.snp.makeConstraints { make in
            make.width.height.equalTo(96)
        }

        lblSendTitle.text = Localizable.sendARedEnvelope
        sendImage.image = content.type.image
        lblSendDescription.text = content.description
    }
}
