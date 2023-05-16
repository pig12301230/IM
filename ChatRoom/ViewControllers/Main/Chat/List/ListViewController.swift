//
//  ListViewController.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/5/27.
//

import UIKit
import RxSwift

public class ListViewController<T: ListViewControllerVM>: DetectNetworkBaseVC, UITableViewDelegate, UITableViewDataSource {
    
    private(set) lazy var tableView: IntrinsicTableView = {
        let tView = IntrinsicTableView.init()
        tView.separatorStyle = .none
        tView.registerHeaderFooter(TitleSectionView.self)
        tView.registerHeaderFooter(FriendListMainHeaderView.self)
        tView.register(IndexListCell.self)
        tView.register(NameTableViewCell.self)
        tView.register(RecordTableViewCell.self)
        tView.register(SeeMoreTableViewCell.self)
        tView.register(ChatTableViewCell.self)
        tView.register(MessageTableViewCell.self)
        tView.register(MessageSearchTableViewCell.self)
        tView.delegate = self
        tView.dataSource = self
        tView.bounces = false
        if #available(iOS 15, *) {
            tView.sectionHeaderTopPadding = 0
        }
        return tView
    }()
    
    private(set) lazy var tableViewBG: UIView = {
        let view = UIView.init()
        view.theme_backgroundColor = Theme.c_07_neutral_0.rawValue
        return view
    }()
    
    private(set) lazy var emptyView: EmptyView = {
        let view = EmptyView.init()
        return view
    }()
    
    var viewModel: T!
    
    public static func initVC(with vm: ListViewControllerVM) -> ListViewController {
        let vc = ListViewController.init()
        vc.barType = .pure
        vc.title = Localizable.chat
        if let viewModel = vm as? T {
            vc.viewModel = viewModel
        }
        return vc
    }
    
    override func initBinding() {
        super.initBinding()
        
        self.viewModel.goto.observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] scene in
            self.navigator.show(scene: scene, sender: self)
        }.disposed(by: self.disposeBag)
        
        self.viewModel.reloadData
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] _ in
            self.tableView.reloadData()
        }.disposed(by: self.disposeBag)
        
        self.viewModel.showEmptyView.observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] (show, type) in
            self.emptyView.updateEmptyType(type)
            self.emptyView.isHidden = !show
            self.tableViewBG.isHidden = show
        }.disposed(by: self.disposeBag)
    }
    
    override func setupViews() {
        super.setupViews()
        self.view.theme_backgroundColor = Theme.c_07_neutral_50.rawValue
        self.view.addSubview(self.tableViewBG)
        self.tableViewBG.addSubview(self.tableView)
        self.view.addSubview(self.emptyView)
        
        self.tableViewBG.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        self.tableView.snp.makeConstraints { (make) in
            make.leading.trailing.top.equalToSuperview()
            make.height.lessThanOrEqualToSuperview()
        }
        
        self.emptyView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
        
        self.unreachableTopView.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
            make.height.equalTo(44)
        }
    }
    
    // MARK: - protocol
    
    // MARK: - tableview datasource, delegate
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.numberOfRow(in: section)
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cViewModel = self.viewModel.cellViewModel(in: indexPath) else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SeeMoreTableViewCell", for: indexPath)
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cViewModel.cellIdentifier, for: indexPath)
        if let cel = cell as? ImplementViewModelProtocol {
            cel.setupViewModel(viewModel: cViewModel)
        }
        return cell
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return self.viewModel.numberOfSection()
    }
    
    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard self.viewModel.isNeedFooter(in: section) else {
            return nil
        }
        let footer = UIView.init()
        footer.theme_backgroundColor = Theme.c_07_neutral_0.rawValue
        return footer
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let sectionVM = self.viewModel.sectionViewModel(in: section) else {
            return 0
        }
        
        return sectionVM.headerHeight
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let sViewModel = self.viewModel.sectionViewModel(in: section) else {
            return UIView.init(frame: .zero)
        }
        
        let sectionView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "TitleSectionView") as? TitleSectionView
        sectionView?.setupViewModel(viewModel: sViewModel)
        return sectionView
    }
    
    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard self.viewModel.isNeedFooter(in: section) else {
            return 0
        }
        
        return 8
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.viewModel.didSelectRow(at: indexPath)
    }
    
    public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        return UISwipeActionsConfiguration.init(actions: [])
    }
}
