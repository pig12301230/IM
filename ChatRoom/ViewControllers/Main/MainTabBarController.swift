//
//  MainTabBarController.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/4/29.
//

import UIKit

class MainTabBarController: UITabBarController {
    
    var viewModel: MainTabBarControllerVM!
    
    static func initVC(with vm: MainTabBarControllerVM) -> MainTabBarController {
        let vc = MainTabBarController.init()
        vc.viewModel = vm
        vc.viewControllers = vm.tabViewControllers
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupViews()
    }
    
    func setupViews() {
        self.tabBar.isTranslucent = false
        
        self.tabBar.theme_backgroundColor = Theme.c_07_neutral_50.rawValue
        self.tabBar.theme_tintColor = Theme.c_01_primary_0_500.rawValue
        self.tabBar.theme_unselectedItemTintColor = Theme.c_07_neutral_800.rawValue
    }
}
