//
//  DataAccess+wallet.swift
//  ChatRoom
//
//  Created by ERay_Peng on 2023/4/20.
//

import Foundation
import RxSwift

extension DataAccess {
    func getMediumBinding() -> Observable<[WalletProviderModel]> {
        return Observable.create { observer -> Disposable in
            ApiClient.getMediumBinding()
                .subscribe(onNext: { model in
                    observer.onNext(model.providers.map({ return WalletProviderModel(with: $0) }))
                    observer.onCompleted()
                }, onError: { _ in
                    observer.onNext([])
                    observer.onCompleted()
                })
                .disposed(by: self.disposeBag)
            return Disposables.create()
        }
    }
    
    func wellPayExchange(_ amount: String, _ securityCode: String) -> Observable<Error?> {
        return Observable.create { observer -> Disposable in
            ApiClient.wellPayExchange(amount: amount, securityCode: securityCode)
                .subscribe(onError: { error in
                    observer.onNext(error)
                    observer.onCompleted()
                }, onCompleted: {
                    observer.onNext(nil)
                    observer.onCompleted()
                })
                .disposed(by: self.disposeBag)
            return Disposables.create()
        }
    }
    
    func bindWellPayWallet(_ code: String, _ address: String) -> Observable<Error?> {
        return Observable.create { observer -> Disposable in
            ApiClient.bindWellPayWallet(code: code, address: address)
                .subscribe(onError: { error in
                    observer.onNext(error)
                    observer.onCompleted()
                }, onCompleted: {
                    observer.onNext(nil)
                    observer.onCompleted()
                })
                .disposed(by: self.disposeBag)
            return Disposables.create()
        }
    }
}
