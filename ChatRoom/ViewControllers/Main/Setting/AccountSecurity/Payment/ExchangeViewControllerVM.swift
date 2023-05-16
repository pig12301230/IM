//
//  ExchangeViewControllerVM.swift
//  GuChat
//
//  Created by ERay_Peng on 2023/2/13.
//

import RxSwift
import RxCocoa

enum ExchangeType: CaseIterable {
    case wellPay
    //        case platform
    
    var title: String {
        switch self {
        case .wellPay:
            return Localizable.wellPayPointsExchange
//            case .platform:
//                return Localizable.brandPointsExchange
        }
    }
}


class ExchangeViewControllerVM: BaseViewModel, SettingViewModelProtocol {
    struct ExchangeOption {
        var type: ExchangeType
        var enable: Bool = false
        var isBind: Bool = false
        var walletAddress: String = ""
        var config: SettingCellConfig
    }
    
    var disposeBag = DisposeBag()
    let cellTypes: [SettingCellType] = [.titleArrow]
    var cellOptions: [ExchangeOption] = []
    private (set) var hongBaoBalance: String = ""
    
    let reloadRowAt: PublishRelay<Int> = .init()
    let showExchangeDisableAlert = PublishSubject<Void>()
    
    override init() {
        super.init()
        self.cellOptions = ExchangeType.allCases.map { type in
            return ExchangeOption(type: type, config: SettingCellConfig(leading: 0, title: type.title, hiddenArrowRight: false))
        }
    }
    
    func numberOfRows() -> Int {
        return cellOptions.count
    }
    
    func cellIdentifier(at index: Int) -> String {
        return SettingCellType.titleArrow.cellIdentifier
    }
    
    func cellConfig(at index: Int) -> SettingCellConfig {
        return self.cellOptions[index].config
    }
    
    func getScene(at index: Int) -> Navigator.Scene? {
        let option = cellOptions[index]
        switch option.type {
        case .wellPay:
            guard option.enable else {
                self.showExchangeDisableAlert.onNext(())
                return nil
            }
            guard option.isBind else {
                let vm = WellPayBindingViewControllerVM()
                return Navigator.Scene.wellPayBinding(vm: vm)
            }
            let vm = WellPayExchangeViewControllerVM(walletAddress: option.walletAddress)
            return Navigator.Scene.wellPayExchange(vm: vm)
//        case .platform:
//            let vm = PlatformExchangeViewControllerVM()
//            return Navigator.Scene.platformExchange(vm: vm)
        }
    }
    
    func fetchMediumBinding() {
        DataAccess.shared.getMediumBinding()
            .subscribeSuccess { [weak self] providers in
                guard let self = self else { return }
                _ = providers.map { provider in
                    switch provider.walletName {
                    case "wellpay":
                        if let index = self.cellOptions.firstIndex(where: { $0.type == .wellPay }) {
                            var newCellOptions = self.cellOptions
                            let newConfig = SettingCellConfig(leading: 0,
                                                              title: ExchangeType.wellPay.title,
                                                              subTitle: provider.isBind ? Localizable.hasBind : Localizable.notBindYet,
                                                              hiddenArrowRight: false)
                            newCellOptions[index].config = newConfig
                            newCellOptions[index].enable = provider.enable
                            newCellOptions[index].isBind = provider.isBind
                            newCellOptions[index].walletAddress = provider.bindAddress
                            self.cellOptions = newCellOptions
                            self.reloadRowAt.accept(index)
                        }
                    default:
                        break
                    }
                }
            }.disposed(by: disposeBag)
    }
}
