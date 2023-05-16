//
//  TextMessageRCell.swift
//  ChatRoom
//
//  Created by Saffi Peng on 2021/7/19.
//

import UIKit
import RxSwift
import SwiftTheme

class TextMessageRCell<T: TextMessageCellVM>: MessageBaseRCell<T> {

    private lazy var textBgImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.isUserInteractionEnabled = false
        imageView.setShadow(offset: CGSize(width: 0, height: 1), radius: 8, opacity: 1, color: Theme.c_08_black_10.rawValue.toCGColor())
        return imageView
    }()

    private lazy var textView: MessageTextView = {
        let textView = MessageTextView()
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 20)
        return textView
    }()

    override func setupViews() {
        super.setupViews()

        contentContainerView.addSubview(textBgImageView)
        contentContainerView.addSubview(textView)

        self.textBgImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        self.textView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(40)
        }
    }

    override func bindViewModel() {
        super.bindViewModel()

        self.viewModel.config.observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] config in
            self.updateTextBackgroundImage(by: config.order)
        }.disposed(by: self.disposeBag)

        // Text Message
        self.viewModel.attributedMessage.observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] attrMessage in
            self.textView.attributedText = attrMessage
        }.disposed(by: self.disposeBag)

        self.viewModel.textHeight.skip(1).distinctUntilChanged().observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] height in
            self.textView.snp.updateConstraints { make in
                make.height.equalTo(height)
            }
        }.disposed(by: self.disposeBag)
    }

    override func updateViews() {
        super.updateViews()

        self.textView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(self.viewModel.textHeight.value)
        }
    }
}

// MARK: - Message Background Image
private extension TextMessageRCell {
    func updateTextBackgroundImage(by order: MessageOrder) {
        let imageName = (order == .first ? "send_bubble_pointer.9" : "send_bubble.9")
        let capInset = UIEdgeInsets(top: 26, left: 8, bottom: 12, right: 16)
        let bgImage = UIImage(named: imageName)?.resizableImage(withCapInsets: capInset, resizingMode: .stretch)
        self.textBgImageView.image = bgImage
    }
}
