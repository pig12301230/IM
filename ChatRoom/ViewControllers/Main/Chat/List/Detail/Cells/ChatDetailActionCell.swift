//
//  ChatDetailActionCell.swift
//  ChatRoom
//
//  Created by Andy Yang on 2021/5/24.
//

import UIKit
import RxSwift
import RxCocoa

class ChatDetailActionCell<T: ChatDetailActionCellVM>: BaseTableViewCell<T> {
    
    private lazy var labelTitle: UILabel = {
        let label = UILabel()
        label.font = .boldParagraphLargeLeft
        label.theme_textColor = Theme.c_01_primary_0_500.rawValue
        return label
    }()
    
    private lazy var imageTitleIcon: UIImageView = {
        let imgView = UIImageView()
        imgView.contentMode = .scaleAspectFit
        return imgView
    }()
    
    override func setupViews() {
        super.setupViews()
        
        selectionStyle = .none
        contentView.theme_backgroundColor = Theme.c_07_neutral_50.rawValue
        contentView.addSubview(labelTitle)
        contentView.addSubview(imageTitleIcon)
        
        labelTitle.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        
        imageTitleIcon.snp.makeConstraints {
            $0.trailing.equalTo(labelTitle.snp.leading).offset(-8)
            $0.centerY.equalTo(labelTitle)
            $0.width.height.equalTo(24)
            $0.top.equalTo(16)
            $0.bottom.equalTo(-16)
        }
    }
    
    override func bindViewModel() {
        super.bindViewModel()
        
        viewModel.title
            .bind(to: labelTitle.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.icon
            .bind(to: imageTitleIcon.rx.image)
            .disposed(by: disposeBag)
    }
    
    override func updateViews() {
        super.updateViews()
        viewModel.setupViews()
    }
}
