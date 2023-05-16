//
//  TermsViewControllerVM.swift
//  ChatRoom
//
//  Created by Saffi Peng on 2021/8/6.
//

import Foundation
import RxSwift
import RxCocoa

class TermsViewControllerVM: BaseViewModel {

    var disposeBag = DisposeBag()

    let title: BehaviorRelay<String> = BehaviorRelay(value: "")
    let url: BehaviorRelay<String> = BehaviorRelay(value: "")

    init(title: String, url: String) {
        super.init()

        self.title.accept(title)
        self.url.accept(url)
    }
}
