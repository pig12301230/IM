//
//  ConversationToolBarVM.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/6/2.
//

import RxSwift
import RxCocoa

enum SuspendType {
    case userBlocked, messageNotAllowed
    
    var text: String {
        switch self {
        case .userBlocked:
            return Localizable.userHasBeenBlocked
        case .messageNotAllowed:
            return Localizable.sendMessagesNotAllowedInGroup
        }
    }
}

class ConversationToolBarVM: BaseViewModel {
    enum ToolBarStatus {
        case typing, endTyping, suspend, attachment, sticker
    }
    
    var disposeBag = DisposeBag()
    
    struct Input {
        // TODO: 代入真的 suspend 狀態
        let suspended: BehaviorRelay<SuspendType?> = BehaviorRelay(value: nil)
        let sticker = PublishSubject<Void>()
        let attachment = PublishSubject<Void>()
        let send = PublishSubject<Void>()
        let finishedPhotoLibrary = PublishSubject<Void>()
    }
    
    struct Output {
        let status: BehaviorRelay<ToolBarStatus> = BehaviorRelay(value: .endTyping)
        let openPhotoLibrary = PublishSubject<PhotoLibraryType>()
        let sendTextMessage = PublishSubject<String>()
        let attachmentAppear = PublishRelay<Void>()
        let showToast = PublishSubject<String>()
        let isInputOverOneCharactor: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    }
    
    let inputTextViewModel: ConversationInputTextViewVM
    let attachmentViewModel: AttachmentViewVM = AttachmentViewVM.init()
    let input: Input = Input.init()
    let output: Output = Output.init()
    private(set) var group: GroupModel
    private(set) var permission: RolePermissionModel = RolePermissionModel()
    
    // TODO: use permission Object
    init(with group: GroupModel) {
        // TOTO: input suspend type
        self.inputTextViewModel = ConversationInputTextViewVM.init(with: nil, originalContent: group.draft)
        self.group = group
        super.init()
        self.initBinding()
    }
    
    func setupGroup(with group: GroupModel) {
        self.group = group
    }
    
    func updatePermission(to role: UserRoleModel) {
        self.permission = role.permission
        // 封鎖原本就不能傳送文字, 所以只需在沒有文字許可且非 blocked 狀態才須更新 suspend type
        if self.input.suspended.value != .userBlocked {
            self.input.suspended.accept( self.permission.sendMessages ? nil : .messageNotAllowed)
        }
    }
    
    func didTapBackgroundView() {
        // suspend 狀態時, 不讓使用這可以輸入文字, 傳送圖檔, 傳送貼圖
        guard self.input.suspended.value == nil else {
            return
        }
        
        if self.output.status.value != .endTyping {
            self.inputTextViewModel.updateStatusToEnd()
            self.output.status.accept(.endTyping)
        }
    }
}

private extension ConversationToolBarVM {
    func initBinding() {
        self.input.suspended.bind(to: self.inputTextViewModel.input.suspended).disposed(by: self.disposeBag)
        // TODO: 等有此功能時, 才開放影響 status
        // self.input.sticker.map { ToolBarStatus.sticker }.bind(to: self.output.status).disposed(by: self.disposeBag)
        self.input.attachment.map { ToolBarStatus.attachment }.bind(to: self.output.status).disposed(by: self.disposeBag)
        
        self.inputTextViewModel.output.status.distinctUntilChanged().subscribeSuccess { [unowned self] inputStatus in
            self.setupStatus(by: inputStatus)
        }.disposed(by: self.disposeBag)
        
        self.inputTextViewModel.output.isInputOverOneCharactor.bind(to: self.output.isInputOverOneCharactor).disposed(by: self.disposeBag)
        
        self.attachmentViewModel.output.photo.subscribeSuccess { [unowned self] _ in
            guard self.permission.sendImages else {
                self.attachmentNotAllowed()
                return
            }
            
            self.output.openPhotoLibrary.onNext(PhotoLibraryType.photo)
        }.disposed(by: self.disposeBag)
        
        self.attachmentViewModel.output.camera.subscribeSuccess { [unowned self] _ in
            guard self.permission.sendImages else {
                self.attachmentNotAllowed()
                return
            }
            
            self.output.openPhotoLibrary.onNext(PhotoLibraryType.camera)
        }.disposed(by: self.disposeBag)
        
        self.input.finishedPhotoLibrary.bind(to: self.attachmentViewModel.input.finish).disposed(by: self.disposeBag)
        
        self.inputTextViewModel.output.content.skip(1).distinctUntilChanged().subscribeSuccess { [unowned self] content in
            guard let content = content else {
                return
            }
            
            DataAccess.shared.saveDraft(content, at: self.group.id)
        }.disposed(by: self.disposeBag)
        
        self.input.send.subscribeSuccess { [unowned self] _ in
            guard let content = self.inputTextViewModel.output.content.value, content.count > 0 else {
                return
            }
            
            guard !content.isBlank else {
                return
            }
            
            if let ranges = content.checkContainLink(), !ranges.isEmpty {
                guard self.permission.sendHyperlinks else {
                    self.output.showToast.onNext(Localizable.sendHyperlinkNotAllowedInGroup)
                    return
                }
            }
            
            self.inputTextViewModel.clearMessage()
            self.output.sendTextMessage.onNext(content)
        }.disposed(by: self.disposeBag)
    }
    
    func setupStatus(by inputStatus: ConversationInputTextViewVM.InputStatus) {
        switch inputStatus {
        case .start:
            self.output.status.accept(.typing)
        case .end:
            self.output.status.accept(.endTyping)
        case .suspend:
            self.output.status.accept(.suspend)
        }
    }
    
    private func attachmentNotAllowed() {
        self.output.showToast.onNext(Localizable.sendImagesNotAllowedInGroup)
        self.attachmentViewModel.input.finish.onNext(())
    }
}
