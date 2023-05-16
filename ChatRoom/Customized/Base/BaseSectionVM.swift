//
//  BaseSectionVM.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/5/3.
//

import Foundation

protocol SectionViewModelProtocol: AnyObject {
    var cellViewModels: [BaseTableViewCellVM] { get }
    var reuseIdentifier: String { get }
    var title: String { get }
    var cellCount: Int { get }
}

class BaseSectionVM: BaseViewModel, SectionViewModelProtocol {
    var cellViewModels: [BaseTableViewCellVM] = []
    var title: String = ""
    var cellCount: Int = 0
    
    var reuseIdentifier: String {
        return ""
    }
    
    override init() {
        super.init()
        self.cellCount = self.cellViewModels.count
    }
}
