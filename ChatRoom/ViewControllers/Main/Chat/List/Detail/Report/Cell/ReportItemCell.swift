//
//  ReportItemCell.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/5/17.
//

import UIKit
import RxSwift

class ReportItemCell<T: ReportItemCellVM>: BaseTableViewCell<T> {
    
    private lazy var radioButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "radioActiveImage"), for: .normal)
        button.setImage(UIImage(named: "radioCheckedImage"), for: .selected)
        return button
    }()

    private lazy var title: UILabel = {
        let label = UILabel()
        label.font = .midiumParagraphLargeLeft
        label.theme_textColor = Theme.c_10_grand_1.rawValue
        return label
    }()

    private lazy var separatorLine: UIView = {
        let view = UIView.init()
        view.theme_backgroundColor = Theme.c_07_neutral_900_10.rawValue
        return view
    }()

    override func setupViews() {
        super.setupViews()

        self.selectionStyle = .none
        self.theme_backgroundColor = Theme.c_07_neutral_50.rawValue

        self.contentView.addSubview(radioButton)
        self.contentView.addSubview(title)
        self.contentView.addSubview(separatorLine)

        self.radioButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }

        self.title.snp.makeConstraints { make in
            make.leading.equalTo(radioButton.snp.trailing).offset(8)
            make.centerY.equalToSuperview()
            make.height.equalTo(24)
        }

        self.separatorLine.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(16)
            make.trailing.bottom.equalToSuperview()
            make.height.equalTo(1)
        }
    }

    override func bindViewModel() {
        super.bindViewModel()

        self.viewModel.selected.bind(to: self.radioButton.rx.isSelected).disposed(by: self.disposeBag)
        self.viewModel.title.bind(to: self.title.rx.text).disposed(by: self.disposeBag)
        self.viewModel.hideSeparatorLine.bind(to: self.separatorLine.rx.isHidden).disposed(by: self.disposeBag)
    }
}
