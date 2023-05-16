//
//  FriendListMainHeaderView.swift
//  ChatRoom
//
//  Created by Andy Yang on 2021/6/1.
//

import UIKit
import RxSwift

protocol FriendListMainHeaderDelegate: AnyObject {
    func userDidTapCollapse(header: FriendListMainHeaderView)
}

class FriendListMainHeaderView: BaseSectionView<FriendListMainHeaderVM> {
    weak var delegate: FriendListMainHeaderDelegate?
    
    private lazy var lblTitle: UILabel = {
        let lbl = UILabel.init()
        lbl.theme_textColor = Theme.c_10_grand_1.rawValue
        lbl.font = .midiumParagraphMediumLeft
        lbl.textAlignment = .left
        return lbl
    }()
    
    private lazy var imgArrow: UIImageView = {
        let imgView = UIImageView()
        imgView.image = UIImage(named: "iconArrowsChevronUp")
        imgView.contentMode = .scaleAspectFit
        return imgView
    }()
    
    private lazy var separator: UIView = {
        let view = UIView.init()
        view.theme_backgroundColor = Theme.c_07_neutral_900_10.rawValue
        return view
    }()
    
    private lazy var btnCollapse: UIButton = {
        let button = UIButton()
        button.backgroundColor = .clear
        return button
    }()
    
    override func setupViews() {
        contentView.theme_backgroundColor = Theme.c_07_neutral_100.rawValue
        contentView.addSubview(lblTitle)
        contentView.addSubview(imgArrow)
        contentView.addSubview(separator)
        contentView.addSubview(btnCollapse)
        
        lblTitle.snp.makeConstraints {
            $0.leading.equalTo(16)
            $0.trailing.equalTo(-16)
            $0.centerY.equalToSuperview()
        }
        
        imgArrow.snp.makeConstraints {
            $0.width.height.equalTo(24)
            $0.trailing.equalTo(-16)
            $0.centerY.equalToSuperview()
        }
        
        separator.snp.makeConstraints {
            $0.height.equalTo(1)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        
        btnCollapse.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    override func bindViewModel() {
        btnCollapse.rx.tap.subscribeSuccess { [weak self] _ in
            guard let self = self else { return }
            
            self.viewModel.didTapCollapsed()
            self.delegate?.userDidTapCollapse(header: self)
        }.disposed(by: disposeBag)
    }
    
    override func updateViews() {
        self.lblTitle.text = self.viewModel.title
        let boolValue = UserDefaults.standard.bool(forKey: self.viewModel.section.collapseKey)
        if boolValue {
            self.imgArrow.rotation()
        } else {
            self.imgArrow.resetRotation()
        }
        self.imgArrow.isHidden = !self.viewModel.collapsable
    }
}
