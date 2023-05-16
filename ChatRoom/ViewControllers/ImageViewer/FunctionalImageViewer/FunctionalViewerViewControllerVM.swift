//
//  FunctionalViewerViewControllerVM.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/7/1.
//

import UIKit
import RxSwift
import RxCocoa

class FunctionalViewerViewControllerVM: BaseViewModel {
    
    let config: ImageViewerConfig
    let image: BehaviorRelay<UIImage?> = BehaviorRelay(value: nil)
    let showAlert = PublishSubject<String>()
    let showToast = PublishSubject<String>()
    let showLoading = PublishRelay<Bool>()
    
    init(config: ImageViewerConfig) {
        self.config = config
        super.init()
        self.downloadImage()
    }
    
    private func downloadImage() {
        ImageProcessor.shared.downloadImage(urlString: config.imageURL) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let retrieve):
                self.image.accept(retrieve.image)
            case .failure(_):
                self.image.accept(nil)
            }
        }
    }
    
    func doEditActionWith(_ image: UIImage) {
        switch self.config.actionType {
        case .viewAndUploadAvatar:
            self.uploadAvatar(image)
        default:
            break
        }
    }
    
    func downloadActionFinish(_ isSuccess: Bool) {
        switch self.config.actionType {
        case .viewAndDownload:
            self.showActionMessage(success: isSuccess)
        default:
            break
        }
    }
    
}

// MARK: - function action
private extension FunctionalViewerViewControllerVM {
    
    func uploadAvatar(_ image: UIImage) {
        self.showLoading.accept(true)
        DataAccess.shared.uploadAvatar(image) { [weak self] newImage in
            guard let self = self else { return }
            self.showLoading.accept(false)
            self.showActionMessage(success: newImage != nil)
            guard let image = newImage else { return }
            self.image.accept(image)
        }
    }
    
    func showActionMessage(success: Bool) {
        let message = success ? self.config.actionType.successMessage : self.config.actionType.failedMessage
        
        switch self.config.actionType.messagePresentTyoe {
        case .alert:
            self.showAlert.onNext(message)
        case .toast:
            self.showToast.onNext(message)
        default:
            break
        }
    }
    
}
