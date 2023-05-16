//
//  BaseIntrinsicTableViewVC.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/6/30.
//

import UIKit

protocol IntrinsicTableViewVCProtocol {
    func implementTableViewDelegateAndDataSource()
    func registerCells()
}

class BaseIntrinsicTableViewVC: BaseVC, IntrinsicTableViewVCProtocol {
    
    lazy var tableView: IntrinsicTableView = {
        let tView = IntrinsicTableView.init()
        tView.separatorStyle = .none
        tView.alwaysBounceVertical = false
        return tView
    }()
    
    override func setupViews() {
        super.setupViews()
        self.view.addSubview(self.tableView)
        self.registerCells()
        self.implementTableViewDelegateAndDataSource()
    }
    
    // MARK: - IntrinsicTableViewVCProtocol
    func implementTableViewDelegateAndDataSource() {
        fatalError("implementTableViewDelegateAndDataSource has not been override")
    }
    
    func registerCells() {
        
    }
}
