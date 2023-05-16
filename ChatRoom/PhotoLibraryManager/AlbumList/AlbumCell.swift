//
//  AlbumCell.swift
//  ImageTest
//
//  Created by ZoeLin on 2021/12/14.
//

import UIKit
import PhotosUI

class AlbumCell: UITableViewCell {
    lazy var iconImageView: UIImageView = {
        let img = UIImageView()
        img.clipsToBounds = true
        img.contentMode = .scaleAspectFill
        img.translatesAutoresizingMaskIntoConstraints = false
        return img
    }()
    
    lazy var lblName: UILabel = {
        let lbl = UILabel()
        lbl.theme_textColor = Theme.c_10_grand_1.rawValue
        lbl.font = .midiumParagraphLargeLeft
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    lazy var statusImageView: UIImageView = {
        let img = UIImageView(image: UIImage(named: "iconIconCheckActive"))
        img.translatesAutoresizingMaskIntoConstraints = false
        return img
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        lblName.text = ""
        statusImageView.isHidden = true
        iconImageView.image = nil
    }
    
    func config(data: CollectionData, selected: Bool) {
        lblName.text = data.title
        statusImageView.isHidden = !selected
        
        guard let lastAsset = data.thumbnail else {
            return
        }
        iconImageView.fetchImageAsset(lastAsset, options: nil)
    }
    
    private func setupViews() {
        contentView.theme_backgroundColor = Theme.c_07_neutral_50.rawValue
        contentView.addSubview(iconImageView)
        contentView.addSubview(lblName)
        contentView.addSubview(statusImageView)
        
        iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        iconImageView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        iconImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        iconImageView.widthAnchor.constraint(equalTo: iconImageView.heightAnchor).isActive = true
        
        lblName.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        lblName.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 16).isActive = true
        
        statusImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        statusImageView.leadingAnchor.constraint(equalTo: lblName.trailingAnchor, constant: 4).isActive = true
        statusImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16).isActive = true
        statusImageView.heightAnchor.constraint(equalToConstant: 24).isActive = true
        statusImageView.widthAnchor.constraint(equalToConstant: 24).isActive = true
        statusImageView.isHidden = true
    }
}
