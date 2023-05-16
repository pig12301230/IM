//
//  InputViewModel.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/4/15.
//

import RxSwift
import RxCocoa

protocol InputExamineProtocol {
    func examineInput(input: String)
}

class InputViewModel: BaseViewModel, InputExamineProtocol {
    
    struct InputViewConfig {
        var clearButtonMode: UITextField.ViewMode = .never
        var placeholder: String = ""
        var defaultString: String = ""
        var keyboardType: UIKeyboardType = .default
        var needKerning: Bool = false
    }
    
    struct Input {
        let inputEnable: BehaviorRelay<Bool> = BehaviorRelay(value: true)
    }
    
    struct Output {
        let correct: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    }
    
    let disposeBag = DisposeBag()
    
    // MARK: - for View
    let updateViewHeight = PublishSubject<CGFloat>()
    let inputBorderColor: BehaviorRelay<CGColor?> = BehaviorRelay(value: nil)
    let inputViewBGColor: BehaviorRelay<UIColor> = BehaviorRelay(value: UIColor.clear)
    let inputText: BehaviorRelay<String?> = BehaviorRelay(value: "")
    let outputText: BehaviorRelay<String?> = BehaviorRelay(value: "")
    
    // MARK: - view setting
    private(set) var textFieldHeight: CGFloat = 42
    private(set) var edge: CGFloat = 8
    private(set) var keepLeft: Bool = true
    private(set) var input: Input = Input()
    private(set) var output: Output = Output()
    var hintViewHeight: CGFloat = 0
    var config: InputViewConfig
    
    init(config: InputViewConfig = InputViewConfig.init()) {
        self.config = config
        super.init()
        self.updateInput(with: config.defaultString)
        self.initBinding()
    }
    
    func initBinding() {
        self.input.inputEnable.distinctUntilChanged().subscribeSuccess { [unowned self] (enable) in
            self.updateEnableSetting(enable)
        }.disposed(by: self.disposeBag)
        
        self.inputText.distinctUntilChanged().subscribeSuccess { [unowned self] (inputText) in
            guard self.input.inputEnable.value, let text = inputText else {
                return
            }
            self.updateInput(with: text)
        }.disposed(by: self.disposeBag)
    }
    
    func totalViewHeight() -> CGFloat {
        return self.textFieldHeight + 2 * self.edge + self.hintViewHeight
    }
    
    // MARK: - protocol
    func examineInput(input: String) {
        let valid = input.count != 0
        self.updateHintSetting(success: valid)
    }
    
    func updateHintSetting(success: Bool) {
        self.output.correct.accept(success)
    }
}

// MARK: - update setting
internal extension InputViewModel {
    
    func updateInput(with inputText: String) {
        self.examineInput(input: inputText)
    }
    
    func updateEnableSetting(_ enable: Bool) {
        /* // MARK: 目前沒有用到, 有需要時再開啟
        // disable color
        guard let color = self.config.disableBGColor else {
            return
        }
        
        let bgColor: UIColor = enable ? .clear : color
        self.inputViewBGColor.accept(bgColor)
         */
    }
}
