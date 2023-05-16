//
//  ChatListViewController.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/5/3.
//

import UIKit
import RxSwift

public class ChatListViewController: SearchListViewController<ChatListViewControllerVM> {
    
    private lazy var navItemAdd: UIBarButtonItem = {
        let btn = UIBarButtonItem.init(image: UIImage.init(named: "iconIconPlusCircle"), style: .plain, target: self, action: #selector(doAddAction(_:)))
        btn.theme_tintColor = Theme.c_10_grand_1.rawValue
        return btn
    }()
    
    private lazy var addConversation: UIView = {
        let view = UIView()
        let separator: UIView = {
            let view = UIView()
            view.theme_backgroundColor = Theme.c_07_neutral_900_10.rawValue
            return view
        }()
        
        let button: UIButton = {
            let btn = UIButton()
            btn.setTitle(Localizable.newChat, for: .normal)
            btn.setImage(UIImage(named: "iconIconMessageWait")?.withRenderingMode(.alwaysTemplate),
                         for: .normal)
            btn.theme_tintColor = Theme.c_09_white.rawValue
            btn.titleLabel?.font = .boldParagraphMediumLeft
            btn.titleLabel?.theme_textColor = Theme.c_09_white.rawValue
            btn.imageEdgeInsets = UIEdgeInsets(top: 0,
                                               left: -8,
                                               bottom: 0,
                                               right: 0)
            btn.addTarget(self,
                          action: #selector(addNewConversation),
                          for: .touchUpInside)
            return btn
        }()
        
        view.addSubview(separator)
        separator.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(1)
        }
        
        view.addSubview(button)
        button.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        return view
    }()
    
    private lazy var addGroup: UIView = {
        let view = UIView()
        let separator: UIView = {
            let view = UIView()
            view.theme_backgroundColor = Theme.c_07_neutral_900_10.rawValue
            return view
        }()
        
        let button: UIButton = {
            let btn = UIButton()
            btn.setTitle(Localizable.addGroup, for: .normal)
            btn.setImage(UIImage(named: "iconIconGroupaddFill")?.withRenderingMode(.alwaysTemplate),
                         for: .normal)
            btn.theme_tintColor = Theme.c_09_white.rawValue
            btn.titleLabel?.font = .boldParagraphMediumLeft
            btn.titleLabel?.theme_textColor = Theme.c_09_white.rawValue
            btn.imageEdgeInsets = UIEdgeInsets(top: 0,
                                               left: -8,
                                               bottom: 0,
                                               right: 0)
            btn.addTarget(self,
                          action: #selector(createGroup),
                          for: .touchUpInside)
            return btn
        }()
        
        view.addSubview(separator)
        separator.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(1)
        }
        
        view.addSubview(button)
        button.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        return view
    }()
    
    private lazy var addFriendBtn: UIButton = {
        let btn = UIButton()
        btn.setTitle(Localizable.newFriend, for: .normal)
        btn.setImage(UIImage(named: "iconIconUserAdd")?.withRenderingMode(.alwaysTemplate),
                     for: .normal)
        btn.theme_tintColor = Theme.c_09_white.rawValue
        btn.titleLabel?.font = .boldParagraphMediumLeft
        btn.titleLabel?.theme_textColor = Theme.c_09_white.rawValue
        btn.imageEdgeInsets = UIEdgeInsets(top: 0,
                                           left: -8,
                                           bottom: 0,
                                           right: 0)
        btn.addTarget(self,
                      action: #selector(addNewFriend),
                      for: .touchUpInside)
        return btn
    }()
    
    public static func initVC(with vm: ChatListViewControllerVM) -> ChatListViewController {
        let vc = ChatListViewController.init()
        vc.barType = .pure
        vc.title = vm.title
        vc.viewModel = vm
        return vc
    }
    
    private var popOver: PopoverView?
    private var isFirstInit: Bool = true
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !isFirstInit {
            viewModel.refetchChatList()
        }
        isFirstInit = false
        viewModel.getUserMe()
        viewModel.resetReadingConversation()
    }
    
    public override func viewDidLoad() {
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
        
        self.viewModel.deleteRow.observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] indexPath in
            self.tableView.beginUpdates()
            self.tableView.deleteRows(at: [indexPath], with: .fade)
            self.tableView.endUpdates()
        }.disposed(by: self.disposeBag)
        
        self.viewModel.insertRow.observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] indexPath in
            self.tableView.beginUpdates()
            self.tableView.insertRows(at: [indexPath], with: .left)
            self.tableView.endUpdates()
            self.tableView.reloadData()
        }.disposed(by: self.disposeBag)
        
        self.viewModel.loading.observe(on: MainScheduler.instance).subscribeSuccess { isLoading in
            isLoading ? LoadingView.shared.show() : LoadingView.shared.hide()
        }.disposed(by: self.disposeBag)
    }
    
    public override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard self.viewModel.isSearchMode else {
            return UIView.init(frame: .zero)
        }
        
        return super.tableView(tableView, viewForHeaderInSection: section)
    }
    
    public override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard self.viewModel.isSearchMode else {
            return 0
        }
        
        return 44
    }

    public override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let actionDelete = UIContextualAction(style: .destructive, title: Localizable.delete) { (action, _, completion) in
            action.backgroundColor = Theme.c_06_danger_0_500.rawValue.toColor()
            self.showConfirm(indexPath: indexPath, completion: completion)
        }

        let muted = self.viewModel.isMute(indexPath: indexPath)
        let muteTitle = muted ? Localizable.unmute : Localizable.buttonMute
        let actionMute = UIContextualAction(style: .normal, title: muteTitle) { (action, _, completion) in
            action.backgroundColor = Theme.c_07_neutral_500.rawValue.toColor()
            self.viewModel.muteGroup(indexPath: indexPath, mute: !muted)
            completion(true)
        }

        return UISwipeActionsConfiguration(actions: [actionDelete, actionMute])
    }
    
    private func showConfirm(indexPath: IndexPath, completion: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: "", message: Localizable.deleteGroupConfirmation, preferredStyle: .alert)

        let cancel = UIAlertAction(title: Localizable.cancel, style: .default) { _ in
            completion(false)
        }
        let delete = UIAlertAction(title: Localizable.delete, style: .destructive) { _ in
            self.viewModel.deleteGroup(at: indexPath)
            completion(true)
        }
        alert.addAction(cancel)
        alert.addAction(delete)

        self.present(alert, animated: true)
    }
}

@objc extension ChatListViewController {
    
    func doAddAction(_ sender: UIBarButtonItem) {
        showPopView(sender: sender)
        viewModel.getUserMe { [unowned self] in
            let actionViews: [UIView] = (UserData.shared.userInfo?.permissions.canCreateGroup ?? false) ? [addConversation, addGroup, addFriendBtn] : [addConversation, addFriendBtn]
            popOver?.updateView(actionViews: actionViews)
        }
    }
    
    private func showPopView(sender: UIBarButtonItem) {
        popOver = PopoverView()
        let actionViews: [UIView] = (UserData.shared.userInfo?.permissions.canCreateGroup ?? false) ? [addConversation, addGroup, addFriendBtn] : [addConversation, addFriendBtn]
        popOver?.show(at: sender.value(forKey: "view") as? UIView,
                      actions: actionViews)
    }
    
    func addNewConversation() {
        popOver?.close()
        navigator.show(scene: .selectFriend(vm: SelectFriendChatViewControllerVM()),
                       sender: self)
    }
    
    func createGroup() {
        popOver?.close()
        navigator.show(scene: .addMember(type: .createGroup, members: [], groupID: nil),
                       sender: self)
    }
    
    func addNewFriend() {
        popOver?.close()
        navigator.show(scene: .addFriend(vm: AddFriendViewControllerVM()),
                       sender: self)
    }
}

// MARK: - UIPopoverPresentationControllerDelegate
extension ChatListViewController: UIPopoverPresentationControllerDelegate {
    public func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        .none
    }

    public func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
        true
    }
}
