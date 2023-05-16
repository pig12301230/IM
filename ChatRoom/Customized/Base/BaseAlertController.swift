//
//  BaseAlertController.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/4/28.
//

import UIKit

class BaseAlertController: UIAlertController {

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
    }

    private func setupViews() {
        if let message = self.message {
            let msgAttributes = NSAttributedString(string: message,
                                                   attributes: [.foregroundColor: Theme.c_10_grand_1.rawValue.toColor(),
                                                                .font: UIFont.regularParagraphLargeLeft])
            self.setValue(msgAttributes, forKey: "attributedMessage")
        }
    }
}
