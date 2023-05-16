//
//  HintViewModel.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/4/20.
//

import UIKit
import RxCocoa
import RxSwift

enum ExamineRules {
    case custom(message: String)
    case alphabetAndDigit(min: Int?, max: Int?)
    case limit(min: Int?, max: Int?)
    case allDigit(min: Int?, max: Int?)
    case atLeastDigit(count: Int = 1)
    case atLeastLowercased(count: Int = 1)
    case atLeastUppercased(count: Int = 1)
    case alphabet(lowercased: Int = 1, uppercased: Int = 1)
    case atLeastAlphabet(count: Int = 1)
    case specifyNumber(count: Int = 1)
    case largerNumber(original: Double)
    
    var typeCode: Int {
        switch self {
        case .limit(min: _, max: _):
            return 0
        case .allDigit(min: _, max: _):
            return 1
        case .atLeastDigit(count: _):
            return 2
        case .atLeastLowercased(count: _):
            return 3
        case .atLeastUppercased(count: _):
            return 4
        case .alphabet(lowercased: _, uppercased: _):
            return 5
        case .custom(message: _):
            return 6
        case .alphabetAndDigit(min: _, max: _):
            return 7
        case .atLeastAlphabet:
            return 8
        case .specifyNumber:
            return 9
        case .largerNumber:
            return 10
        }
    }
    
    var hintMessage: String {
        switch self {
        case .custom(message: let msg):
            return msg
        case .limit(min: let inMin, max: let inMax):
            return self.messageWithRange(min: inMin, max: inMax, suffix: "位字符长度")
        case .allDigit(min: let inMin, max: let inMax):
            return self.messageWithRange(min: inMin, max: inMax, suffix: "个数字")
        case .atLeastDigit(count: let count):
            return String(format: "至少%ld个数字", count)
        case .atLeastLowercased(count: let count):
            return String(format: "至少%ld个小写", count)
        case .atLeastUppercased(count: let count):
            return String(format: "至少%ld个大写", count)
        case .alphabet(lowercased: let lower, uppercased: let upper):
            return String(format: "至少%ld个小写和%ld个大写英文", lower, upper)
        case .alphabetAndDigit(min: let inMin, max: let inMax):
            return self.messageWithRange(min: inMin, max: inMax, suffix: "位字符长度, 不含符号")
        case .atLeastAlphabet(let count):
            return String(format: "至少%ld个英文", count)
        case .specifyNumber(let count):
            return String(format: "%ld位数字的长度", count)
        case .largerNumber:
            return ""
        }
    }
    
    func messageWithRange(min: Int?, max: Int?, suffix: String) -> String {
        if min == nil, let max = max {
            return "至多" + String(max) + suffix
        } else if max == nil, let min = min {
            return "至少" + String(min) + suffix
        } else if let min = min, let max = max {
            return String(min) + "-" + String(max)  + suffix
        }
        return ""
    }
}

class HintViewModel: BaseViewModel {
    var disposeBag = DisposeBag()
    
    // Input from parent
    let inputText: BehaviorRelay<String?> = BehaviorRelay(value: nil)
    
    // Output for parent
    let isValid: BehaviorRelay<(Bool, ExamineRules?)> = BehaviorRelay(value: (false, nil))
    
    // Output for view
    let iconImage: BehaviorRelay<UIImage?> = BehaviorRelay(value: UIImage.init(named: "iconIconCheck"))
    let hintMessage: BehaviorRelay<String> = BehaviorRelay(value: "")
    let hintColor: BehaviorRelay<UIColor> = BehaviorRelay(value: Theme.c_07_neutral_400.rawValue.toColor())
    
    private(set) var rule: ExamineRules
    private var isInputValid: Bool = false {
        didSet {
            if oldValue != isInputValid {
                self.setupIsValidStatus(isInputValid)
            }
        }
    }
    
    init(rule: ExamineRules = .atLeastLowercased(count: 1)) {
        self.rule = rule
        super.init()
        self.initBinding()
        self.hintMessage.accept(rule.hintMessage)
    }
    
    func updateVaildStatus(_ isValid: Bool) {
        self.isInputValid = isValid
    }
    
    func initBinding() {
        self.inputText.distinctUntilChanged().subscribeSuccess { [unowned self] (input) in
            guard let input = input else {
                self.isInputValid = false
                return
            }
            
            // type 6 為 custom, 不檢核既有規則
            guard self.rule.typeCode != 6 else {
                return
            }
            
            self.examineInput(input)
        }.disposed(by: self.disposeBag)
    }
    
}

private extension HintViewModel {
    func examineInput(_ input: String) {
        let isValid = self.isValidInput(input)
        
        guard isValid != self.isInputValid else {
            return
        }
        
        self.isInputValid = isValid
    }
    
    func setupIsValidStatus(_ isValid: Bool) {
        let image = isValid ? UIImage.init(named: "iconIconCheckActive") : UIImage.init(named: "iconIconCheck")
        self.iconImage.accept(image)

        let color = isValid ? Theme.c_10_grand_1.rawValue : Theme.c_07_neutral_400.rawValue
        self.hintColor.accept(color.toColor())

        self.isValid.accept((self.isInputValid, self.rule))
    }
    
    func isValidInput(_ input: String) -> Bool {
        guard input.count > 0 else {
            return false
        }
        
        var isValid: Bool = false
        switch self.rule {
        case .custom(message: _):
            return true
        case .limit(min: let min, max: let max):
            return self.checkInputRange(total: input.count, min: min, max: max)
        case .allDigit(min: let min, max: let max):
            let total = input.digitCount()
            return total == input.count && self.checkInputRange(total: total, min: min, max: max)
        case .atLeastDigit(count: let count):
            isValid = input.digitCount() >= count
            return isValid
        case .atLeastLowercased(count: let count):
            isValid = input.lowercasedCount() >= count
            return isValid
        case .atLeastUppercased(count: let count):
            isValid = input.uppercasedCount() >= count
            return isValid
        case .alphabet(lowercased: let lower, uppercased: let upper):
            let lowercasedCount = input.lowercasedCount()
            let uppercasedCount = input.uppercasedCount()
            isValid = lowercasedCount >= lower && uppercasedCount >= upper
            return isValid
        case .alphabetAndDigit(min: let min, max: let max):
            let isValid = input.isValidate(type: .vtAlphabetDigit)
            let range = self.checkInputRange(total: input.count, min: min, max: max)
            return isValid && range
        case .atLeastAlphabet(let count):
            let lowercasedCount = input.lowercasedCount()
            let uppercasedCount = input.uppercasedCount()
            isValid = (lowercasedCount >= count || uppercasedCount >= count)
            return isValid
        case .specifyNumber(let count):
            return input.digitCount() == count
        case .largerNumber(original: let original):
            guard !input.isEmpty else { return true }
            let new: Double = Double(input) ?? 0.0
            return new <= original
        }
    }
    
    func checkInputRange(total: Int, min: Int?, max: Int?) -> Bool {
        if min == nil, let max = max {
            return total <= max
        } else if max == nil, let min = min {
            return total >= min
        } else if let min = min, let max = max {
            return total >= min && total <= max
        }
        
        return false
    }
}
