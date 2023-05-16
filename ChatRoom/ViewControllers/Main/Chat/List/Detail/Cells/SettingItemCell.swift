//
//  SettingItemCell.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/5/7.
//

import UIKit
import RxSwift
import RxCocoa

class SettingItemCell<T: SettingItemCellVM>: BaseTableViewCell<T> {

    private lazy var lblTitle: UILabel = {
        let label = UILabel()
        label.font = .midiumParagraphLargeLeft
        label.theme_textColor = Theme.c_10_grand_1.rawValue
        label.textAlignment = .left
        return label
    }()

    private lazy var switchControl: UISwitch = {
        let button = UISwitch()
        button.theme_onTintColor = Theme.c_01_primary_0_500.rawValue
        button.theme_tintColor = Theme.c_07_neutral_300.rawValue
        return button
    }()

    private lazy var separatorLine: UIView = {
        let view = UIView()
        view.theme_backgroundColor = Theme.c_07_neutral_900_10.rawValue
        return view
    }()

    override func setupViews() {
        super.setupViews()

        self.selectionStyle = .none
        self.theme_backgroundColor = Theme.c_07_neutral_50.rawValue

        self.contentView.isUserInteractionEnabled = true

        self.addSubview(lblTitle)
        self.addSubview(switchControl)
        self.addSubview(separatorLine)

        self.lblTitle.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.height.equalTo(24)
            make.top.equalTo(16)
            make.bottom.equalTo(-16)
        }

        self.switchControl.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.height.equalTo(31)
        }

        self.separatorLine.snp.makeConstraints { make in
            make.leading.equalTo(lblTitle)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview()
            make.height.equalTo(1)
        }
    }

    override func bindViewModel() {
        super.bindViewModel()

        self.viewModel.title.bind(to: self.lblTitle.rx.text).disposed(by: self.disposeBag)
        self.viewModel.isOn.bind(to: self.switchControl.rx.isOn).disposed(by: self.disposeBag)

        self.switchControl.rx.isOn.skip(1).bind(to: self.viewModel.switchUpdated).disposed(by: self.disposeBag)
    }
}
