//
//  UnreachableTopView.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/5/13.
//

import UIKit

class UnreachableTopView: UIView {

    private lazy var noticeIcon: UIImageView = {
        let imageV = UIImageView()
        imageV.image = UIImage(named: "actionsInfo")
        imageV.contentMode = .scaleAspectFit
        return imageV
    }()

    private lazy var lblnoticeMessage: UILabel = {
        let lbl = UILabel()
        lbl.textAlignment = .left
        lbl.font = .midiumParagraphMediumLeft
        lbl.theme_textColor = Theme.c_06_danger_700.rawValue
        lbl.text = Localizable.networkErrorPleaseCheck
        return lbl
    }()
    
    private lazy var loadingView: UIImageView = {
        let imgView = UIImageView()
        let gifImage = UIImage.gifWithName("spinner_warning")
        imgView.animationImages = gifImage
        imgView.startAnimating()
        imgView.isHidden = true
        return imgView
    }()
    
    private var currentStatus: IMNetworkStatus = .connected
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        self.theme_backgroundColor = Theme.c_06_danger_100.rawValue

        self.addSubview(self.noticeIcon)
        self.addSubview(self.lblnoticeMessage)
        self.addSubview(self.loadingView)
        // Auto Layout 相關設定
        self.noticeIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(18)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }

        self.lblnoticeMessage.snp.makeConstraints { make in
            make.leading.equalTo(self.noticeIcon.snp.trailing).offset(18)
            make.centerY.equalTo(self.noticeIcon)
            make.trailing.equalToSuperview().offset(-26)
            make.height.equalTo(20)
        }
        
        self.loadingView.snp.makeConstraints { make in
            make.width.height.equalTo(24)
            make.centerY.equalToSuperview()
            make.trailing.equalTo(-16)
        }
    }
    
    func setup(status: IMNetworkStatus) {
        guard status != currentStatus else { return }
        currentStatus = status
        noticeIcon.image = status.icon
        lblnoticeMessage.text = status.description
        switch status {
        case .disconnected:
            self.isHidden = false
            self.loadingView.isHidden = true
            UIView.animate(withDuration: 0.5) {
                self.alpha = 1
            }
            self.theme_backgroundColor = Theme.c_06_danger_100.rawValue
            lblnoticeMessage.theme_textColor = Theme.c_06_danger_700.rawValue
        case .connecting:
            self.isHidden = false
            self.loadingView.isHidden = false
            UIView.animate(withDuration: 0.5) {
                self.alpha = 1
            }
            self.theme_backgroundColor = Theme.c_05_warning_100.rawValue
            lblnoticeMessage.theme_textColor = Theme.c_05_warning_700.rawValue
        case .connected:
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.isHidden = true
            }
            self.loadingView.isHidden = true
            self.theme_backgroundColor = Theme.c_04_success_100.rawValue
            self.lblnoticeMessage.theme_textColor = Theme.c_04_success_700.rawValue
        }
    }
}
