//
//  SelectRegionViewController.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/4/20.
//

import UIKit

class SelectRegionViewController: BaseVC, UISearchBarDelegate {
    
    var viewModel: SelectRegionViewControllerVM!
    
    private lazy var tableView: UITableView = {
        let tView = UITableView.init()
        tView.delegate = self
        tView.dataSource = self
        tView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tView.theme_separatorColor = Theme.c_07_neutral_900_10.rawValue
        tView.register(RegionTableViewCell.self, forCellReuseIdentifier: "RegionTableViewCell")
        return tView
    }()
    
    private lazy var searchBar: SearchView = {
        let sBar = SearchView.init(with: self.viewModel.searchViewModel)
        return sBar
    }()
    
    static func initVC(with vm: SelectRegionViewControllerVM) -> SelectRegionViewController {
        let vc = SelectRegionViewController.init()
        vc.barType = .pure
        vc.title = Localizable.selectCountryAndRegion
        vc.viewModel = vm
        return vc
    }
    
    override func setupViews() {
        super.setupViews()
        
        self.view.addSubview(self.searchBar)
        self.view.addSubview(self.tableView)
        
        self.searchBar.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(52)
        }

        self.tableView.snp.makeConstraints { (make) in
            make.top.equalTo(self.searchBar.snp.bottom)
            make.bottom.leading.trailing.equalToSuperview()
        }
    }
    
    override func initBinding() {
        super.initBinding()
        self.viewModel.reloadData.subscribeSuccess { [unowned self] _ in
            self.tableView.reloadData()
            
            guard self.viewModel.numberOfRows(in: 0) > 0 else {
                return
            }
            self.tableView.scrollToRow(at: IndexPath.init(row: 0, section: 0), at: .top, animated: true)
        }.disposed(by: self.disposeBag)
    }
    
    override func viewIsMovingFromParent() {
        super.viewIsMovingFromParent()
        self.searchBar.reset()
        self.viewModel.resetSearch()
    }
}

extension SelectRegionViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.numberOfRows(in: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let config = self.viewModel.cellConfigModel(in: indexPath) else {
            let cell: UITableViewCell = UITableViewCell.init()
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "RegionTableViewCell", for: indexPath)
        if let cell = cell as? RegionTableViewCell {
            cell.setup(with: config)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.viewModel.didSelected(at: indexPath)
        self.navigator.pop(sender: self)
    }
}
