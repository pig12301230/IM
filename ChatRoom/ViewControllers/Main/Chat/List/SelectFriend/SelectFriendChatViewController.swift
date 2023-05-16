//
//  SelectFriendChatViewController.swift
//  ChatRoom
//
//  Created by Andy Yang on 2021/6/30.
//

import UIKit
import RxSwift

class SelectFriendChatViewController: BaseVC {
    var viewModel: SelectFriendChatViewControllerVM!
    
    private lazy var tableView: UITableView = {
        let table = UITableView()
        table.delegate = self
        table.dataSource = self
        table.separatorStyle = .none
        table.theme_sectionIndexColor = Theme.c_10_grand_1.rawValue
        table.theme_backgroundColor = Theme.c_07_neutral_0.rawValue
        table.registerHeaderFooter(IndexSectionHeaderView.self)
        table.register(FriendListCell.self)
        return table
    }()
    
    private lazy var searchView: SearchView = {
        let view = SearchView.init(with: self.viewModel.searchVM)
        return view
    }()
    
    private lazy var navItemClose: UIBarButtonItem = {
        let btn = UIBarButtonItem.init(image: UIImage.init(named: "iconIconCross")?.withRenderingMode(.alwaysTemplate),
                                       style: .plain,
                                       target: self,
                                       action: #selector(close))
        btn.theme_tintColor = Theme.c_10_grand_1.rawValue
        return btn
    }()
    
    private lazy var emptyView: EmptyView = {
        let view = EmptyView()
        view.updateEmptyType(.noSearchResults)
        return view
    }()
    
    private var visibleHeaders: [UIView] = []
    
    static func initVC(with vm: SelectFriendChatViewControllerVM) -> SelectFriendChatViewController {
        let vc = SelectFriendChatViewController.init()
        vc.barType = .pure
        vc.title = Localizable.selectFriend
        vc.viewModel = vm
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = navItemClose
    }
    
    override func setupViews() {
        super.setupViews()
        view.theme_backgroundColor = Theme.c_07_neutral_50.rawValue
        view.addSubview(emptyView)
        view.addSubview(tableView)
        view.addSubview(searchView)
        
        searchView.snp.makeConstraints {
            $0.leading.trailing.top.equalToSuperview()
            $0.height.equalTo(52)
        }
        
        emptyView.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        
        tableView.snp.makeConstraints {
            $0.top.equalTo(searchView.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }
    
    override func initBinding() {
        super.initBinding()
        
        viewModel
            .reloadData
            .observe(on: MainScheduler.instance)
            .subscribeSuccess { [weak self] _ in
            guard let self = self else { return }
            self.tableView.reloadData()
        }.disposed(by: disposeBag)
        
        viewModel
            .isLoading
            .observe(on: MainScheduler.instance)
            .subscribeSuccess { isLoading in
            isLoading ? LoadingView.shared.show() : LoadingView.shared.hide()
        }.disposed(by: disposeBag)
        
        viewModel
            .goto
            .observe(on: MainScheduler.instance)
            .subscribeSuccess { [weak self] (scene) in
            guard let self = self else { return }
            self.navigator.show(scene: scene,
                                sender: self,
                                transition: .push(animated: true),
                                completion: nil)
        }.disposed(by: disposeBag)
        
        viewModel
            .showEmptyView
            .observe(on: MainScheduler.instance)
            .subscribeSuccess { [weak self] show in
            guard let self = self else { return }
            self.emptyView.isHidden = !show
            self.tableView.isHidden = show
        }.disposed(by: disposeBag)
    }
}

@objc private extension SelectFriendChatViewController {
    func close() {
        navigator.pop(sender: self)
    }
}

extension SelectFriendChatViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.numberOfSections()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.numberOfItem(in: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let vm = viewModel.cellViewModel(at: indexPath) else {
            return UITableViewCell()
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: vm.cellIdentifier,
                                                 for: indexPath)
        if let cell = cell as? ImplementViewModelProtocol {
            cell.setupViewModel(viewModel: vm)
        }
        
        if let cell = cell as? FriendListCell {
            cell.updateSeparator(fullyFilled: true)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let vm = viewModel.sectionViewModel(in: section) else { return nil }
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: vm.cellIdentifier)
        if let header = header as? IndexSectionHeaderView {
            header.setupViewModel(viewModel: vm)
        }
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        viewModel.heightForHeader(in: section)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        viewModel.heightForRow(at: indexPath)
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        viewModel.sectionIndexTitle()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.didSelect(at: indexPath)
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        visibleHeaders.append(view)
        updateHeaderStyle()
    }
    
    func tableView(_ tableView: UITableView, didEndDisplayingHeaderView view: UIView, forSection section: Int) {
        if let view = view as? IndexSectionHeaderView, let firstIndex = visibleHeaders.firstIndex(where: { header in
            if let header = header as? IndexSectionHeaderView {
                return header.lblTitle.text == view.lblTitle.text
            }
            return false
        }) {
            visibleHeaders.remove(at: firstIndex)
        }
    }
}

extension SelectFriendChatViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateHeaderStyle()
    }
    
    func updateHeaderStyle() {
        for (idx, view) in self.visibleHeaders.sorted(by: { $0.frame.minY < $1.frame.minY }).enumerated() {
            if let view = view as? IndexSectionHeaderView {
                view.updateSelectionStyle(isSelect: idx == 0 ? true : false)
            }
        }
    }
}
