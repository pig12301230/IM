//
//  SearchTextField.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/4/27.
//

import UIKit

class SearchTextField: UITextField {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupView() {
        self.autocapitalizationType = .none
        self.returnKeyType = .search
        
        self.setupLeftView()
        self.setupText()
        
        self.theme_backgroundColor = Theme.c_07_neutral_100.rawValue
        self.clearButtonMode = .whileEditing
    }
    
    override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect.init(origin: CGPoint.init(x: 10, y: 6), size: CGSize.init(width: bounds.size.height, height: 24))
    }
    
    private func setupLeftView() {
        let iView = UIImageView.init(image: UIImage.init(named: "iconIconSearch"))
        iView.contentMode = .scaleAspectFit
        iView.theme_tintColor = Theme.c_07_neutral_400.rawValue
        self.leftView = iView
        self.leftViewMode = .always
        self.layer.cornerRadius = 4
    }
    
    private func setupText() {
        updatePlaceHolder(placeHolderStr: Localizable.search)
        self.theme_textColor = Theme.c_10_grand_1.rawValue
        self.font = .medium(16)
    }
    
    func updatePlaceHolder(placeHolderStr: String) {
        let attr = NSAttributedString(string: placeHolderStr, attributes: [NSAttributedString.Key.foregroundColor: Theme.c_07_neutral_400.rawValue.toColor(), NSAttributedString.Key.font: UIFont.regularParagraphLargeLeft])
        attributedPlaceholder = attr
    }
}
