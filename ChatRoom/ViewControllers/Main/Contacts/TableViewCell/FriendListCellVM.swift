//
//  FriendListCellVM.swift
//  ChatRoom
//
//  Created by Andy Yang on 2021/5/31.
//

import Foundation
import RxSwift
import RxCocoa

class FriendListCellVM: BaseTableViewCellVM {
    let avatarImage: BehaviorRelay<String> = BehaviorRelay(value: "")
    let name: PublishRelay<NSAttributedString> = PublishRelay()
    let count: BehaviorRelay<String> = BehaviorRelay(value: "")
    var friend: FriendModel?
    private let disposeBag = DisposeBag()
    
    convenience init(friend: FriendModel?) {
        self.init()
        self.friend = friend
        
        if let number = friend?.memberCount {
            let countString = String(format: "(%ld)", number)
            self.count.accept(countString)
        }
        
        guard let friend = friend, let groupID = friend.groupID, friend.isGroup else { return }
        DataAccess.shared.getGroupObserver(by: groupID).groupObserver
            .map({ String(format: "(%ld)", $0.memberCount) })
            .bind(to: count).disposed(by: disposeBag)
    }
    
    override init() {
        super.init()
        self.cellIdentifier = "FriendListCell"
    }
    
    func setupViews() {
        avatarImage.accept(friend?.thumbNail ?? "")
        name.accept(friend?.display() ?? NSAttributedString())
    }
}
