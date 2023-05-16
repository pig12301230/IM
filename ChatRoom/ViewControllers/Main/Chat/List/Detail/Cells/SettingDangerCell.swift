//
//  SettingDangerCell.swift
//  ChatRoom
//
//  Created by Andy Yang on 2021/5/26.
//

import Foundation
import RxSwift
import RxCocoa

class SettingDangerCell<T: SettingDangerCellVM>: BaseTableViewCell<T> {
    private lazy var lblTitle: UILabel = {
        let label = UILabel()
        label.font = .midiumParagraphLargeLeft
        label.theme_textColor = Theme.c_06_danger_700.rawValue
        label.textAlignment = .left
        return label
    }()
    
    private lazy var separatorLine: UIView = {
        let view = UIView()
        view.theme_backgroundColor = Theme.c_07_neutral_900_10.rawValue
        return view
    }()
    
    override func setupViews() {
        super.setupViews()
        
        selectionStyle = .none
        theme_backgroundColor = Theme.c_07_neutral_50.rawValue

        self.addSubview(lblTitle)
        self.addSubview(separatorLine)
        
        lblTitle.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.height.equalTo(24)
            make.top.equalTo(16)
            make.bottom.equalTo(-16)
        }
        
        separatorLine.snp.makeConstraints { make in
            make.leading.equalTo(lblTitle)
            make.bottom.trailing.equalToSuperview()
            make.height.equalTo(1)
        }
    }
    
    override func bindViewModel() {
        super.bindViewModel()
        
        viewModel.title.bind(to: lblTitle.rx.text)
            .disposed(by: disposeBag)
    }
    
    override func updateViews() {
        super.updateViews()
        viewModel.setupViews()
    }
}
