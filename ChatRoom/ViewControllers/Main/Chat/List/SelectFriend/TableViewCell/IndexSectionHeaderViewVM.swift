//
//  IndexSectionHeaderViewVM.swift
//  ChatRoom
//
//  Created by Andy Yang on 2021/6/30.
//

import Foundation
import RxSwift
import RxCocoa

class IndexSectionHeaderViewVM: BaseTableViewCellVM {
    private var data: String?
    
    let title: PublishRelay<String> = PublishRelay()
    
    override init() {
        super.init()
        self.cellIdentifier = "IndexSectionHeaderView"
    }
    
    convenience init(with data: String) {
        self.init()
        self.data = data
        setupViews()
    }
    
    func setupViews() {
        guard let data = data else { return }
        title.accept(data)
    }
}
