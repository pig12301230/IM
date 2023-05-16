//
//  LoginViewControllerVM.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/4/15.
//

import Foundation
import RxSwift
import RxCocoa

class LoginViewControllerVM: ReachableViewControllerVM {
    var disposeBag = DisposeBag()
    
    /// Output for view controller
    let submitEnable: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    let rememberButtonImage: BehaviorRelay<UIImage?>
    let loginSuccess = PublishSubject<Void>()
    
    /**
     呼叫API時使用, 當收到 error and complete(next) 呼叫
     */
    let showLoading: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    
    /// Input from view controller
    let submitLogin = PublishSubject<Void>()
    
    private(set) var regionInputViewModel: TitleInputViewModel
    private(set) var phoneInputViewModel: PhoneInputViewModel
    private(set) var passwordInputViewModel: MultipleRulesInputViewModel
    private(set) var regionSelectVM: SelectRegionViewControllerVM = SelectRegionViewControllerVM.init()
    private(set) var isRemember: Bool
    
    override init() {
        self.passwordInputViewModel = MultipleRulesInputViewModel.init(title: Localizable.password, needSecurity: true ,
                                                                       rules: .limit(min: 1, max: nil))
        self.passwordInputViewModel.maxInputLength = 16
        self.passwordInputViewModel.config.placeholder = Localizable.inputPassword
        
        self.regionInputViewModel = TitleInputViewModel.init(title: Localizable.countryAndRegion, inputEnable: false)
        self.regionInputViewModel.inputTextFont = .midiumParagraphLargeLeft
        
        self.isRemember = UserData.shared.getData(key: .remember) as? Bool ?? false
        let image = self.isRemember ? UIImage.init(named: "checkboxCheckedImage") : UIImage.init(named: "checkboxActiveImage")
        self.rememberButtonImage = BehaviorRelay(value: image)
        
        self.phoneInputViewModel = PhoneInputViewModel.init(title: "", rules: .custom(message: ""))
        self.phoneInputViewModel.config.placeholder = Localizable.inputCellphoneNumbers
        self.phoneInputViewModel.config.keyboardType = .numberPad
        self.phoneInputViewModel.maxInputLength = Application.shared.maxInputLenght
        
        if self.isRemember, let phone = UserData.shared.userPhone {
            self.phoneInputViewModel.config.defaultString = phone
        }
        self.regionSelectVM = SelectRegionViewControllerVM.init()

        super.init()
        self.initBinding()
    }
    
    func initBinding() {
        self.regionSelectVM.localeDigit.bind(to: self.phoneInputViewModel.typeTitle).disposed(by: self.disposeBag)
        self.regionSelectVM.localeCountryName.bind(to: self.regionInputViewModel.outputText).disposed(by: self.disposeBag)
        
        Observable.combineLatest(self.phoneInputViewModel.output.correct, self.passwordInputViewModel.output.correct).subscribeSuccess { [unowned self] (term1, term2) in
            self.submitEnable.accept(term1 && term2)
        }.disposed(by: self.disposeBag)
        
        self.submitLogin.subscribeSuccess { [unowned self] _ in
            self.doLoginAction()
        }.disposed(by: self.disposeBag)
        
        self.regionSelectVM.locateCountryCode.bind(to: self.phoneInputViewModel.countryCode).disposed(by: self.disposeBag)
    }
    
    func changeRememberStatus() {
        let remb = !self.isRemember
        self.isRemember = remb
        let image = remb ? UIImage.init(named: "checkboxCheckedImage") : UIImage.init(named: "checkboxActiveImage")
        self.rememberButtonImage.accept(image)
    }
    
    func resetCountryInfo() {
        self.regionSelectVM.setupDefaultCountryInfo()
    }
}

private extension LoginViewControllerVM {
    func doLoginAction() {
        guard self.showLoading.value == false else {
            return
        }
        
        guard self.isReachable() else {
            return
        }
        
        guard let digit = self.regionSelectVM.localeDigit.value,
              let number = self.phoneInputViewModel.outputText.value,
              let password = self.passwordInputViewModel.outputText.value else {
            return
        }
        
        self.showLoading.accept(true)
        var region: String = digit
        region.remove(at: region.startIndex)
        let phone = region + number
        
        ApiClient.parmaterLogin(country: self.regionSelectVM.localeCountryCode, phone: phone, password: password).subscribe(onNext: { [unowned self] (info) in
            DataAccess.shared.checkUserAccountAndDatabase(country: self.regionSelectVM.localeCountryCode, phone: number) {
                DataAccess.shared.saveUserInformation(info)
                UserData.shared.setData(key: .remember, data: self.isRemember)
                self.fetchUserInfo()
            }
        }, onError: { [unowned self] _ in
            self.showLoading.accept(false)
        }, onCompleted: nil, onDisposed: nil).disposed(by: self.disposeBag)
    }
    
    func fetchUserInfo() {
        DataAccess.shared.fetchUserMe().subscribe { [unowned self] _ in
            self.loginSuccess.onNext(())
            self.showLoading.accept(false)
        } onError: { [unowned self] _ in
            self.showLoading.accept(false)
        }.disposed(by: self.disposeBag)
    }
    
}
