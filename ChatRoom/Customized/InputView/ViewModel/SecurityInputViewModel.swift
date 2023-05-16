//
//  SecurityInputViewModel.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/4/16.
//

import RxCocoa
import RxSwift

class SecurityInputViewModel: FormInputViewModel {
    
    let changeSecurity = PublishSubject<Void>()
    let isSecurity: BehaviorRelay<Bool> = BehaviorRelay(value: true)
    let securityImage: BehaviorRelay<UIImage?> = BehaviorRelay(value: nil)
    
    override init(type: String.ValidateType = .vtNone, limit: InputLimit? = nil, config: InputViewConfig = InputViewConfig.init(), hintConfig: FormInputViewModel.HintViewConfig) {
        super.init(type: type, limit: limit, config: config)
        self.config.clearButtonMode = .never
    }
    
    override func initBinding() {
        super.initBinding()
        self.changeSecurity.subscribeSuccess { [unowned self] in
            let status = !self.isSecurity.value
            self.updateSecuritySetting(status)
        }.disposed(by: self.disposeBag)
    }
}

private extension SecurityInputViewModel {
    
    func updateSecuritySetting(_ isSecurity: Bool) {
        self.isSecurity.accept(isSecurity)
        let image = isSecurity ? UIImage.init() : UIImage.init()
        self.securityImage.accept(image)
    }
}
