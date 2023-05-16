//
//  FriendListViewController.swift
//  ChatRoom
//
//  Created by ERay_Peng on 2022/3/23.
//

import UIKit
import RxSwift

class FriendListViewController: SearchListViewController<FriendListViewControllerVM> {
    
    private lazy var navItemAdd: UIBarButtonItem = {
        let btn = UIBarButtonItem.init(image: UIImage.init(named: "iconIconUserAdd")?.withRenderingMode(.alwaysTemplate),
                                       style: .plain,
                                       target: self,
                                       action: #selector(addFriend))
        btn.theme_tintColor = Theme.c_10_grand_1.rawValue
        return btn
    }()
    
    static func initVC(with vm: FriendListViewControllerVM) -> FriendListViewController {
        let vc = FriendListViewController.init()
        vc.barType = .pure
        vc.title = vm.title
        vc.viewModel = vm
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItem = self.navItemAdd
    }
    
    override func setupViews() {
        super.setupViews()
        self.unreachableTopView.snp.remakeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(self.searchView.snp.bottom)
            make.height.equalTo(44)
        }
    }
    
    override func initBinding() {
        super.initBinding()
        
        self.viewModel.loading.observe(on: MainScheduler.instance).subscribeSuccess { isLoading in
            isLoading ? LoadingView.shared.show() : LoadingView.shared.hide()
        }.disposed(by: self.disposeBag)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let vm = viewModel.cellViewModel(in: indexPath) else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SeeMoreTableViewCell", for: indexPath)
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: vm.cellIdentifier, for: indexPath)
        if let cell = cell as? ImplementViewModelProtocol {
            cell.setupViewModel(viewModel: vm)
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard self.viewModel.isSearchMode else {
            guard let vm = viewModel.withoutSearchingSectionViewModel(in: section) else { return nil }
            
            let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: vm.reuseIdentifier)
            if let view = header as? FriendListMainHeaderView {
                view.delegate = self
            }
            if let header = header as? ImplementViewModelProtocol {
                header.setupViewModel(viewModel: vm)
            }
            return header
        }
        
        return super.tableView(tableView, viewForHeaderInSection: section)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionModel = self.viewModel.sortedSectionVM[section]
        if !self.viewModel.isSearchMode {
            let isCollapse: Bool = UserDefaults.standard.bool(forKey: self.viewModel.sectionList[section].collapseKey)
            return isCollapse ? 0 : sectionModel.originalCellVMsWithAlphabetical.count
        }
        return sectionModel.cellCount
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.viewModel.sortedSectionVM.count
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }
}

@objc extension FriendListViewController {
    func addFriend(_ sender: UIBarButtonItem) {
        navigator.show(scene: .addFriend(vm: AddFriendViewControllerVM()),
                       sender: self)
    }
}

// MARK: - delegate
extension FriendListViewController: FriendListMainHeaderDelegate {
    func userDidTapCollapse(header: FriendListMainHeaderView) {
        guard let viewModel = header.viewModel else { return }
        UIView.performWithoutAnimation {
            tableView.reloadSections(IndexSet(integer: viewModel.section.rawValue), with: .none)
        }
    }
}
