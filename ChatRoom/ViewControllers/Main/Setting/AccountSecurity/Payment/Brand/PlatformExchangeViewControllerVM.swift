//
//  PlatformExchangeViewControllerVM.swift
//  ChatRoom
//
//  Created by ERay_Peng on 2023/2/17.
//
import Foundation
import RxSwift
import RxCocoa

class PlatformExchangeViewControllerVM: BaseViewModel {
    
    struct Output {
        let btnStatusDidTouchUpIndside = PublishSubject<Void>()
        let exchangeEnable: BehaviorRelay<Bool> = BehaviorRelay(value: false)
        let gotoScene = PublishSubject<Navigator.Scene>()
        let addressInpuText = PublishSubject<String>()
        let showToast = PublishSubject<String>()
        let alert = PublishSubject<Void>()
    }
    
    struct Input {
        let exchangeAction = PublishSubject<Void>()
    }
    
    var disposeBag = DisposeBag()
    
    private(set) var addressInputViewModel: UserInteractiveStatusInputViewModel
    private(set) var securityPasswordInputViewModel: MultipleRulesInputViewModel
    
    let input = Input()
    let output = Output()
    
    override init() {
        self.addressInputViewModel = UserInteractiveStatusInputViewModel(title: Localizable.exchangeAddress, statusImageName: "iconIconFormScan")
        self.addressInputViewModel.config.placeholder = Localizable.pleaseEnterExchangeAddressOrScan
        
        self.securityPasswordInputViewModel = MultipleRulesInputViewModel.init(title: Localizable.securityPassword,
                                                                               check: false,
                                                                               rules: .specifyNumber(count: 6),
                                                                               needKerning: true,
                                                                               clearButtonMode: .never)
        
        self.securityPasswordInputViewModel.maxInputLength = 6
        self.securityPasswordInputViewModel.config.keyboardType = .numberPad
        
        super.init()
        self.initBinding()
    }
    
    func initBinding() {
        self.securityPasswordInputViewModel.output.correct.subscribeSuccess { [weak self] enable in
            guard let self = self else { return }
            self.output.exchangeEnable.accept(enable)
        }.disposed(by: self.disposeBag)
        
        self.addressInputViewModel.btnStatusDidTouchUpIndside.subscribeSuccess { [weak self] _ in
            guard let self = self else { return }
            let vm = ScanToPayQRCodeViewControllerVM { qrCode in
                guard let txt = qrCode else { return }
                self.output.addressInpuText.onNext(txt)
            }
            self.output.gotoScene.onNext(.scanToPayQRCode(vm: vm))
        }.disposed(by: self.disposeBag)
        
        self.input.exchangeAction.subscribeSuccess { [weak self] _ in
            guard let self = self else { return }
            self.exchange()
        }.disposed(by: self.disposeBag)
    }
    
    func goToLoading() {
        let vm = ExchangeLoadingViewControllerVM()
        self.output.gotoScene.onNext(.exchangeLoad(vm: vm))
    }
}

private extension PlatformExchangeViewControllerVM {
    
    func exchange() {
        guard let securityPassword = self.securityPasswordInputViewModel.outputText.value else {
            self.output.showToast.onNext(Localizable.sercurityPasswordInputError)
            return
        }
        // 輸入正確
        self.output.alert.onNext(())        
    }
}
