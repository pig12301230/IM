//
//  ChatDetailViewController.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/5/7.
//

import UIKit
import RxSwift

class ChatDetailViewController: DetectNetworkBaseVC {

    var viewModel: ChatDetailViewControllerVM!

    private lazy var tableView: IntrinsicTableView = {
        let table = IntrinsicTableView()
        table.backgroundColor = .clear
        table.separatorStyle = .none
        table.delegate = self
        table.dataSource = self

        table.register(MemberInfoCell.self)
        table.register(SettingItemCell.self)
        table.register(SettingMoreCell.self)
        table.register(SettingMoreInfoCell.self)
        table.register(ChatDetailActionCell.self)
        table.register(SettingDangerCell.self)
        table.register(HintMessageCell.self)
        table.register(MemoCell.self)
        table.estimatedRowHeight = 56
        table.rowHeight = UITableView.automaticDimension
        return table
    }()

    private lazy var navSetting: UIBarButtonItem = {
        let btn = UIBarButtonItem(image: UIImage(named: "iconIconSettings"),
                                  style: .plain,
                                  target: self,
                                  action: #selector(gotoSetting))
        btn.theme_tintColor = Theme.c_10_grand_1.rawValue
        return btn
    }()
    
    static func initVC(with vm: ChatDetailViewControllerVM) -> ChatDetailViewController {
        let vc = ChatDetailViewController()
        vc.barType = .default
        vc.viewModel = vm
        vc.title = vc.viewModel.title()
        return vc
    }
    
    override func setupViews() {
        super.setupViews()

        self.view.theme_backgroundColor = Theme.c_07_neutral_0.rawValue
        self.view.addSubview(tableView)
        self.tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        viewModel.isNeedSetting { [weak self] (isNeed) in
            guard let self = self else { return }
            if isNeed {
                self.navigationItem.rightBarButtonItem = self.navSetting
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.viewModel.fetchData()
    }

    override func initBinding() {
        super.initBinding()

        viewModel.reload.observe(on: MainScheduler.instance).subscribeSuccess { [weak self] _ in
            guard let self = self else { return }
            self.tableView.reloadData()
        }.disposed(by: disposeBag)
        viewModel.showLoading.observe(on: MainScheduler.instance).subscribeSuccess { show in
            show ? LoadingView.shared.show() : LoadingView.shared.hide()
        }.disposed(by: disposeBag)
        viewModel.errorMessage.observe(on: MainScheduler.instance).subscribeSuccess { [weak self] message in
            guard let self = self else { return }
            self.showAlert(message: message, comfirmBtnTitle: Localizable.sure)
        }.disposed(by: disposeBag)
        viewModel.showImageViewer.observe(on: MainScheduler.instance).subscribeSuccess { [weak self] config in
            guard let self = self else { return }
            let vm = FunctionalViewerViewControllerVM.init(config: config)
            self.navigator.show(scene: .functionalImageViewer(vm: vm), sender: self, transition: .present(animated: true, style: .fullScreen))
        }.disposed(by: disposeBag)
        viewModel.showBlockConfirm.observe(on: MainScheduler.instance).subscribeSuccess { [weak self] in
            guard let self = self else { return }
            self.showBlockAlert()
        }.disposed(by: disposeBag)
        viewModel.deleteHistory.observe(on: MainScheduler.instance).subscribeSuccess { [weak self] in
            guard let self = self else { return }
            self.showDeleteConfirm()
        }.disposed(by: disposeBag)
        viewModel.leaverGroup.observe(on: MainScheduler.instance).subscribeSuccess { [weak self] in
            guard let self = self else { return }
            self.showLeaveConfirm()
        }.disposed(by: disposeBag)
        viewModel.goto.observe(on: MainScheduler.instance).subscribeSuccess { [weak self] scene in
            guard let self = self else { return }
            self.navigator.show(scene: scene,
                                sender: self)
        }.disposed(by: disposeBag)
        viewModel.showToast.observe(on: MainScheduler.instance).subscribeSuccess { [weak self] toast in
            guard let self = self else { return }
            self.showToast(icon: toast.isSuccess ? UIImage(named: "iconIconActionsCheckmarkCircle") : UIImage(named: "iconIconAlertError"),
                           hint: toast.message)
        }.disposed(by: disposeBag)
    }
}

// MARK: - Info Setting
@objc extension ChatDetailViewController {
    func gotoSetting() {
        guard self.viewModel.style != .blockedListToPerson else {
            self.viewModel.gotoBlockedSettingPage()
            return
        }
        
        guard let vm = viewModel.getSettingViewModel() else {
            // TODO: error handling
            return
        }
    
        navigator.show(scene: .infoSetting(vm: vm),
                       sender: self,
                       transition: .push(animated: true))
    }
}

extension ChatDetailViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.numberOfSections()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.numberOfRow(in: section)
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
        self.viewModel.didSelect(at: indexPath)
    }
}

// MARK: - Setup the spacing between sections
extension ChatDetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        UIView()
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        8
    }
}

private extension ChatDetailViewController {

    func showBlockAlert() {
        let actions: [UIAlertAction] = [
            UIAlertAction(title: Localizable.sure, style: .destructive, handler: { _ in
                self.viewModel.enableBlock()
            }),
            UIAlertAction(title: Localizable.cancel, style: .cancel, handler: { _ in
                self.viewModel.setBlock(on: false)
            })
        ]
        self.showSheet(message: Localizable.addBlacklistHint, actions: actions)
    }
    
    func showDeleteConfirm() {
        let alert = UIAlertController(title: "", message: Localizable.deleteRecordWarning, preferredStyle: .alert)
        let cancel = UIAlertAction(title: Localizable.cancel, style: .cancel, handler: nil)
        let delete = UIAlertAction(title: Localizable.delete, style: .destructive) { _ in
            self.viewModel.deleteHistoryRecord { [weak self] (isFinish) in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    if isFinish {
                        self.showToast(icon: UIImage(named: "iconIconActionsCheckmarkCircle"),
                                       hint: Localizable.deletedSuccessfully)
                        self.navigator.pop(sender: self)
                        return
                    }
                    self.showToast(icon: UIImage(named: "iconIconAlertError"),
                                   hint: Localizable.failedToDelete)
                }
            }
        }
        alert.addAction(cancel)
        alert.addAction(delete)
        self.present(alert, animated: true)
    }
    
    func showLeaveConfirm() {
        let alert = UIAlertController(title: "", message: Localizable.deleteAndLeaveWarning, preferredStyle: .alert)
        let cancel = UIAlertAction(title: Localizable.cancel, style: .cancel, handler: nil)
        let delete = UIAlertAction(title: Localizable.leaveGroup, style: .destructive) { _ in
            self.viewModel.leaveGroup { [weak self] (isFinish, failureMessage) in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    if isFinish {
                        self.showToast(icon: UIImage(named: "iconIconActionsCheckmarkCircle"),
                                  hint: Localizable.deletedAndLeavedSuccessfully)
                        self.backToChatList()
                        return
                    }
                    self.showToast(icon: UIImage(named: "iconIconAlertError"),
                                   hint: failureMessage ?? Localizable.failedToDeleteAndLeave)
                }
            }
        }
        alert.addAction(cancel)
        alert.addAction(delete)
        present(alert, animated: true)
    }
    
    func backToChatList() {
        navigator.pop(sender: self, toRoot: true, animated: true)
    }
    
    func showToast(icon: UIImage?, hint: String) {
        toastManager.showToast(icon: icon ?? UIImage(), hint: hint)
    }
}
