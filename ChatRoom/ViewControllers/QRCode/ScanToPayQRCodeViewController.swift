//
//  ScanToPayQRCodeViewController.swift
//  ChatRoom
//
//  Created by ERay_Peng on 2023/4/13.
//

import AVFoundation
import UIKit

class ScanToPayQRCodeViewController: ScanQRCodeViewController<ScanToPayQRCodeViewControllerVM> {
    
    private lazy var imgAlbum: UIImageView = {
        let imgView = UIImageView()
        imgView.image = UIImage(named: "iconIconPictureFill")?.withRenderingMode(.alwaysTemplate)
        imgView.tintColor = .white
        return imgView
    }()

    static func initVC(with vm: ScanToPayQRCodeViewControllerVM) -> ScanToPayQRCodeViewController {
        let vc = ScanToPayQRCodeViewController()
        vc.viewModel = vm
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.addBottomStackViewSubViews(with: imgAlbum)
    }
    
    override func initBinding() {
        super.initBinding()
        imgAlbum.rx.click.subscribeSuccess { _ in
            PhotoLibraryManager.open(sender: self, type: .photo) { [weak self] image in
                guard let self = self else { return }
                guard let image = image else { return }
                // TODO: function upcomplete
                if let features = ImageProcessor.shared.detectQRCode(image),
                   let link = features.first as? CIQRCodeFeature,
                   let linkString = link.messageString {
                    self.viewModel.handleQRCode(with: linkString)
                } else {
//                    LogHelper.print(.error, item: "didn't detect QR Code")
                }
            }
        }.disposed(by: disposeBag)
        
        self.viewModel.finishedScan.subscribeSuccess { _ in
            self.navigator.pop(sender: self)
        }.disposed(by: disposeBag)
    }
}
