//
//  ScanToLoginQRCodeViewControllerVM.swift
//  ChatRoom
//
//  Created by Kedia on 2023/4/14.
//

import Foundation
import RxSwift
import RxCocoa

class ScanToLoginQRCodeViewControllerVM: ScanQRCodeViewControllerVM {
    
    let showLoading: PublishRelay<Bool> = PublishRelay<Bool>()
    let isLoginWithNewDeviceSubject = PublishSubject<(isNewDevice: Bool, deviceID: String, data: String)>()
    let wrongQRCodeContentSubject = PublishSubject<Void>()
    var enableScanning: Bool = true
    
    private let disposeBag = DisposeBag()
    
    // 這個 method 會在一秒內被呼叫許多次，為避免在一個 request 還沒回來之前就發出第二個 request，所以透過 Task 做 queue 的處理
    override func handleQRCode(with qrCodeString: String) {
        if !enableScanning {
            return
        }
        Task {
            await _handle(qrCodeString: qrCodeString)
        }
    }
    
    private func _handle(qrCodeString: String) async {
        
        enableScanning = false
        
        await withCheckedContinuation { [weak self] cont in
                        
            guard let data = qrCodeString.data(using: .utf8), let dataModel = try? JSONDecoder().decode(ScanToLoginQRCodeModel.self, from: data), let deviceID = dataModel.device_id, let data = dataModel.data else {
                self?.wrongQRCodeContentSubject.onNext(())
                self?.enableScanning = true
                cont.resume()
                return
            }
            
            self?.showLoading.accept(true)
            ApiClient.scanQRCodeLogin(deviceID: deviceID, data: data).subscribe(onNext: { [weak self] (result) in
                
                guard let self else {
                    self?.enableScanning = true
                    cont.resume()
                    return
                }
                
                self.showLoading.accept(false)
                
                guard let resultType = result.type else {
                    assertionFailure("result type 應該要有值，且為 2 或 3")
                    self.enableScanning = true
                    cont.resume()
                    return
                }
                
                self.isLoginWithNewDeviceSubject.onNext((resultType == .newDevice, deviceID, data))
                cont.resume()
                
            }, onError: { [weak self] _ in
                self?.enableScanning = true
                self?.showLoading.accept(false)
                cont.resume()
            }).disposed(by: disposeBag)
        }
        
    }
}
