//
//  AppDelegate.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/4/7.
//

import UIKit
import RxSwift

let appDelegate = UIApplication.shared.delegate as? AppDelegate

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    private lazy var disposeBag: DisposeBag = {
        return DisposeBag()
    }()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Notification: setup
        application.beginReceivingRemoteControlEvents()
        UNUserNotificationCenter.current().delegate = PushManager.shared
        
        // App: setups
        Application.shared.setups()
        
        /// setup init view controller
        let window = IMWindow(frame: UIScreen.main.bounds)
        if #available(iOS 13.0, *) {
            window.overrideUserInterfaceStyle = .light
        }
        if let devRootVC = DevRootVCSwitch.viewController() {
            window.rootViewController = devRootVC
        } else {
            let splashVC = SplashViewController.initVC(with: SplashViewControllerVM.init())
            let nav = BaseNC.init(rootViewController: splashVC)
            window.rootViewController = nav
        }
        window.makeKeyAndVisible()
        self.window = window
#if DEBUG
        window.shakeSubject.subscribe(onNext: {
            let nvc = DebuggingNavigationController()
            self.window?.rootViewController?.present(nvc, animated: true)
        }).disposed(by: disposeBag)
#endif
        
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        return true
    }
    
    // MARK: - Push Notification
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        PushManager.shared.registerSuccess(deviceToken: deviceToken)
    }
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // get device token from APNs: Fail
        print("get device token failed: \(error.localizedDescription)")
    }
}
