//
//  UserData.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/4/12.
//

import Foundation

class UserData {
    
    enum UDKey: String, CaseIterable {
        case token = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case userPhone = "user_phone"
        case remember = "user_remember"
        case countryCode = "user_country_code"
        case userID = "user_id"
        case userBalance = "user_balance"
    }

    static let shared = UserData()

    private(set) var token: String?
    private(set) var userPhone: String?
    private(set) var rememberAccount: Bool?
    private(set) var countryCode: String?
    private(set) var refreshToken: String?
    private(set) var userID: String?
    private(set) var expiresIn: Int?
    private(set) var userBalance: String?
    
    private(set) var userInfo: RAccountInfo?
    
    private init() {
        // init 時, 撈出 user default
        self.setupCacheParameter()
    }
    
    func setData(key: UDKey, data: Any) {
        self.setupValue(value: data, key: key)
        UserDefaults.standard.setValue(data, forKey: key.rawValue)
    }
    
    func setUserInfo(userInfo: RAccountInfo) {
        self.userInfo = userInfo
    }
    
    func updateAvatarInfo(info: RAvatarInfo) {
        self.userInfo?.avatar = info.avatar
        self.userInfo?.avatarThumbnail = info.avatar_thumbnail
    }
    
    func updateNotifyStatus(_ option: NotifyOption, to type: NotifyType) {
        switch option {
        case .newMessage:
            self.userInfo?.notify = type
        case .detail:
            self.userInfo?.notifyDetail = type
        case .vibration:
            self.userInfo?.vibration = type
        case .sound:
            self.userInfo?.sound = type
        }
    }
    
    func updateNickname(_ nickname: String) {
        self.userInfo?.nickname = nickname
    }
    
    func setHasSetSecurityCode(_ hasSet: Bool) {
        self.userInfo?.hadSecurityCode = hasSet
    }
    
    // MARK: - user data read write
    func getData(key: UDKey) -> Any? {
        var data: Any?
        switch key {
        case .userID:
            data = self.userID
        case .token:
            data = self.token
        case .userPhone:
            data = self.userPhone
        case .remember:
            data = self.rememberAccount
        case .countryCode:
            data = self.countryCode
        case .refreshToken:
            data = self.refreshToken
        case .expiresIn:
            data = self.expiresIn
        case .userBalance:
            data = self.userBalance
        }
        
        if let data = data {
            return data
        }
        
        if key == .remember {
            let value = UserDefaults.standard.bool(forKey: key.rawValue)
            self.setupValue(value: value, key: key)
            return value
        } else if let nData = UserDefaults.standard.string(forKey: key.rawValue) {
            self.setupValue(value: nData, key: key)
            if key == .expiresIn {
                return self.expiresIn ?? 0
            }
            return nData
        }
        
        return nil
    }
    
    func clearData(key: UDKey) {
        UserDefaults.standard.removeObject(forKey: key.rawValue)
        switch key {
        case .userID:
            self.userID = nil
        case .token:
            self.token = nil
        case .userPhone:
            self.userPhone = nil
        case .countryCode:
            self.countryCode = nil
        case .refreshToken:
            self.refreshToken = nil
        case .expiresIn:
            self.expiresIn = nil
        case .remember:
            self.rememberAccount = nil
        case .userBalance:
            self.userBalance = nil
        }
        userInfo = nil
    }
    
    func clearData() {
        UDKey.allCases.forEach {
            UserDefaults.standard.removeObject(forKey: $0.rawValue)
            self.setupValue(value: nil, key: $0)
        }
        UserDefaults.standard.synchronize()
    }
    
    private func setupValue(value: Any?, key: UDKey) {
        if value == nil {
            switch key {
            case .userID:
                self.userID = nil
            case .token:
                self.token = nil
            case .userPhone:
                self.userPhone = nil
            case .countryCode:
                self.countryCode = nil
            case .refreshToken:
                self.refreshToken = nil
            case .expiresIn:
                self.expiresIn = 0
            case .remember:
                self.rememberAccount = false
            case .userBalance:
                self.userBalance = nil
            }
            return
        }
        
        if key == .remember, let value = value as? Bool {
            self.rememberAccount = value
        } else if let value = value as? String {
            switch key {
            case .userID:
                self.userID = value
            case .token:
                self.token = value
            case .userPhone:
                self.userPhone = value
            case .countryCode:
                self.countryCode = value
            case .refreshToken:
                self.refreshToken = value
            case .expiresIn:
                self.expiresIn = Int(value)
            case .remember:
                break
            case .userBalance:
                self.userBalance = value
            }
        }
    }
    
    private func setupCacheParameter() {
        UDKey.allCases.forEach { udKey in
            let key: String = udKey.rawValue
            if let val = UserDefaults.standard.value(forKey: key) {
                self.setupValue(value: val, key: udKey)
            }
        }
    }
    
}
