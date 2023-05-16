//
//  SplashViewControllerVM.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/4/28.
//

import Foundation
import RxSwift
import RxCocoa

class SplashViewControllerVM: BaseViewModel {
    var disposeBag = DisposeBag()
    
    let showActionButton: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    let gotoView = PublishSubject<(Navigator.Scene, Bool)>()
    let accessFailed = PublishSubject<Void>()
    var viewAppear: Bool = false
    
    init(_ clearAccess: Bool = false) {
        super.init()
        
        guard clearAccess == false else {
            self.showActionButton.accept(true)
            return
        }
        
        self.checkStatus()
    }
    
    func checkStatus() {
        DataAccess.shared.getUserAccess { [unowned self] (status) in
            if status == .noAccess {
                self.showActionButton.accept(true)
            } else if status == .invalid {
                self.goto(scene: .login)
            } else {
                self.fetchSessionAndGotoChatList()
            }
        }
    }
    
    func goto(scene: Navigator.Scene) {
        guard self.viewAppear else {
            return
        }
        
        self.viewAppear = false
        
        var toRoot: Bool = false
        switch scene {
        case .mainTabBar:
            toRoot = true
        default:
            break
        }
        
        self.gotoView.onNext((scene, toRoot))
    }
}

private extension SplashViewControllerVM {
    func fetchSessionAndGotoChatList() {
        DataAccess.shared.fetchUserMe().subscribe { [unowned self] _ in
            DataAccess.shared.finishNeededLoginAccess()
            self.enterMainView()
        } onError: { [unowned self] _ in
            self.accessFailure()
        }.disposed(by: self.disposeBag)
    }
    
    func enterMainView() {
        PushManager.shared.registerPushNotification()
        let mainVM = MainTabBarControllerVM.init(withStock: true)
        self.goto(scene: .mainTabBar(vm: mainVM))
    }
    
    func accessFailure() {
        self.accessFailed.onNext(())
        UserData.shared.clearData(key: .refreshToken)
        UserData.shared.clearData(key: .token)
        self.showActionButton.accept(true)
    }
}
