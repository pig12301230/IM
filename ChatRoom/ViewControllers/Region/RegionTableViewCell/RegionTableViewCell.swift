//
//  RegionTableViewCell.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/4/20.
//

import UIKit

class RegionTableViewCell: UITableViewCell {
    private lazy var lblName: UILabel = {
        let lbl = UILabel.init()
        lbl.textAlignment = .left
        lbl.font = .midiumParagraphLargeLeft
        lbl.theme_textColor = Theme.c_10_grand_1.rawValue
        return lbl
    }()
    
    private lazy var lblDigit: UILabel = {
        let lbl = UILabel.init()
        lbl.textAlignment = .right
        lbl.font = .midiumParagraphLargeLeft
        lbl.theme_textColor = Theme.c_10_grand_1.rawValue
        return lbl
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        self.contentView.addSubview(self.lblName)
        self.contentView.addSubview(self.lblDigit)
        self.lblName.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        
        self.lblDigit.snp.makeConstraints { (make) in
            make.trailing.equalToSuperview().offset(-32)
            make.centerY.equalToSuperview()
            make.leading.equalTo(self.lblName.snp.trailing).offset(5)
        }
    }
    
    func setup(with info: SelectRegionViewControllerVM.CountryInfo) {
        self.lblName.text = info.name
        self.lblDigit.text = "+" + info.digit
    }
}
