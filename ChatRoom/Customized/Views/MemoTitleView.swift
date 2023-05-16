//
//  MemoTitleView.swift
//  ChatRoom
//
//  Created by Winston_Chuang on 2022/9/5.
//

import UIKit

class MemoTitleView: UIView {
    private lazy var lblTitle: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.font = .midiumParagraphMediumLeft
        label.theme_textColor = Theme.c_10_grand_2.rawValue
        return label
    }()
    
    private lazy var lblLimit: UILabel = {
        let label = UILabel()
        label.textAlignment = .right
        label.font = .regularParagraphMediumRight
        label.theme_textColor = Theme.c_10_grand_2.rawValue
        return label
    }()
    
    private lazy var lineView: UIView = {
        let view = UIView()
        view.theme_backgroundColor = Theme.c_07_neutral_900_10.rawValue
        return view
    }()
    
    convenience init(title: String, limit: String) {
        self.init(frame: .zero)
        setupView()
        lblTitle.text = title
        lblLimit.text = limit
    }
    
    func setupView() {
        addSubviews([lblTitle, lblLimit, lineView])
        
        self.snp.makeConstraints { make in
            make.height.equalTo(44)
        }
        
        lblTitle.snp.makeConstraints { make in
            make.top.leading.equalTo(16)
            make.bottom.equalTo(-8)
            make.height.equalTo(20)
        }
        
        lblLimit.snp.makeConstraints { make in
            make.top.equalTo(16)
            make.trailing.equalTo(-16)
            make.bottom.equalTo(-8)
            make.height.equalTo(20)
        }
        
        lineView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(1)
        }
    }
}
