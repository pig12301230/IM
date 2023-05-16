//
//  SectionHeaderView.swift
//  ChatRoom
//
//  Created by Winston_Chuang on 2022/1/19.
//

import Foundation
import UIKit

class SectionHeaderView: UITableViewHeaderFooterView {
    
    private lazy var lblTitle: UILabel = {
        let lbl = UILabel.init()
        lbl.theme_textColor = Theme.c_10_grand_2.rawValue
        lbl.font = .midiumParagraphMediumLeft
        lbl.textAlignment = .left
        return lbl
    }()
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setSectionTitle(_ title: String) {
        self.lblTitle.text = title
    }
    
    private func setupViews() {
        self.tintColor = Theme.c_07_neutral_0.rawValue.toColor()
        self.addSubview(lblTitle)
        
        self.lblTitle.snp.makeConstraints { (make) in
            make.leading.equalTo(16)
            make.trailing.equalTo(-16)
            make.centerY.equalToSuperview()
        }
    }
}
