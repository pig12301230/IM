//
//  DesignableUITextField.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/4/15.
//

import UIKit

class DesignableUITextField: UITextField {
    
    @IBInspectable var imageLeftPadding: CGFloat = 8
    @IBInspectable var leftImage: UIImage? {
        didSet {
            self.updateView()
        }
    }
    
    @IBInspectable var placeholderColor: UIColor = UIColor.lightGray {
        didSet {
            self.updateView()
        }
    }
    
    var copyAndPasteDisable: Bool = false
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if self.copyAndPasteDisable && (action == #selector(copy(_:)) || action == #selector(paste(_:))) {
            return false
        }
        return super.canPerformAction(action, withSender: sender)
    }
    
    override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        var textRect = super.leftViewRect(forBounds: bounds)
        textRect.origin.x += self.imageLeftPadding
        return textRect
    }
    
    func updateView() {
        if let image = self.leftImage {
            leftViewMode = UITextField.ViewMode.always
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 16, height: 16))
            imageView.contentMode = .scaleAspectFit
            imageView.image = image
            leftView = imageView
        } else {
            leftViewMode = UITextField.ViewMode.never
            leftView = nil
        }
        
        guard let placeholder = placeholder else {
            return
        }
        
        attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [NSAttributedString.Key.foregroundColor: self.placeholderColor])
    }
}
