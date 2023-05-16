//
//  DebuggingNavigationController.swift
//  ChatRoom
//
//  Created by Kedia on 2023/4/6.
//

import Foundation
import UIKit

final class DebuggingNavigationController: UINavigationController {
    convenience init() {
        self.init(rootViewController: DebuggingOptionsViewController())
    }
    private override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
