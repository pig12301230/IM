//
//  ExchangeLoadingViewController.swift
//  GuChat
//
//  Created by ERay_Peng on 2023/2/16.
//

import AVFoundation
import UIKit


class ExchangeLoadingViewController: BaseVC {
    var viewModel: ExchangeLoadingViewControllerVM!
    var timer: Timer?
    static func initVC(with vm: ExchangeLoadingViewControllerVM) -> ExchangeLoadingViewController {
        let vc = ExchangeLoadingViewController.init()
        vc.title = Localizable.platFormExchange
        vc.viewModel = vm
        return vc
    }
    
    private lazy var imgLoading: UIImageView = {
        let img = UIImageView(image: UIImage(named: "emptyStatusTesting"))
        return img
    }()
    
    private lazy var lblLoading: UILabel = {
        let lbl = UILabel()
        lbl.text = Localizable.brandExchangeHint
        lbl.theme_textColor = Theme.c_05_warning_700.rawValue
        lbl.font = .boldParagraphMediumCenter
        lbl.textAlignment = .center
        lbl.numberOfLines = 0
        return lbl
    }()
    
    override func setupViews() {
        super.setupViews()
        self.view.theme_backgroundColor = Theme.c_07_neutral_50.rawValue
        
        self.view.addSubview(imgLoading)
        self.view.addSubview(lblLoading)
        
        imgLoading.snp.makeConstraints { make in
            let width = UIScreen.main.bounds.size.width * 160 / 414
            make.center.equalToSuperview()
            make.width.height.equalTo(width)
            
        }
        
        lblLoading.snp.makeConstraints { make in
            make.top.equalTo(imgLoading.snp.bottom)
            make.centerX.equalToSuperview()
            make.width.equalTo(imgLoading)
        }
    }
    
    override func initBinding() {
        super.initBinding()
        
        self.viewModel.exchangeResult.subscribeSuccess { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success, .addressFail:
                self.toastManager.showToast(hint: result.toastOrAlertTxt)
            case .addressErrorOrBindingUnmatch:
                let config = DisplayConfig(font: .regularParagraphLargeCenter, textColor: Theme.c_10_grand_1.rawValue.toColor(), text: result.toastOrAlertTxt)
                let okAction = UIAlertAction(title: Localizable.sure, style: .cancel, handler: nil)

                self.showAlert(title: nil, message: config, actions: [okAction])
            }
        }.disposed(by: disposeBag)
    }
}
