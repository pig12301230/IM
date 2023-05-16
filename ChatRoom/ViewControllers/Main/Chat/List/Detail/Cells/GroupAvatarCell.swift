//
//  GroupAvatarCell.swift
//  ChatRoom
//
//  Created by Andy Yang on 2021/5/26.
//

import UIKit
import RxSwift
import RxCocoa

class GroupAvatarCell: UICollectionViewCell, BaseCollectionViewCellProtocol {
    
    static let cellID = String(describing: GroupAvatarCell.self)
    
    var disposeBag = DisposeBag()
    typealias ViewModelType = GroupAvatarCellVM
    var viewModel: GroupAvatarCellVM?
    
    private lazy var imgView: UIImageView = {
        let imgView = UIImageView(image: UIImage(named: "avatarsPhoto"))
        imgView.contentMode = .scaleAspectFill
        return imgView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imgView.kf.cancelDownloadTask()
        imgView.image = UIImage(named: "avatarsPhoto")
    }

    private func setupViews() {
        contentView.addSubview(imgView)
        
        imgView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        imgView.roundSelf()
    }
    
    func bindViewModel() {
        viewModel?.avatar.subscribeSuccess { [weak self] (avatarStr) in
            guard let self = self, let avatarURL = avatarStr, let url = URL(string: avatarURL) else { return }
            self.imgView.kf.setImage(with: url, placeholder: UIImage(named: "avatarsPhoto"))
        }.disposed(by: disposeBag)
    }
    
    func updateViews() {
        viewModel?.setupViews()
    }
}
