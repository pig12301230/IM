//
//  UIImageView+util.swift
//  ChatRoom
//
//  Created by Andy Yang on 2021/5/26.
//

import UIKit
import Photos

extension UIImageView {
    func roundSelf() {
        layoutIfNeeded()
        layer.cornerRadius = frame.width / 2
        layer.masksToBounds = true
    }
    
    func setImageColor(color: UIColor) {
        let templateImage = self.image?.withRenderingMode(.alwaysTemplate)
        self.image = templateImage
        self.tintColor = color
    }
}

extension UIImageView {
    func fetchImageAsset(_ asset: PHAsset?, size: CGSize = UIScreen.main.bounds.size, contentMode: PHImageContentMode = .aspectFill, options: PHImageRequestOptions? = PhotoLibraryManager.cacheManagerOpts()) {
        guard let asset = asset else {
            return
        }
        
        let resultHandler: (UIImage?, [AnyHashable: Any]?) -> Void = { image, _ in
            self.image = image
        }
        let options = options
        options?.deliveryMode = .highQualityFormat
        
        PhotoLibraryManager.manager.cacheManager.requestImage(
            for: asset,
            targetSize: .zero,
            contentMode: contentMode,
            options: options,
            resultHandler: resultHandler)
    }
}
