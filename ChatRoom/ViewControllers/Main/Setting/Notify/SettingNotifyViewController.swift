//
//  SettingNotifyViewController.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/7/2.
//

import UIKit
import RxSwift

class SettingNotifyViewController: BaseIntrinsicTableViewVC {
    
    var viewModel: SettingNotifyViewControllerVM!
    
    static func initVC(with vm: SettingNotifyViewControllerVM) -> SettingNotifyViewController {
        let vc = SettingNotifyViewController.init()
        vc.viewModel = vm
        vc.title = Localizable.messageNotify
        vc.barType = .default
        return vc
    }
    
    override func setupViews() {
        super.setupViews()
        self.view.theme_backgroundColor = Theme.c_07_neutral_50.rawValue
        
        self.tableView.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
            make.bottom.lessThanOrEqualToSuperview().offset(0)
            make.height.equalTo(self.viewModel.numberOfRows() * 56)
        }
    }
    
    override func initBinding() {
        super.initBinding()
        
        self.viewModel.confirmAlert.observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] (option, message) in
            let confirm = UIAlertAction.init(title: Localizable.confrimClose, style: .destructive) { [weak self] _ in
                self?.viewModel.confiromExecAction(option)
            }
            let cancle = UIAlertAction.init(title: Localizable.cancel, style: .cancel) { [weak self] _ in
                self?.viewModel.cancelAction(option)
            }
            self.showSheet(message: message, actions: confirm, cancle)
        }.disposed(by: self.disposeBag)
    }
    
    // MARK: - IntrinsicTableViewVCProtocol
    override func implementTableViewDelegateAndDataSource() {
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func registerCells() {
        for type in viewModel.cellTypes {
            tableView.register(type.cellClass, forCellReuseIdentifier: type.cellIdentifier)
        }
    }
}

extension SettingNotifyViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.numberOfRows()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.viewModel.cellIdentifier(at: indexPath.row), for: indexPath)
        
        if let cell = cell as? ImplementViewModelProtocol, let vm = self.viewModel.cellViewModel(at: indexPath.row) {
            cell.setupViewModel(viewModel: vm)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let scene = self.viewModel.getScene(at: indexPath.row) else {
            return
        }
        
        self.navigator.show(scene: scene, sender: self)
    }
}
