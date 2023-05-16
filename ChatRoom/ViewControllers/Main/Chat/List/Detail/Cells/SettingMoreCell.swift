//
//  SettingMoreCell.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/5/10.
//

import UIKit

class SettingMoreCell<T: SettingMoreCellVM>: BaseTableViewCell<T> {

    private lazy var lblTitle: UILabel = {
        let label = UILabel()
        label.font = .midiumParagraphLargeLeft
        label.theme_textColor = Theme.c_10_grand_1.rawValue
        label.textAlignment = .left
        return label
    }()

    lazy var moreImageView: UIImageView = {
        let image = UIImageView(image: UIImage(named: "iconArrowsChevronRight"))
        return image
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

        self.addSubview(lblTitle)
        self.addSubview(moreImageView)
        self.addSubview(separatorLine)

        self.lblTitle.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalTo(16)
            make.bottom.equalTo(-16)
            make.height.equalTo(24)
        }

        self.moreImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }

        self.separatorLine.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview()
            make.height.equalTo(1)
        }
    }

    override func bindViewModel() {
        super.bindViewModel()

        self.viewModel.title.bind(to: self.lblTitle.rx.text).disposed(by: self.disposeBag)
    }

    override func updateViews() {
        super.updateViews()
        
        self.moreImageView.image = UIImage(named: self.viewModel.iconName)
        self.moreImageView.setImageColor(color: Theme.c_07_neutral_500.rawValue.toColor())
        
        self.viewModel.setupViews()
    }
}
