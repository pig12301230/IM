//
//  ToastViewVM.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/5/19.
//

import UIKit
import RxSwift
import RxCocoa

class ToastViewVM: BaseViewModel {

    enum ToastType {
        // fixed height
        case image
        case gif
        
        // adjust height
        case message
        
        var toastSize: CGSize? {
            switch self {
            case .image, .gif:
                return CGSize.init(width: Application.shared.minToastWidth, height: Application.shared.minToastWidth)
            default:
                return nil
            }
        }
    }
    
    var disposeBag = DisposeBag()

    let iconImage: BehaviorRelay<UIImage?> = BehaviorRelay(value: nil)
    let iconGif: BehaviorRelay<[UIImage]?> = BehaviorRelay(value: nil)
    let hint: BehaviorRelay<String> = BehaviorRelay(value: "")
    let message: BehaviorRelay<String> = BehaviorRelay(value: "")
    let toastType: BehaviorRelay<ToastType> = BehaviorRelay(value: .message)
    // toast view size, adjust or fixed
    private(set) var toastSize: CGSize = .zero
    // super view size, screen.size
    private(set) var superSize: CGSize = .zero
    let minWidth = Application.shared.minToastWidth

    convenience init(size: CGSize, icon: UIImage?, hint: String) {
        self.init()
        self.superSize = size
        self.updateHintSize(with: hint, maxSize: size, type: .image)
        self.iconImage.accept(icon)
        self.hint.accept(hint)
    }

    convenience init(size: CGSize, icons: [UIImage], hint: String) {
        self.init()
        self.superSize = size
        self.updateHintSize(with: hint, maxSize: size, type: .gif)
        self.iconGif.accept(icons)
        self.hint.accept(hint)
    }
    
    convenience init(size: CGSize, hint: String) {
        self.init()
        self.superSize = size
        self.updateHintSize(with: hint, maxSize: size, type: .message)
        self.hint.accept(hint)
    }

    convenience init(message: String) {
        self.init()
        
        self.message.accept(message)
    }
    
    func updateView(icon: UIImage?, hint: String) {
        self.updateHintSize(with: hint, maxSize: self.superSize, type: .image)
        self.iconImage.accept(icon)
        self.hint.accept(hint)
    }

    func updateView(icons: [UIImage]?, hint: String) {
        self.updateHintSize(with: hint, maxSize: self.superSize, type: .gif)
        self.iconGif.accept(icons)
        self.hint.accept(hint)
    }
    
    func updateView(hint: String) {
        self.updateHintSize(with: hint, maxSize: self.superSize, type: .message)
        self.hint.accept(hint)
    }
    
    private func updateHintSize(with hint: String, maxSize: CGSize, type: ToastType) {
        if type == .message {
            // 純訊息部分, 需隨著內容改變 size, 最小寬度為 120
            let size = hint.size(font: .regularParagraphMediumLeft, maxSize: CGSize.init(width: maxSize.width, height: maxSize.height))
            
            var width = size.width + 32
            if width < Application.shared.minToastWidth {
                width = Application.shared.minToastWidth
            }
            
            // 上下間距 (8, 8)
            let height = ceil(size.height + 16)
            self.toastSize = CGSize.init(width: width, height: height)
            
        } else if let size = type.toastSize {
            // 其餘型態的 toast 為固定寬高 (120, 120)
            let maxWidth = size.width - 32
            let newHeight = hint.size(font: .regularParagraphMediumLeft, maxSize: CGSize.init(width: maxWidth, height: maxSize.height)).height + 40 + 32 + 4
            
            let height = max(size.height, newHeight)
            self.toastSize = CGSize(width: size.width, height: height)
        }
        
        self.toastType.accept(type)
    }
    
    func updateView(message: String) {
        self.message.accept(message)
    }
}
