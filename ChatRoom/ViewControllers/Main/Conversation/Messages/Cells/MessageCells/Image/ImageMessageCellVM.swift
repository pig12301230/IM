//
//  ImageMessageCellVM.swift
//  ChatRoom
//
//  Created by Saffi Peng on 2021/7/20.
//

import Foundation
import RxSwift
import RxCocoa

class ImageMessageCellVM: MessageBaseCellVM {

    enum ImageUseType: Equatable {
        case localImage(_ url: URL)
        case url(_ url: URL)
        case needToGetFile(_ fileId: String)
        
        var url: URL? {
            switch self {
            case .localImage(let url), .url(let url):
                return url
            default:
                return nil
            }
        }
    }
    
    enum ImageLoadingStatus {
        case success
        case failed
        case loading
    }
    
    private(set) var modelID: String?
    private(set) var cacheImageUrl: URL?
    
    let imageType: BehaviorRelay<ImageUseType?> = BehaviorRelay(value: nil)
    let imageStatus: BehaviorRelay<(MessageStatus)> = BehaviorRelay(value: (.success))
    let imageLoadingStatus: BehaviorRelay<ImageLoadingStatus?> = .init(value: nil)
    let sendImageByUrl: BehaviorRelay<(URL?)> = BehaviorRelay(value: nil)
    let cancelUpload = PublishSubject<Void>()

    init(model: MessageBaseModel, withRead: Bool, imageType: ImageUseType) {
        super.init(model: model, withRead: withRead)
        self.cellIdentifier = (model.config.sender == .me ? "ImageMessageRCell" : "ImageMessageLCell")
        self.modelID = model.message.id
        self.imageType.accept(imageType)
        self.cacheImageUrl = imageType.url
        self.config.accept(model.config)
        self.updateView(model: model)
        self.imageStatus.accept(self.status)
        self.initBinding()
        if case .needToGetFile(_) = imageType {
            self.getFile(groupId: model.message.groupID, messageId: model.message.id, fileId: model.message.fileIDs.first ?? "")
        }
    }

    private func initBinding() {
        self.cancelUpload.subscribeSuccess { [unowned self] _ in
            guard self.status == .fakeSending, let id = self.modelID else {
                return
            }
            self.imageStatus.accept(.failed)
            DataAccess.shared.cancelUpload(modelID: id)
        }.disposed(by: self.disposeBag)
    }
    
    private func getFile(groupId: String, messageId: String, fileId: String) {
        DataAccess.shared.loadFile(groupId, messageID: messageId, fileIDs: [fileId])
            .subscribeSuccess { [weak self] rmessage in
                guard let self = self else { return }
                guard let rmessage = rmessage else { return }
                guard let thumbUrl = rmessage.files.first?.thumbURL, let url = URL(string: thumbUrl) else { return }
                self.cacheImageUrl = url
                self.imageType.accept(.url(url))
                
                let format = String(format: "_id = '%@' AND deleted = false", rmessage.diffID)
                let isExist = DataAccess.shared.realmDAO.checkExist(type: RLMMessage.self, predicateFormat: format)
                guard isExist else { return }
                guard let imageUrl = DataAccess.shared.getFile(by: rmessage.fileIDs.first ?? "")?.url,
                      let transceiver = DataAccess.shared.getGroupTransceiver(by: groupId, memberID: rmessage.userID) else { return }
                let title = transceiver.nickname
                let imageConfig = ImageViewerConfig(title: title, date: rmessage.createAt, imageURL: imageUrl, actionType: .viewAndDownload, fileID: rmessage.fileIDs.first, messageId: rmessage.diffID)
                DataAccess.shared.getGroupObserver(by: groupId).localGroupImagesConfigs.append(elements: [imageConfig])
        }.disposed(by: disposeBag)
    }
    
    func clickContentImage() {
        if self.imageStatus.value == .success {
            guard let transceiver = self.baseModel.transceiver,
                  let fileID = self.baseModel.message.fileIDs.first else {
                return
            }
            var imageURL: String = ""
            if let imageFileName = self.baseModel.message.imageFileName {
                imageURL = AppConfig.Device.localImageFilePath.appendingPathComponent(imageFileName, isDirectory: false).absoluteString
            } else if let url = DataAccess.shared.getFile(by: fileID)?.url {
                imageURL = url
            }
            let config = ImageViewerConfig(title: transceiver.display, date: self.baseModel.message.createAt, imageURL: imageURL, actionType: .viewAndDownload, fileID: fileID, messageId: self.baseModel.message.diffID)
            self.showImageViewer.onNext(config)
        } else if self.imageStatus.value == .failed {
            self.showImageFailureToast.onNext(("iconIconAlertError", Localizable.pleaseCheckNetworkSetting))
        }
    }
    
    func sendImage() {
        self.sendImageByUrl.accept(self.imageType.value?.url)
    }
    
    func getLoadingProgress() -> Double? {
        guard let createAt = self.baseModel.message.createAt else { return nil }
        let now = Date()
        let threeSecondsAgo = now.addingTimeInterval(-3)
        // 3秒內計算 progress，使用此方法避免 cell reuse binding disposed
        return createAt > threeSecondsAgo ? now.timeIntervalSince(createAt) / 3 : nil
    }
        
    // MARK: - MessageContentCellProtocol
    override func updateMessageStatus(_ status: MessageStatus) {
        super.updateMessageStatus(status)
    }

    override func updateReadStatus(_ read: Bool) {
        super.updateReadStatus(read)
        self.isRead.accept(read)
    }
}
