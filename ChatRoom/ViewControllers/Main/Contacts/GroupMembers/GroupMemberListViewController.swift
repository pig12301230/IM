//
//  GroupMemberListViewController.swift
//  ChatRoom
//
//  Created by Andy Yang on 2021/6/7.
//

import Foundation
import RxSwift

class GroupMemberListViewController: BaseVC {
    var viewModel: GroupMemberListViewControllerVM!
    
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .grouped)
        table.delegate = self
        table.dataSource = self
        table.separatorStyle = .none
        table.theme_backgroundColor = Theme.c_07_neutral_0.rawValue
        table.register(FriendListCell.self)
        table.register(GroupMemberListHeaderView.self, forHeaderFooterViewReuseIdentifier: GroupMemberListHeaderView.headerID)
        return table
    }()
    
    private lazy var searchView: SearchView = {
        let view = SearchView.init(with: self.viewModel.searchVM)
        return view
    }()
    
    private lazy var emptyView: EmptyView = {
        let view = EmptyView()
        view.updateEmptyType(.noSearchResults)
        return view
    }()
    
    static func initVC(with vm: GroupMemberListViewControllerVM) -> GroupMemberListViewController {
        let vc = GroupMemberListViewController.init()
        vc.barType = .pure
        vc.viewModel = vm
        vc.title = vm.title()
        return vc
    }
    
    override func setupViews() {
        super.setupViews()
        view.theme_backgroundColor = Theme.c_07_neutral_50.rawValue
        view.addSubview(emptyView)
        view.addSubview(tableView)
        view.addSubview(searchView)
        
        emptyView.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        
        searchView.snp.makeConstraints {
            $0.leading.trailing.top.equalToSuperview()
            $0.height.equalTo(52)
        }
        
        tableView.snp.makeConstraints {
            $0.top.equalTo(searchView.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }
    
    override func initBinding() {
        super.initBinding()
        viewModel.reloadData.observe(on: MainScheduler.instance).subscribeSuccess { [weak self] in
            guard let self = self else { return }
            self.tableView.reloadData()
        }.disposed(by: disposeBag)
        viewModel.showEmptyView.observe(on: MainScheduler.instance).subscribeSuccess { [weak self] show in
            guard let self = self else { return }
            self.emptyView.isHidden = !show
            self.tableView.isHidden = show
        }.disposed(by: disposeBag)
    }
}

extension GroupMemberListViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.numberOfRow(in: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let vm = viewModel.cellViewModel(indexPath: indexPath) else { return UITableViewCell() }
        let cell = tableView.dequeueReusableCell(withIdentifier: vm.cellIdentifier, for: indexPath)
        if let cell = cell as? ImplementViewModelProtocol {
            cell.setupViewModel(viewModel: vm)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        viewModel.heightForRow(at: indexPath)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section == 0 else { return nil }
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: GroupMemberListHeaderView.headerID)
        if let header = header as? GroupMemberListHeaderView {
            header.label.text = viewModel.titleForHeader(in: section)
        }
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        viewModel.heightForHeader(in: section)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let detailVM = viewModel.detailViewModel(at: indexPath) else { return }
        navigator.show(scene: .chatDetail(vm: detailVM), sender: self, transition: .push(animated: true), completion: nil)
    }
}
