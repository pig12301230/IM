//
//  ListTableViewCellVM.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/5/3.
//

import Foundation

protocol CellViewModelProtocol {
    var cellIdentifier: String { get }
}

class BaseTableViewCellVM: BaseViewModel, CellViewModelProtocol {
    var cellIdentifier: String = "BaseTableViewCellVM"
}
