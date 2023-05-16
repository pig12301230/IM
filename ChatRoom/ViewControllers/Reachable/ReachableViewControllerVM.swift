//
//  ReachableViewControllerVM.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/5/13.
//

import RxSwift

class ReachableViewControllerVM: BaseViewModel {
    let apiErrorCause = PublishSubject<ApiError>()
    
    /// 需要顯示無網路詳情時, 呼叫 isReachable() 即可顯示對應的 alert, 及點擊了解更多後的 view controller
    ///
    /// - Parameters:
    ///   - show: 是否要顯示後需一連串 "了解更多" 的 UI
    /// - Returns: 是否有網路可以使用
    func isReachable(_ show: Bool = true) -> Bool {
        guard NetworkManager.reachability() else {
            if show {
                self.apiErrorCause.onNext(.unreachable)
            }
            return false
        }
        
        return true
    }
}
