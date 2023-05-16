//
//  UserInteractiveStatusInputView.swift
//  ChatRoom
//
//  Created by ERay_Peng on 2023/4/14.
//

import UIKit

class UserInteractiveStatusInputView<T: UserInteractiveStatusInputViewModel>: TitleInputView<T> {
    override func bindViewModel() {
        super.bindViewModel()
        self.btnStatus.rx.click.bind(to: self.viewModel.btnStatusDidTouchUpIndside).disposed(by: disposeBag)
    }
}
