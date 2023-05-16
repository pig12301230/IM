//
//  UICollectionView+util.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/6/2.
//

import UIKit

extension UICollectionView {

    func reloadData(_ completion: @escaping () -> Void) {
        reloadData()
        layoutIfNeeded()
        DispatchQueue.main.async {
            completion()
        }
    }

    func scrollToBottom(animated: Bool) {
        let y = contentSize.height - 1
        let rect = CGRect(x: 0, y: y + safeAreaInsets.bottom, width: 1, height: 1)
        scrollRectToVisible(rect, animated: animated)
    }
}
