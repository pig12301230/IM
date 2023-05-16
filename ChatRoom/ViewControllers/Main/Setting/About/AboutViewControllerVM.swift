//
//  AboutViewControllerVM.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/7/6.
//

import RxSwift

enum AboutOption: String, CaseIterable {
    case version
    case provision
    case privacy
    case deleteAccount
    
    var title: String {
        switch self {
        case .version:
            return Localizable.useVersion
        case .provision:
            return Localizable.termsOfService
        case .privacy:
            return Localizable.privacyPolicy
        case .deleteAccount:
            return Localizable.deleteAccount
        }
    }
    
    var subTitle: String {
        switch self {
        case .version:
            return String(format: Localizable.version, Application.shared.appVersion)
        case .provision, .privacy, .deleteAccount:
            return ""
        }
    }
    
    var cellIdentifier: String {
        switch self {
        case .version, .deleteAccount:
            return SettingCellType.title.cellIdentifier
        case .provision, .privacy:
            return SettingCellType.titleArrow.cellIdentifier
        }
    }

    var url: String {
        switch self {
        case .version, .deleteAccount:
            return ""
        case .provision:
            return AppConfig.Info.servicePolicy
        case .privacy:
            return AppConfig.Info.privacyPolicy
        }
    }
}

class AboutViewControllerVM: BaseViewModel {
    struct Output {
        let loadWebView = PublishSubject<AboutOption>()
    }
    private var disposeBag = DisposeBag()

    let showDeleteAccountAlert: PublishSubject<Void> = .init()
    let gotoLogin: PublishSubject<Void> = .init()
    let navigateTo: PublishSubject<Navigator.Scene> = .init()
    let cellOptions: [AboutOption] = AboutOption.allCases
    let output = Output()
    
}

extension AboutViewControllerVM: SettingViewModelProtocol {
    var cellTypes: [SettingCellType] {
        return [.title, .titleArrow]
    }
    
    func numberOfRows() -> Int {
        return cellOptions.count
    }
    
    func cellIdentifier(at index: Int) -> String {
        let option = cellOptions[index]
        return option.cellIdentifier
    }
    
    func cellConfig(at index: Int) -> SettingCellConfig {
        let option = cellOptions[index]
        switch option {
        case .version:
            return SettingCellConfig(leading: 16, title: option.title, subTitle: option.subTitle, hiddenArrowRight: true)
        case .provision:
            return SettingCellConfig(leading: 16, title: option.title, subTitle: option.subTitle, hiddenArrowRight: false)
        case .privacy:
            return SettingCellConfig(leading: 0, title: option.title, subTitle: option.subTitle, hiddenArrowRight: false)
        case .deleteAccount:
            return SettingCellConfig(leading: 0, title: option.title, subTitle: option.subTitle, hiddenArrowRight: true)
        }
    }
    
    func getScene(at index: Int) -> Navigator.Scene? {
        // 目前這個VM 用不到這個 function
        return nil
    }
    
    func didSelect(at index: Int) {
        let option = cellOptions[index]
        switch option {
        case .deleteAccount:
            self.showDeleteAccountAlert.onNext(())
        case .privacy, .provision:
            let vm = TermsViewControllerVM(title: option.title, url: option.url)
            self.navigateTo.onNext(.termsHint(vm: vm))
        default:
            break
        }
    }
    
    func deleteAccount() {
        ApiClient.deleteAccount().subscribe(onCompleted: { [weak self] in
            DataAccess.shared.deleteAccount {
                self?.gotoLogin.onNext(())
            }
        }).disposed(by: self.disposeBag)
    }
}
