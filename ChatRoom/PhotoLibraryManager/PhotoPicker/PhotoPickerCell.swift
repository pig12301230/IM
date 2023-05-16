//
//  PhotoPickerCell.swift
//  ImageTest
//
//  Created by ZoeLin on 2021/12/13.
//

import UIKit
import PhotosUI

class PhotoPickerCell: UICollectionViewCell {
    
    lazy var imageView: UIImageView = {
        let img = UIImageView()
        img.clipsToBounds = true
        img.contentMode = .scaleAspectFill
        img.translatesAutoresizingMaskIntoConstraints = false
        return img
    }()
    
    lazy var selectedMaskView: UIView = {
        let view = UIView()
        view.theme_backgroundColor = Theme.c_08_black_50.rawValue
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = false
        return view
    }()
    
    lazy var lblCount: UILabel = {
        let lbl = UILabel()
        lbl.font = .midiumParagraphSmallCenter
        lbl.theme_textColor = Theme.c_09_white.rawValue
        lbl.isUserInteractionEnabled = false
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    lazy var btnSelect: UIButton = {
        let btn = UIButton()
        btn.layer.cornerRadius = 12
        btn.theme_backgroundColor = Theme.c_08_black_25.rawValue
        btn.layer.borderColor = Theme.c_07_neutral_100.rawValue.toCGColor()
        btn.layer.borderWidth = 1
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(didClickSelectButton), for: .touchUpInside)
        return btn
    }()
    
    var clickSelectButton: ((String) -> Void)?
    private(set) var identifier: String = ""
    private(set) var requestID: PHImageRequestID?
    private(set) var cacheRequestID: PHImageRequestID?
    private let fetchImageQueue = DispatchQueue(label: "com.fetchAssetImage.queue", qos: .background, attributes: .concurrent)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        lblCount.text = ""
        clickSelectButton = nil
        selectedMaskView.isHidden = true
        btnSelect.theme_backgroundColor = Theme.c_08_black_25.rawValue
        
        if let requestID = requestID {
            PhotoLibraryManager.manager.cacheManager.cancelImageRequest(requestID)
            self.requestID = nil
        }

        if let cacheRequestID = cacheRequestID {
            PhotoLibraryManager.manager.cacheManager.cancelImageRequest(cacheRequestID)
            self.cacheRequestID = nil
        }

    }
    
    private func setupViews() {
        contentView.addSubview(imageView)
        contentView.addSubview(selectedMaskView)
        contentView.addSubview(btnSelect)
        contentView.addSubview(lblCount)
        
        imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        imageView.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
        imageView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        
        btnSelect.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8).isActive = true
        btnSelect.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8).isActive = true
        btnSelect.widthAnchor.constraint(equalToConstant: 24).isActive = true
        btnSelect.heightAnchor.constraint(equalToConstant: 24).isActive = true
        
        lblCount.centerXAnchor.constraint(equalTo: btnSelect.centerXAnchor).isActive = true
        lblCount.centerYAnchor.constraint(equalTo: btnSelect.centerYAnchor).isActive = true
      
        selectedMaskView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        selectedMaskView.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
        selectedMaskView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        selectedMaskView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
    }
    
    func config(asset: PHAsset, selectedIndex: Int?, size: CGSize) {
        identifier = asset.localIdentifier
        // 先使用低畫質顯示, 在替換成高畫質
        fetchImageQueue.async { [weak self] in
            guard let self = self else { return }
            self.cacheRequestID = PhotoLibraryManager.manager.cacheManager.requestImage(for: asset,
                                                                                        targetSize: size,
                                                                                        contentMode: .aspectFill,
                                                                                        options: PhotoLibraryManager.cacheManagerOpts()) { image, _ in
                DispatchQueue.main.async {
                    if self.identifier == asset.localIdentifier {
                        self.imageView.image = image
                    }
                }
                // fetch highQuality image
                let opts = PHImageRequestOptions()
                opts.deliveryMode = .highQualityFormat
                opts.resizeMode = .exact
                let newSize = CGSize(width: size.width * 2, height: size.height * 2)
                self.requestID = PhotoLibraryManager.manager.cacheManager.requestImage(for: asset,
                                                                                       targetSize: newSize,
                                                                                       contentMode: .aspectFill,
                                                                                       options: opts) { image, _ in
                    DispatchQueue.main.async {
                        if self.identifier == asset.localIdentifier {
                            self.imageView.image = image
                        }
                    }
                }
            }
        }
        guard let index = selectedIndex else {
            selectedMaskView.isHidden = true
            return
        }
        
        // 已選取
        selectedMaskView.isHidden = false
        btnSelect.backgroundColor = PhotoLibraryManager.manager.selectedColor
        lblCount.text = "\(index + 1)"
    }
    
    @objc private func didClickSelectButton() {
        clickSelectButton?(identifier)
    }
}
