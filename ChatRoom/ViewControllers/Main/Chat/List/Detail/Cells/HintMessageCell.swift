//
//  HintMessageCell.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/7/9.
//

import UIKit

class HintMessageCell<T: HintMessageCellVM>: BaseTableViewCell<T> {
    
    private lazy var hintImageView: UIImageView = {
        let view = UIImageView.init()
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    private lazy var lblHint: UILabel = {
        let lbl = UILabel.init()
        lbl.font = .midiumParagraphMediumLeft
        lbl.theme_textColor = Theme.c_10_grand_2.rawValue
        return lbl
    }()
    
    override func setupViews() {
        super.setupViews()
        
        self.selectionStyle = .none
        self.backgroundColor = .clear
        self.contentView.backgroundColor = .clear

        self.addSubview(self.hintImageView)
        self.addSubview(self.lblHint)
        
        self.hintImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.height.width.equalTo(24)
            make.top.equalToSuperview().offset(10)
        }
        
        self.lblHint.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalTo(self.hintImageView)
            make.leading.equalTo(self.hintImageView.snp.trailing).offset(16)
        }
    }
    
    override func bindViewModel() {
        super.bindViewModel()
        self.viewModel.hidden.bind(to: self.rx.isHidden).disposed(by: self.disposeBag)
    }
    
    override func updateViews() {
        super.updateViews()
        self.lblHint.text = self.viewModel.message
        
        guard let name = self.viewModel.icon, let image = UIImage(named: name) else {
            return
        }
        self.hintImageView.image = image
    }
}
