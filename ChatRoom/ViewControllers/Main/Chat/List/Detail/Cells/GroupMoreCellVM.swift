//
//  GroupMoreCellVM.swift
//  ChatRoom
//
//  Created by Andy Yang on 2021/5/26.
//

import RxSwift
import RxCocoa

class GroupMoreCellVM: BaseCollectionViewCellVMProtocol {
    var cellID: String = "GroupMoreCell"
    
    let memberCount: PublishRelay<String?> = PublishRelay()
    private(set) var data: [FriendModel]?
    
    init(with data: [FriendModel]?) {
        self.data = data
    }
    
    func setupViews() {
        memberCount.accept("\(data?.count ?? 0)")
    }
}
