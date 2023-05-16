//
//  AddAsFriendViewVM.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/7/13.
//

import Foundation
import RxSwift
import RxCocoa

class AddAsFriendViewVM: BaseViewModel {
    var disposeBag = DisposeBag()
    
    let avatarThumbnail: BehaviorRelay<UIImage?> = BehaviorRelay(value: nil)
    let acceptFriend = PublishSubject<Void>()
    let showBlockConfirm = PublishRelay<Void>()
    let actionFinishIsBlocked = PublishSubject<Bool>()
    private(set) var transceiver: TransceiverModel?
    
    override init() {
        super.init()
        self.avatarThumbnail.accept(UIImage.init(named: "avatarsPhoto"))
    }
    
    convenience init(with transceiver: TransceiverModel) {
        self.init()
        self.transceiver = transceiver
        self.avatarThumbnail.accept(UIImage.init(named: "avatarsPhoto"))
        self.downloadAvatar()
        self.initBinding()
    }
    
    func setupTransceiverModel(_ model: TransceiverModel?) {
        self.transceiver = model
        self.downloadAvatar()
    }
    
    func isAsFriendViewHidden() -> Bool {
        guard let transceiver = transceiver else {
            return true
        }
        if DataAccess.shared.isFriend(with: transceiver.userID) {
            return true
        } else {
            return DataAccess.shared.isBlockedUser(with: transceiver.userID)
        }
    }
    
    private func initBinding() {
        self.acceptFriend.subscribeSuccess { [unowned self]  in
            guard let model = self.transceiver else {
                return
            }
            DataAccess.shared.fetchAddUserContact(model.username) { isSuccess in
                if isSuccess {
                    self.actionFinishIsBlocked.onNext(false)
                }
            }
        }.disposed(by: self.disposeBag)
    }
    
    private func downloadAvatar() {
        guard let model = self.transceiver else {
            return
        }
        DataAccess.shared.downloadUserAvatar(model.avatarThumbnail) { [weak self] image in
            guard let self = self else {
                return
            }
            
            guard let image = image else {
                return
            }
            
            self.avatarThumbnail.accept(image)
        }
    }
}
