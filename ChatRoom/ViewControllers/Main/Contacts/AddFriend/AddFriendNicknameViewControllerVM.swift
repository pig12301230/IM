//
//  AddFriendNicknameViewControllerVM.swift
//  ChatRoom
//
//  Created by Winston_Chuang on 2022/9/5.
//

import Foundation
import RxSwift
import RxRelay

class AddFriendNicknameViewControllerVM: BaseViewModel {
    private var friend: FriendModel
    private var contactName: String
    private(set) var memoInputViewModel: MultipleRulesInputViewModel
    private var disposeBag = DisposeBag()
    
    var showLoading: PublishSubject<Bool> = .init()
    var showToastResult: PublishSubject<Bool> = .init()
    
    init(friend: FriendModel) {
        self.friend = friend
        
        if let contactName = friend.userName, !contactName.isEmpty {
            self.contactName = contactName
        } else {
            self.contactName = friend.displayName
        }
        
        self.memoInputViewModel = .init(title: nil,
                                            needSecurity: false,
                                            isOptional: false,
                                            showHint: false,
                                            check: false)
        memoInputViewModel.config.placeholder = friend.nickname ?? friend.displayName
        if let personalSetting = DataAccess.shared.getUserPersonalSetting(with: friend.id),
           let nickname = personalSetting.nickname {
            self.memoInputViewModel.config.defaultString = nickname
        } else {
            self.memoInputViewModel.config.defaultString = friend.nickname ?? friend.displayName
        }
        memoInputViewModel.maxInputLength = 30
        
        super.init()
    }
    
    func addUserContact() {
        showLoading.onNext(true)
        DataAccess.shared.fetchAddUserContact(self.contactName, takeoverError: true) { [weak self] isSuccess in
            guard let self = self else { return }
            self.showLoading.onNext(false)
            self.showToastResult.onNext(isSuccess)
            self.updateFriendData()
        }
    }
    
    func addUserContactWithNickname(nickname: String) {
        showLoading.onNext(true)
        DataAccess.shared.fetchAddUserContact(self.contactName, takeoverError: true) { [weak self] isSuccess in
            guard let self = self else { return }
            // 成功就去更新 nickname 失敗直接錯誤
            if isSuccess {
                DataAccess.shared.updateUserNickname(userID: self.friend.id, nickname: nickname, takeoverError: true)
                    .subscribe { isSuccess in
                        self.showLoading.onNext(false)
                        self.showToastResult.onNext(isSuccess)
                        self.updateFriendData()
                    } onError: { _ in
                        self.showLoading.onNext(false)
                        self.showToastResult.onNext(false)
                    }.disposed(by: self.disposeBag)
            } else {
                self.showLoading.onNext(false)
                self.showToastResult.onNext(isSuccess)
            }
        }
    }
    
    private func updateFriendData() {
        NotificationCenter.default.post(name: NSNotification.Name(FriendModel.updateFriendModelNotification + friend.id), object: nil, userInfo: ["data": friend])
    }
}
