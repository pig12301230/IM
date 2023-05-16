//
//  ReportHeaderView.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/5/17.
//

import UIKit

class ReportHeaderView: UIView {

    private lazy var lblTitle: UILabel = {
        let label = UILabel()
        label.font = .midiumParagraphMediumLeft
        label.theme_textColor = Theme.c_10_grand_2.rawValue
        return label
    }()

    private lazy var separatorLine: UIView = {
        let view = UIView.init()
        view.theme_backgroundColor = Theme.c_07_neutral_900_10.rawValue
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    convenience init(frame: CGRect, title: String) {
        self.init(frame: frame)

        self.lblTitle.text = title
    }

    func setupViews() {

        self.theme_backgroundColor = Theme.c_07_neutral_50.rawValue

        self.addSubview(lblTitle)
        self.addSubview(separatorLine)

        self.lblTitle.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(16)
            make.height.equalTo(20)
        }

        self.separatorLine.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(1)
        }
    }
}
