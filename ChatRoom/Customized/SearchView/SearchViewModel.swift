//
//  SearchViewModel.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/4/27.
//

import RxCocoa

struct SearchViewConfig {
    var underLine: Bool = true
    var defaultKey: String = ""
    var placeHolder: String?
    var maxLength: Int = 24
    var underLineTheme: Theme = Theme.c_07_neutral_900_10
}

class SearchViewModel: BaseViewModel {

    let searchString: BehaviorRelay<String> = BehaviorRelay(value: "")
    let doSearch: PublishRelay<String> = PublishRelay()
    private(set) var config: SearchViewConfig
    
    init(config: SearchViewConfig = SearchViewConfig.init()) {
        self.config = config
        super.init()
    }
}
