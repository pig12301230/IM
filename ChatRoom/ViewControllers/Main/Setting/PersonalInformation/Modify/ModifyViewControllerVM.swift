//
//  ModifyViewControllerVM.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/7/1.
//

import Foundation
import RxSwift
import RxCocoa

class ModifyViewControllerVM: BaseViewModel {
    enum ModifyType {
        case nickname
        case groupName(groupID: String)
        
        var title: String {
            switch self {
            case .nickname:
                return Localizable.nickname
            case .groupName:
                return Localizable.groupName
            }
        }
        
        var placeholder: String {
            switch self {
            case .nickname:
                return Localizable.nicknameInputPlaceholder
            case .groupName:
                return Localizable.groupNameInputPlaceholder
            }
        }
        
        var rule: ExamineRules {
            switch self {
            case .nickname:
                return .custom(message: Localizable.nicknameValidateRule)
            case .groupName:
                return .limit(min: 1, max: maxInput)
            }
        }
        
        var maxInput: Int {
            switch self {
            case .nickname:
                return 12
            case .groupName:
                return 20
            }
        }
        
        var showHint: Bool {
            switch self {
            case .nickname:
                return true
            case .groupName:
                return false
            }
        }
    }
    
    var disposeBag = DisposeBag()
    let inputVM: MultipleRulesInputViewModel
    let modifyType: ModifyType
    
    let submitEnable: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    let inputCount: BehaviorRelay<String> = BehaviorRelay(value: "")
    let submitModify = PublishSubject<Void>()
    let goBack = PublishSubject<Void>()
    let showLoading = PublishRelay<Bool>()
    
    init(type: ModifyType, default defaultString: String) {
        self.modifyType = type
        self.inputVM = MultipleRulesInputViewModel(showHint: type.showHint, check: false, rules: type.rule)
        self.inputVM.maxInputLength = type.maxInput
        self.inputVM.config.placeholder = type.placeholder
        self.inputVM.config.defaultString = defaultString
        self.inputVM.inputText.accept(defaultString)
        
        super.init()
        initBinding()
    }
    
    func initBinding() {
        observerInput()
        
        self.submitModify.subscribeSuccess { [unowned self] _ in
            self.doSubmitAction()
        }.disposed(by: self.disposeBag)
    }
    
    func observerInput() {        
        self.inputVM.output.correct.distinctUntilChanged().bind(to: self.submitEnable).disposed(by: self.disposeBag)
        self.inputVM.outputText.subscribeSuccess { [unowned self] inputText in
            self.detectInput(inputText)
        }.disposed(by: self.disposeBag)
    }
    
    private func detectInput(_ input: String?) {
        let count = input?.count ?? 0
        let countString = String(format: "%ld/%ld", count, self.modifyType.maxInput)
        self.inputCount.accept(countString)
        
        switch self.modifyType {
        case .nickname:
            guard let text = input, text.count > 0 else {
                self.inputVM.updateCustomRuleTo(false)
                return
            }
            self.inputVM.updateCustomRuleTo(text.isValidate(type: .vtNickname))
        default:
            break
        }
    }
    
    private func doSubmitAction() {
        switch self.modifyType {
        case .nickname:
            self.modifyNickname()
        case .groupName:
            self.modifyGroupName()
        }
    }
}

private extension ModifyViewControllerVM {
    func modifyNickname() {
        guard let text = self.inputVM.outputText.value else {
            return
        }
        showLoading.accept(true)
        DataAccess.shared.modifyNickname(to: text) { [weak self] isSuccess in
            self?.showLoading.accept(false)
            guard let self = self, isSuccess == true else { return }
            self.goBack.onNext(())
        }
    }
    
    func modifyGroupName() {
        guard let text = self.inputVM.outputText.value else {
            return
        }
        
        if case .groupName(let groupID) = self.modifyType {
            showLoading.accept(true)
            DataAccess.shared.setGroupDisplayName(groupID: groupID, name: text) { [weak self] isSuccess in
                self?.showLoading.accept(false)
                guard let self = self, isSuccess == true else { return }
                self.goBack.onNext(())
            }
        }
        
    }
}
