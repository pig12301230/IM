//
//  SelectMoreCell.swift
//  ImageTest
//
//  Created by ZoeLin on 2021/12/16.
//

import UIKit

class SelectMoreCell: UICollectionViewCell {
    lazy var iconImage: UIImageView = {
        let img = UIImageView(image: UIImage(named: "iconIconPlus"))
        img.translatesAutoresizingMaskIntoConstraints = false
        return img
    }()
    
    lazy var lblMessage: UILabel = {
        let lbl = UILabel()
        lbl.text = Localizable.addPhoto
        lbl.font = .midiumParagraphSmallCenter
        lbl.theme_textColor =  Theme.c_10_grand_2.rawValue
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        contentView.theme_backgroundColor = Theme.c_07_neutral_200.rawValue
        contentView.addSubview(iconImage)
        contentView.addSubview(lblMessage)
        
        iconImage.bottomAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 5).isActive = true
        iconImage.widthAnchor.constraint(equalToConstant: 32).isActive = true
        iconImage.heightAnchor.constraint(equalToConstant: 32).isActive = true
        iconImage.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        
        lblMessage.topAnchor.constraint(equalTo: iconImage.bottomAnchor).isActive = true
        lblMessage.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
    }
}
