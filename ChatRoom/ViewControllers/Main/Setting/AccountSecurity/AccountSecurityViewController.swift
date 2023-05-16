//
//  AccountSecurityViewController.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/7/5.
//

import UIKit
import RxSwift

class AccountSecurityViewController: BaseIntrinsicTableViewVC {
    
    private lazy var btnLogout: UIButton = {
        let btn = UIButton.init(type: .custom)
        btn.layer.cornerRadius = 4
        btn.clipsToBounds = true
        btn.theme_backgroundColor = Theme.c_07_neutral_500.rawValue
        btn.titleLabel?.font = .boldParagraphMediumLeft
        btn.theme_setTitleColor(Theme.c_09_white.rawValue, forState: .normal)
        btn.setTitle(Localizable.logout, for: .normal)
        return btn
    }()
    
    var viewModel: AccountSecurityViewControllerVM!
    
    static func initVC(with vm: AccountSecurityViewControllerVM) -> AccountSecurityViewController {
        let vc = AccountSecurityViewController.init()
        vc.barType = .default
        vc.viewModel = vm
        vc.title = Localizable.accountSafe
        return vc
    }
    
    override func setupViews() {
        super.setupViews()
        
        self.view.theme_backgroundColor = Theme.c_07_neutral_50.rawValue
        self.view.addSubview(self.btnLogout)
        
        self.tableView.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
            make.bottom.lessThanOrEqualToSuperview().offset(0)
            make.height.equalTo(self.viewModel.numberOfRows() * 56)
        }
                
        self.btnLogout.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(48)
            make.top.equalTo(self.tableView.snp.bottom).offset(32)
        }
    }
    
    override func initBinding() {
        super.initBinding()
        
        self.viewModel.output.alertSetting.observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] (message, btnTitle) in
            let confirm = UIAlertAction.init(title: btnTitle, style: .destructive) { [weak self] _ in
                self?.viewModel.doAction()
            }
            
            let cancle = UIAlertAction.init(title: Localizable.cancel, style: .cancel)
            self.showSheet(message: message, actions: confirm, cancle)
        }.disposed(by: self.disposeBag)
        
        self.viewModel.output.gotoLogin.observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] _ in
            self.gotoViewController(locate: .login)
        }.disposed(by: self.disposeBag)
        
        self.btnLogout.rx.controlEvent(.touchUpInside).bind(to: self.viewModel.input.logoutTap).disposed(by: self.disposeBag)
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

extension AccountSecurityViewController: UITableViewDelegate, UITableViewDataSource {
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
        guard let scene = self.viewModel.getScene(at: indexPath.row) else {
            return
        }
        
        self.navigator.show(scene: scene, sender: self)
    }
}
