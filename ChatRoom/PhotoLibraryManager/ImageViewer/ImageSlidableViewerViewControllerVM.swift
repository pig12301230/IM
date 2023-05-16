//
//  ImageSlidableViewerViewControllerVM.swift
//  ChatRoom
//
//  Created by ERay_Peng on 2022/9/2.
//

import Foundation
import RxSwift
import RxCocoa

class ImageSlidableViewerViewControllerVM: BaseViewModel {
    private var disposeBag = DisposeBag()
    let showAlert = PublishSubject<String>()
    let showToast = PublishSubject<String>()
    
    let localGroupImagesConfigs: BehaviorRelay<[ImageViewerConfig]> = BehaviorRelay(value: [])
    var firstInConfig: ImageViewerConfig
    
    var groupId: String
    
    init(groupId: String, firstInConfig: ImageViewerConfig) {
        self.groupId = groupId
        self.firstInConfig = firstInConfig
        super.init()
        self.initBinding()
    }
    
    func initBinding() {
        DataAccess.shared.getGroupObserver(by: groupId).localGroupImagesConfigs.bind(to: localGroupImagesConfigs).disposed(by: self.disposeBag)
        
        DataAccess.shared.getGroupObserver(by: groupId).localGroupImagesConfigs.subscribeSuccess { [weak self] configs in
            guard let self = self, configs.count > 0 else { return }
            let removedDuplicateConfigs = Array(Set(configs)).sorted(by: { $0.messageId ?? "" < $1.messageId ?? "" })
            self.localGroupImagesConfigs.accept(removedDuplicateConfigs)
        }.disposed(by: disposeBag)
    }
    
    func downloadActionFinish(_ isSuccess: Bool, currentConfig: ImageViewerConfig) {
        switch currentConfig.actionType {
        case .viewAndDownload:
            self.showActionMessage(success: isSuccess, currentConfig: currentConfig)
        default:
            break
        }
    }
    
    func showActionMessage(success: Bool, currentConfig: ImageViewerConfig) {
        let message = success ? currentConfig.actionType.successMessage : currentConfig.actionType.failedMessage
        
        switch currentConfig.actionType.messagePresentTyoe {
        case .alert:
            self.showAlert.onNext(message)
        case .toast:
            self.showToast.onNext(message)
        default:
            break
        }
    }
}
