//
//  TitleSectionView.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/5/3.
//

import UIKit

class TitleSectionView: BaseSectionView<TitleSectionViewModel> {
    
    private lazy var lblTitle: UILabel = {
        let lbl = UILabel.init()
        lbl.theme_textColor = Theme.c_10_grand_2.rawValue
        lbl.font = .midiumParagraphMediumLeft
        lbl.textAlignment = .left
        return lbl
    }()
    
    private lazy var separatorView: UIView = {
        let view = UIView.init()
        view.theme_backgroundColor = Theme.c_07_neutral_900_10.rawValue
        return view
    }()
    
    override func setupViews() {
        super.setupViews()
        self.contentView.theme_backgroundColor = Theme.c_07_neutral_50.rawValue
        self.contentView.addSubview(self.lblTitle)
        self.contentView.addSubview(self.separatorView)
        
        self.lblTitle.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().offset(-8)
        }
        
        self.separatorView.snp.makeConstraints { (make) in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(1)
        }
    }
    
    override func updateViews() {
        super.updateViews()
        self.lblTitle.text = self.viewModel.title
        self.contentView.backgroundColor = self.viewModel.backgroundColor
    }
}
