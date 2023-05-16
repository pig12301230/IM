//
//  ContactorMemoViewControllerVM.swift
//  ChatRoom
//
//  Created by Winston_Chuang on 2022/3/22.
//

import Foundation
import RxSwift
import RxRelay

class ContactorMemoViewControllerVM: BaseViewModel {
    private var friend: FriendModel
    private(set) var nickNameInputViewModel: MultipleRulesInputViewModel
    private(set) var describeInputText: BehaviorRelay<String?> = .init(value: nil)
    private var originNickname: String = ""
    private var originDescription: String = ""
    private var disposeBag = DisposeBag()
    
    var contentChanged: BehaviorRelay<Bool> = .init(value: false)
    var showLoading: PublishSubject<Bool> = .init()
    var dismissVC: PublishSubject<Void> = .init()
    
    init(friend: FriendModel) {
        self.friend = friend
        self.nickNameInputViewModel = .init(title: nil,
                                            needSecurity: false,
                                            isOptional: false,
                                            showHint: false,
                                            check: false)
        nickNameInputViewModel.config.placeholder = friend.nickname ?? friend.displayName
        nickNameInputViewModel.maxInputLength = 30
        
        if let personalSetting = DataAccess.shared.getUserPersonalSetting(with: friend.id) {
            let nickname = personalSetting.nickname ?? (friend.nickname ?? friend.displayName)
            self.nickNameInputViewModel.config.defaultString = nickname
            originNickname = nickname
            if let memo = personalSetting.memo {
                originDescription = memo
                self.describeInputText.accept(memo)
            }
        } else {
            self.nickNameInputViewModel.config.defaultString = friend.displayName
        }
        
        super.init()
        self.initBinding()
    }
    
    func initBinding() {
        Observable.combineLatest(nickNameInputViewModel.inputText, describeInputText)
            .subscribeSuccess { [weak self] newNickName, newDescribe in
                guard let self = self else { return }
                let hasChanged = newNickName != self.originNickname || newDescribe != self.originDescription
                self.contentChanged.accept(hasChanged)
            }.disposed(by: disposeBag)
    }
    
    func updatePersonalSetting() {
        self.showLoading.onNext(true)
        let updateMemo = DataAccess.shared.updateUserMemo(userID: friend.id, memo: self.describeInputText.value ?? "")
        var updateNickname: Observable<Bool>
        
        if let nickname = self.nickNameInputViewModel.inputText.value, !nickname.isEmptyWhitespace {
            updateNickname = DataAccess.shared.updateUserNickname(userID: friend.id, nickname: nickname)
        } else {
            updateNickname = DataAccess.shared.deleteUserNickname(userID: friend.id)
        }
        
        Observable.combineLatest(updateMemo, updateNickname)
            .subscribeSuccess { [unowned self] (updateMemoSuccess, updateNicknameSuccess) in
                self.showLoading.onNext(false)
                if updateMemoSuccess && updateNicknameSuccess {
                    self.updateFriendData()
                    dismissVC.onNext(())
                } else {
                    //TODO: show error?
                }
            }.disposed(by: disposeBag)
    }
    
    private func updateFriendData() {
        NotificationCenter.default.post(name: NSNotification.Name(FriendModel.updateFriendModelNotification + friend.id), object: nil, userInfo: ["data": friend])
    }
}
