//
//  VerificationCodeInputViewModel.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/4/22.
//

import Foundation
import RxCocoa
import RxSwift

class VerificationCodeInputViewModel: TitleInputViewModel {
    
    // Output for view
    let btnTitle: BehaviorRelay<String> = BehaviorRelay(value: Localizable.retrieveVerificationCode)
    let getVerificationCodeAction = PublishSubject<Void>()
    let isUserInteractionEnabled = PublishSubject<Bool>()
    let layoutStyleEnable: BehaviorRelay<Bool> = BehaviorRelay(value: true)
    let isCounting: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    
    private(set) var hintVMs: [HintViewModel] = []
    private let hintIsValid = PublishSubject<(Bool, ExamineRules?)>()
    private var validRules: [ExamineRules] = []
    
    private var reduceTimes: Int = 0
    
    init(title: String? = nil, inputEnable: Bool = true, rules: ExamineRules...) {
        super.init(title: title, inputEnable: true)
        self.config.placeholder = Localizable.pleaseInputVerificationCode
        self.config.clearButtonMode = .whileEditing
        self.config.keyboardType = .numberPad
        self.setupRules(rules)
        self.config.keyboardType = .numberPad
    }
    
    func setupRules(_ rules: [ExamineRules]) {
        for rule in rules {
            let hViewModel = HintViewModel.init(rule: rule)
            hViewModel.isValid.bind(to: self.hintIsValid).disposed(by: self.disposeBag)
            self.inputText.bind(to: hViewModel.inputText).disposed(by: self.disposeBag)
            self.hintVMs.append(hViewModel)
        }
    }
    
    override func setupStatusImage() {
        
    }
    
    override func initBinding() {
        super.initBinding()
        
        self.hintIsValid.subscribeSuccess { [unowned self] (isValid, rule) in
            guard let rule = rule else {
                return
            }
            
            self.updateRuleStatus(isValid: isValid, rule: rule)
        }.disposed(by: self.disposeBag)
    }
    
    /*
     After request server send verification code, start count down for `Next Send permission`
     */
    func startCountDown() {
        guard self.reduceTimes == 0 else {
            return
        }
        self.isCounting.accept(true)
        self.layoutStyleEnable.accept(false)
        
        self.reduceTimes = 60
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] timer in
            guard let strongSelf = self, !strongSelf.layoutStyleEnable.value else {
                timer.invalidate()
                return
            }
            
            strongSelf.reduceTimes -= 1
            
            if strongSelf.reduceTimes <= 0 {
                timer.invalidate()
                strongSelf.finishVerificationCodeAction()
            }
            
            self?.updateVerificationCodeStatus(strongSelf.reduceTimes)
        })
    }
    
    func doVerificationAction() {
        self.isUserInteractionEnabled.onNext(false)
        self.getVerificationCodeAction.onNext(())
    }
    
    func finishVerificationCodeAction() {
        self.stopCountDown()
        self.isCounting.accept(false)
    }
}

private extension VerificationCodeInputViewModel {
    
    func stopCountDown() {
        self.isUserInteractionEnabled.onNext(true)
        self.layoutStyleEnable.accept(true)
        self.reduceTimes = 0
    }
    
    func updateVerificationCodeStatus(_ time: Int) {
        var status: String = Localizable.retrieveVerificationCode
        if time > 0 {
            status = String(time) + Localizable.retryAfterSecond
        }
        
        self.btnTitle.accept(status)
    }
    
    func updateRuleStatus(isValid: Bool, rule: ExamineRules) {
        if isValid {
            self.validRules.append(rule)
        } else {
            self.validRules.removeAll(where: { $0.typeCode == rule.typeCode })
        }
        
        self.checkStatus()
    }
    
    func checkStatus() {
        let allPass = self.validRules.count == self.hintVMs.count
        self.output.correct.accept(allPass)
        self.setupStatusImage()
    }
}
