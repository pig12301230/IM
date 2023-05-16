//
//  MainTabBarControllerVM.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/4/29.
//

import UIKit

class MainTabBarControllerVM: BaseViewModel {
    
    let tabViewControllers: [BaseNC]
    
    init(withStock: Bool) {
        // TODO: 6/15 不送測指數
        let forceCloseStock = true
        guard withStock, forceCloseStock == false else {
            self.tabViewControllers = [MainBarKind.chat.navigationController,
                                       MainBarKind.friendsList.navigationController,
                                       MainBarKind.my.navigationController]
            return
        }
        
        self.tabViewControllers = MainBarKind.allCases.map { (item) -> BaseNC in
            return item.navigationController
        }
    }
    
}
