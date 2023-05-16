//
//  ImageProcessor.swift
//  ChatRoom
//
//  Created by Winston_Chuang on 2023/3/23.
//

import Foundation
import Kingfisher

class ImageProcessor {
    private var imgCheckDomainTimer: Timer?
    static let shared = ImageProcessor()
    private(set) lazy var loadingGif: UIImage? = {
        guard let gif = UIImage.gifWithName("Rolling-1s-200px") else { return nil }
        let loadingImage = UIImage.animatedImage(with: gif, duration: 1)
        return loadingImage
    }()
    private lazy var context: CIContext = {
        return CIContext()
    }()
    
    func downloadImage(urlString: String, progressBlock: DownloadProgressBlock? = nil, completionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void)?, retryTime: Int = 1) {
        guard var url = URL(string: urlString) else {
            completionHandler?(Result.failure(KingfisherError.requestError(reason: .emptyRequest)))
            return
        }
        
        if self.imgCheckDomainTimer == nil {
            self.setupImgCheckDomainTimer()
        }
        
        let downloadTimeout: Int = (retryTime >= 1) ? 3 : 15 // 15 is KingFisher downloader default timeout
        ImageDownloader.default.downloadTimeout = TimeInterval(downloadTimeout)
        
        #if PROD
        // change domain in PROD
        var newURL = URLComponents.init(url: url, resolvingAgainstBaseURL: true)
        newURL?.host = AppConfig.CurrentDomain.imageDomain
        guard let updatedURL = newURL?.url else { return }
        url = updatedURL
        #endif
        
        PRINT("Start At: \(urlString)", cate: .process)
        let resource = ImageResource(downloadURL: url)
        KingfisherManager.shared.retrieveImage(with: resource) { result in
            switch result {
            case .success(_):
                break
            case .failure(_):
                if retryTime >= 1 {
                    self.imgCheckDomainTimer?.invalidate()
                    self.setupImgCheckDomainTimer()
                    self.downloadImage(urlString: urlString, completionHandler: completionHandler, retryTime: retryTime - 1)
                    return
                }
            }
            completionHandler?(result)
        }
    }
    
    func getCompressionImageData(with image: UIImage) -> Data? {
        let size = image.getSizeIn(.megabyte, opt: .jpeg)
        guard size > 0.0 else {
            return nil
        }
        
        let limit = Application.shared.limitImageMB
        let compression = size < limit ? 1 : (limit / size) - 0.05
        return image.jpegData(compressionQuality: CGFloat(compression))
    }
    
    private func setupImgCheckDomainTimer() {
        // update image CDN before reset timer
        self.updateImageDomain(completion: nil)
        self.imgCheckDomainTimer = Timer.scheduledTimer(withTimeInterval: AppConfig.imgDomainRefreshTime, repeats: true, block: { _ in
            self.updateImageDomain(completion: nil)
        })
    }
    
    private func updateImageDomain(completion: (() -> Void)?) {
        let cDNList = AppConfig.ImageParallelCDN.allCases.map({ $0.line })
        MultiRequestAPI.parallel.request(domains: cDNList, target: "/speed_test.jpeg") { domain in
            guard let domain = domain else {
                return
            }
            AppConfig.CurrentDomain.imageDomain = domain
            completion?()
        }
    }
    
    func detectQRCode(_ image: UIImage?) -> [CIFeature]? {
        if let image = image, let ciImage = image.ciImage {
            var options: [String: Any]
            options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
            let qrDetector = CIDetector(ofType: CIDetectorTypeQRCode, context: context, options: options)
            if ciImage.properties.keys.contains((kCGImagePropertyOrientation as String)) {
                options = [CIDetectorImageOrientation: ciImage.properties[(kCGImagePropertyOrientation as String)] ?? 1]
            } else {
                options = [CIDetectorImageOrientation: 1]
            }
            let features = qrDetector?.features(in: ciImage, options: options)
            return features

        }
        return nil
    }
}
