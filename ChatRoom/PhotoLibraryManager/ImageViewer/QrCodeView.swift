//
//  QrCodeView.swift
//  ChatRoom
//
//  Created by ERay_Peng on 2022/9/7.
//

import UIKit
import SnapKit

class QrCodeView: UIView {
    private lazy var qrCodeIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "iconIconQrCode")
        return imageView
    }()
    
    lazy var qrCodeLinkTextView: UITextView = {
        let textView = UITextView()
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.selectedTextRange = nil
        textView.textContainerInset = UIEdgeInsets.zero
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainer.lineBreakMode = .byTruncatingTail
        textView.textContainer.maximumNumberOfLines = 1
        textView.backgroundColor = .clear
        return textView
    }()
    
    private lazy var lblQrCodeReminder: UILabel = {
        let label = UILabel()
        label.text = Localizable.clickUrlToOpenWeb
        label.font = .midiumParagraphSmallLeft
        label.theme_textColor = Theme.c_10_grand_2.rawValue
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        self.theme_backgroundColor = Theme.c_10_grand_4.rawValue
        self.layer.cornerRadius = 18
        
        self.addSubviews([qrCodeIconView, qrCodeLinkTextView, lblQrCodeReminder])
        qrCodeLinkTextView.snp.makeConstraints({
            $0.leading.trailing.equalToSuperview().inset(48)
            $0.height.equalTo(20)
            $0.top.equalToSuperview().inset(18)
            $0.bottom.equalToSuperview().inset(34)
        })
        
        qrCodeIconView.snp.makeConstraints({
            $0.width.height.equalTo(qrCodeLinkTextView.snp.height)
            $0.centerY.equalTo(qrCodeLinkTextView)
            $0.trailing.equalTo(qrCodeLinkTextView.snp.leading).offset(-8)
        })
        
        lblQrCodeReminder.snp.makeConstraints({
            $0.top.equalTo(qrCodeLinkTextView.snp.bottom)
            $0.leading.equalTo(qrCodeLinkTextView)
        })
    }
}
