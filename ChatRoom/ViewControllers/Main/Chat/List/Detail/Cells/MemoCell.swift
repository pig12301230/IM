//
//  MemoCell.swift
//  ChatRoom
//
//  Created by Winston_Chuang on 2022/3/28.
//

import Foundation
import UIKit

class MemoCell<T: MemoCellVM>: BaseTableViewCell<T> {
    
    private lazy var lblSetTitle: UILabel = {
        let lbl = UILabel()
        lbl.text = Localizable.settingMemo
        lbl.font = .boldParagraphLargeCenter
        lbl.theme_textColor = Theme.c_03_tertiary_0_500.rawValue
        return lbl
    }()
    
    private lazy var imgTitleIcon: UIImageView = {
        let imgView = UIImageView()
        imgView.contentMode = .scaleAspectFit
        imgView.image = UIImage(named: "icon_icon_form_edit")
        return imgView
    }()
    
    private lazy var lblDescribeTitle: UILabel = {
        let lbl = UILabel()
        lbl.text = Localizable.describe
        lbl.theme_textColor = Theme.c_10_grand_1.rawValue
        lbl.font = .midiumParagraphLargeLeft
        lbl.textAlignment = .left
        return lbl
    }()
    
    private lazy var lblDescription: UILabel = {
        let lbl = UILabel()
        lbl.textAlignment = .left
        lbl.theme_textColor = Theme.c_07_neutral_400.rawValue
        lbl.font = .midiumParagraphMediumLeft
        lbl.lineBreakMode = .byTruncatingTail
        lbl.numberOfLines = 2
        return lbl
    }()
    
    private lazy var arrowIconImgView: UIImageView = {
        let imgView = UIImageView()
        imgView.image = UIImage(named: "icon_arrows_chevron_right")
        return imgView
    }()
    
    override func setupViews() {
        super.setupViews()
        
        selectionStyle = .none
        contentView.theme_backgroundColor = Theme.c_07_neutral_50.rawValue
        
        contentView.addSubviews([lblDescribeTitle, lblDescription, arrowIconImgView])
        contentView.addSubviews([lblSetTitle, imgTitleIcon])
        
        lblSetTitle.snp.makeConstraints {
            $0.top.greaterThanOrEqualTo(16)
            $0.center.equalToSuperview()
            $0.height.equalTo(24)
            $0.bottom.lessThanOrEqualTo(-16)
        }
        
        imgTitleIcon.snp.makeConstraints {
            $0.trailing.equalTo(lblSetTitle.snp.leading).offset(-8)
            $0.centerY.equalTo(lblSetTitle)
            $0.width.height.equalTo(24)
        }
        
        lblDescribeTitle.snp.makeConstraints {
            $0.leading.equalTo(16)
            $0.centerY.equalToSuperview()
            $0.height.equalTo(24)
        }
        lblDescribeTitle.setContentHuggingPriority(.required, for: .horizontal)
        lblDescribeTitle.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        lblDescription.snp.makeConstraints {
            $0.top.equalTo(18)
            $0.bottom.equalTo(-18)
            $0.leading.equalTo(lblDescribeTitle.snp.trailing).offset(8)
            $0.trailing.equalTo(arrowIconImgView.snp.leading).offset(-16)
            $0.centerY.equalToSuperview()
        }

        arrowIconImgView.snp.makeConstraints {
            $0.height.width.equalTo(24)
            $0.trailing.equalTo(-16)
            $0.centerY.equalToSuperview()
        }
    }
    
    override func bindViewModel() {
        super.bindViewModel()
        self.viewModel.description.subscribeSuccess { [unowned self] memo in
            self.lblDescription.text = memo
            let isEmpty = memo.isEmpty
            self.arrowIconImgView.isHidden = isEmpty
            self.lblDescription.isHidden = isEmpty
            self.lblDescribeTitle.isHidden = isEmpty
            self.lblSetTitle.isHidden = !isEmpty
            self.imgTitleIcon.isHidden = !isEmpty
        }.disposed(by: disposeBag)
    }
}
