//
//  DevRootVCSwitch.swift
//  ChatRoom
//
//  Created by Kedia on 2023/4/17.
//

import Foundation
import UIKit

class DevRootVCSwitch {
    
    static func viewController() -> UIViewController? {
#if !DEBUG
        return nil
#else
        guard let rootVCName = ProcessInfo.processInfo.environment["rootVC"] else {
            return nil
        }
        
        switch rootVCName {
        case "InputBoxesViewController":
            let vm = InputPasscodeViewControllerVM(deviceID: "", data: "")
            return InputPasscodeViewController(viewModel: vm)
        case "WellPayExchangeViewController":
            let vm = WellPayExchangeViewControllerVM(walletAddress: "0x999")
            let vc = WellPayExchangeViewController.initVC(with: vm)
            let nav = UINavigationController(rootViewController: vc)
            return nav
        default:
            return nil
        }
#endif
    }
}
