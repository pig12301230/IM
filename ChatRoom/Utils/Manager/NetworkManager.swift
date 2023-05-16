//
//  NetworkManager.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/5/12.
//

import Foundation
import Alamofire
import RxSwift
import RxCocoa
import UIKit

enum IMNetworkStatus {
    case disconnected, connecting, connected
    
    var icon: UIImage? {
        switch self {
        case .disconnected:
            return UIImage(named: "actionsInfo")
        case .connecting:
            return UIImage(named: "iconActionsInfo")
        case .connected:
            return UIImage(named: "icon_icon_actions_checkmark_circle")
        }
    }
    
    var description: String {
        switch self {
        case .disconnected:
            return Localizable.networkErrorPleaseCheck
        case .connecting:
            return Localizable.connecting
        case .connected:
            return Localizable.connected
        }
    }
}

class NetworkManager {
    static let networkStatus = Observable.combineLatest(isConnected, websocketStatus)
    static let isConnected: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    static let websocketStatus: BehaviorRelay<IMNetworkStatus> = .init(value: .connecting)
    
    private static let manager = NetworkReachabilityManager()

    class func startListening() {
        manager?.startListening(onUpdatePerforming: { status in
            switch status {
            case .reachable:
                self.isConnected.accept(true)
            default:
                self.isConnected.accept(false)
                self.websocketStatus.accept(.disconnected)
            }
        })
    }

    class func stopListening() {
        manager?.stopListening()
    }

    class func reachability() -> Bool {
        return (manager?.isReachable ?? false)
    }
}
