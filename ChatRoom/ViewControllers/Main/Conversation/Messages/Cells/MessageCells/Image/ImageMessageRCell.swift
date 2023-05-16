//
//  ImageMessageRCell.swift
//  ChatRoom
//
//  Created by Saffi Peng on 2021/7/20.
//

import UIKit
import RxSwift
import SwiftTheme
import Kingfisher

class ImageMessageRCell<T: ImageMessageCellVM>: MessageBaseRCell<T> {
    private var url: URL?
    private var retryCount: Int = 0

    private lazy var contentImage: UIImageView = {
        let imageView = UIImageView()
        imageView.theme_backgroundColor = Theme.c_01_primary_200.rawValue
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 4
        imageView.clipsToBounds = true
        return imageView
    }()

    private lazy var imagePlaceholder: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "icon_icon_picture_placeholder"))
        imageView.isHidden = true
        return imageView
    }()
    
    private lazy var lblLoadingStatus: UILabel = {
        let lbl = UILabel()
        lbl.font = .regularParagraphTinyCenter
        lbl.theme_textColor = Theme.c_07_neutral_400.rawValue
        lbl.textAlignment = .center
        return lbl
    }()
    
    private lazy var btnCancel: ProgressCancelButton = {
        let button = ProgressCancelButton()
        button.isHidden = true
        return button
    }()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.contentImage.image = nil
        self.contentImage.theme_backgroundColor = Theme.c_01_primary_200.rawValue
        self.btnCancel.resetFractionCompleted()
        self.imagePlaceholder.image = UIImage(named: "icon_icon_picture_placeholder")
        self.imagePlaceholder.isHidden = false
        self.lblLoadingStatus.isHidden = false
        self.url = nil
        self.retryCount = 0
    }

    override func setupViews() {
        super.setupViews()
        self.layer.cornerRadius = 4

        contentContainerView.addSubview(contentImage)
        contentContainerView.addSubview(imagePlaceholder)
        contentContainerView.addSubview(lblLoadingStatus)

        contentContainerView.addSubview(btnCancel)

        self.contentImage.snp.makeConstraints { make in
            make.top.bottom.leading.equalToSuperview()
            make.width.height.equalTo(MessageContentSize.imageNormalHeight)
            make.trailing.equalTo(-8)
        }
        
        self.imagePlaceholder.snp.makeConstraints { make in
            make.center.equalTo(contentImage)
            make.width.height.equalTo(40)
        }
        
        self.lblLoadingStatus.snp.makeConstraints { make in
            make.top.equalTo(imagePlaceholder.snp.bottom).offset(4)
            make.centerX.equalTo(imagePlaceholder.snp.centerX)
            make.height.equalTo(14)
        }
        
        self.btnCancel.snp.makeConstraints { make in
            make.center.equalTo(contentImage)
        }
    }

    override func bindViewModel() {
        super.bindViewModel()

        // Image Message
        self.viewModel.imageType
            .observe(on: MainScheduler.instance)
            .compactMap { $0 }
            .distinctUntilChanged()
            .subscribeSuccess { [weak self] imageType in
            guard let self = self else { return }
            switch imageType {
            case .localImage(let url):
                let image = UIImage(fileURLWithPath: url)
                self.updateImage(with: image)
            case .url(let url):
                self.url = url
                if let image = KingfisherManager.shared.cache.retrieveImageInMemoryCache(forKey: url.absoluteString) {
                    self.updateImage(with: image)
                } else {
                    self.downloadImage(with: url)
                }
            default:
                self.viewModel.imageLoadingStatus.accept(.loading)
            }
        }.disposed(by: self.disposeBag)

        
        // Image Status
        self.viewModel.imageStatus.observe(on: MainScheduler.instance).subscribeSuccess { [weak self] status in
            guard let self = self else { return }
            self.updateStatusView(status: status)
        }.disposed(by: self.disposeBag)
        
        self.viewModel.imageLoadingStatus
            .observe(on: MainScheduler.instance)
            .compactMap { $0 }
            .bind { [weak self] status in
                guard let self else { return }
                switch status {
                case .loading:
                    self.imagePlaceholder.isHidden = false
                    self.lblLoadingStatus.isHidden = false
                    if let loadingGif = ImageProcessor.shared.loadingGif {
                        self.imagePlaceholder.image = loadingGif
                        self.lblLoadingStatus.text = Localizable.loading
                        self.updateImageLayout(withImage: nil)
                    }
                case .success:
                    self.imagePlaceholder.isHidden = true
                    self.lblLoadingStatus.isHidden = true
                    self.contentImage.backgroundColor = .clear
                case .failed:
                    self.imagePlaceholder.isHidden = false
                    self.lblLoadingStatus.isHidden = false
                    self.imagePlaceholder.image = UIImage(named: "icon_icon_picture_fail")
                    self.lblLoadingStatus.text = Localizable.loadingFailed
                }
            }.disposed(by: self.disposeBag)

        // MARK: - click signal
        self.btnCancel.rx.controlEvent(.touchUpInside).subscribeSuccess { [weak self] _ in
            guard let self = self else { return }
            self.viewModel.cancelUpload.onNext(())
        }.disposed(by: self.disposeBag)

        self.contentImage.rx.click
            .throttle(.microseconds(300), scheduler: MainScheduler.instance)
            .subscribeSuccess { [weak self] in
                guard let self else { return }
                switch self.viewModel.imageLoadingStatus.value {
                case .success:
                    self.viewModel.clickContentImage()
                case .failed:
                    guard let url = self.url else { return }
                    self.retryCount = 0
                    self.downloadImage(with: url)
                default:
                    break
                }
            }.disposed(by: self.disposeBag)
    }

    override func resetViewSetting() {
        super.resetViewSetting()
        self.contentImage.image = nil
        self.imagePlaceholder.image = UIImage(named: "icon_icon_picture_placeholder")
        self.lblLoadingStatus.text = Localizable.loading
    }
}

// MARK: - Image Message
private extension ImageMessageRCell {
    
    func downloadImage(with url: URL) {
        self.viewModel.imageLoadingStatus.accept(.loading)
                        
        ImageProcessor.shared.downloadImage(urlString: url.absoluteString) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let data):
                guard data.source.url == self.viewModel.cacheImageUrl else { return }
                self.updateImage(with: data.image)
            case .failure(_):
                if self.retryCount < 1 {
                    self.retryCount += 1
                    self.downloadImage(with: url)
                } else {
                    self.updateImage(with: nil)
                }
            }
        }
    }
    
    func updateImage(with image: UIImage?) {
        self.viewModel.imageLoadingStatus.accept(image != nil ? .success : .failed)
        self.contentImage.image = image?.withRoundedCorners(radius: 4)
        self.updateImageLayout(withImage: image)
    }

    func updateImageLayout(withImage: UIImage?) {
        self.contentImage.snp.remakeConstraints { make in
            make.top.bottom.leading.equalToSuperview()
            make.trailing.equalTo(-8)
            if withImage == nil {
                make.width.greaterThanOrEqualTo(MessageContentSize.imageNormalHeight)
            }
            
            if let image = withImage {
                let ratio = MessageContentSize.imageNormalHeight / image.size.height
                if ratio <= 1 {
                    let width = image.size.width * ratio
                    make.width.equalTo(width)
                } else {
                    make.width.equalTo(image.size.width)
                }
            }

            make.width.lessThanOrEqualTo(MessageContentSize.maxWidth).priority(.required)
            make.height.equalTo(MessageContentSize.imageNormalHeight)
        }
    }
}

// MARK: - Image Status
private extension ImageMessageRCell {
    func updateStatusView(status: MessageStatus) {
        switch viewModel.status {
        case .success:
            guard btnCancel.isHidden == false else { return }
            btnCancel.fractionCompleted(completion: nil)
            
        case .fakeSending:
            guard let fractionCompleted = self.viewModel.getLoadingProgress() else {
                self.btnCancel.resetFractionCompleted()
                return
            }
            self.updateFraction(fraction: fractionCompleted)
            
        default:
            self.btnCancel.resetFractionCompleted()
        }
    }
    
    func updateFraction(fraction: Double) {
        if fraction < 1 {
            self.btnCancel.isUserInteractionEnabled = true
            self.btnCancel.updateFractionCompleted(fraction)
        } else {
            btnCancel.fractionCompleted() {
                self.btnCancel.isUserInteractionEnabled = false
            }
        }
    }
}
