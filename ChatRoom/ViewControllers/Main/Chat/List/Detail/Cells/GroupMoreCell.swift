//
//  GroupMoreCell.swift
//  ChatRoom
//
//  Created by Andy Yang on 2021/5/26.
//

import UIKit
import RxSwift
import RxCocoa

class GroupMoreCell: UICollectionViewCell, BaseCollectionViewCellProtocol {

    var disposeBag: DisposeBag = DisposeBag()
    
    var viewModel: GroupMoreCellVM?
    typealias ViewModelType = GroupMoreCellVM
    static var cellID = String(describing: GroupMoreCell.self)
        
    private var container: UIView = {
        let view = UIView()
        view.theme_backgroundColor = Theme.c_07_neutral_200.rawValue
        view.layer.cornerRadius = 18
        view.clipsToBounds = true
        return view
    }()
    
    private var memberCountLabel: UILabel = {
        let label = UILabel()
        label.font = .boldParagraphSmallLeft
        label.theme_textColor = Theme.c_09_white.rawValue
        label.textAlignment = .center
        return label
    }()
    
    private var whiteArrowIcon: UIImageView = {
        let imgView = UIImageView()
        imgView.image = UIImage(named: "iconArrowsChevronRight")
        imgView.theme_tintColor = Theme.c_09_white.rawValue
        return imgView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        contentView.addSubview(container)
        container.addSubview(memberCountLabel)
        container.addSubview(whiteArrowIcon)
        
        container.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        whiteArrowIcon.snp.makeConstraints {
            $0.trailing.equalTo(-16)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(16)
        }
        
        memberCountLabel.snp.makeConstraints {
            $0.leading.equalTo(16)
            $0.centerY.equalTo(whiteArrowIcon)
        }
    }
    
    func bindViewModel() {
        viewModel?.memberCount.debug().bind(to: memberCountLabel.rx.text)
            .disposed(by: disposeBag)
    }
    
    func updateViews() {
        viewModel?.setupViews()
    }
}
