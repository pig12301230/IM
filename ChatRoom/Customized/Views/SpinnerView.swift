//
//  SpinnerView.swift
//  LotBase
//
//  Created by saffi_peng on 2020/10/15.
//  Copyright © 2020 Paridise-Soft. All rights reserved.
//

import UIKit
import SnapKit

#warning("Has to confirm Chat style")
class SpinnerView: UIView {

    lazy var activityIndiactor: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .gray)
        v.color = .darkGray
        v.hidesWhenStopped = true
        return v
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        backgroundColor = .clear

        self.addSubview(activityIndiactor)

        activityIndiactor.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.equalTo(28)
            make.height.equalTo(28)
        }
        activityIndiactor.startAnimating()
    }
}
