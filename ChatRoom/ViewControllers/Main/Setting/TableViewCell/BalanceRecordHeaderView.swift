//
//  BalanceRecordHeaderView.swift
//  ChatRoom
//
//  Created by ERay_Peng on 2022/12/30.
//

import Foundation
import UIKit

class BalanceRecordHeaderView: UITableViewHeaderFooterView {
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .leading
        stackView.spacing = 16
        return stackView
    }()
    
    private lazy var lblTitle: UILabel = {
        let lbl = UILabel.init()
        lbl.theme_textColor = Theme.c_10_grand_2.rawValue
        lbl.font = .midiumParagraphMediumLeft
        lbl.textAlignment = .left
        lbl.text = Localizable.monthlyExchangeRecord
        return lbl
    }()
    
    private lazy var lblPoints: UILabel = {
        let lbl = UILabel.init()
        lbl.theme_textColor = Theme.c_10_grand_2.rawValue
        lbl.font = .midiumParagraphMediumLeft
        lbl.textAlignment = .left
        lbl.text = Localizable.point
        return lbl
    }()
    
    private lazy var lblType: UILabel = {
        let lbl = UILabel.init()
        lbl.theme_textColor = Theme.c_10_grand_2.rawValue
        lbl.font = .midiumParagraphMediumLeft
        lbl.textAlignment = .center
        lbl.text = Localizable.mediumType
        return lbl
    }()
    
    private lazy var lblStatus: UILabel = {
        let lbl = UILabel.init()
        lbl.theme_textColor = Theme.c_10_grand_2.rawValue
        lbl.font = .midiumParagraphMediumLeft
        lbl.textAlignment = .center
        lbl.text = Localizable.state
        return lbl
    }()
    
    private lazy var lblTime: UILabel = {
        let lbl = UILabel.init()
        lbl.theme_textColor = Theme.c_10_grand_2.rawValue
        lbl.font = .midiumParagraphMediumLeft
        lbl.textAlignment = .right
        lbl.text = Localizable.dateAndTime
        return lbl
    }()
    
    private lazy var seperateBottomView: UIView = {
        let view = UIView()
        view.theme_backgroundColor = Theme.c_07_neutral_900.rawValue
        view.alpha = 0.1
        return view
    }()
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        self.tintColor = Theme.c_09_white.rawValue.toColor()
        self.contentView.addSubviews([lblTitle, seperateBottomView, stackView])
        
        lblTitle.snp.makeConstraints { (make) in
            make.leading.top.trailing.equalToSuperview().inset(16)
            make.height.equalTo(20)
        }
        
        seperateBottomView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(lblTitle.snp.bottom).offset(7)
            make.height.equalTo(1)
        }
        
        stackView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalTo(seperateBottomView.snp.bottom).offset(7)
            make.bottom.equalToSuperview().offset(-7)
        }
        
        self.stackView.addArrangedSubviews([lblPoints, lblType, lblStatus, lblTime])
        
        let deviceUnitWidth = UIScreen.main.bounds.width / 414
        let subViewHeight = 20
        
        lblPoints.snp.makeConstraints { (make) in
            make.height.equalTo(subViewHeight)
            make.width.lessThanOrEqualTo(deviceUnitWidth * 108)
        }
        
        lblType.snp.makeConstraints { (make) in
            make.height.equalTo(subViewHeight)
            make.width.equalTo(deviceUnitWidth * 80)
        }
        
        lblStatus.snp.makeConstraints { (make) in
            make.height.equalTo(subViewHeight)
            make.width.equalTo(deviceUnitWidth * 52)
        }
        
        lblTime.snp.makeConstraints { make in
            make.height.equalTo(subViewHeight)
            make.width.equalTo(deviceUnitWidth * 108)
        }
    }
}
