//
//  DataAccess+user.swift
//  ChatRoom
//
//  Created by Winston_Chuang on 2023/3/23.
//

import Foundation
import RxSwift
import Kingfisher

extension DataAccess {
    
    func registerDeviceToken(token: String) {
        ApiClient.registerNotificationDeviceToken(token: token).subscribe(onCompleted: {
            PRINT("register device token status success")
        }).disposed(by: self.disposeBag)
    }
    // MARK: - account access (login, register, auto login)
    /**
     delete account
     */
    func deleteAccount(complete: RealmDAO.CompletionHandler) {
        logout()
        UserData.shared.clearData()
        clearDatabaseAndCache(complete: complete)
    }
    
    /**
     auto login success, then connect web socket
     */
    func finishNeededLoginAccess() {
        if !socket.isConnected {
            socket.connect()
        }
        socket.delegate = self
    }
    
    /**
     check current access
     */
    func getUserAccess(_ completeHandler: @escaping (UserAccessStatus) -> Void) {
        ApiClient.checkAccess { (status) in
            completeHandler(status)
        }
    }
    
    func fetchUserMe() -> Observable<Void> {
        return Observable<Void>.create { observer -> Disposable in
            ApiClient.getUserInfo().subscribe { [weak self] userInfo in
                guard let self = self else {
                    observer.onNext(())
                    observer.onCompleted()
                    return
                }
                UserData.shared.setData(key: .userID, data: userInfo.id)
                PRINT("user ID = \(userInfo.id)", cate: .database)
                UserData.shared.setUserInfo(userInfo: userInfo)
                self.userInfo.nickname.accept(userInfo.nickname)
                self.userInfo.id.accept(userInfo.id)
                self.userInfo.socialAccount.accept(userInfo.socialAccount)
                
                self.downloadUserAvatar(userInfo.avatar, complete: nil)
                self.downloadUserAvatarThumbnail(userInfo.avatarThumbnail, complete: nil)
                observer.onNext(())
                observer.onCompleted()
            } onError: { error in
                observer.onError(error)
            }.disposed(by: self.disposeBag)
            return Disposables.create()
        }
    }
    /**
     save account.access information
     */
    func saveUserInformation(_ info: RLoginRegister) {
        let currentTimeInterval = Date().timeIntervalSince1970
        let expiresDate = Int(currentTimeInterval) + info.expiresIn
        
        UserData.shared.setData(key: .expiresIn, data: expiresDate)
        UserData.shared.setData(key: .refreshToken, data: info.refreshToken)
        UserData.shared.setData(key: .token, data: info.accessToken)
        
        finishNeededLoginAccess()
    }
    
    /**
     確認登入的帳號是否與前次相同, 如果不同會清除 DB
     - Parameters:
        - country: 國碼 e.g. CN
        - phone: 電話號碼 (不包含+86)
     */
    func checkUserAccountAndDatabase(country: String, phone: String, complete: () -> Void) {
        guard let preCountry = UserData.shared.getData(key: .countryCode) as? String,
              let prePhone = UserData.shared.getData(key: .userPhone) as? String else {
            UserData.shared.setData(key: .userPhone, data: phone)
            clearDatabaseAndCache(complete: complete)
            return
        }
        
        guard country != preCountry || phone != prePhone else {
            complete()
            return
        }
                
        UserData.shared.setData(key: .userPhone, data: phone)
        clearDatabaseAndCache(complete: complete)
    }
    
    /**
     clear all cache and database
     */
    private func clearDatabaseAndCache(complete: RealmDAO.CompletionHandler) {
        KingfisherManager.shared.cache.clearMemoryCache()
        KingfisherManager.shared.cache.clearDiskCache()
        KingfisherManager.shared.cache.cleanExpiredDiskCache()
        realmDAO.clearAllDatabase(complete: complete)
    }
}

// MARK: User Avatar
extension DataAccess {
    func uploadAvatar(_ image: UIImage, returnThumbnail: Bool = false, complete: @escaping (UIImage?) -> Void) {
        guard let imageData = ImageProcessor.shared.getCompressionImageData(with: image) else {
            return complete(nil)
        }
        
        ApiClient.uploadAvatar(imageData: imageData).subscribe { [weak self] avatarInfo in
            guard let self = self else {
                complete(nil)
                return
            }
            UserData.shared.updateAvatarInfo(info: avatarInfo)
            self.downloadUserAvatar(avatarInfo.avatar) { image in
                if !returnThumbnail {
                    complete(image)
                }
            }
            self.downloadUserAvatarThumbnail(avatarInfo.avatar_thumbnail) { image in
                if returnThumbnail {
                    complete(image)
                }
            }
        } onError: { _ in
            complete(nil)
        }.disposed(by: self.disposeBag)
    }
    
    private func downloadAvatar(_ urlString: String, complete: ((UIImage?) -> Void)?) {
        ImageProcessor.shared.downloadImage(urlString: urlString) { result in
            switch result {
            case .success(let value):
                complete?(value.image)
            case .failure(_):
                complete?(nil)
            }
        }
    }
    
    func downloadUserAvatar(_ urlString: String, complete: ((UIImage?) -> Void)?) {
        self.downloadAvatar(urlString) { [weak self] image in
            guard let self = self else {
                complete?(nil)
                return
            }
            if image != nil {
                self.userInfo.avatar.accept(image)
            }
            complete?(image)
        }
    }
    
    func downloadUserAvatarThumbnail(_ urlString: String, complete: ((UIImage?) -> Void)?) {
        self.downloadAvatar(urlString) { [weak self] image in
            guard let self = self else {
                complete?(nil)
                return
            }
            if image != nil {
                self.userInfo.avatarThumbnail.accept(image)
            }
            complete?(image)
        }
    }
}

// MARK: User PersonalSetting
extension DataAccess {
    
    /**
     初始化備註的資訊
     */
    func initUserSettingInfo() {
        realmDAO.getModels(type: UserPersonalSettingModel.self) { settingModels in
            guard let settingModels = settingModels else { return }
            let settingDict = settingModels.toDictionary(with: { $0.id })
            self.userPersonalSetting.accept(settingDict)
        }
    }
    
    func getUserPersonalSetting(with userID: String) -> UserPersonalSettingModel? {
        userPersonalSetting.value[userID]
    }

    func getUserPersonalSettingDict() -> [String: UserPersonalSettingModel] {
        userPersonalSetting.value
    }
    
    func setupUserPersonalSetting(with setting: UserPersonalSettingModel) {
        var settings = getUserPersonalSettingDict()
        settings[setting.id] = setting
        userPersonalSetting.accept(settings)
    }
}

// MARK: Wallet
extension DataAccess {
    func getWalletBalance(complete: @escaping (Bool, String?) -> Void) {
        ApiClient.getHongBaoBalance().subscribe { balance in
            complete(balance.signValid, balance.balance)
        } onError: { _ in
            complete(false, nil)
        }.disposed(by: self.disposeBag)
    }
    
    func getWalletBalanceRecord(complete: @escaping ([HongBaoRecord]) -> Void) {
        ApiClient.getHongBaoRecord().subscribe { record in
            complete(record.list)
        } onError: { _ in
            complete([])
        }.disposed(by: self.disposeBag)
    }
    
    /**
     第一次設定/重設安全密碼
     - Parameters:
        - oldSecurityCode: 第一次設密碼 old_code 欄位非必填, 不帶也行
     */
    func setSecurityCode(from oldSecurityCode: String = "", to newSecurityCode: String) -> Observable<Void> {
        return Observable.create { observer -> Disposable in
            ApiClient.setSecurityCode(from: oldSecurityCode, to: newSecurityCode)
                .subscribe(onError: { error in
                    observer.onError(error)
                }, onCompleted: {
                    observer.onNext(())
                    observer.onCompleted()
                }).disposed(by: self.disposeBag)
            return Disposables.create()
        }
    }
}

// MARK: - User memo and nickname
extension DataAccess {
    func getUserNicknames() {
        ApiClient.getUserNicknames().subscribeSuccess { [weak self] users in
            guard let self = self else { return }
            // 刪除不必要的欄位
            let userSettingDict = users.toDictionary { $0.id }
            self.realmDAO.getModels(type: UserPersonalSettingModel.self) { userSettings in
                var newResult: [UserPersonalSettingModel.DBObject] = []
                var originalIds = [String]()
                if let userSettings = userSettings {
                    // 更新原有的 Setting model
                    newResult += userSettings.map {
                        var model = $0
                        model.nickname = userSettingDict[model.id]?.nickname
                        originalIds.append($0.id)
                        return model.convertToDBObject()
                    }
                }
                // 產生新的 Setting model
                let newSettings = userSettingDict.filter { !originalIds.contains($0.0) }.compactMap { UserPersonalSettingModel(memberID: $0.1.id, nickname: $0.1.nickname).convertToDBObject() }
                newResult += newSettings

                // 更新至 database
                self.realmDAO.update(newResult) {
                    // init user setting info signal
                    self.initUserSettingInfo()
                }
            }

            // 更新 nickname 設定至聯絡人清單
            self.realmDAO.getModels(type: ContactModel.self) { contactModel in
                guard let contactModel = contactModel, !contactModel.isEmpty else { return }
                let contactResult: [ContactModel.DBObject] = contactModel.map {
                    var model = $0
                    model.display = userSettingDict[$0.id]?.nickname ?? model.nickname
                    return model.convertToDBObject()
                }

                self.realmDAO.update(contactResult) {
                    self.contactListUpdate.onNext(())
                }
            }
        }.disposed(by: disposeBag)
    }
    
    func updateUserNickname(userID: String, nickname: String, takeoverError: Bool = false) -> Observable<Bool> {
        return Observable.create { [unowned self] observer -> Disposable in
            ApiClient.updateUserNickname(userID: userID, nickname: nickname, takeoverError: takeoverError)
                .subscribe(onError: { error in
                    observer.onError(error)
                }, onCompleted: { [weak self] in
                    self?.updateDatabaseNickName(userID: userID, nickname: nickname)
                    observer.onNext(true)
                    observer.onCompleted()
                })
               .disposed(by: disposeBag)
            return Disposables.create()
        }
    }
    
    func deleteUserNickname(userID: String) -> Observable<Bool> {
        return Observable.create { [unowned self] observer -> Disposable in
            ApiClient.deleteUserNickname(userID: userID)
                .subscribe(onError: { error in
                    observer.onError(error)
                }, onCompleted: { [weak self] in
                    self?.updateDatabaseNickName(userID: userID, nickname: nil)
                    observer.onNext(true)
                    observer.onCompleted()
                })
               .disposed(by: disposeBag)
            return Disposables.create()
        }
    }
    
    func modifyNickname(to name: String, complete: @escaping (Bool) -> Void) {
        ApiClient.modifyNickname(name).subscribe { [weak self] info in
            guard let self = self else {
                complete(false)
                return
            }
            UserData.shared.updateNickname(info.nickname)
            self.userInfo.nickname.accept(info.nickname)
            complete(true)
        } onError: { _ in
            complete(false)
        }.disposed(by: self.disposeBag)
    }
    
    func getUserMemo(userID: String) {
        ApiClient.getUserMemo(userID: userID).subscribeSuccess { [weak self] memo in
            guard let self = self else { return }
            self.updateDatabaseMemo(userID: userID, memo: memo.memo)
        }.disposed(by: disposeBag)
    }
    
    func updateUserMemo(userID: String, memo: String) -> Observable<Bool> {
        return Observable.create { [unowned self] observer -> Disposable in
            ApiClient.updateUserMemo(userID: userID, memo: memo)
                .subscribe(onError: { error in
                    observer.onError(error)
                }, onCompleted: { [weak self] in
                    self?.updateDatabaseMemo(userID: userID, memo: memo)
                    observer.onNext(true)
                    observer.onCompleted()
                })
               .disposed(by: disposeBag)
            return Disposables.create()
        }
    }
    
    private func updateDatabaseMemo(userID: String, memo: String) {
        var model: UserPersonalSettingModel
        if let personalSetting = self.getUserPersonalSetting(with: userID) {
            model = personalSetting
            model.memo = memo
        } else {
            model = UserPersonalSettingModel(memberID: userID, memo: memo)
        }
        self.setupUserPersonalSetting(with: model)
        
        self.realmDAO.update([model.convertToDBObject()]) {
            self.memoUpdateObserver.onNext(userID)
        }
    }
    
    private func updateDatabaseNickName(userID: String, nickname: String?) {
        var model: UserPersonalSettingModel

        if let personalSetting = self.getUserPersonalSetting(with: userID) {
            model = personalSetting
            model.nickname = nickname
        } else {
            model = UserPersonalSettingModel(memberID: userID, nickname: nickname)
        }
        
        self.setupUserPersonalSetting(with: model)

        self.realmDAO.update([model.convertToDBObject()]) {
            self.nicknameUpdateObserver.onNext(userID)
            self.updateContactNickname(memberID: userID, nickname: nickname)
            self.updateTransceiversNickname(memberID: userID, nickname: nickname)
        }
    }
    
    private func updateContactNickname(memberID: String, nickname: String?) {
        self.realmDAO.getModel(type: ContactModel.self, id: memberID) { contact in
            guard var contact = contact else { return }
            contact.display = nickname ?? contact.nickname
            self.realmDAO.update([contact.convertToDBObject()]) {
                self.contactListUpdate.onNext(())
            }
        }
    }
    
    private func updateTransceiversNickname(memberID: String, nickname: String?) {
        self.realmDAO.getModels(type: TransceiverModel.self, predicateFormat: "userID = '\(memberID)'") { transceivers in
            guard let transceivers = transceivers else {
                return
            }
            let newTrans = transceivers.map { transceiver -> RLMTransceiver in
                var newTran = transceiver
                newTran.display = nickname ?? newTran.nickname
                return newTran.convertToDBObject()
            }
            
            self.realmDAO.update(newTrans)
        }
    }
}
