//
//  IndexListCellVM.swift
//  ChatRoom
//
//  Created by Andy Yang on 2021/6/2.
//

import Foundation
import RxSwift
import RxCocoa

class IndexListCellVM: BaseTableViewCellVM {
    let index: BehaviorRelay<String> = BehaviorRelay(value: "")
    var data: String?
    
    convenience init(data: String?) {
        self.init()
        self.data = data
    }
    
    override init() {
        super.init()
        self.cellIdentifier = "IndexListCell"
    }
    
    func setupViews() {
        guard let data = data else { return }
        index.accept(data)
    }
}
