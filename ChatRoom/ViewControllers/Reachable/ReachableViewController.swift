//
//  ReachableViewController.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/5/13.
//

import Foundation

class ReachableViewController<T: ReachableViewControllerVM>: BaseVC {
    var viewModel: T!
    
    override func initBinding() {
        super.initBinding()
        
        self.viewModel.apiErrorCause.subscribeSuccess { [unowned self] (error) in
            self.showErrorAlert(error)
        }.disposed(by: self.disposeBag)
    }
}

private extension ReachableViewController {
    func showErrorAlert(_ error: ApiError) {
        switch error {
        case .unreachable:
            self.showAlert(message: Localizable.checkNetworkSetting, cancelBtnTitle: Localizable.cancel, comfirmBtnTitle: Localizable.learnMore, onConfirm: { [unowned self] in
                self.navigator.show(scene: .unreachableHint, sender: self, transition: .present(animated: true))
            })
        case .requestError(code: _, requestID: _, present: let present):
            self.showAlert(message: present.message, comfirmBtnTitle: Localizable.learnMore)
        default:
            PRINT(error.localizedString, cate: .error)
        }
    }
}
