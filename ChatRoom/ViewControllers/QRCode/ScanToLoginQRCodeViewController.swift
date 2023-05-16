//
//  ScanToLoginQRCodeViewController.swift
//  ChatRoom
//
//  Created by Kedia on 2023/4/14.
//

import Foundation
import RxSwift

class ScanToLoginQRCodeViewController: ScanQRCodeViewController<ScanToLoginQRCodeViewControllerVM> {
    
    static func initVC(with vm: ScanToLoginQRCodeViewControllerVM) -> ScanToLoginQRCodeViewController {
        let vc = ScanToLoginQRCodeViewController()
        vc.viewModel = vm
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hintString = Localizable.scanQRToLoginHint
    }
    
    override func initBinding() {
        super.initBinding()
        
        // QR Code 內容不是用來登入用的
        viewModel.wrongQRCodeContentSubject.observe(on: MainScheduler.instance).subscribeOn(next: { [weak self] in
            self?.toastManager.showToast(message: Localizable.parseQrCodeFailed)
        }).disposed(by: disposeBag)

        // show/hide LoadingView
        viewModel.showLoading.observe(on: MainScheduler.instance).subscribeOn(next: { isLoading in
            isLoading ? LoadingView.shared.show() : LoadingView.shared.hide()
        }).disposed(by: self.disposeBag)
        
        // 掃到了登入用的 QR code
        viewModel.isLoginWithNewDeviceSubject.observe(on: MainScheduler.instance).subscribeOn(next: { [weak self] (isNewDevice, deviceID, data) in
            
            guard let self else { return }
            
            // 使用者用的瀏覽器之前已經用 QR Code 登入過了，pop 掉這個掃瞄頁
            if !isNewDevice {
                self.navigator.pop(sender: self)
                return
            }
            
            // 使用者用是第一次用這個瀏覽器用 QR Code 登入，進輸入驗證碼頁面
            let vm = InputPasscodeViewControllerVM(deviceID: deviceID, data: data)
            
            // passcode 驗證成功後，連這個掃瞄頁也 pop 掉
            vm.passcodeDidPassSubject.subscribe { [weak self] _ in
                guard let self else { return }
                
                self.navigator.pop(sender: self)
            }.disposed(by: self.disposeBag)
            
            self.navigator.show(scene: .inputPasscode(vm: vm), sender: self, transition: .custom(animated: true)) { [weak self] in
                self?.viewModel.enableScanning = true
            }
            
        }).disposed(by: self.disposeBag)
    }
}
