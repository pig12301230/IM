//
//  SearchListViewController.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/5/28.
//

import UIKit

public class SearchListViewController<T: SearchListViewControllerVM>: ListViewController<T> {
    
    private var firstAppear: Bool = true
    
    private(set) lazy var searchView: SearchView = {
        let sView = SearchView.init(with: self.viewModel.searchVM)
        return sView
    }()
    
    static func initVC(with vm: SearchListViewControllerVM) -> SearchListViewController {
        let vc = SearchListViewController.init()
        vc.barType = .pure
        vc.title = vm.title
        if let viewModel = vm as? T {
            vc.viewModel = viewModel
        }
        return vc
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    override func setupViews() {
        super.setupViews()
        self.view.addSubview(self.searchView)
        
        self.searchView.snp.makeConstraints { (make) in
            make.leading.trailing.top.equalToSuperview()
            make.height.equalTo(52)
        }
        
        self.tableViewBG.snp.remakeConstraints { (make) in
            make.leading.bottom.trailing.equalToSuperview()
            make.top.equalTo(self.searchView.snp.bottom)
        }
    }
    
}
