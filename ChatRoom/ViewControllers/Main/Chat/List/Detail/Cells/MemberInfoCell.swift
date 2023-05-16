//
//  MemberInfoCell.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/5/7.
//

import UIKit
import RxSwift
import Kingfisher
import RxCocoa

class MemberInfoCell<T: MemberInfoCellVM>: BaseTableViewCell<T>, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    private lazy var avatar: UIImageView = {
        let imageV = UIImageView()
        imageV.image = UIImage(named: "avatarsPhoto")
        imageV.frame = CGRect(origin: .zero, size: CGSize(width: 96, height: 96))
        imageV.contentMode = .scaleAspectFill
        imageV.isUserInteractionEnabled = true
        imageV.roundSelf()
        return imageV
    }()

    private lazy var nameStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 4
        stackView.distribution = .fill
        return stackView
    }()
    
    private lazy var lblNickname: UILabel = {
        let lbl = UILabel()
        lbl.font = .midiumParagraphSmallLeft
        lbl.theme_textColor = Theme.c_10_grand_1.rawValue
        lbl.textAlignment = .center
        return lbl
    }()
    
    private lazy var lblDeletedUser: UILabel = {
        let lbl = UILabel()
        lbl.text = Localizable.accountHasBeenDeleted
        lbl.font = .midiumParagraphSmallCenter
        lbl.theme_textColor = Theme.c_10_grand_2.rawValue
        return lbl
    }()
    
    private lazy var memberContainer: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let collectionView = UICollectionView(frame: .zero,
                                              collectionViewLayout: layout)
        collectionView.theme_backgroundColor = Theme.c_07_neutral_50.rawValue
        collectionView.register(GroupAvatarCell.self,
                                forCellWithReuseIdentifier: GroupAvatarCell.cellID)
        collectionView.register(GroupMoreCell.self,
                                forCellWithReuseIdentifier: GroupMoreCell.cellID)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isScrollEnabled = false
        return collectionView
    }()
    
    override func setupViews() {
        super.setupViews()
        
        selectionStyle = .none
        theme_backgroundColor = Theme.c_07_neutral_50.rawValue

        contentView.addSubview(avatar)
        contentView.addSubview(nameStackView)
        nameStackView.addArrangedSubviews([lblNickname, lblDeletedUser])
        contentView.addSubview(memberContainer)

        avatar.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(96)
        }

        nameStackView.snp.makeConstraints { make in
            make.top.equalTo(avatar.snp.bottom).offset(4)
            make.centerX.equalTo(avatar)
            make.trailing.lessThanOrEqualToSuperview()
            make.leading.greaterThanOrEqualToSuperview()
            make.height.equalTo(18)
        }
        
        memberContainer.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.top.equalTo(nameStackView.snp.bottom).offset(16)
            $0.bottom.equalTo(0)
            $0.height.equalTo(0)
        }
    }

    override func bindViewModel() {
        super.bindViewModel()

        self.avatar.rx.click.bind(to: self.viewModel.avatarTapped).disposed(by: disposeBag)

        self.viewModel.avatarImage.subscribeSuccess { [unowned self] urlString in
            guard let url = URL(string: urlString) else {
                self.avatar.image = UIImage(named: "avatarsPhoto")
                return
            }
            self.avatar.kf.setImage(with: url,
                                    placeholder: UIImage(named: "avatarsPhoto"))
        }.disposed(by: self.disposeBag)

        self.viewModel.nickname.bind(to: self.lblNickname.rx.text)
            .disposed(by: disposeBag)
        
        self.viewModel.showIsDeletedUser.observe(on: MainScheduler.instance).subscribeSuccess { isDeleted in
            self.lblDeletedUser.isHidden = !isDeleted
            self.avatar.alpha = isDeleted ? 0.5 : 1
        }.disposed(by: disposeBag)
        
        self.viewModel.reloadData.observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] (_) in
            self.memberContainer.reloadData()
        }.disposed(by: disposeBag)
    }

    override func updateViews() {
        super.updateViews()
        
        if viewModel.infoModel?.members?.count ?? 0 > 0 {
            memberContainer.snp.updateConstraints {
                $0.height.equalTo(36)
                $0.bottom.equalTo(-16)
            }
        }
        self.viewModel.setupViews()
    }
    
    // MARK: - UICollectionViewDelegate & UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.numberOfRow(in: section)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        viewModel.numerOfSection()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cellViewModel = viewModel.cellViewModel(in: indexPath) else { return UICollectionViewCell() }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellViewModel.cellID, for: indexPath)
        if let cell = cell as? GroupAvatarCell, let cellViewModel = cellViewModel as? GroupAvatarCellVM {
            cell.setupViewModel(viewModel: cellViewModel)
        } else if let theCell = cell as? GroupMoreCell, let cellViewModel = cellViewModel as? GroupMoreCellVM {
            theCell.setupViewModel(viewModel: cellViewModel)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return indexPath.section == 0 ? CGSize(width: 36, height: 36) : CGSize(width: 76, height: 36)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let isRemainSectionExist = viewModel.numerOfSection() > 1
        let numberOfItems = collectionView.numberOfItems(inSection: 0)
        let totalCellWidth = 36 * numberOfItems + (isRemainSectionExist ? 76 : 0) // 76: remain section
        let totalSpacingWidth = 8 * (numberOfItems - 1)

        let leftInset = (collectionView.layer.frame.size.width - CGFloat(totalCellWidth + totalSpacingWidth)) / 2
        let rightInset = leftInset

        return section == 0 ? UIEdgeInsets(top: 0, left: leftInset, bottom: 0, right: 0) : UIEdgeInsets(top: 0, left: 8, bottom: 0, right: rightInset)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.didSelect(at: indexPath)
    }
}
