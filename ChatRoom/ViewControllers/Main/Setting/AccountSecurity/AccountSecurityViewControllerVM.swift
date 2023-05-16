//
//  AccountSecurityViewControllerVM.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/7/5.
//

import Foundation
import RxSwift

enum SecurityOption: String, CaseIterable {
    case id
    case phone
    case password
    case securityPassword
    
    var title: String {
        switch self {
        case .id:
            return Localizable.userID
        case .phone:
            return Localizable.cellphoneNumbers
        case .password:
            return Localizable.guPassword
        case .securityPassword:
            return Localizable.securityPassword
        }
    }
    
    var cellIdentifier: String {
        switch self {
        case .password, .securityPassword:
            return SettingCellType.titleArrow.cellIdentifier
        default:
            return SettingCellType.title.cellIdentifier
        }
    }
}

class AccountSecurityViewControllerVM: BaseViewModel {
    enum ActionType {
        case none
        case logout
        
        var confirmMessage: String? {
            switch self {
            case .logout:
                return Localizable.logoutHint
            default:
                return nil
            }
        }
        
        var actionTitle: String? {
            switch self {
            case .logout:
                return Localizable.logout
            default:
                return nil
            }
        }
    }
    
    struct Input {
        let logoutTap = PublishSubject<Void>()
    }
    
    struct Output {
        let alertSetting = PublishSubject<(String?, String?)>()
        let gotoLogin = PublishSubject<Void>()
    }
    
    var disposeBag = DisposeBag()
    let cellOptions: [SecurityOption] = SecurityOption.allCases
    let hasSetSecurityCode = UserData.shared.userInfo?.hadSecurityCode ?? false
    let input = Input()
    let output = Output()
    private var actionType: ActionType = .none
    
    override init() {
        super.init()
        self.initBinding()
    }
    
    func doAction() {
        switch self.actionType {
        case .logout:
            self.logout()
        default:
            break
        }
    }
}

private extension AccountSecurityViewControllerVM {
    func initBinding() {
                
        self.input.logoutTap.subscribeSuccess { [unowned self] _ in
            self.setupAction(to: .logout)
        }.disposed(by: self.disposeBag)
    }
    
    func setupAction(to type: ActionType) {
        self.actionType = type
        self.output.alertSetting.onNext((type.confirmMessage, type.actionTitle))
    }
    
    private func logout() {
        ApiClient.logout().subscribe { error in
            print("### error", error)
        } onCompleted: { [weak self] in
            DataAccess.shared.logout()
            self?.output.gotoLogin.onNext(())
        }.disposed(by: self.disposeBag)
    }
}

extension AccountSecurityViewControllerVM: SettingViewModelProtocol {
    var cellTypes: [SettingCellType] {
        return [.title, .titleArrow]
    }
    
    func numberOfRows() -> Int {
        return cellOptions.count
    }
    
    func cellIdentifier(at index: Int) -> String {
        return cellOptions[index].cellIdentifier
    }
    
    func cellConfig(at index: Int) -> SettingCellConfig {
        let option = cellOptions[index]
        switch option {
        case .id:
            let val = UserData.shared.userInfo?.username ?? ""
            return SettingCellConfig(leading: 16, title: option.title, subTitle: val, hiddenArrowRight: true)
        case .phone:
            let phone = UserData.shared.userInfo?.phone ?? ""
            let val = "+" + phone
            return SettingCellConfig(leading: 0, title: option.title, subTitle: val, hiddenArrowRight: true)
        case .password:
            return SettingCellConfig(leading: 0, title: option.title, subTitle: Localizable.alreadySetting, hiddenArrowRight: false)
        case .securityPassword:
            return SettingCellConfig(leading: 0, title: option.title, subTitle: self.hasSetSecurityCode ? Localizable.alreadySetting : Localizable.notSet, hiddenArrowRight: false)
        }
    }
    
    func getScene(at index: Int) -> Navigator.Scene? {
        let option = cellOptions[index]
        switch option {
        case .password:
            let vm = ChangePasswordViewControllerVM.init(type: .withOldPassword)
            return Navigator.Scene.changePassword(vm: vm)
        case .securityPassword:
            let vm = ChangeSecurityPasswordViewControllerVM.init(type: self.hasSetSecurityCode ? .withOldSecurityPassword : .withoutOldSecurityPassword, isFromCheckBinding: false)
            return Navigator.Scene.changeSecurityPassword(vm: vm)
        default:
            return nil
        }
    }
}
