//
//  CreditViewControllerVM.swift
//  ChatRoom
//
//  Created by ERay_Peng on 2022/12/27.
//

import RxSwift
import RxCocoa

class CreditViewControllerVM: BaseViewModel {
    private var disposeBag = DisposeBag()
    private (set) var hongBaoRecords: [HongBaoRecord] = []
    
    let updateAmount = PublishSubject<String>()
    let showSetPwdAlert = PublishSubject<Void>()
    let goto: PublishRelay<Navigator.Scene> = PublishRelay()
    
    func fetchHongBaoRecord() {
        DataAccess.shared.getWalletBalanceRecord { [weak self] records in
            guard let self = self else { return }
            let dateOneMonthAgo = Date().addOrSubtractMonth(month: -1)
            self.hongBaoRecords = records.filter({ $0.createAt > dateOneMonthAgo }).sorted(by: { $0.createAt > $1.createAt })
            
            self.fetchBalance { balance in
                var userBalance: String
                if let balance = balance {
                    userBalance = balance.isEmpty ? "0" : balance
                    UserData.shared.setData(key: .userBalance, data: userBalance)
                } else {
                    // if failed, use UserDefault data
                    userBalance = UserData.shared.getData(key: .userBalance) as? String ?? "0"
                }
                self.updateAmount.onNext(userBalance)
            }
        }
    }
    
    func handleSecurityCodeHasSet() {
        guard let hadSecurityCode = UserData.shared.userInfo?.hadSecurityCode, hadSecurityCode else {
            self.showSetPwdAlert.onNext(())
            return
        }
        let vm = ExchangeViewControllerVM()
        self.goto.accept(.exchange(vm: vm))
    }
    
    func gotoSetSecurityPwd() {
        let vm = ChangeSecurityPasswordViewControllerVM.init(type: .withoutOldSecurityPassword, isFromCheckBinding: true)
        self.goto.accept(.changeSecurityPassword(vm: vm))
    }
    
    func isExchangeValid() async -> Bool {
        do {
            return try await withCheckedThrowingContinuation({ cont in
                DataAccess.shared.getMediumBinding().subscribeSuccess { providers in
                    guard !providers.isEmpty else {
                        cont.resume(returning: false)
                        return
                    }
                    cont.resume(returning: !providers.allSatisfy({ $0.enable == false }))
                }.disposed(by: disposeBag)
            })
        } catch {
            return false
        }
    }
}

private extension CreditViewControllerVM {
    func fetchBalance(completion: @escaping (String?) -> Void) {
        DataAccess.shared.getWalletBalance { _, balance in
            completion(balance)
        }
    }
}
