//
//  AboutViewController.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/7/6.
//

import Foundation
import RxSwift

class AboutViewController: BaseIntrinsicTableViewVC {
    
    var viewModel: AboutViewControllerVM!
    
    static func initVC(with vm: AboutViewControllerVM) -> AboutViewController {
        let vc = AboutViewController.init()
        vc.viewModel = vm
        vc.title = Localizable.about
        return vc
    }
    
    override func setupViews() {
        super.setupViews()

        self.view.theme_backgroundColor = Theme.c_07_neutral_50.rawValue
        
        self.tableView.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
            make.bottom.lessThanOrEqualToSuperview().offset(0)
            make.height.equalTo(56 * self.viewModel.numberOfRows())
        }
    }
    
    override func initBinding() {
        super.initBinding()
        
        self.viewModel.navigateTo.subscribeSuccess { [unowned self] scene in
            self.navigator.show(scene: scene, sender: self, transition: .present(animated: true))
        }.disposed(by: disposeBag)
        
        self.viewModel.showDeleteAccountAlert.subscribeSuccess { [unowned self] in
            let confirm = UIAlertAction.init(title: Localizable.deleteAccount, style: .destructive) { [weak self] _ in
                self?.viewModel.deleteAccount()
            }
            let cancel = UIAlertAction.init(title: Localizable.cancel, style: .cancel)
            
            self.showSheet(message: Localizable.deleteAccountHint, actions: confirm, cancel)
        }.disposed(by: disposeBag)
        
        self.viewModel.gotoLogin.subscribeSuccess { [unowned self] in
            self.gotoViewController(locate: .login)
        }.disposed(by: disposeBag)
    }
    
    // MARK: - IntrinsicTableViewVCProtocol
    override func implementTableViewDelegateAndDataSource() {
        tableView.dataSource = self
        tableView.delegate = self
    }

    override func registerCells() {
        for type in viewModel.cellTypes {
            tableView.register(type.cellClass, forCellReuseIdentifier: type.cellIdentifier)
        }
    }
}

extension AboutViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.numberOfRows()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.viewModel.cellIdentifier(at: indexPath.row), for: indexPath)
        
        if let cell = cell as? TitleTableViewCell {
            let config = self.viewModel.cellConfig(at: indexPath.row)
            cell.setupConfig(config)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.viewModel.didSelect(at: indexPath.row)
    }
}
