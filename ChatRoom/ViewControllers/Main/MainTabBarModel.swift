//
//  MainTabBarModel.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/4/29.
//

import Foundation
import UIKit

enum MainBarKind: Int, CaseIterable {
    case chat
    case friendsList
    case stockIndex
    case my
    
    var title: String? {
        switch self {
        case .chat:
            return Localizable.talk
        case .friendsList:
            return Localizable.friendsList
        case .stockIndex:
            return Localizable.stock_index
        case .my:
            return Localizable.my
        }
    }
    
    var icon: String {
        switch self {
        case .chat:
            return "iconIconMessageWait"
        case .friendsList:
            return "iconIconGroup"
        case .stockIndex:
            return "iconIconChart"
        case .my:
            return "iconIconSmiling"
        }
    }
    
    var selectedIcon: String {
        switch self {
        case .chat:
            return "iconIconMessageWaitFill"
        case .friendsList:
            return "iconIconGroupFill"
        case .stockIndex:
            return "iconIconChartFill"
        case .my:
            return "iconIconSmilingFill"
        }
    }
    
    var navigationController: BaseNC {
        let navigation = BaseNC()
        navigation.tabBarItem.setTitleTextAttributes([NSAttributedString.Key.font: UIFont.midiumParagraphTinyLeft], for: .normal)
        navigation.tabBarItem.setTitleTextAttributes([NSAttributedString.Key.font: UIFont.midiumParagraphTinyLeft], for: .selected)
        navigation.tabBarItem.title = self.title
        navigation.tabBarItem.image = UIImage.init(named: self.icon)
        navigation.tabBarItem.selectedImage = UIImage.init(named: self.selectedIcon)
        
//        switch self {
//        case .chat:
//            let vm = ChatListViewControllerVM.init()
//            let vc = ChatListViewController.initVC(with: vm)
//            navigation.viewControllers = [vc]
//        case .friendsList:
//            let vm = FriendListViewControllerVM()
//            let vc = FriendListViewController.initVC(with: vm)
//            navigation.viewControllers = [vc]
//        case .stockIndex:
//            break
//        case .my:
//            let vm = SettingViewControllerVM()
//            let vc = SettingViewController.initVC(with: vm)
//            navigation.viewControllers = [vc]
//        }
        
        return navigation
    }
}
