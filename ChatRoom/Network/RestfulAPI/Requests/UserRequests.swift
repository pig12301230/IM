//
//  UserRequests.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/4/14.
//

import Foundation
import Alamofire
import RxSwift
import RxCocoa

extension ApiClient {

    class func createDirectGroup(_ contactID: String) -> Observable<RUserGroups> {
        return fetch(ApiRouter.createDirectGroup(contactID: contactID))
    }
    
    class func getUserInfo() -> Observable<RAccountInfo> {
        return fetch(ApiRouter.getUserInfo, takeoverError: true)
    }
    
    class func modifyNotify(with parameter: [String: Any]) -> Observable<Empty> {
        return fetch(ApiRouter.userNotify(parameter: parameter))
    }
    
    class func modifyNickname(_ name: String) -> Observable<RUserInfo> {
        return fetch(ApiRouter.modifyNickname(name: name))
    }
    
    class func updatePassword(from oldPassword: String, to newPassword: String) -> Observable<Empty> {
        return fetch(ApiRouter.updatePassword(oldPassword: oldPassword, newPassword: newPassword))
    }

    class func getUserGroups() -> Observable<[RUserGroups]> {
        return fetch(ApiRouter.getUserGroups, takeoverError: true)
    }
    
    class func getUserGroupsPart() -> Observable<RUserGroupsPart> {
        return fetch(.getUserGroupsPart)
    }
    
    class func getUserGroupsGeneral() -> Observable<[RUserGroups]> {
        return fetch(.getUserGroupsGeneral, takeoverError: true)
    }
    
    class func getUserGroupPart(groupID: String) -> Observable<RUserGroupPart> {
        return fetch(.getUserGroupPart(groupID: groupID), takeoverError: true)
    }
    
    class func getUserUnread() -> Observable<[RUserUnread]> {
        return fetch(.getUserUnread, takeoverError: true)
    }
    
    class func deleteAccount() -> Observable<Empty> {
        return fetch(ApiRouter.deleteAccount)
    }
    
    class func resetUserPassword(password: String, oneTimeToken: String) -> Observable<Empty> {
        return fetch(ApiRouter.resetUserPassword(password: password, oneTimeToken: oneTimeToken))
    }
    
    class func getUserContacts() -> Observable<[RUserInfo]> {
        return fetch(ApiRouter.getUserContacts, takeoverError: true)
    }

    class func uploadAvatar(imageData: Data) -> Observable<RAvatarInfo> {
        return upload(ApiRouter.uploadAvatar(data: imageData), uploadRequest: nil)
    }

    class func block(userID: String) -> Observable<Empty> {
        return fetch(ApiRouter.userBlock(userID: userID))
    }

    class func removeBlock(userID: String) -> Observable<Empty> {
        return fetch(ApiRouter.removeUserBlock(userID: userID))
    }
    
    class func report(userID: String, reason: Int) -> Observable<Empty> {
        return fetch(ApiRouter.userReport(userID: userID, reason: reason))
    }
    
    class func getBlockedList() -> Observable<[RUserInfo]> {
        return fetch(ApiRouter.blockedList, takeoverError: true)
    }
    
    class func registerNotificationDeviceToken(token: String) -> Observable<Empty> {
        return fetch(ApiRouter.registerDeviceToken(token: token))
    }
    
    // User Memo/Nickname
    class func getUserMemo(userID: String) -> Observable<RUserMemo> {
        return fetch(.getUserMemo(userID: userID))
    }
    
    class func updateUserMemo(userID: String, memo: String) -> Observable<Empty> {
        return fetch(.updateUserMemo(userID: userID, memo: memo))
    }
    
    class func getUserNicknames() -> Observable<[RUserNickname]> {
        return fetch(.getUserNicknames)
    }
    
    class func updateUserNickname(userID: String, nickname: String, takeoverError: Bool = false) -> Observable<Empty> {
        return fetch(.updateUserNickname(userID: userID, nickname: nickname), takeoverError: takeoverError)
    }
    
    class func deleteUserNickname(userID: String) -> Observable<Empty> {
        return fetch(.deleteUserNickname(userID: userID))
    }
    
    class func getShareLink() -> Observable<RUserShareLink> {
        return fetch(ApiRouter.getShareLink)
    }
    
    class func setSecurityCode(from oldSecurityCode: String, to newSecurityCode: String) -> Observable<Empty> {
        return fetch(.setSecurityCode(oldSecurityCode: oldSecurityCode, newSecurityCode: newSecurityCode))
    }
}
