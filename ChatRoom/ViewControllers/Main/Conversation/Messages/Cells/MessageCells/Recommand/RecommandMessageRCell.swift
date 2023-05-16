//
//  RecommandMessageRCell.swift
//  ChatRoom
//
//  Created by Saffi Peng on 2021/7/20.
//

import UIKit
import RxSwift
import SwiftTheme

class RecommandMessageRCell<T: RecommandMessageCellVM>: MessageBaseRCell<T> {

    private lazy var messageBgImage: UIImageView = {
        let imageView = UIImageView()
        imageView.setShadow(offset: CGSize(width: 0, height: 1), radius: 8, opacity: 1, color: Theme.c_08_black_10.rawValue.toCGColor())
        return imageView
    }()

    private lazy var stockContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private lazy var lblStocksTitle: UILabel = {
        let label = UILabel()
        label.font = .boldParagraphLargeLeft
        label.theme_textColor = Theme.c_03_tertiary_0_500.rawValue
        return label
    }()

    private lazy var lblSubTitle: UILabel = {
        let label = UILabel()
        label.font = .regularParagraphSmallLeft
        label.theme_textColor = Theme.c_10_grand_2.rawValue
        return label
    }()

    private lazy var outlineContainerView: UIView = {
        let view = UIView()
        view.theme_backgroundColor = Theme.c_07_neutral_0.rawValue
        view.layer.cornerRadius = 4
        return view
    }()

    private lazy var lblOutline: UILabel = {
        let label = UILabel()
        label.font = .midiumParagraphSmallLeft
        label.textAlignment = .center
        label.numberOfLines = 0
        label.layer.cornerRadius = 4
        return label
    }()

    private lazy var lblDescription: UILabel = {
        let label = UILabel()
        label.font = .regularParagraphSmallLeft
        label.theme_textColor = Theme.c_10_grand_1.rawValue
        label.numberOfLines = 0
        return label
    }()

    private lazy var btnAction: UIButton = {
        let button = UIButton()
        button.theme_backgroundColor = Theme.c_03_tertiary_0_500.rawValue
        button.setTitle(Localizable.followPro, for: .normal)
        button.titleLabel?.font = .boldParagraphSmallLeft
        button.setImage(UIImage(named: "iconIconPlusCircleFill"), for: .normal)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 16)
        button.layer.cornerRadius = 4
        return button
    }()

    override func setupViews() {
        super.setupViews()

        self.backgroundColor = .clear

        contentContainerView.addSubview(messageBgImage)
        contentContainerView.addSubview(stockContainerView)

        // 不會出現resend，由後台直接丟出訊息
        self.btnResend.snp.remakeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-8)
            make.width.height.equalTo(0)
        }

        self.messageBgImage.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(MessageContentSize.maxWidth)
        }

        let edgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 20)
        self.stockContainerView.snp.makeConstraints { make in
            make.edges.equalTo(edgeInsets)
        }

        self.stockContainerView.addSubview(lblStocksTitle)
        self.stockContainerView.addSubview(lblSubTitle)
        self.stockContainerView.addSubview(outlineContainerView)
        self.stockContainerView.addSubview(lblDescription)
        self.stockContainerView.addSubview(btnAction)

        self.outlineContainerView.addSubview(lblOutline)

        self.lblStocksTitle.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(24)
        }

        self.lblSubTitle.snp.makeConstraints { make in
            make.top.equalTo(lblStocksTitle.snp.bottom)
            make.leading.trailing.equalTo(lblStocksTitle)
            make.height.equalTo(18)
        }

        self.outlineContainerView.snp.makeConstraints { make in
            make.top.equalTo(lblSubTitle.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview()
        }

        self.lblOutline.snp.makeConstraints { make in
            make.top.leading.equalTo(4)
            make.trailing.bottom.equalTo(-4)
            make.height.greaterThanOrEqualTo(26)
        }

        self.lblDescription.snp.makeConstraints {
            $0.top.equalTo(lblOutline.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview()
        }

        self.btnAction.snp.makeConstraints {
            $0.top.equalTo(lblDescription.snp.bottom).offset(12)
            $0.bottom.equalToSuperview()
            $0.centerX.equalToSuperview()
            $0.width.equalTo(136)
            $0.height.equalTo(40)
        }
    }

    override func bindViewModel() {
        super.bindViewModel()

        self.viewModel.config.observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] config in
            self.updateTextBackgroundImage(by: config.order)
        }.disposed(by: disposeBag)

        // Stock Message
        self.viewModel.template.observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] template in
            guard let template = template else {
                return
            }
            self.updateView(with: template)
        }.disposed(by: disposeBag)
        
        self.btnAction.rx.controlEvent(.touchUpInside).subscribeSuccess { _ in
            self.viewModel.gotoRecommand()
        }.disposed(by: self.disposeBag)
    }
    
    override func resetViewSetting() {
        super.resetViewSetting()
        self.btnAction.isUserInteractionEnabled = true
    }
}

// MARK: - Message Background Image
private extension RecommandMessageRCell {
    func updateTextBackgroundImage(by order: MessageOrder) {
        let capInset = UIEdgeInsets(top: 26, left: 8, bottom: 12, right: 16)
        let bgImage = UIImage(named: "send_bubble_pointer.9")?.resizableImage(withCapInsets: capInset, resizingMode: .stretch)
        self.messageBgImage.image = bgImage
    }
}

// MARK: - Message Views
private extension RecommandMessageRCell {
    func updateView(with template: TemplateModel) {
        guard let option = template.option else { return }
        self.lblStocksTitle.text = template.game
        self.lblSubTitle.text = template.freq
        self.lblDescription.text = template.description

        let string = String(format: Localizable.templatePeriodNumberIOS, template.num, template.betType, option.text)
        let attrString = NSMutableAttributedString(string: string)
        attrString.recoverColor(to: Theme.c_10_grand_1.rawValue.toColor())
        attrString.recoverFont(to: .midiumParagraphSmallLeft)
        attrString.setColor(color: UIColor(option.color), forText: option.text)
        self.lblOutline.attributedText = attrString

        guard let action = template.action else { return }
        if !action.icon.isEmpty {
            self.btnAction.setImage(UIImage(named: action.icon), for: .normal)
        }
        if !action.label.isEmpty {
            self.btnAction.setTitle(action.label, for: .normal)
        }
    }
}
