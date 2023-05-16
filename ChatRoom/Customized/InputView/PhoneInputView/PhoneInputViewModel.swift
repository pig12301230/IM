//
//  PhoneInputViewModel.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/5/13.
//

import RxCocoa
import libPhoneNumber_iOS

class PhoneInputViewModel: MultipleRulesInputViewModel {
    
    let countryCode: BehaviorRelay<String?> = BehaviorRelay(value: nil)

    override func initBinding() {
        super.initBinding()

        self.typeTitle.distinctUntilChanged().subscribeSuccess { [unowned self] _ in
            self.examineInput(input: self.outputText.value ?? "")
        }.disposed(by: self.disposeBag)
    }
    
    override func setupStatusImage() {
        guard self.needCheck else {
            return
        }
        
        let image = self.output.correct.value ? UIImage.init(named: "iconIconCheckAll") : UIImage.init(named: "iconIconAttention")
        self.statusImage.accept(image)
    }
    
    override func examineInput(input: String) {
        super.examineInput(input: input)
        guard let code = self.countryCode.value, code.count > 0 else {
            return
        }
        
        do {
            let phoneNumber = try NBPhoneNumberUtil.sharedInstance().parse(input, defaultRegion: code)
            let isValid = NBPhoneNumberUtil.sharedInstance().isValidNumber(phoneNumber)
            self.output.correct.accept(isValid)
        } catch {
            self.output.correct.accept(false)
        }
        self.setupStatusImage()
    }
}
