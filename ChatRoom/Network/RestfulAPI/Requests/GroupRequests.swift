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
    
    struct CreateGroupRequset {
        let img: Data?
        let displayName: String
        let users: String
    }
    
    class func createGroup(name: String) -> Observable<RGroupInfo> {
        return fetch(ApiRouter.createGroup(name: name))
    }
    
    class func createGroup(request: CreateGroupRequset) -> Observable<RGroupInfo> {
        return upload(.createGroupWithImage(request: request), uploadRequest: nil)
    }
    
    class func getGroupBy(groupID: String) -> Observable<RUserGroups> {
        return fetch(ApiRouter.getGroupBy(groupID: groupID), takeoverError: true)
    }

    class func getGroupMembersBy(groupID: String) -> Observable<[RUserInfo]> {
        return fetch(ApiRouter.getGroupMembersBy(groupID: groupID), takeoverError: true)
    }

    class func getGroupMember(groupID: String, memberID: String, takeoverError: Bool = true) -> Observable<RUserInfo> {
        return fetch(ApiRouter.getGroupMember(groupID: groupID, memberID: memberID), takeoverError: takeoverError)
    }
    
    class func clearGroupMessage(groupID: String) -> Observable<Empty> {
        return fetch(ApiRouter.clearGroupMessage(groupID: groupID))
    }
    
    class func getGroupLastMessage(groupID: String) -> Observable<RGroupLastMessage?> {
        return fetch(.getGroupLastMessage(groupID: groupID), takeoverError: true)
    }
    
    class func addGroupBlockMember(groupID: String, memberID: [String]) -> Observable<Empty> {
        return fetch(.addGroupBlockMember(groupID: groupID, memberID: memberID))
    }
    
    class func removeGroupBlockedMember(groupID: String, memberID: String) -> Observable<Empty> {
        return fetch(.removeGroupBlockedMember(groupID: groupID, memberID: memberID))
    }
    
    // Success: response noth., status = #204
    class func addGroupMember(groupID: String, memberID: [String]) -> Observable<Empty> {
        return fetch(ApiRouter.addGroupMember(groupID: groupID, memberID: memberID))
    }

    // Success: response noth., status = #204
    class func deleteGroupMember(groupID: String, memberID: String) -> Observable<Empty> {
        return fetch(ApiRouter.deleteGroupMember(groupID: groupID, memberID: memberID), takeoverError: true)
    }
    
    // response 只拿取 notify 使用
    class func updateGroupNotify(groupID: String, notify: NotifyType) -> Observable<RUserGroups> {
        return fetch(ApiRouter.updateGroupNotify(groupID: groupID, notifyType: notify))
    }
    
    // response 只拿取 display name 使用
    class func updateGroup(groupID: String, displayName: String) -> Observable<RUserGroups> {
        return fetch(ApiRouter.updateGroupDisplayName(groupID: groupID, displayName: displayName))
    }

    class func readMessage(groupID: String, messageID: String) -> Observable<Empty> {
        return fetch(ApiRouter.readMessage(groupID: groupID, messageID: messageID), takeoverError: true)
    }
    
    class func groupReport(groupID: String, reason: Int) -> Observable<Empty> {
        return fetch(ApiRouter.groupReport(groupID: groupID, reason: reason))
    }
    
    class func getGroupAdminPermission(groupID: String, userID: String) -> Observable<RUserAuth> {
        return fetch(ApiRouter.getGroupAdminRole(groupID: groupID, memberID: userID), takeoverError: true)
    }
    
    class func getGroupAdmins(groupID: String) -> Observable<[RUserInfo]> {
        return fetch(ApiRouter.getGroupAdmins(groupID: groupID), takeoverError: true)
    }
    
    class func addGroupAdmin(groupID: String, parameter: Parameters) -> Observable<Empty> {
        return fetch(ApiRouter.addGroupAdmin(groupID: groupID, parameter: parameter))
    }
    
    class func getGroupBlocks(groupID: String) -> Observable<[RUserInfo]> {
        return fetch(ApiRouter.getGroupBlocks(groupID: groupID), takeoverError: true)
    }
    
    class func setGroupMemberPermission(groupID: String, paramater: [String: Any]) -> Observable<RPermission> {
        return fetch(ApiRouter.setGroupMemberPermissions(groupID: groupID, parameter: paramater))
    }
    
    class func uploadGroupIcon(groupID: String, imageData: Data) -> Observable<RGropIcon> {
        return upload(ApiRouter.uploadGroupIcon(groupID: groupID, data: imageData), uploadRequest: nil)
    }
    
    class func deleteGroupAdmins(groupID: String, userID: String) -> Observable<Empty> {
        return fetch(ApiRouter.deleteGroupAmdin(groupID: groupID, memberID: userID))
    }
    
    class func updateGroupAmdin(groupID: String, userID: String, parameter: [String: Any]) -> Observable<RPermission> {
        return fetch(ApiRouter.updateGroupAmdin(groupID: groupID, memberID: userID, parameter: parameter))
    }
    
    class func getGroupPins(groupID: String) -> Observable<[RMessage]> {
        return fetch(.getPins(groupID: groupID))
    }
    
    class func pinMessage(groupID: String, messageID: String) -> Observable<Empty> {
        return fetch(.pinMessage(groupID: groupID, messageID: messageID))
    }
    
    class func unpinAllMessages(groupID: String) -> Observable<Empty> {
        return fetch(.unpinMessages(groupID: groupID))
    }
    
    class func unpinMessage(groupID: String, messageID: String) -> Observable<Empty> {
        return fetch(.unpinMessage(groupID: groupID, messageID: messageID))
    }
    
    class func getGroupMembers(groupID: String, memberIDs: [String]) -> Observable<[RUserInfo]> {
        return fetch(ApiRouter.getGroupMemberIDs(groupID: groupID, ids: memberIDs))
    }
}
