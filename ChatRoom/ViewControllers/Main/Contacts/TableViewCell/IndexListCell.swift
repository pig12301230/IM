//
//  IndexListCell.swift
//  ChatRoom
//
//  Created by Andy Yang on 2021/6/2.
//

import UIKit
import RxSwift

class IndexListCell<T: IndexListCellVM>: BaseTableViewCell<T> {
    
    private lazy var lblTitle: UILabel = {
        let lbl = UILabel.init()
        lbl.theme_textColor = Theme.c_10_grand_2.rawValue
        lbl.font = .midiumParagraphMediumLeft
        lbl.textAlignment = .left
        return lbl
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setupViews() {
        contentView.theme_backgroundColor = Theme.c_07_neutral_0.rawValue
        contentView.addSubview(lblTitle)
        
        lblTitle.snp.makeConstraints {
            $0.leading.equalTo(16)
            $0.trailing.equalTo(-16)
            $0.top.bottom.equalTo(0)
            $0.height.equalTo(36)
        }
    }
    
    override func bindViewModel() {
        super.bindViewModel()
        viewModel.index.observe(on: MainScheduler.instance).subscribeSuccess { [weak self] (indexStr) in
            guard let self = self else { return }
            self.lblTitle.text = indexStr
        }.disposed(by: disposeBag)
    }
    
    override func updateViews() {
        super.updateViews()
        viewModel.setupViews()
    }
}
