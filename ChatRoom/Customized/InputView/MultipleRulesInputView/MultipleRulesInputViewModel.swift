//
//  MultipleRulesInputViewModel.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/4/20.
//

import RxCocoa
import RxSwift

class MultipleRulesInputViewModel: TitleInputViewModel {
    private(set) var hintVMs: [HintViewModel] = []
    
    // Output for view
    let isSecurity: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    let securityImage: BehaviorRelay<UIImage?> = BehaviorRelay(value: UIImage.init(named: "iconIconViewClose"))
    let needSecurity: Bool
    let canCheckSecurity: Bool
    let isOptional: Bool
    let showHint: Bool
    let needCheck: Bool
    
    // Input from view
    let changeSecurity = PublishSubject<Void>()
    
    private let hintIsValid = PublishSubject<(Bool, ExamineRules?)>()
    private var validRules: [ExamineRules] = []
    
    init(title: String? = nil, needSecurity: Bool = false, canCheckSecurity: Bool = true, isOptional: Bool = false, showHint: Bool = false, check: Bool = true, rules: ExamineRules..., needKerning: Bool = false, clearButtonMode: UITextField.ViewMode = .whileEditing) {
        self.needSecurity = needSecurity
        self.canCheckSecurity = canCheckSecurity
        self.showHint = showHint
        self.isOptional = isOptional
        self.needCheck = check
        super.init(title: title, inputEnable: true)
        self.inputText.accept(self.config.defaultString)
        self.isSecurity.accept(needSecurity)
        self.config.clearButtonMode = clearButtonMode
        self.config.needKerning = needKerning
        self.typeTitle.accept(title)
        self.setupRules(rules)
    }
    
    func setupRules(_ rules: [ExamineRules]) {
        for rule in rules {
            let hViewModel = HintViewModel.init(rule: rule)
            if let index = self.hintVMs.firstIndex(where: { $0.rule.typeCode == rule.typeCode }) {
                // 如果有一模一樣規則，替換掉
                self.hintVMs[index] = hViewModel
                self.validRules.removeAll(where: { $0.typeCode == rule.typeCode })
            } else {
                self.hintVMs.append(hViewModel)
            }
            hViewModel.isValid.bind(to: self.hintIsValid).disposed(by: self.disposeBag)
            self.inputText.bind(to: hViewModel.inputText).disposed(by: self.disposeBag)
        }
        
        guard self.showHint else {
            return
        }
        
        self.hintViewHeight = 16.0 + 28.0 * CGFloat(self.hintVMs.count)
    }
    
    override func initBinding() {
        super.initBinding()
        
        self.hintIsValid.subscribeSuccess { [unowned self] (isValid, rule) in
            guard let rule = rule else {
                return
            }
            
            self.updateRuleStatus(isValid: isValid, rule: rule)
        }.disposed(by: self.disposeBag)
        
        self.changeSecurity.subscribeSuccess { [unowned self] _ in
            self.changeSecurityStatus()
        }.disposed(by: self.disposeBag)
    }
    
    override func setupStatusImage() {
        guard self.needCheck else {
            return
        }
        // 如果是選填 則不顯示
        var image: UIImage?
        if isOptional && (self.outputText.value ?? "").isEmpty {
            image = nil
        } else {
            image = self.output.correct.value ? UIImage.init(named: "iconIconCheckAll") : UIImage.init(named: "iconIconAttention")
        }
        self.statusImage.accept(image)
    }
    
    func updateCustomRuleTo(_ isValid: Bool) {
        // 無效 and 目前皆為不符合規定
        if !isValid && self.validRules.count == 0 {
            checkStatus()
            return
        }
        
        for vm in self.hintVMs {
            if vm.rule.typeCode != 6 {
                continue
            }
            vm.updateVaildStatus(isValid)
        }
    }
}

private extension MultipleRulesInputViewModel {
    
    func changeSecurityStatus() {
        let status = !self.isSecurity.value
        self.isSecurity.accept(status)
        let image = status ? UIImage.init(named: "iconIconViewClose") : UIImage.init(named: "iconIconView")
        self.securityImage.accept(image)
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
        // 如果是選填且欄位為空, 則不檢查
        if isOptional && (self.outputText.value ?? "").isEmpty {
            self.output.correct.accept(true)
            self.setupStatusImage()
            return
        }
        
        let allPass = self.validRules.count == self.hintVMs.count
        
        self.output.correct.accept(allPass)
        self.setupStatusImage()
    }
}
