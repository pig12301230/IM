//
//  EmptyView.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/5/4.
//

import UIKit

class EmptyView: UIView {
    enum EmptyType {
        case noConversation
        case noSearchResults
        
        var image: String {
            switch self {
            case .noConversation:
                return "emptyStatusMessage"
            case .noSearchResults:
                return "emptyStatusClue"
            }
        }
        
        var message: String {
            switch self {
            case .noConversation:
                return Localizable.emptyChats
            case .noSearchResults:
                return Localizable.emptySearchResult
            }
        }
    }
    
    private(set) var type: EmptyType = .noConversation
    
    private lazy var image: UIImageView = {
        let iView = UIImageView.init()
        return iView
    }()
    
    private lazy var lblMessage: UILabel = {
        let lbl = UILabel.init()
        lbl.theme_textColor = Theme.c_10_grand_2.rawValue
        lbl.textAlignment = .center
        lbl.numberOfLines = 0
        return lbl
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateEmptyType(_ type: EmptyType) {
        guard type != self.type else {
            return
        }
        
        self.type = type
        self.setupInfo()
    }
}

private extension EmptyView {
    func setupViews() {
        self.addSubview(self.image)
        self.addSubview(self.lblMessage)
        
        self.setupInfo()
        
        self.image.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(0)
            make.trailing.lessThanOrEqualToSuperview().offset(0)
            make.height.equalTo(160)
        }
        
        self.lblMessage.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(self.image.snp.bottom)
            make.leading.greaterThanOrEqualToSuperview().offset(0)
            make.trailing.lessThanOrEqualToSuperview().offset(0)
            make.bottom.equalToSuperview()
        }
    }
    
    func setupInfo() {
        self.image.image = UIImage.init(named: self.type.image)
        self.lblMessage.text = self.type.message
    }
}
