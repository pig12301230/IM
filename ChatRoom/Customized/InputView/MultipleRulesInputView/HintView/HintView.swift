//
//  HintView.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/4/20.
//

import UIKit

class HintView: BaseViewModelView<HintViewModel> {
    private lazy var iconImage: UIImageView = {
        let image = UIImageView.init()
        return image
    }()
    
    private lazy var lblHint: UILabel = {
        let lbl = UILabel.init()
        lbl.font = .regularParagraphSmallLeft
        return lbl
    }()
    
    override func setupViews() {
        super.setupViews()
        self.addSubview(self.iconImage)
        self.addSubview(self.lblHint)
        self.iconImage.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(4)
            make.height.width.equalTo(24)
            make.top.equalToSuperview().offset(2)
            make.bottom.equalToSuperview().offset(-2)
        }
        
        self.lblHint.snp.makeConstraints { (make) in
            make.leading.equalTo(self.iconImage.snp.trailing).offset(8)
            make.trailing.equalToSuperview().offset(-8)
            make.centerY.equalToSuperview()
        }
    }
    
    override func bindViewModel() {
        super.bindViewModel()
        self.viewModel.hintMessage.bind(to: self.lblHint.rx.text).disposed(by: self.disposeBag)
        self.viewModel.iconImage.bind(to: self.iconImage.rx.image).disposed(by: self.disposeBag)
        self.viewModel.hintColor.bind(to: self.lblHint.rx.textColor).disposed(by: self.disposeBag)
    }
}
