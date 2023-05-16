//
//  DateTimeCell.swift
//  ChatRoom
//
//  Created by Saffi Peng on 2021/7/20.
//

import UIKit
import RxSwift

class DateTimeCell<T: DateTimeCellVM>: ConversationBaseCell<T> {

    private lazy var lblDateTime: UILabel = {
        let label = UILabel()
        label.font = .regularParagraphSmallLeft
        label.theme_textColor = Theme.c_07_neutral_400.rawValue
        label.textAlignment = .center
        return label
    }()

    override func setupViews() {
        super.setupViews()

        containerView.addSubview(lblDateTime)

        self.lblDateTime.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func bindViewModel() {
        super.bindViewModel()
        self.viewModel.dateTime.bind(to: self.lblDateTime.rx.text).disposed(by: self.disposeBag)
    }
}
