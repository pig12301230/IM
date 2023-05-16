//
//  InputPasscodeViewControllerVM.swift
//  ChatRoom
//
//  Created by Kedia on 2023/4/17.
//

import Foundation
import RxSwift

final class InputPasscodeViewControllerVM {
    
    let passcodeDidPassSubject = PublishSubject<Void>()
    let passcodeDidExpiredSubject = PublishSubject<Void>()
    let showInvalidAccessAlert = PublishSubject<Void>()
    
    init(deviceID: String, data: String) {
        self.deviceID = deviceID
        self.data = data
    }
    
    func validate(passcode: String) async -> Bool {
        
        guard validateObserver == nil else {
            return false
        }
        do {
            return try await withCheckedThrowingContinuation { cont in
                validateObserver = ApiClient.validateLoginQRCode(deviceID: deviceID, data: data, passcode: passcode).subscribe(onNext: {_ in
                    
                }, onError: { [weak self] error in
                    
                    guard let e = error as? ApiError else {
                        self?.validateObserver = nil
                        cont.resume(returning: false)
                        return
                    }
                    
                    switch e {
                    case .requestError(code: let code, requestID: _, present: _):
                        // 代碼過期了，要回掃瞄 QR Code 頁面
                        if code.contains("forbidden") {
                            self?.passcodeDidExpiredSubject.onNext(())
                        }
                        cont.resume(returning: false)
                    case .invalidAccess, .noAccess:
                        self?.showInvalidAccessAlert.onNext(())
                        cont.resume(returning: false)
                    default:
                        cont.resume(returning: false)
                    }
                    self?.validateObserver = nil
                    
                }, onCompleted: { [weak self] in
                    
                    self?.validateObserver = nil
                    cont.resume(returning: true)
                    self?.passcodeDidPassSubject.onNext(())
                    
                })
                validateObserver?.disposed(by: disposeBag)
            }
        } catch {
            validateObserver = nil
            return false
        }
    }
    
    private var deviceID: String
    private var data: String
    private var validateObserver: Disposable?
    private let disposeBag = DisposeBag()
}
