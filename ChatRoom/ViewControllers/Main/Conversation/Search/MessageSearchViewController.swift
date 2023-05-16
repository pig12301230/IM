//
//  MessageSearchViewController.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/7/4.
//

import UIKit
import RxSwift

class MessageSearchViewController: ListViewController<MessageSearchViewControllerVM> {

    static func initVC(with vm: MessageSearchViewControllerVM) -> MessageSearchViewController {
        let vc = MessageSearchViewController()
        vc.barType = .pure
        vc.title = Localizable.chat
        vc.viewModel = vm
        // 讓childVC互相切換時不會清空disposeBag
        vc.isChildVC = true
        return vc
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.reloadData()
    }

    override func initBinding() {
        super.initBinding()

        self.viewModel.loading.observe(on: MainScheduler.instance).subscribeSuccess { isLoading in
            isLoading ? LoadingView.shared.show() : LoadingView.shared.hide()
        }.disposed(by: self.disposeBag)
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }
}
