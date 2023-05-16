//
//  EmojiToolView.swift
//  ChatRoom
//
//  Created by ERay_Peng on 2022/11/21.
//

import Foundation
import RxSwift

class EmojiToolView: BaseViewModelView<EmojiToolVM> {
    private let actionItemWidth: CGFloat = 40
    
    private lazy var backGroundView: UIView = {
        let view = UIView()
        view.theme_backgroundColor = Theme.c_07_neutral_700.rawValue
        view.layer.cornerRadius = 24
        return view
    }()
    
    private lazy var stackView: UIStackView = {
        let sView = UIStackView()
        sView.axis = .horizontal
        sView.distribution = .fill
        sView.alignment = .bottom
        sView.spacing = 12
        sView.translatesAutoresizingMaskIntoConstraints = false
        return sView
    }()
    
    override func bindViewModel() {
        self.viewModel.currentTapEmoji.subscribeSuccess { [weak self] emojiType in
            guard let self = self else { return }
            self.updateEmojis(with: emojiType)
        }.disposed(by: self.disposeBag)
    }
    
    override func setupViews() {
        super.setupViews()
        self.backgroundColor = .clear
        self.addSubview(backGroundView)
        self.addSubview(stackView)
        
        backGroundView.snp.makeConstraints { make in
            make.height.equalTo(48)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        stackView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(8)
            make.top.bottom.equalToSuperview().inset(4)
            make.centerY.equalToSuperview()
        }
    }
    
    func setupEmojis() {
        self.viewModel.emojiTypes.forEach { emojiType in
            if emojiType == .all { return }
            let imageView = UIImageView(frame: .zero)
            imageView.image = UIImage(named: emojiType.imageName)
            imageView.snp.makeConstraints { make in
                make.width.height.equalTo(40)
            }
            imageView.rx.click.subscribeSuccess { [weak self] _ in
                guard let self = self else { return }
                self.viewModel.didTapEmojiButton(emojiType: emojiType)
            }.disposed(by: self.disposeBag)
            
            self.stackView.addArrangedSubview(imageView)
        }
    }
    
    func updateEmojis(with emoji: EmojiType?) {
        guard let biggerIndex = self.viewModel.emojiTypes.firstIndex(where: { $0 == emoji }) else {
            self.stackView.arrangedSubviews.forEach({ $0.snp.updateConstraints({ $0.width.height.equalTo(40) }) })
            return
        }
        for (index, view) in self.stackView.arrangedSubviews.enumerated() {
            view.snp.updateConstraints { make in
                make.width.height.equalTo(index == biggerIndex ? 48 : 40)
            }
        }
    }
}
