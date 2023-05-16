//
//  InfoSettingViewController.swift
//  ChatRoom
//
//  Created by Andy Yang on 2021/6/7.
//

import Foundation
import RxSwift
import RxCocoa

class InfoSettingViewController: BaseVC {
    var viewModel: InfoSettingViewControllerVM!
    
    private lazy var tableView: IntrinsicTableView = {
        let table = IntrinsicTableView()
        table.backgroundColor = .clear
        table.separatorStyle = .none
        table.delegate = self
        table.dataSource = self

        table.register(SettingItemCell.self)
        table.register(SettingMoreCell.self)
        table.register(SettingMoreInfoCell.self)
        table.register(ChatDetailActionCell.self)
        table.register(SettingDangerCell.self)
        return table
    }()
    
    static func initVC(with vm: InfoSettingViewControllerVM) -> InfoSettingViewController {
        let vc = InfoSettingViewController()
        vc.title = Localizable.setting
        vc.viewModel = vm
        return vc
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.viewModel.fetchData()
    }
    
    override func setupViews() {
        super.setupViews()
        
        view.theme_backgroundColor = Theme.c_07_neutral_0.rawValue
        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    override func initBinding() {
        super.initBinding()
        
        viewModel.reload.observe(on: MainScheduler.instance).subscribeSuccess { [weak self] _ in
            guard let self = self else { return }
            self.tableView.reloadData()
        }.disposed(by: disposeBag)
        
        viewModel.showLoading.observe(on: MainScheduler.instance).subscribeSuccess { (isShow) in
            isShow ? LoadingView.shared.show() : LoadingView.shared.hide()
        }.disposed(by: disposeBag)
        
        viewModel.errorMessage.observe(on: MainScheduler.instance).subscribeSuccess { [weak self] (msg) in
            guard let self = self else { return }
            self.showAlert(message: msg, comfirmBtnTitle: Localizable.sure)
        }.disposed(by: disposeBag)
        
        viewModel.showBlockConfirm.observe(on: MainScheduler.instance).subscribeSuccess { [weak self] in
            guard let self = self else { return }
            self.showBlockAlert()
        }.disposed(by: self.disposeBag)
        
        viewModel.gotoReport.observe(on: MainScheduler.instance).subscribeSuccess { [weak self] in
            guard let self = self else { return }
            self.showReport()
        }.disposed(by: disposeBag)
        
        viewModel.deleteHistory.observe(on: MainScheduler.instance).subscribeSuccess { [weak self] in
            guard let self = self else { return }
            self.showDeleteConfirm()
        }.disposed(by: disposeBag)
        
        viewModel.leaverGroup.observe(on: MainScheduler.instance).subscribeSuccess { [weak self] in
            guard let self = self else { return }
            self.showLeaveConfirm()
        }.disposed(by: disposeBag)
        
        viewModel.unFriend.observe(on: MainScheduler.instance).subscribeSuccess { [weak self] name in
            guard let self = self else { return }
            self.showUnFriendConfirm(displayName: name)
        }.disposed(by: disposeBag)
        
        viewModel.goto.observe(on: MainScheduler.instance).subscribeSuccess { [weak self] scene in
            guard let self = self else { return }
            self.navigator.show(scene: scene, sender: self)
        }.disposed(by: disposeBag)
    }
}

extension InfoSettingViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.numberOfSections()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.numberOfRow(in: section)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        viewModel.heightForRow(in: indexPath)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: viewModel.vmList[indexPath.section][indexPath.item]?.cellIdentifier ?? "",
                                                 for: indexPath)
        if let cell = cell as? ImplementViewModelProtocol, let vm = self.viewModel.cellViewModel(in: indexPath) {
            cell.setupViewModel(viewModel: vm)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.didSelect(at: indexPath)
    }
}

// setup the spacing between sections
extension InfoSettingViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        UIView()
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        8
    }
}

// MARK: - Cell Tapped
extension InfoSettingViewController {
    func showBlockAlert() {
        let actions: [UIAlertAction] = [
            UIAlertAction(title: Localizable.sure,
                          style: .destructive,
                          handler: { _ in
                self.viewModel.enableBlock()
            }),
            UIAlertAction(title: Localizable.cancel,
                          style: .cancel,
                          handler: { _ in
                self.viewModel.setBlock(on: false)
            })
        ]
        self.showSheet(message: Localizable.addBlacklistHint,
                       actions: actions)
    }

    func showReport() {
        guard let vm = viewModel.getReportViewModel() else { return }
        navigator.show(scene: .report(vm: vm),
                            sender: self,
                            transition: .push(animated: true))
    }
    
    func showDeleteConfirm() {
        let alert = UIAlertController(title: nil,
                                      message: Localizable.deleteRecordWarning,
                                      preferredStyle: .alert)
        let cancel = UIAlertAction(title: Localizable.cancel,
                                   style: .cancel,
                                   handler: nil)
        let delete = UIAlertAction(title: Localizable.delete,
                                   style: .destructive) { _ in
            self.viewModel.deleteHistoryRecord { [weak self] (isFinish) in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.toastManager = ToastManager()
                    if isFinish {
                        self.toastManager.showToast(icon: UIImage(named: "iconIconActionsCheckmarkCircle") ?? UIImage(),
                                                     hint: Localizable.deletedSuccessfully)
                        self.navigator.pop(sender: self)
                        return
                    }
                    self.toastManager.showToast(icon: UIImage(named: "iconIconAlertError") ?? UIImage(),
                                                 hint: Localizable.failedToDelete)
                }
            }
        }
        alert.addAction(cancel)
        alert.addAction(delete)
        present(alert, animated: true)
    }
    
    func showLeaveConfirm() {
        let alert = UIAlertController(title: nil,
                                      message: Localizable.deleteAndLeaveWarning,
                                      preferredStyle: .alert)
        let cancel = UIAlertAction(title: Localizable.cancel,
                                   style: .cancel,
                                   handler: nil)
        let delete = UIAlertAction(title: Localizable.leaveGroup,
                                   style: .destructive) { _ in
            self.viewModel.leaveGroup { [weak self] (isFinish, failureMessage) in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.toastManager = ToastManager()
                    if isFinish {
                        self.toastManager.showToast(icon: UIImage(named: "iconIconActionsCheckmarkCircle") ?? UIImage(),
                                                     hint: Localizable.deletedAndLeavedSuccessfully)
                        self.backToFriendList()
                        return
                    }
                    self.toastManager.showToast(icon: UIImage(named: "iconIconAlertError") ?? UIImage(),
                                                 hint: failureMessage ?? Localizable.failedToDeleteAndLeave)
                }
            }
        }
        alert.addAction(cancel)
        alert.addAction(delete)
        present(alert, animated: true)
    }
    
    func showUnFriendConfirm(displayName: String) {
        let alert = UIAlertController(title: nil,
                                      message: String(format: Localizable.deleteFriendWarningiOS, displayName),
                                      preferredStyle: .alert)
        let cancel = UIAlertAction(title: Localizable.cancel,
                                   style: .cancel,
                                   handler: nil)
        let delete = UIAlertAction(title: Localizable.delete,
                                   style: .destructive) { _ in
            self.viewModel.unfriend { [weak self] (isFinish) in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.toastManager = ToastManager()
                    if isFinish {
                        self.toastManager.showToast(icon: UIImage(named: "iconIconActionsCheckmarkCircle") ?? UIImage(),
                                                     hint: Localizable.deletedSuccessfully)
                        self.backToFriendList()
                        return
                    }
                    self.toastManager.showToast(icon: UIImage(named: "iconIconAlertError") ?? UIImage(),
                                                 hint: Localizable.failedToDelete)
                }
            }
        }
        alert.addAction(cancel)
        alert.addAction(delete)
        present(alert, animated: true)
    }
    
    func backToFriendList() {
        navigator.pop(sender: self, toRoot: true, animated: true)
    }
}
