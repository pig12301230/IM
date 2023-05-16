//
//  CreateGroupViewControllerVM.swift
//  ChatRoom
//
//  Created by Winston_Chuang on 2022/1/21.
//

import Foundation
import RxSwift
import UIKit
import RxRelay

class CreateGroupViewControllerVM {
    private(set) var groupNameViewModel: MultipleRulesInputViewModel
    var selectedMembers: [FriendModel]
    var mySelfData: FriendModel
    
    let canCreate: BehaviorRelay<Bool> = .init(value: false)
    let groupImg: BehaviorRelay<UIImage?> = .init(value: nil)
    var removeMember: PublishSubject<FriendModel> = .init()
    let reloadData: PublishSubject<Void> = .init()
    let showError: PublishSubject<String> = .init()
    let createSuccess: PublishSubject<Void> = .init()
    
    let showLoading: BehaviorRelay<Bool> = .init(value: false)
    private var disposeBag = DisposeBag()
    
    init(selectedMembers: [FriendModel], mySelfData: FriendModel) {
        self.selectedMembers = selectedMembers
        self.mySelfData = mySelfData
    
        // 把自己放入名單第一位
        self.selectedMembers.insert(mySelfData, at: 0)
        
        groupNameViewModel = MultipleRulesInputViewModel(title: nil,
                                                        needSecurity: false,
                                                        isOptional: false,
                                                        showHint: false,
                                                        check: false,
                                                        rules: .alphabetAndDigit(min: 1, max: 20))
        self.groupNameViewModel.config.placeholder = Localizable.groupName
        self.groupNameViewModel.maxInputLength = 20
        
        removeMember.subscribeSuccess { [unowned self] member in
            self.removeMember(member)
        }.disposed(by: disposeBag)
        
        groupNameViewModel.inputText.subscribeSuccess { [unowned self] input in
            if let input = input, !input.isEmpty && self.selectedMembers.count > 1 {
                canCreate.accept(true)
            } else {
                canCreate.accept(false)
            }
        }.disposed(by: disposeBag)
    }
    
    func createGroup(with image: UIImage?) {
        // call API
        let usersString = self.selectedMembers.dropFirst().map { $0.id }.joined(separator: ",")
        guard let displayName = self.groupNameViewModel.inputText.value else { return }
        
        let request: ApiClient.CreateGroupRequset
        if let image = groupImg.value {
            let size = image.getSizeIn(.megabyte, opt: .jpeg)
            guard size > 0.0 else {
                return
            }
            let limit = Application.shared.limitImageMB
            let compression = size < limit ? 1 : (limit / size) - 0.05
            guard let data = image.jpegData(compressionQuality: CGFloat(compression)) else {
                return
            }
            
            request = ApiClient.CreateGroupRequset(img: data,
                                                   displayName: displayName,
                                                   users: usersString)
        } else {
            request = ApiClient.CreateGroupRequset(img: nil, displayName: displayName, users: usersString)
        }
        
        self.showLoading.accept(true)
        ApiClient.createGroup(request: request)
            .subscribe(onNext: { [unowned self] _ in
                createSuccess.onNext(())
            }, onError: { [unowned self] error in
                self.showLoading.accept(false)
                guard let apiError = error as? ApiError else {
                    self.showError.onNext(error.localizedDescription)
                    return
                }
                self.showError.onNext(apiError.localizedString)
            }, onCompleted: { [unowned self] in
                self.showLoading.accept(false)
            }).disposed(by: disposeBag)
    }
    
    private func removeMember(_ member: FriendModel) {
        // 如果是自己就不做動作
        guard member.id != mySelfData.id else { return }
        
        if let index = selectedMembers.firstIndex(where: { $0.id == member.id }) {
            selectedMembers.remove(at: index)
            if selectedMembers.count <= 1 {
                canCreate.accept(false)
            }
            reloadData.onNext(())
        }
    }
}
