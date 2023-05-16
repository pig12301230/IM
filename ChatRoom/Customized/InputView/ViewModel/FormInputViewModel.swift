//
//  FormInputViewModel.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/4/16.
//

import Foundation
import RxSwift
import RxCocoa

class FormInputViewModel: InputViewModel {
    
    struct InputLimit {
        var min: Int
        var max: Int
    }
    
    struct HintViewConfig {
        var message: String
        var textColor: UIColor = .green
        var image: UIImage?
        var hidden: Bool = true
    }
    
    let hintViewText: BehaviorRelay<String> = BehaviorRelay(value: "")
    let updateHintViewSetting = PublishSubject<Void>()
    private(set) var validateType: String.ValidateType
    private(set) var limit: InputLimit?
    private(set) var hintConfig: HintViewConfig
    
    init(type: String.ValidateType = .vtNone, limit: InputLimit? = nil, config: InputViewConfig = InputViewConfig.init(), hintConfig: FormInputViewModel.HintViewConfig = HintViewConfig.init(message: "")) {
        self.hintConfig = hintConfig
        self.validateType = type
        self.limit = limit
        super.init(config: config)
    }
    
    override func examineInput(input: String) {
        self.updateHintViewHidden(input.count == 0)
        
        let valid = input.isValidate(type: self.validateType)
        guard let limit = self.limit else {
            self.updateHintSetting(success: valid)
            return
        }
        
        let fitLimit = input.count >= limit.min && input.count <= limit.max
        self.updateHintSetting(success: fitLimit)
        if let maxInputLength = self.limit?.max, input.count > maxInputLength {
            let fixedInputText = String(input.prefix(maxInputLength))
            self.outputText.accept(fixedInputText)
        } else {
            self.outputText.accept(input)
        }
    }
    
    func updateHintViewHidden(_ hidden: Bool) {
        self.hintConfig.hidden = hidden
    }
    
    override func updateHintSetting(success: Bool) {
        super.updateHintSetting(success: success)
        // TODO: implement real setting
        if success {
            self.hintConfig.image = nil
            self.hintConfig.textColor = .green
        } else {
            self.hintConfig.image = nil
            self.hintConfig.textColor = .red
        }

        self.hintViewHeight = self.hintConfig.hidden ? 0 : 23
        self.updateHintViewSetting.onNext(())
    }
}
