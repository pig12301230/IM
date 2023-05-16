//
//  MaintenanceViewController.swift
//  ChatRoom
//
//  Created by ERay_Peng on 2022/4/15.
//

import UIKit

class MaintenanceViewController: BaseVC {
    
    lazy var bgView: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(named: "constructionBg4X")
        return view
    }()
    
    lazy var iconView: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(named: "constructionFix")
        return view
    }()
    
    lazy var lblTitle: UILabel = {
        let label = UILabel()
        label.textColor = Theme.c_05_warning_700.rawValue.toColor()
        label.font = .regularParagraphGiantCenter
        label.text = Localizable.maintenance
        return label
    }()
    
    lazy var descriptionTextView: UITextView = {
        let textView = UITextView()
        textView.textAlignment = .center
        textView.backgroundColor = .clear
        textView.showsVerticalScrollIndicator = false
        textView.textColor = Theme.c_07_neutral_400.rawValue.toColor()
        textView.font = .boldParagraphMediumCenter
        return textView
    }()

    static func initVC(_ announcement: String) -> MaintenanceViewController {
        let vc = MaintenanceViewController()
        vc.descriptionTextView.text = announcement
        return vc
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func setupViews() {
        super.setupViews()

        self.view.addSubviews([bgView, iconView, lblTitle, descriptionTextView])
        
        self.bgView.snp.makeConstraints({ $0.edges.equalToSuperview() })
        self.iconView.snp.makeConstraints({
            $0.center.equalToSuperview()
        })
        
        self.lblTitle.snp.makeConstraints({
            $0.centerX.equalToSuperview()
            $0.top.equalTo(self.iconView.snp.bottom)
        })
        
        self.descriptionTextView.snp.makeConstraints({
            $0.top.equalTo(self.lblTitle.snp.bottom).offset(8)
            $0.centerX.equalToSuperview()
            $0.width.equalToSuperview().dividedBy(2)
            $0.bottom.equalToSuperview().offset(-20)
        })
    }
}
