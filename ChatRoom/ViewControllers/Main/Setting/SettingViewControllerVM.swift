//
//  SettingViewControllerVM.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/6/30.
//

import UIKit
import RxSwift
import RxCocoa

enum SettingCellType {
    case title
    case titleArrow
    case titleSwitch
    case iconTitleArrow
    case icon
    case iconDescription

    var cellClass: AnyClass {
        switch self {
        case .title:
            return TitleTableViewCell.self
        case .titleArrow:
            return TitleArrowTableViewCell.self
        case .titleSwitch:
            return TitleSwitchTableViewCell.self
        case .iconTitleArrow:
            return IconTitleArrowTableViewCell.self
        case .icon:
            return MemberTableViewCell.self
        case .iconDescription:
            return MemberDescriptionTableViewCell.self
        }
    }
    
    var cellIdentifier: String {
        switch self {
        case .title:
            return "TitleTableViewCell"
        case .titleArrow:
            return "TitleArrowTableViewCell"
        case.titleSwitch:
            return "TitleSwitchTableViewCell"
        case .iconTitleArrow:
            return "IconTitleArrowTableViewCell"
        case .icon:
            return "MemberTableViewCell"
        case .iconDescription:
            return "MemberDescriptionTableViewCell"
        }
    }
}

protocol SettingViewModelProtocol {
    associatedtype CellConfig
    var cellTypes: [SettingCellType] { get }
    func numberOfRows() -> Int
    func cellIdentifier(at index: Int) -> String
    func cellConfig(at index: Int) -> CellConfig
    func getScene(at index: Int) -> Navigator.Scene?
}

struct SettingCellConfig: CellConfigProtocol {
    var leading: CGFloat
    var title: String
    var subTitle: String = ""
    var icon: String = ""
    var hiddenArrowRight: Bool
}

class SettingViewControllerVM: BaseViewModel, SettingViewModelProtocol {
    enum SettingOption: CaseIterable {
        case credit
        case notify
        case accountSecurity
        case blockList
        case share
        case aboutStock
        
        var config: SettingCellConfig {
            return SettingCellConfig.init(leading: 16, title: self.title, subTitle: self.subTitle, icon: self.icon, hiddenArrowRight: self.hiddenArrowRight)
        }
        
        var icon: String {
            switch self {
            case .credit:
                return "iconPopint"
            case .notify:
                return "iconIconAlertNotification"
            case .accountSecurity:
                return "iconIconLock"
            case .blockList:
                return "iconIconBlackList"
            case .share:
                return "iconIconShare"
            case .aboutStock:
                return "iconIconChartFillGu"
            }
        }
        
        var title: String {
            switch self {
            case .credit:
                return ""
            case .notify:
                return Localizable.messageNotify
            case .accountSecurity:
                return Localizable.accountSafe
            case .blockList:
                return Localizable.blockList
            case .share:
                return Localizable.share
            case .aboutStock:
                return Localizable.about
            }
        }
        
        var subTitle: String {
            switch self {
            case .aboutStock:
                return String(format: Localizable.version, Application.shared.appVersion)
            default:
                return ""
            }
        }
        
        var hiddenArrowRight: Bool {
            switch self {
            case .share:
                return true
            default:
                return false
            }
        }
    }
    
    var disposeBag = DisposeBag()
    let userName: String
    let cellTypes: [SettingCellType] = [.iconTitleArrow]
    let avatarImage: BehaviorRelay<UIImage?> = BehaviorRelay(value: UIImage.init(named: "avatarsPhoto"))
    let nickname: BehaviorRelay<String?> = BehaviorRelay(value: nil)
    let showShareContent = PublishSubject<ShareInfoModel>()
    let showLoading = BehaviorRelay<Bool>(value: false)
    let reloadData = PublishSubject<Void>()
    let cellOptions: [SettingOption] = SettingOption.allCases
    private (set) var hongBaoBalance: String = ""
    
    override init() {
        userName = UserData.shared.userInfo?.username ?? ""
        
        super.init()
        initBinding()
    }
    
    func numberOfRows() -> Int {
        return cellOptions.count
    }
    
    func cellIdentifier(at index: Int) -> String {
        return SettingCellType.iconTitleArrow.cellIdentifier
    }
    
    func cellConfig(at index: Int) -> SettingCellConfig {
        var configs: [SettingCellConfig] = []
        for option in cellOptions {
            if case .credit = option {
                let config = SettingCellConfig.init(leading: 16, title: self.hongBaoBalance, subTitle: option.subTitle, icon: option.icon, hiddenArrowRight: option.hiddenArrowRight)
                configs.append(config)
            } else {
                configs.append(option.config)
            }
        }
        return configs[index]
    }
    
    func getScene(at index: Int) -> Navigator.Scene? {
        let option = cellOptions[index]
        switch option {
        case .credit:
            let vm = CreditViewControllerVM.init()
            return Navigator.Scene.credit(vm: vm)
        case .notify:
            let vm = SettingNotifyViewControllerVM.init()
            return Navigator.Scene.notify(vm: vm)
        case .accountSecurity:
            let vm = AccountSecurityViewControllerVM.init()
            return Navigator.Scene.account(vm: vm)
        case .aboutStock:
            let vm = AboutViewControllerVM.init()
            return Navigator.Scene.about(vm: vm)
        case .share:
            getShareContent()
            return nil
        case .blockList:
            let vm = SearchListViewControllerVM.init(.blockedList)
            return Navigator.Scene.searchList(vm: vm)
        }
    }
    
    func getPersonalInformationVM() -> PersonalInformationViewControllerVM {
        return PersonalInformationViewControllerVM.init()
    }
    
    func setHongBaoBalance() {
        DataAccess.shared.getWalletBalance { [weak self] _, balance in
            guard let self = self else { return }
            var userBalance: String
            if let balance = balance {
                userBalance = balance.isEmpty ? "0" : balance
                UserData.shared.setData(key: .userBalance, data: userBalance)
            } else {
                // if failed, use UserDefault data
                userBalance = UserData.shared.getData(key: .userBalance) as? String ?? "0"
            }
            self.hongBaoBalance = userBalance
            self.reloadData.onNext(())
        }
    }
    
    private func getShareContent() {
        showLoading.accept(true)
        DataAccess.shared.fetchShareLink { [weak self] model in
            self?.showLoading.accept(false)
            guard let self = self, let model = model else { return }
            self.showShareContent.onNext(model)
        }
    }
    
    private func initBinding() {
        DataAccess.shared.userInfo.avatarThumbnail.bind(to: self.avatarImage).disposed(by: self.disposeBag)
        DataAccess.shared.userInfo.nickname.bind(to: self.nickname).disposed(by: self.disposeBag)
    }
}
