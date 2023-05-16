//
//  SettingNotifyViewControllerVM.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/7/2.
//

import Foundation
import RxSwift

class SettingNotifyViewControllerVM: BaseViewModel, SettingStatusVMProtocol {
    typealias Option = NotifyOption
    
    var disposeBag = DisposeBag()
    let cellOptions: [Option] = Option.allCases
    private(set) var cellVMs = [TitleSwitchTableViewCellVM]()
    
    let execOnAction = PublishSubject<TitleSwitchTableViewCellVM.OptionType>()
    let execOffAction = PublishSubject<TitleSwitchTableViewCellVM.OptionType>()
    let confirmAlert = PublishSubject<(TitleSwitchTableViewCellVM.OptionType, String)>()
    
    override init() {
        super.init()
        self.setupViewModels()
        self.initBinding()
    }    
    
    func confiromExecAction(_ option: TitleSwitchTableViewCellVM.OptionType) {
        if let cellVM = self.cellVMs.first(where: { $0.option.isEqual(to: option) }) {
            cellVM.execAction(cellVM.config.notify.value)
        }
    }
    
    func getEnable(_ option: Option) -> Bool {
        return true
    }
    
    // MARK: - SettingStatusVMProtocol
    func getStatus(_ option: Option) -> NotifyType {
        guard let userInfo = UserData.shared.userInfo else { return .off }
        switch option {
        case .newMessage:
            return userInfo.notify
        case .detail:
            return userInfo.notifyDetail
        case .vibration:
            return userInfo.vibration
        case .sound:
            return userInfo.sound
        }
    }
    
    func modifyStatus(_ option: Option, isOn: Bool) {
        let requestParameter = self.getParameter()
        ApiClient.modifyNotify(with: requestParameter).subscribe { [weak self] _ in
            self?.cancelAction(option)
        } onCompleted: { [weak self] in
            self?.updateCacheData(option, isOn: isOn)
        }.disposed(by: self.disposeBag)
    }
}

private extension SettingNotifyViewControllerVM {
    func initBinding() {
        self.execOnAction.subscribeSuccess { [unowned self] option in
            guard let option = option as? NotifyOption else { return }
            self.modifyStatus(option, isOn: true)
        }.disposed(by: self.disposeBag)
        
        self.execOffAction.subscribeSuccess { [unowned self] option in
            guard let option = option as? NotifyOption else { return }
            self.modifyStatus(option, isOn: false)
        }.disposed(by: self.disposeBag)
    }
    
    func setupViewModels() {
        self.cellVMs.removeAll()
        
        for enumerate in cellOptions.enumerated() {
            let option = self.cellConfig(at: enumerate.offset)
            let cellVM = TitleSwitchTableViewCellVM.init(config: option, option: enumerate.element)
            cellVM.output.confirmAlert.bind(to: self.confirmAlert).disposed(by: self.disposeBag)
            cellVM.output.execOnAction.bind(to: self.execOnAction).disposed(by: self.disposeBag)
            cellVM.output.execOffAction.bind(to: self.execOffAction).disposed(by: self.disposeBag)
            self.cellVMs.append(cellVM)
        }
        
        self.updateCacheData(.newMessage, isOn: UserData.shared.userInfo?.notify.value ?? false)
    }
    
    func getParameter() -> [String: Any] {
        var parameter = [String: Any]()
        for cellVM in self.cellVMs {
            parameter[cellVM.option.key] = cellVM.config.notify.rawValue
        }
        
        return parameter
    }
    
    func updateCacheData(_ option: NotifyOption, isOn: Bool) {
        if option == .newMessage {
            self.cellVMs.filter { !$0.option.isEqual(to: option) }.forEach { $0.input.isEnable.accept(isOn) }
        }
        
        let notify: NotifyType = isOn ? .on : .off
        UserData.shared.updateNotifyStatus(option, to: notify)
    }
}

extension SettingNotifyViewControllerVM: SettingViewModelProtocol {
    var cellTypes: [SettingCellType] {
        return [.titleSwitch]
    }
    
    func numberOfRows() -> Int {
        return cellOptions.count
    }
    
    func cellIdentifier(at index: Int) -> String {
        SettingCellType.titleSwitch.cellIdentifier
    }
    
    func cellConfig(at index: Int) -> NotifyCellConfig {
        let option = cellOptions[index]
        let notify = self.getStatus(option)
        let isEnable = self.getEnable(option)
        let leading: CGFloat = index == cellOptions.count - 1 ? 0 : 16
        return NotifyCellConfig(leading: leading, title: option.title, notify: notify, onConfirm: option.onConfirmMessage, offConfirm: option.offConfirmMessage, isEnable: isEnable)
    }
    
    func getScene(at index: Int) -> Navigator.Scene? {
        return nil
    }
    
}
