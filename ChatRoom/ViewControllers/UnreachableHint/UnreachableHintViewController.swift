//
//  UnreachableHintViewController.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/5/5.
//

import UIKit

class UnreachableHintViewController: BaseVC {

    private lazy var closeItem: UIBarButtonItem = {
        let btnClose = UIButton(frame: CGRect(origin: .zero, size: CGSize(width: 24, height: 24)))
        btnClose.setImage(UIImage(named: "iconIconCross"), for: .normal)
        btnClose.theme_tintColor = Theme.c_07_neutral_800.rawValue
        btnClose.addTarget(self, action: #selector(dismissViewController), for: .touchUpInside)
        return UIBarButtonItem(customView: btnClose)
    }()

    private lazy var lblTitle: UILabel = {
        let lbl = UILabel()
        lbl.textAlignment = .left
        lbl.font = .boldParagraphGiantLeft
        lbl.theme_textColor = Theme.c_10_grand_1.rawValue
        lbl.text = Localizable.noInternet
        return lbl
    }()

    private lazy var lblHint: UILabel = {
        let lbl = UILabel()
        lbl.textAlignment = .left
        lbl.font = .regularParagraphMediumLeft
        lbl.theme_textColor = Theme.c_08_black.rawValue
        lbl.text = Localizable.noInternetHint
        lbl.lineBreakMode = .byWordWrapping
        lbl.numberOfLines = 0
        return lbl
    }()

    static func initVC() -> UnreachableHintViewController {
        let vc = UnreachableHintViewController()
        vc.title = Localizable.noInternet
        return vc
    }

    override func setupViews() {
        super.setupViews()

        self.navigationItem.leftBarButtonItem = closeItem

        self.view.theme_backgroundColor = Theme.c_07_neutral_50.rawValue

        self.view.addSubview(lblTitle)
        self.view.addSubview(lblHint)

        lblTitle.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(16)
            make.leading.equalToSuperview().offset(16)
            make.height.equalTo(28)
        }

        lblHint.snp.makeConstraints { make in
            make.top.equalTo(lblTitle.snp.bottom).offset(32)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalTo(-16)
        }
    }
}

private extension UnreachableHintViewController {
    @objc func dismissViewController() {
        self.navigator.dismiss(sender: self)
    }
}
