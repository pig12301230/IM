//
//  HongBaoGroupStatusView.swift
//  ChatRoom
//
//  Created by Winston_Chuang on 2023/2/15.
//

import UIKit

class HongBaoGroupStatusView: UIView {
    private lazy var backgroundView: UIImageView = {
        let img = UIImageView()
        let edgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        img.image = UIImage(named: "fill")?.resizableImage(withCapInsets: edgeInsets)
        return img
    }()
    
    private lazy var iconImage: UIImageView = {
        let img = UIImageView()
        img.image = UIImage(named: "chat_bubble_envelope_x_icon_big_award")
        return img
    }()
    
    private lazy var lblStatus: UILabel = {
        let lbl = UILabel()
        lbl.font = .midiumParagraphSmallCenter
        lbl.theme_textColor = Theme.c_09_white.rawValue
        return lbl
    }()
    
    init() {
        super.init(frame: CGRect(origin: .zero, size: .zero))
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        self.addSubviews([backgroundView, iconImage, lblStatus])
        
        backgroundView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(24)
        }
        
        iconImage.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.width.height.equalTo(32)
            make.leading.equalTo(backgroundView.snp.leading).offset(12)
        }
        
        lblStatus.snp.makeConstraints { make in
            make.leading.equalTo(iconImage.snp.trailing).offset(4)
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalTo(backgroundView.snp.centerY)
        }
    }
    
    func setup(status: String) {
        self.lblStatus.text = status
    }
}
