//
//  GroupAvatarCellVM.swift
//  ChatRoom
//
//  Created by Andy Yang on 2021/5/26.
//

import RxSwift
import RxCocoa

class GroupAvatarCellVM: BaseCollectionViewCellVMProtocol {
    var disposeBag = DisposeBag()
    
    let avatar: PublishRelay<String?> = PublishRelay()
    let cellID = "GroupAvatarCell"
    private(set) var item: FriendModel?
    
    init(with data: FriendModel?) {
        item = data
    }
    
    func setupViews() {
        guard let item = item else { return }
        avatar.accept(item.thumbNail)
    }
}
