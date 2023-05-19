//
//  BaseVC.swift
//  LotBase
//
//  Created by george_tseng on 2020/5/28.
//  Copyright © 2020 Paridise-Soft. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

public class BaseVC: UIViewController {

    enum NaviBarType {
        case `default`
        case pure
        case hide
        case transparent
    }
    
    enum NaviBackTitle {
        case none
        case cancel
        case custom(_ title: String)
        
        var title: String? {
            switch self {
            case .none:
                return nil
            case .cancel:
                return Localizable.cancel
            case .custom(let title):
                return title
            }
        }
    }
    
    enum LocateTo {
        case login
        case chat
        case maintenance(_ announcement: String)
    }

    var disposeBag = DisposeBag()
    let onDisappear = PublishSubject<Void>()
    let navigator = Navigator.default
    var backTitle: NaviBackTitle = .none
    var barType: NaviBarType = .default
    var isChildVC: Bool = false
    // 若頁面需要toast時才需要去實現
    lazy var toastManager: ToastManager = {
        let manager = ToastManager.init()
        return manager
    }()
    
    private(set) lazy var btnBack: UIButton = {
        let btn = UIButton.init(frame: CGRect.init(origin: .zero, size: CGSize.init(width: 75, height: 44)))
        let renderingMode: UIImage.RenderingMode = barType == .transparent ? .alwaysTemplate : .alwaysOriginal
        btn.setImage(UIImage(named: "iconArrowsChevronLeft")?.withRenderingMode(renderingMode), for: .normal)
        btn.titleEdgeInsets = UIEdgeInsets.init(top: 0, left: 8, bottom: 0, right: 0)
        btn.contentHorizontalAlignment = .leading
        btn.addTarget(self, action: #selector(popViewController), for: .touchUpInside)
        return btn
    }()

    public override func viewDidLoad() {
        super.viewDidLoad()
        commonSetting()
        setupViews()
        initBinding()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        switch barType {
        case .hide:
            break
        case .transparent:
            self.setupTransparentNavigationBar()
        default:
            self.setupNavigationBar()
        }
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if case .hide = barType {
            self.setupNavigationBar()
        }
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.view.endEditing(true)
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        onDisappear.onNext(())
        
        if !isChildVC, self.isMovingFromParent {
            self.viewIsMovingFromParent()
        }
    }
    
    /**
     BaseVC 共同設定相關
     */
    func commonSetting() {
        // setup FOR system background color
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        
        if let bar = navigationController?.navigationBar {
            bar.setBackButtonTitle("")
        }
    }
    
    /**
     畫面相關
     */
    func setupViews() {
        /**
            view controller 相關設定
         */
        
        /**
            Auto Layout 相關設定
         */
    }
    
    /**
     Rx Binding
     */
    func initBinding() {
        
    }
    
    func add(childVC: UIViewController, in containerView: UIView) {
        self.addChild(childVC)
        containerView.addSubview(childVC.view)
        childVC.view.frame = containerView.bounds
        childVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        childVC.didMove(toParent: self)
    }
    
    func remove(childVC: UIViewController) {
        childVC.willMove(toParent: nil)
        childVC.view.removeFromSuperview()
        childVC.removeFromParent()
    }
    
    func disableNavigationBar() {
        self.navigationController?.setNavigationBarHidden(self.barType == .hide, animated: false)
        self.navigationController?.navigationBar.isUserInteractionEnabled = false
        if #available(iOS 15.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundImage = UIImage.init(color: Theme.c_08_black_75.rawValue.toColor())
            let backImage = UIImage(named: "iconArrowsChevronLeft")
            appearance.setBackIndicatorImage(backImage, transitionMaskImage: backImage)
            self.navigationController?.navigationBar.standardAppearance = appearance
            self.navigationController?.navigationBar.scrollEdgeAppearance = appearance
        } else {
            self.navigationController?.navigationBar.setBackgroundImage(UIImage.init(color: Theme.c_08_black_75.rawValue.toColor()), for: .default)
        }
        
        switch self.barType {
        case .default:
            self.navigationController?.navigationBar.showSeparator()
        case .pure:
            self.navigationController?.navigationBar.hideSeparator()
        default: break
        }
        
        if let back = self.backTitle.title {
            self.setupBackTitle(text: back)
        }
    }
    
    func setupTransparentNavigationBar() {
        // setup navigation bar background color
        self.navigationController?.navigationBar.isHidden = false
        self.navigationController?.navigationBar.isUserInteractionEnabled = true
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.view.backgroundColor = .clear
        if #available(iOS 15.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithTransparentBackground()
            let backImage = UIImage(named: "iconArrowsChevronLeft")
            
            appearance.setBackIndicatorImage(backImage, transitionMaskImage: backImage)
            appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            self.navigationController?.navigationBar.standardAppearance = appearance
            self.navigationController?.navigationBar.scrollEdgeAppearance = appearance
        } else {
            self.navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        }
        self.navigationController?.navigationBar.hideSeparator()
        
        self.setupBackTitle(text: self.backTitle.title ?? "")
        btnBack.tintColor = .white
    }
    
    func setupNavigationBar() {
        // setup navigation bar background color
        self.navigationController?.setNavigationBarHidden(self.barType == .hide, animated: false)
        self.navigationController?.navigationBar.isUserInteractionEnabled = true
        self.navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.black]
        if #available(iOS 15.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundImage = UIImage.init(color: Theme.c_07_neutral_50.rawValue.toColor())
            let backImage = UIImage(named: "iconArrowsChevronLeft")
            appearance.setBackIndicatorImage(backImage, transitionMaskImage: backImage)
            self.navigationController?.navigationBar.standardAppearance = appearance
            self.navigationController?.navigationBar.scrollEdgeAppearance = appearance
        } else {
            self.navigationController?.navigationBar.setBackgroundImage(UIImage.init(color: Theme.c_07_neutral_50.rawValue.toColor()), for: .default)
        }
        
        switch self.barType {
        case .default:
            self.navigationController?.navigationBar.showSeparator()
            self.navigationController?.navigationBar.isTranslucent = false
        case .pure:
            self.navigationController?.navigationBar.hideSeparator()
            self.navigationController?.navigationBar.isTranslucent = false
        default: break
        }
        
        if let back = self.backTitle.title {
            self.setupBackTitle(text: back)
        }
    }
    
    @objc func popViewController() {
//        self.navigator.pop(sender: self)
    }
    
    func gotoViewController(locate: LocateTo) {
//        switch locate {
//        case .chat:
//            guard let window = appDelegate?.window else { return }
//            self.navigator.pop(sender: self, toRoot: true, animated: false)
//            let mainVM = MainTabBarControllerVM.init(withStock: true)
//            self.navigator.show(scene: .mainTabBar(vm: mainVM), sender: self, transition: .root(in: window, duration: 0))
//        case .login: 
//            guard self.navigator.pop(sender: self, to: LoginViewController.self) == false, let window = appDelegate?.window else {
//                return
//            }
//            
//            let splashVC = SplashViewController.initVC(with: SplashViewControllerVM.init(true))
//            let login = LoginViewController.initVC(with: LoginViewControllerVM.init())
//            let nav = BaseNC.init(rootViewController: splashVC)
//            window.rootViewController = nav
//            nav.pushViewController(login, animated: false)
//        case .maintenance(let announcement):
//            guard let window = appDelegate?.window else { return }
//            let maintenance = MaintenanceViewController.initVC(announcement)
//            let nav = BaseNC.init(rootViewController: maintenance)
//            window.rootViewController = nav
//        }
    }
    
    func setupBackTitle(text: String) {
        let attString: NSAttributedString = NSAttributedString.init(string: text, attributes: [NSAttributedString.Key.foregroundColor: Theme.c_10_grand_1.rawValue.toColor(), NSAttributedString.Key.font: UIFont.midiumParagraphLargeLeft])
        btnBack.setAttributedTitle(attString, for: .normal)
        let barItem = UIBarButtonItem.init(customView: btnBack)
        self.navigationItem.leftBarButtonItem = barItem
    }
    
    /*
     返回 parent view controller, dispose 已綁定 signal
     */
    func viewIsMovingFromParent() {
        disposeBag = DisposeBag()
    }
    
    /**
     Deinit check
     */
    deinit {
        PRINT("=====\(type(of: self)) deinit=====", cate: .deinit)
    }
}

fileprivate extension UINavigationBar {

    func hideSeparator() {
        let navBarImageView = separatorInNavBar(view: self)
        navBarImageView?.isHidden = true
    }

    func showSeparator() {
        let navBarImageView = separatorInNavBar(view: self)
        navBarImageView?.isHidden = false
    }

    func separatorInNavBar(view: UIView) -> UIImageView? {
        if view is UIImageView && view.bounds.height <= 1.0 {
            return (view as? UIImageView)
        }

        let subviews = (view.subviews as [UIView])
        for subview: UIView in subviews {
            if let imageView: UIImageView = separatorInNavBar(view: subview) {
                return imageView
            }
        }
        return nil
    }
}

protocol DetectNetworkProtocol {
    var parentView: UIView { get }
    var reachableStatusView: UnreachableTopView { get }
    
    func setupNetworkStatusTopView()
    func setupNetworkStatus(status: IMNetworkStatus)
}

extension DetectNetworkProtocol {

    func setupNetworkStatusTopView() {
        parentView.addSubview(reachableStatusView)
        reachableStatusView.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
            make.height.equalTo(44)
        }
    }

    func setupNetworkStatus(status: IMNetworkStatus) {
        parentView.bringSubviewToFront(reachableStatusView)
        reachableStatusView.setup(status: status)
    }
}

public class DetectNetworkBaseVC: BaseVC, DetectNetworkProtocol {
    
    var reachableStatusView: UnreachableTopView {
        unreachableTopView
    }

    var parentView: UIView {
        view
    }
    
    private(set) lazy var unreachableTopView: UnreachableTopView = {
        let view = UnreachableTopView()
        view.isHidden = true
        return view
    }()
    
    override func initBinding() {
        super.initBinding()
        
        NetworkManager.networkStatus
            .subscribeSuccess { [unowned self] (reachable, websocketStatus) in
                let status = reachable ? websocketStatus : .disconnected
                self.setupNetworkStatus(status: status)
            }.disposed(by: disposeBag)
    }
    
    override func setupViews() {
       super.setupViews()
       setupNetworkStatusTopView()
   }
}
