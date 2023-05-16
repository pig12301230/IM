//
//  ImageViewerViewController.swift
//  ImageTest
//
//  Created by ZoeLin on 2021/12/14.
//

import Foundation
import UIKit
import Photos
import Kingfisher

class ImageViewerViewController: UIViewController {
    private(set) lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var imagePlaceholder: UIImageView = {
        let view = UIImageView()
        return view
    }()
    
    private lazy var lblLoadingStatus: UILabel = {
        let lbl = UILabel()
        lbl.font = .regularParagraphMediumCenter
        lbl.theme_textColor = Theme.c_09_white.rawValue
        lbl.textAlignment = .center
        return lbl
    }()
    
    private(set) var index: Int!
    private(set) var asset: PHAsset?
    private(set) var imageUrlString: String?
    
    static func initVC(asset: PHAsset? = nil, imageUrlString: String? = nil, index: Int) -> ImageViewerViewController {
        let vc = ImageViewerViewController()
        vc.asset = asset
        vc.index = index
        vc.imageUrlString = imageUrlString
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
}

private extension ImageViewerViewController {
    func setupViews() {
        view.backgroundColor = .clear
        view.addSubview(imageView)
        view.addSubviews([imagePlaceholder, lblLoadingStatus, imageView])
        
        imageView.topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor, constant: 0).isActive = true
        imageView.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: 0).isActive = true
        imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        imagePlaceholder.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(40)
        }
        
        lblLoadingStatus.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(imagePlaceholder.snp.bottom).offset(4)
        }
        
        if let asset = asset {
            imageView.fetchImageAsset(asset, contentMode: .aspectFit)
        } else if let imageUrlString = imageUrlString {
            guard let url = URL(string: imageUrlString) else { return }
            // show loadingView
            if let loadingGif = ImageProcessor.shared.loadingGif {
                self.imagePlaceholder.image = loadingGif
                self.lblLoadingStatus.text = Localizable.loading
            }
            
            KingfisherManager.shared.retrieveImage(with: url) { result in
                switch result {
                case .success(let retrieve):
                    self.imageView.image = retrieve.image
                    self.imagePlaceholder.isHidden = true
                    self.lblLoadingStatus.isHidden = true
                case .failure(_):
                    self.imagePlaceholder.image = UIImage(named: "icon_icon_picture_fail")
                    self.lblLoadingStatus.text = Localizable.loadingFailed
                }
            }
        }
    }
}
