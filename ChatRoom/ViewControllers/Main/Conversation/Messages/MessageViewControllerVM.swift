//
//  MessageViewControllerVM.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/7/4.
//

import Foundation
import RxSwift
import RxCocoa
import Photos

class MessageViewControllerVM: BaseViewModel {
    
    struct Input {
        let selectedMessage: BehaviorRelay<MessageModel?> = BehaviorRelay(value: nil)
        let showImageViewer = PublishSubject<ImageViewerConfig>()
        let showHongBaoView = PublishSubject<HongBaoContent>()
        let showEmojiList = PublishSubject<String>()
        let goToContactDetail = PublishSubject<FriendModel>()
        let showToastWithIcon = PublishSubject<(String, String)>()
        let setReadMessage = PublishSubject<String>()
        let searchingContent = BehaviorRelay<String>(value: "")
        let deletedMessage = PublishSubject<MessageModel>()
        let announcements = BehaviorRelay<[AnnouncementModel]>(value: [])
        let scrollToMessage = PublishSubject<String>()
        let clearMessage = PublishSubject<Void>()
    }
    
    struct Output {
        let endEditing = PublishRelay<Void>()
        let resendMessageModel = PublishSubject<MessageModel>()
        let deleteMessageSignal = PublishSubject<MessageModel>()
        let unsendMessageModel = PublishSubject<MessageModel>()
        let unOpenedHongBao: BehaviorRelay<UnOpenedHongBaoModel?> = .init(value: nil)
        let lottieUrl: BehaviorRelay<String?> = .init(value: nil)
        let floatingViewHidden: BehaviorRelay<Bool> = BehaviorRelay(value: true)
    }
    
    var disposeBag = DisposeBag()
    
    let showToast = PublishSubject<String>()
    let showLoading = PublishRelay<Bool>()
    let showAlert = PublishSubject<String>()
    let showScrollButton: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    var keyboardHeight: Observable<CGFloat> = Observable.from(optional: .zero)
    let openPhotoLibrary = PublishSubject<PhotoLibraryType>()
    let finishedPhotoLibrary = PublishSubject<Void>()
    var attachmentShowed = PublishRelay<Void>()
    let showConversatonBottom = PublishSubject<Void>()
    var closeToolView = PublishSubject<Void>()
    
    let scrollToHighlightIndexPath = PublishRelay<IndexPath>()
    
    private(set) var input: Input = Input()
    private(set) var output: Output = Output()
    
    let dataAccess = DataAccess.shared
    
    private(set) var announcementViewModel: AnnouncementViewModel
    private(set) var replyViewModel: ReplyMessageViewVM
    private(set) var toolBarViewModel: ConversationToolBarVM
    private(set) var permission: UserRoleModel?
    private(set) var resendModels = [String]()
    let actionToolVM = ActionToolVM()
    let emojiToolVM = EmojiToolVM()
    
    let interactor: ConversationInteractor
    private(set) var position: LocatePosition = .bottom
    var direction: MessageDirection = .after
    private var lastIndex: Int = 0
    let assetsQueue = DispatchQueue.init(label: "photo.library.asset.queue")
    
    private(set) var recoverLastMessage: String?
    
    var group: GroupModel {
        interactor.group
    }
    
    init(with conversationDataSource: ConversationDataSource, target: String? = nil) {
        self.announcementViewModel = AnnouncementViewModel(with: conversationDataSource.output.allTransceivers.value)
        self.replyViewModel = ReplyMessageViewVM(with: conversationDataSource.output.allTransceivers.value)
        self.interactor = ConversationInteractor(dataSource: conversationDataSource, target: target)
        self.toolBarViewModel = ConversationToolBarVM.init(with: conversationDataSource.group)
        super.init()
        self.keyboardHeight = self.observeKeyboardHeight()
        self.initBinding()
        getAnnouncements()
        getUnOpenedHongBao()
        
        conversationDataSource.input.deleteMessage.bind(to: self.input.deletedMessage).disposed(by: disposeBag)
        conversationDataSource.input.announcements.bind(to: self.input.announcements).disposed(by: disposeBag)
        conversationDataSource.input.rolePermission
            .observe(on: MainScheduler.instance)
            .subscribeSuccess { [unowned self] role in
                guard let role = role else { return }
                self.actionToolVM.setup(scene: role.type.actionToolScene)
                self.permission = role
                
                // 只有群組管理員跟擁有者 有權限
                if self.permission?.type == .admin || self.permission?.type == .owner {
                    self.announcementViewModel.setPermission(true)
                }
                self.toolBarViewModel.updatePermission(to: role)
            }.disposed(by: disposeBag)
        
        conversationDataSource.input.fetchUnopenedHongBao
            .bind { [weak self] in
                guard let self = self else { return }
                self.getUnOpenedHongBao()
            }.disposed(by: disposeBag)
        
        // 取得 group 的 permission
        
        guard conversationDataSource.group.groupType == .group else {
            let userIDs = group.name.components(separatedBy: "_").filter({ $0 != UserData.shared.userInfo?.id })
            if !userIDs.isEmpty {
                dataAccess.fetchGroupMembers(groupID: group.id, memberIDs: userIDs)
            }
            
            actionToolVM.setup(scene: .directMessage)
            // 一對一 有權限設定公告
            announcementViewModel.setPermission(true)
            return
        }
        
        dataAccess.fetchGroup(by: group.id)
    }
    
    func dispose() {
        disposeBag = DisposeBag()
        setViewStatus(false)
        interactor.dispose()
    }
    
    func fetchAdminList() {
        guard group.groupType == .group else { return }
        dataAccess.fetchGroupOwnerAdminList(groupID: group.id, ownerID: group.ownerID)
    }
    
    func setViewStatus(_ view: Bool) {
        guard view else {
            interactor.endReading()
            return
        }
        
        interactor.startReading()
    }
    
    func resignResponderView() {
        self.toolBarViewModel.didTapBackgroundView()
        self.output.endEditing.accept(())
    }
    
    func upload(image: UIImage) {
        guard let rightOrientationData = image.fixOrientation().pngData(),
              let url = PhotoLibraryManager.manager.saveImageDataAndGetFileName(imageData: rightOrientationData, suffix: AssetMimeType.png.fileSuffix) else { return }
        self.interactor.createImageMessage(imageFileName: url, index: 0)
    }

    func detailVM() -> ChatDetailViewControllerVM? {
        switch group.groupType {
        case .dm:
            guard let member = interactor.transceiversDict.value.values.filter({ $0.userID != UserData.shared.userInfo?.id }).first else { return nil }
            return ChatDetailViewControllerVM(data: FriendModel.converTransceiverToFriend(transceiver: member), style: .chatToPerson)
        case .group:
            return ChatDetailViewControllerVM(data: FriendModel.convertGroupToFriend(group: group), style: .chatToGroup)
        }
    }
    
    func resendMessage(_ model: MessageModel) {
        guard !self.resendModels.contains(model.id) else { return }
        resendModels.append(model.id)
        interactor.resendMessage(model)
    }
    
    func deleteFailureMessage(_ model: MessageModel) {
        dataAccess.deleteFailureMessage(model)
    }
    
    func deleteMessage(_ model: MessageModel) {
        dataAccess.deleteMessage(model: model)
    }
    
    func unsendMessage(_ model: MessageModel) {
        dataAccess.unsendMessage(model: model)
    }
    
    func updateLastView(isUnreadOverSize: Bool) {
        //        self.messageDataSource.updateLastView(with: isUnreadOverSize)
    }
    
    func getLongPressSender(with messageVM: MessageViewModel, anchor: AnchorPosition) -> Sender {
        guard let cellVM = messageVM.cellModel as? MessageBaseCellVM, let message = messageVM.model else {
            return .oneself
        }
        
        let sender: Sender = cellVM.baseModel.config.sender == .me ? .oneself : .others
        self.actionToolVM.setup(sender: sender, message: message, anchor: anchor)
        return sender
    }
    
    func setupEmoji(with message: MessageModel, emojiType: EmojiType?) {
        self.emojiToolVM.setup(message: message, emojiType: emojiType)
        dataAccess.updateEmojiFile(messageModel: message, emojiType: emojiType)
    }
    
    func unpinMessage(messageID: String) {
        showLoading.accept(true)
        dataAccess.unpinMessage(groupID: group.id, messageID: messageID) { [unowned self] _ in
            showLoading.accept(false)
        }
    }
    
    func pinMessage(messageID: String) {
        guard self.announcementViewModel.announcements.value.count < 5 else {
            showAlert.onNext(Localizable.alertAnnouncementLimit)
            return
        }
        showLoading.accept(true)
        dataAccess.pinMessage(groupID: group.id, messageID: messageID) { [unowned self] _ in
            showLoading.accept(false)
        }
    }
    
    func getMessageEmojiBySelf(model: MessageModel, completion: @escaping (EmojiType?) -> Void) {
        DataAccess.shared.getMessageEmojiBySelf(model: model) { emoji in
            guard let emoji = emoji, let emojiType = EmojiType(rawValue: emoji) else {
                completion(nil)
                return
            }
            completion(emojiType)
        }
    }
    
    func showHongBaoView(messageID: String) {
        interactor.getHongBaoContent(by: messageID) { [weak self] content in
            guard let self = self else { return }
            guard let content = content else { return }
            self.input.showHongBaoView.onNext(content)
        }
    }
    
    func updateFloatingViewHidden(hidden: Bool) {
        interactor.updateFloatingViewHidden(hidden: hidden)
    }
    
    //    func cellVM(index: Int) {
    //        let last = interactor.currentItemCount - 1
    //        if index > lastIndex && direction == .after {
    //            if index == interactor.currentItemCount - 70 {
    //                interactor.prefetchData(direction: .after)
    //            } else {
    //                let bottom = max(interactor.currentItemCount - 70, last)
    //                if let unreadIndex = interactor.unreadIndex {
    //                    let countAfterUnread = interactor.currentItemCount - unreadIndex
    //                    let fetchAfterIndex = countAfterUnread < 50 ? interactor.currentItemCount - (countAfterUnread / 3) : bottom
    //                    if index == fetchAfterIndex {
    //                        interactor.prefetchData(direction: .after)
    //                    }
    //                } else if index == bottom {
    //                    interactor.prefetchData(direction: .after)
    //                }
    //            }
    //        } else if index < lastIndex && direction == .previous {
    //            let top = min(50, last)
    //            if index == DataAccess.conversationPageSize {
    //                interactor.prefetchData(direction: .previous)
    //            } else {
    //                if let unreadIndex = interactor.unreadIndex {
    //                    let countPreviousUnread = interactor.currentItemCount - unreadIndex
    //                    let fetchPreviousIndex = countPreviousUnread < 50 ? countPreviousUnread / 3 : top
    //                    if index == fetchPreviousIndex {
    //                        interactor.prefetchData(direction: .previous)
    //                    }
    //                } else if index == top {
    //                    interactor.prefetchData(direction: .previous)
    //                }
    //            }
    //        }
    //        lastIndex = index
    //    }
    
    func locate(to position: LocatePosition) {
        switch self.position {
        case .unread, .bottom:
            if case .searchingMessage = position {
                recoverLastMessage = interactor.getMessageID(index: lastIndex)
            } else {
                recoverLastMessage = nil
            }
        default:
            recoverLastMessage = nil
        }
        
        self.position = position
        interactor.locate(to: position)
    }
    
    func leaveSearching() {
        guard let msgID = recoverLastMessage else { return }
        interactor.locate(to: .targetMessage(messageID: msgID))
    }
}

// MARK: process image data
extension MessageViewControllerVM {
    func upload(by url: URL) {
        interactor.sendImageMessage(url)
    }
    
    func createImageMessages(photos: [String]) {
        let selectedAssetsResult = PHAsset.fetchAssets(withLocalIdentifiers: photos, options: nil)
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true
        selectedAssetsResult.enumerateObjects { asset, index, _ in
            self.getAssetInfo(asset: asset, options: options) { [weak self] imageResult in
                guard let self = self else { return }
                var assetDict = PhotoDict()
                assetDict["sort"] = photos.firstIndex(of: imageResult.localID) ?? 0
                assetDict["imageFileName"] = imageResult.imageFileName
                assetDict["localIdentifier"] = imageResult.localID
                assetDict["mime"] = imageResult.mime
                assetDict["size"] = imageResult.size
                guard let imageFileName = assetDict["imageFileName"] as? String else { return }
                self.interactor.createImageMessage(imageFileName: imageFileName, index: index)
            }
        }
    }
    
    private func getAssetInfo(asset: PHAsset, options: PHImageRequestOptions, complete: @escaping (ImageResult) -> Void) {
        self.assetsQueue.async {
            asset.requestContentEditingInput(with: nil) { (input, _) in
                var fileName: String = ""
                PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { (imgData, imgUTI, _, _) in
                    guard let imgData = imgData else { return }
                    if let type = PhotoLibraryManager.manager.checkMimeType(by: imgUTI ?? "") {
                        switch type {
                        case .heic, .heif:
                            PhotoLibraryManager.manager.parserImageDataToJpg(data: imgData, queue: self.assetsQueue, localID: asset.localIdentifier, complete: complete)
                        case .png:
                            let compression = PhotoLibraryManager.manager.getCompressionQuality(data: imgData)
                            if compression != 1 {
                                PhotoLibraryManager.manager.parserImageDataToJpg(data: imgData, queue: self.assetsQueue, localID: asset.localIdentifier, complete: complete)
                            } else {
                                let rightOrientationData = UIImage.init(data: imgData)?.fixOrientation().pngData()
                                
                                if let pngData = rightOrientationData {
                                    fileName = PhotoLibraryManager.manager.saveImageDataAndGetFileName(imageData: pngData, suffix: AssetMimeType.png.fileSuffix) ?? input?.fullSizeImageURL?.absoluteString ?? ""
                                }
                                let size = rightOrientationData?.fileSizeInMB ?? 0
                                let imageResult = ImageResult(mime: type.mimeType, localID: asset.localIdentifier, imageFileName: fileName, size: "\(size)")
                                complete(imageResult)
                            }
                        case .jpeg:
                            let resultData = PhotoLibraryManager.manager.getCompressedImageData(oriData: imgData)
                            if let jpegData = resultData {
                                fileName = PhotoLibraryManager.manager.saveImageDataAndGetFileName(imageData: jpegData, suffix: AssetMimeType.jpeg.fileSuffix) ?? input?.fullSizeImageURL?.absoluteString ?? ""
                            }
                            let size = resultData?.fileSizeInMB ?? 0
                            let imageResult = ImageResult(mime: AssetMimeType.jpeg.mimeType, localID: asset.localIdentifier, imageFileName: fileName, size: "\(size)")
                            complete(imageResult)
                        }
                    } else {
                        PhotoLibraryManager.manager.parserImageDataToJpg(data: imgData, queue: self.assetsQueue, localID: asset.localIdentifier, complete: complete)
                    }
                }
            }
        }
    }
}

private extension MessageViewControllerVM {
    func observeKeyboardHeight() -> Observable<CGFloat> {
        let keyboardWillShow = NotificationCenter.default.rx.notification(UIResponder.keyboardWillShowNotification).map { notification -> CGFloat in
            (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.height ?? 0
        }
        let keyboardWillHide = NotificationCenter.default.rx.notification(UIResponder.keyboardWillHideNotification).map { _ -> CGFloat in
            0
        }
        return Observable.from([keyboardWillShow, keyboardWillHide]).merge()
    }
    
    func initBinding() {
        self.finishedPhotoLibrary.bind(to: self.toolBarViewModel.input.finishedPhotoLibrary).disposed(by: self.disposeBag)
        self.toolBarViewModel.output.openPhotoLibrary.throttle(.milliseconds(500), scheduler: MainScheduler.instance).bind(to: self.openPhotoLibrary).disposed(by: self.disposeBag)
        
        self.toolBarViewModel.output.showToast.bind(to: self.showToast).disposed(by: self.disposeBag)
        
        self.toolBarViewModel.output.sendTextMessage.subscribeSuccess { [unowned self] content in
            self.showConversatonBottom.onNext(())
            if let replyMessage = self.replyViewModel.replyMessage.value {
                self.interactor.sendReplyTextMessage(content: content, replyMessage: replyMessage)
                self.replyViewModel.replyMessage.accept(nil)
            } else {
                self.interactor.sendTextMessage(content)
            }
        }.disposed(by: self.disposeBag)
        
        self.toolBarViewModel.output.attachmentAppear.bind(to: self.attachmentShowed).disposed(by: self.disposeBag)
        
        /* // TODO: check new way to achieve
         self.messageDataSource.output.transceiversListUpdate
         .subscribeSuccess { [unowned self] in
         announcementViewModel.updateTransceivers(transceivers: messageDataSource.transceivers)
         }.disposed(by: disposeBag)
         */
        
        self.input.selectedMessage.subscribeSuccess { [unowned self] messageModel in
            guard let model = messageModel else { return }
            self.locate(to: .searchingMessage(messageID: model.id))
        }.disposed(by: self.disposeBag)
        
        self.input.clearMessage
            .subscribeSuccess { [unowned self] in
                self.interactor.clearMessage()
            }.disposed(by: disposeBag)
        
        self.actionToolVM.output.active.subscribeSuccess { [unowned self] (action, messageModel) in
            // TODO: implement action
            self.closeToolView.onNext(())
            switch action {
            case .delete:
                self.output.deleteMessageSignal.onNext(messageModel)
            case .announcement:
                pinMessage(messageID: messageModel.id)
            case .reply:
                replyViewModel.replyMessage.accept(messageModel)
            case .unsend:
                self.output.unsendMessageModel.onNext(messageModel)
            case .copy:
                UIPasteboard.general.string = messageModel.message
            }
            
        }.disposed(by: disposeBag)
        
        self.emojiToolVM.output.action.subscribeSuccess { [weak self] (action, messageModel) in
            guard let self = self else { return }
            self.closeToolView.onNext(())
            DataAccess.shared.handleEmojiDidTap(model: messageModel, emojiType: action)
        }.disposed(by: disposeBag)
        
        self.interactor.floatingViewHidden.bind(to: self.output.floatingViewHidden).disposed(by: disposeBag)
    }
    
    func getMessageViewModel(by messageID: String) -> MessageViewModel? {
        // TODO: Zoe check return message view model or delete function
        //        guard let vm = self.messageDataSource.messageItems.first(where: { $0.model?.id == messageID }) else {
        return nil
        //        }
        //        return vm
    }
    
    func getMessages() {
        /*
         dataManager.getReadMessages(by: group.id) { messages in
         // TODO: parser data to cell view model
         }
         
         dataManager.getUnreadMessages(by: group.id) { messages in
         // TODO: parser data to cell view model
         }
         */
    }
    
    func getAnnouncements() {
        dataAccess.getGroupPins(groupID: group.id)
    }
    
    func getUnOpenedHongBao() {
        dataAccess.fetchUnOpenedHongBaoInfo(groupID: group.id)
            .subscribeSuccess({ [weak self] unOpenedHongBao in
                guard let self = self else { return }
                self.output.unOpenedHongBao.accept(unOpenedHongBao)
                guard let list = unOpenedHongBao?.floatingHongBaoList.sorted(by: { $0.messageID < $1.messageID }), let first = list.first, let last = list.last else {
                    self.updateFloatingViewHidden(hidden: true)
                    return
                }
                
                self.output.lottieUrl.accept(first.floatingUrl)
                
                if self.output.floatingViewHidden.value {
                    // 確認 floatingHongBaoList 最新跟 dataSource 儲存floatingHongBao ID是否一致
                    let isEqual = self.interactor.checkLastFloatingHongBaoIdEqual(newId: last.messageID)
                    self.updateFloatingViewHidden(hidden: isEqual)
                }
                
                self.interactor.setFloatingHongBaoMsgID(with: last.messageID)
            })
            .disposed(by: disposeBag)
    }
}
