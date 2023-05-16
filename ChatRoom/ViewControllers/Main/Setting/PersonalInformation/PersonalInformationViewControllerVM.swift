//
//  PersonalInformationViewControllerVM.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/6/30.
//

import RxSwift
import RxCocoa

class PersonalInformationViewControllerVM: BaseViewModel, SettingViewModelProtocol {
    enum PersonalOption: CaseIterable {
        case nickname
        case personalID
        case socialAccount
        
        var title: String {
            switch self {
            case .nickname:
                return Localizable.nickname
            case .personalID:
                return Localizable.userID
            case .socialAccount:
                return Localizable.accountRemark
            }
        }
        
        var hiddenArrowRight: Bool {
            switch self {
            case .personalID, .socialAccount:
                return true
            default:
                return false
            }
        }
        
    }
    
    let userID: String
    let cellTypes: [SettingCellType] = [.titleArrow]
    
    var disposeBag = DisposeBag()
    
    let didTapAvatar = PublishSubject<Void>()
    let showImageViewer = PublishSubject<FunctionalViewerViewControllerVM>()
    let showAlert = PublishSubject<String>()
    let openCamera = PublishSubject<Void>()
    let avatarImage: BehaviorRelay<UIImage?> = BehaviorRelay(value: UIImage.init(named: "avatarsPhoto"))
    let refresh = PublishSubject<Void>()
    let nickname: BehaviorRelay<String?> = BehaviorRelay(value: nil)
    let socialAccount: BehaviorRelay<String?> = BehaviorRelay(value: nil)
    let showLoading = PublishRelay<Bool>()
    
    // socialAccount 預設不顯示
    private var options: [PersonalOption] = PersonalOption.allCases.filter { $0 != .socialAccount }
    
    override init() {
        userID = UserData.shared.userInfo?.username ?? ""
        
        super.init()
        binding()
        fetchRegisterInfo()
    }
    
    func numberOfRows() -> Int {
        return options.count
    }
    
    func cellIdentifier(at index: Int) -> String {
        return SettingCellType.titleArrow.cellIdentifier
    }
    
    func cellConfig(at index: Int) -> SettingCellConfig {
        let option = options[index]
        switch option {
        case .nickname:
            let val = self.nickname.value ?? ""
            return SettingCellConfig(leading: 16, title: option.title, subTitle: val, hiddenArrowRight: option.hiddenArrowRight)
        case .personalID:
            return SettingCellConfig(leading: 16, title: option.title, subTitle: userID, hiddenArrowRight: option.hiddenArrowRight)
        case .socialAccount:
            let val = self.socialAccount.value ?? ""
            return SettingCellConfig(leading: 16, title: option.title, subTitle: val, hiddenArrowRight: option.hiddenArrowRight)
        }
    }
    
    func getScene(at index: Int) -> Navigator.Scene? {
        // TODO: create scene
        let option = options[index]
        if option == .nickname {
            let val = self.nickname.value ?? ""
            let vm = ModifyViewControllerVM.init(type: .nickname, default: val)
            return Navigator.Scene.modify(vm: vm)
        }
        return nil
    }
    
    func uploadAvatar(_ avatarImage: UIImage) {
        self.showLoading.accept(true)
        DataAccess.shared.uploadAvatar(avatarImage) { [weak self] newImage in
            guard let self = self else { return }
            self.showLoading.accept(false)
            let message = newImage == nil ? ViewerActionType.viewAndUploadAvatar.failedMessage : ViewerActionType.viewAndUploadAvatar.successMessage
            self.showAlert.onNext(message)
            
            guard let image = newImage else { return }
            self.avatarImage.accept(image)
        }
    }
}

private extension PersonalInformationViewControllerVM {
    func binding() {
        self.didTapAvatar.subscribeSuccess { [unowned self] _ in
            guard let thumbnail = UserData.shared.userInfo?.avatarThumbnail, !thumbnail.isEmpty else {
                self.openCamera.onNext(())
                return
            }
            
            let config = ImageViewerConfig(title: Localizable.personalPhoto, date: nil, imageURL: thumbnail, actionType: .viewAndUploadAvatar, fileID: nil, messageId: nil)
            let vm = FunctionalViewerViewControllerVM.init(config: config)
            self.showImageViewer.onNext((vm))
        }.disposed(by: self.disposeBag)
        
        DataAccess.shared.userInfo.avatarThumbnail.bind(to: self.avatarImage).disposed(by: self.disposeBag)
        DataAccess.shared.userInfo.socialAccount.bind(to: self.socialAccount).disposed(by: self.disposeBag)
        DataAccess.shared.userInfo.nickname.bind(to: self.nickname).disposed(by: self.disposeBag)
        DataAccess.shared.userInfo.nickname.distinctUntilChanged().subscribeSuccess { _ in
            self.refresh.onNext(())
        }.disposed(by: self.disposeBag)
    }
    
    func fetchRegisterInfo() {
        showLoading.accept(true)
        ApiClient.getRegisterInfo().subscribe { [unowned self] result in
            showLoading.accept(false)
            /* result state 1: 隐藏 2: 显示且选填 3: 显示且必填 */
            switch result {
            case 2, 3:
                addSocialAccount()
            default:
                break
            }
        } onError: { [unowned self] _ in
            showLoading.accept(false)
        }.disposed(by: disposeBag)
    }
    
    private func addSocialAccount() {
        options.append(PersonalOption.socialAccount)
        self.refresh.onNext(())
    }
}
