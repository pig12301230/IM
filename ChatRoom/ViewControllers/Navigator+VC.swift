//
//  Navigator+VC.swift
//  ChatRoom
//
//  Created by Winston_Chuang on 2023/5/15.
//

import Foundation

extension Navigator {
    // MARK: - define All ViewControllers
    enum Scene {
        case forDev
        case termsHint(vm: TermsViewControllerVM)

        // Login
        case login
        case selectRegion(vm: SelectRegionViewControllerVM)
        case forgotPassword(vm: ForgotPasswordViewControllerVM)
        case setupPassword(vm: SetupNewPasswordViewControllerVM)

        // Register
        case phoneVerify(vm: PhoneVerifyViewControllerVM)
        case codeVerify(vm: CodeVerifyViewControllerVM)
        case register(vm: RegisterControllerVM)
        case setAvatar(vm: SetAvatarViewControllerVM)
        case mainTabBar(vm: MainTabBarControllerVM)
        case unreachableHint
        case mainTab(tab: MainBarKind)

        // Chat
        case list(vm: ListViewControllerVM)
        case searchList(vm: SearchListViewControllerVM)
        case chatDetail(vm: ChatDetailViewControllerVM)
        case conversation(vm: ConversationViewControllerVM)
        case addMember(type: AddMemberType, members: [FriendModel], groupID: String?)
        case createGroup(vm: CreateGroupViewControllerVM)
        case selectFriend(vm: SelectFriendChatViewControllerVM)
        case authSetting(vm: AuthSettingViewControllerVM)
        case editGroupMember(vm: EditMemberViewControllerVM)
        
        // Contact
        case report(vm: ReportViewControllerVM)
        case infoSetting(vm: InfoSettingViewControllerVM)
        case memberList(vm: GroupMemberListViewControllerVM)
        case addFriend(vm: AddFriendViewControllerVM)
        case addFriendNickname(vm: AddFriendNicknameViewControllerVM)
        case contactMemo(vm: ContactorMemoViewControllerVM)
        // My_Setting
        case personalInformation(vm: PersonalInformationViewControllerVM)
        case scanLoginQRCode(vm: ScanToLoginQRCodeViewControllerVM)
        case inputPasscode(vm: InputPasscodeViewControllerVM)
        case functionalImageViewer(vm: FunctionalViewerViewControllerVM)
        case imageSlidableViewer(vm: ImageSlidableViewerViewControllerVM)
        case modify(vm: ModifyViewControllerVM)
        case notify(vm: SettingNotifyViewControllerVM)
        case changePassword(vm: ChangePasswordViewControllerVM)
        case changeSecurityPassword(vm: ChangeSecurityPasswordViewControllerVM)
        case fillVerificationCode(vm: FillVerificationCodeViewControllerVM)
        case account(vm: AccountSecurityViewControllerVM)
        case about(vm: AboutViewControllerVM)
        
        // exchange
        case credit(vm: CreditViewControllerVM)
        case exchange(vm: ExchangeViewControllerVM)
        case scanToPayQRCode(vm: ScanToPayQRCodeViewControllerVM)
        case exchangeLoad(vm: ExchangeLoadingViewControllerVM)
        case platformExchange(vm: PlatformExchangeViewControllerVM)
        case wellPayBinding(vm: WellPayBindingViewControllerVM)
        case wellPayExchange(vm: WellPayExchangeViewControllerVM)

        // Web
        case customWeb(vm: WebViewControllerVM)
    }

    // MARK: - init ViewControllers
    func get(scene: Scene) -> UIViewController? {
        switch scene {
        case .forDev:
            return UIStoryboard.init(name: "Main", bundle: nil).instantiateInitialViewController()
        case .termsHint(vm: let vm):
            return TermsViewController.initVC(with: vm)
        case .login:
            let vm = LoginViewControllerVM.init()
            return LoginViewController.initVC(with: vm)
        case .selectRegion(vm: let vm):
            return SelectRegionViewController.initVC(with: vm)
        case .forgotPassword(vm: let vm):
            return ForgotPasswordViewController.initVC(with: vm)
        case .setupPassword(vm: let vm):
            return SetupNewPasswordViewController.initVC(with: vm)
        // Register
        case .phoneVerify(let vm):
            return PhoneVerifyViewController.initVC(with: vm)
        case .codeVerify(let vm):
            return CodeVerifyViewController.initVC(with: vm)
        case .register(let vm):
            return RegisterController.initVC(with: vm)
        case .setAvatar(let vm):
            return SetAvatarViewController.initVC(with: vm)
        case .mainTabBar(let vm):
            return MainTabBarController.initVC(with: vm)
        case .unreachableHint:
            return UnreachableHintViewController.initVC()
        case .chatDetail(let vm):
            return ChatDetailViewController.initVC(with: vm)
        case .contactMemo(let vm):
            return ContactorMemoViewController.initVC(with: vm)
        case .conversation(vm: let vm):
            return ConversationViewController.initVC(with: vm)
        case .report(let vm):
            return ReportViewController.initVC(with: vm)
        case .list(vm: let vm):
            return ListViewController.initVC(with: vm)
        case .searchList(vm: let vm):
            return SearchListViewController.initVC(with: vm)
        case .infoSetting(let vm):
            return InfoSettingViewController.initVC(with: vm)
        case .memberList(let vm):
            return GroupMemberListViewController.initVC(with: vm)
        case .mainTab(let tab):
            let tabbar = appDelegate?.window?.rootViewController as? MainTabBarController
            return tabbar?.viewControllers?[tab.rawValue]
        case .addFriend(let vm):
            return AddFriendViewController.initVC(with: vm)
        case .addFriendNickname(let vm):
            return AddFriendNicknameViewController.initVC(with: vm)
        case .selectFriend(let vm):
            return SelectFriendChatViewController.initVC(with: vm)
        case .authSetting(vm: let vm):
            return AuthSettingViewController.initVC(with: vm)
        case .editGroupMember(vm: let vm):
            return EditMemberViewController.initVC(with: vm)
        case .addMember(let type, let members, let groupID):
            return AddMemberViewController.initVC(type: type, members: members, groupID: groupID)
        case .createGroup(let vm):
            return CreateGroupViewController.initVC(with: vm)
        // My_Setting
        case .personalInformation(vm: let vm):
            return PersonalInformationViewController.initVC(with: vm)
        case .scanLoginQRCode(vm: let vm):
            return ScanToLoginQRCodeViewController.initVC(with: vm)
        case .inputPasscode(vm: let vm):
            return InputPasscodeViewController(viewModel: vm)
        case .functionalImageViewer(vm: let vm):
            return FunctionalViewerViewController.initVC(with: vm)
        case .imageSlidableViewer(let vm):
            return ImageSlidableViewerViewController.initVC(vm: vm)
        case .modify(vm: let vm):
            return ModifyViewController.initVC(with: vm)
        case .notify(vm: let vm):
            return SettingNotifyViewController.initVC(with: vm)
        case .customWeb(let vm):
            return WebViewController.initVC(with: vm)
        case .account(vm: let vm):
            return AccountSecurityViewController.initVC(with: vm)
        case .about(vm: let vm):
            return AboutViewController.initVC(with: vm)
        case .changePassword(vm: let vm):
            return ChangePasswordViewController.initVC(with: vm)
        case .changeSecurityPassword(vm: let vm):
            return ChangeSecurityPasswordViewController.initVC(with: vm)
        case .fillVerificationCode(vm: let vm):
            return FillVerificationCodeViewController.initVC(with: vm)
        // exchange
        case .credit(vm: let vm):
            return CreditViewController.initVC(with: vm)
        case .exchange(vm: let vm):
            return ExchangeViewController.initVC(with: vm)
        case .scanToPayQRCode(vm: let vm):
            return ScanToPayQRCodeViewController.initVC(with: vm)
        case .exchangeLoad(vm: let vm):
            return ExchangeLoadingViewController.initVC(with: vm)
        case .platformExchange(vm: let vm):
            return PlatformExchangeViewController.initVC(with: vm)
        case .wellPayBinding(vm: let vm):
            return WellPayBindingViewController.initVC(with: vm)
        case .wellPayExchange(vm: let vm):
            return WellPayExchangeViewController.initVC(with: vm)
        }
    }
    
    func pop(sender: UIViewController?, toTargetVC: UIViewController, animated: Bool = true) {
        sender?.navigationController?.popToViewController(toTargetVC, animated: animated)
    }
    
    func pop(sender: UIViewController?, to targetVCType: AnyClass, animated: Bool = true) -> Bool {
        guard let nav = sender?.navigationController else {
            return false
        }
        
        var findTarget = false
        for vc in nav.viewControllers {
            if vc.isKind(of: targetVCType) {
                findTarget = true
                nav.popToViewController(vc, animated: animated)
                break
            }
        }
        
        return findTarget
    }
    
    /**
     返回至 target vc, 並前往 show to
     - Paramater:
        - targetVCType: 要 pop 到的 vc class type
        - andShow: pop 完之後要顯示的 push 顯示 vc
        - animated: 是否需要過場動畫
     */
    func pop(sender: UIViewController?, to targetVCType: AnyClass, andShow showTo: Scene, animated: Bool = true) {
        guard let nav = sender?.navigationController else {
            return
        }
        
        for vc in nav.viewControllers {
            if vc.isKind(of: targetVCType) {
                nav.popToViewController(vc, animated: animated)
                self.show(scene: showTo, sender: vc)
                break
            }
        }
    }
    
    func pop(sender: UIViewController?, toRoot: Bool = false, animated: Bool = true) {
        if toRoot {
            sender?.navigationController?.popToRootViewController(animated: animated)
        } else {
            sender?.navigationController?.popViewController(animated: animated)
        }
    }

    func dismiss(sender: UIViewController?, animated: Bool = true, completion: (() -> Void)? = nil) {
        if let nav = sender?.navigationController {
            nav.dismiss(animated: animated, completion: completion)
        } else {
            sender?.dismiss(animated: animated, completion: completion)
        }
    }

    // MARK: - invoke a single scene
    public func show(scene: Scene, sender: UIViewController?, transition: TransitionType = .push(animated: true), completion: (() -> Void)? = nil) {
        if let target = get(scene: scene) {
            show(target: target, sender: sender, transition: transition, completion: completion)
        }
    }

    private func show(target: UIViewController, sender: UIViewController?, transition: TransitionType, completion: (() -> Void)? = nil) {
        switch transition {
        case .root(in: let window, duration: let duration):
            UIView.transition(with: window, duration: duration, options: .transitionCrossDissolve, animations: {
                window.rootViewController = target
            }, completion: { _ in
                completion?()
            })
            return

        default: break
        }
        
        guard let sender = sender else {
            fatalError("You need to pass in a sender for .navigation or .modal transitions")
        }
        switch transition {
        case .push(let animated):
            target.hidesBottomBarWhenPushed = true
            if let nav = sender as? UINavigationController {
                nav.pushViewController(target, animated: animated)
                return
            } else if let nav = sender.navigationController {
                nav.pushViewController(target, animated: animated)
            } else {
                fatalError("Can't found UINavigationController")
            }
        case .present(let animated, let style):
            DispatchQueue.main.async {
                let nav = BaseNC(rootViewController: target)
                nav.modalPresentationStyle = style
                sender.present(nav, animated: animated, completion: completion)
            }
        case .custom(let animated):
            DispatchQueue.main.async {
                sender.present(target, animated: animated, completion: completion)
            }
        case .toTabRoot(let tab):
            DispatchQueue.main.async {
                guard let tabbar = appDelegate?.window?.rootViewController as? MainTabBarController else { return }
                tabbar.selectedIndex = tab.rawValue
                sender.navigationController?.popToRootViewController(animated: true)
            }
        default: break
        }
    }
}
