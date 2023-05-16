//
//  SearchNavigationViewVM.swift
//  ChatRoom
//
//  Created by Saffi Peng on 2021/7/10.
//

import RxSwift
import RxCocoa

class SearchNavigationViewVM: BaseViewModel {

    struct Input {
        let onFocus: BehaviorRelay<Bool> = BehaviorRelay(value: true)
    }

    struct Output {
        let searchString: BehaviorRelay<String> = BehaviorRelay(value: "")
        let leaveSearch = PublishRelay<Void>()
    }

    private(set) var input = Input()
    private(set) var output = Output()

    private(set) var config: SearchViewConfig

    init(config: SearchViewConfig = SearchViewConfig()) {
        self.config = config
        super.init()
    }
}
