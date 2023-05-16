//
//  ScanToPayQRCodeViewControllerVM.swift
//  ChatRoom
//
//  Created by ERay_Peng on 2023/4/13.
//

import Foundation
import RxSwift
import RxCocoa

class ScanToPayQRCodeViewControllerVM: ScanQRCodeViewControllerVM {
    typealias ScanResult = (String?) -> Void
    
    private var scanResult: ScanResult
    let finishedScan = PublishSubject<Void>()
    
    init(result: @escaping ScanResult) {
        self.scanResult = result
        super.init()
    }
    
    override func handleQRCode(with qrCodeString: String) {
        self.scanResult(qrCodeString)
        self.finishedScan.onNext(())
    }
}
