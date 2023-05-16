//
//  IndexSectionHeaderView.swift
//  ChatRoom
//
//  Created by Andy Yang on 2021/6/30.
//

import UIKit
import RxSwift

class IndexSectionHeaderView: UITableViewHeaderFooterView {
    private(set) var disposeBag = DisposeBag()
    
    private(set) var viewModel: IndexSectionHeaderViewVM? {
        didSet {
            bindViewModel()
            updateViews()
        }
    }

    lazy var lblTitle: UILabel = {
        let lbl = UILabel.init()
        lbl.theme_textColor = Theme.c_10_grand_1.rawValue
        lbl.font = .midiumParagraphMediumLeft
        lbl.textAlignment = .left
        return lbl
    }()
 
    private lazy var separator: UIView = {
        let view = UIView.init()
        view.theme_backgroundColor = Theme.c_07_neutral_900_10.rawValue
        return view
    }()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        contentView.theme_backgroundColor = Theme.c_07_neutral_100.rawValue
        contentView.addSubview(lblTitle)
        contentView.addSubview(separator)
        
        lblTitle.snp.makeConstraints {
            $0.leading.equalTo(16)
            $0.trailing.equalTo(-16)
            $0.centerY.equalToSuperview()
        }
        
        separator.snp.makeConstraints {
            $0.height.equalTo(1)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }
    
    func setupViewModel(viewModel: IndexSectionHeaderViewVM) {
        self.viewModel = viewModel
    }
    
    func bindViewModel() {
        viewModel?.title.observe(on: MainScheduler.instance).subscribeSuccess({ [weak self] (title) in
            guard let self = self else { return }
            self.lblTitle.text = title
        }).disposed(by: disposeBag)
    }
    
    func updateViews() {
        viewModel?.setupViews()
    }
    
    func updateSelectionStyle(isSelect: Bool) {
        DispatchQueue.main.async {
            if isSelect {
                self.contentView.theme_backgroundColor = Theme.c_07_neutral_50.rawValue
                self.lblTitle.theme_textColor = Theme.c_01_primary_0_500.rawValue
            } else {
                self.contentView.theme_backgroundColor = Theme.c_07_neutral_100.rawValue
                self.lblTitle.theme_textColor = Theme.c_10_grand_1.rawValue
            }
        }
    }
}
