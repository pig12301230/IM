//
//  TitleSwitchTableViewCellVM.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/7/5.
//

import UIKit
import RxSwift
import RxCocoa

class TitleSwitchTableViewCellVM: BaseTableViewCellVM, SwitchOptionProtocol {
    typealias OptionType = OptionTypeProtocol
    
    struct Input {
        let switchStatus: BehaviorRelay<Bool>
        let isEnable: BehaviorRelay<Bool> = BehaviorRelay(value: true)
    }
    
    struct Output {
        let switchStatus = PublishSubject<Bool>()
        let confirmAlert = PublishSubject<(OptionType, String)>()
        let execOffAction = PublishSubject<OptionType>()
        let execOnAction = PublishSubject<OptionType>()
    }
    
    var disposeBag = DisposeBag()
    let input: Input
    let output = Output()
    private(set) var config: NotifyCellConfig
    private(set) var option: OptionType
    
    required init(config: NotifyCellConfig, option: OptionType, enable: Bool = true) {
        self.config = config
        self.option = option
        self.input = Input(switchStatus: BehaviorRelay(value: config.notify.value))
        
        super.init()
        self.input.isEnable.accept(config.isEnable)
        self.cellIdentifier = SettingCellType.titleSwitch.cellIdentifier
        self.initBinding()
    }
    
    private func initBinding() {
        
        self.input.switchStatus.subscribeSuccess { [unowned self] isOn in
            guard isOn != self.config.notify.value else {
                return
            }
            
            self.config.notify = isOn ? .on : .off
            let message: String? = isOn ? self.config.onConfirm : self.config.offConfirm
            
            guard let msg = message else {
                self.execAction(isOn)
                return
            }
            self.output.confirmAlert.onNext((self.option, msg))
        }.disposed(by: self.disposeBag)
    }
    
    func execAction(_ isOn: Bool) {
        if isOn {
            self.output.execOnAction.onNext(self.option)
        } else {
            self.output.execOffAction.onNext(self.option)
        }
    }
    
    func cancelAction() {
        self.config.notify = self.config.notify == .on ? .off : .on
        let isOn = self.config.notify == .on ? true : false
        self.output.switchStatus.onNext(isOn)
    }
}
