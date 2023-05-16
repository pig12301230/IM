//
//  UIViewController+util.swift
//  LotBase
//
//  Created by george_tseng on 2020/6/5.
//  Copyright © 2020 Paridise-Soft. All rights reserved.
//

import UIKit

extension UIViewController {

    /**
     *  Height of status bar + navigation bar (if navigation bar exist)
     */
    var topbarHeight: CGFloat {
        return UIApplication.shared.statusBarFrame.size.height + (self.navigationController?.navigationBar.frame.height ?? 0.0)
    }
    
    static func loadFromNib() -> Self {
        func instantiateFromNib<T: UIViewController>() -> T {
            return T.init(nibName: String(describing: T.self), bundle: nil)
        }
        return instantiateFromNib()
    }

    // MARK: - Alert
    func showAlert(title: String? = "", message: String? = "", cancelBtnTitle: String? = nil, comfirmBtnTitle: String?, onCancel: (() -> Void)? = nil, onConfirm: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        if let title = cancelBtnTitle {
            let cancel = UIAlertAction(title: title, style: .default) { _ in
                onCancel?()
            }
            alert.addAction(cancel)
        }
        if let title = comfirmBtnTitle {
            let confirm = UIAlertAction(title: title, style: .default) { _ in
                onConfirm?()
            }
            alert.addAction(confirm)
        }

        self.present(alert, animated: true, completion: nil)
    }
    
    func showAlert(title: DisplayConfig? = nil, message: DisplayConfig? = nil, actions: [UIAlertAction]) {
        let titleText: String? = title == nil ? nil : ""
        let messageText: String? = message == nil ? nil : ""
        let alert = UIAlertController(title: titleText, message: messageText, preferredStyle: .alert)
        
        
        if let title = title {
            let titleAttributed = NSAttributedString(string: title.text, attributes: [NSAttributedString.Key.foregroundColor: title.textColor, NSAttributedString.Key.font: title.font])
            alert.setValue(titleAttributed, forKey: "attributedTitle")
        }
        
        if let message = message {
            let messageAttributed = NSAttributedString(string: message.text, attributes: [NSAttributedString.Key.foregroundColor: message.textColor, NSAttributedString.Key.font: message.font])
            alert.setValue(messageAttributed, forKey: "attributedMessage")
        }
        
        for action in actions {
            alert.addAction(action)
        }
        
        self.present(alert, animated: true, completion: nil)
    }

    func showSheet(title: String? = nil, message: String? = nil, actions: UIAlertAction..., cancelBtnTitle: String? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)

        for action in actions {
            alert.addAction(action)
        }
        if let title = cancelBtnTitle {
            let cancel = UIAlertAction(title: title, style: .cancel, handler: nil)
            alert.addAction(cancel)
        }

        self.present(alert, animated: true, completion: nil)
    }

    func showSheet(title: String? = nil, message: String, actions: [UIAlertAction]) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)

        for action in actions {
            alert.addAction(action)
        }
        self.present(alert, animated: true, completion: nil)
    }
    
    struct DisplayConfig {
        var font: UIFont
        var textColor: UIColor
        var text: String
    }
}
