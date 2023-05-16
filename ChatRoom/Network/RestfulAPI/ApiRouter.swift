//
//  ApiRouter.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/4/9.
//

import Foundation
import Alamofire

// swiftlint:disable file_length
// swiftlint:disable type_body_length

enum ApiRouter: URLRequestConvertible {
    case country

    case phoneVerify(request: ApiClient.VerifyRequset)
    case getVerifyCode(request: ApiClient.VerifyRequset)
    case examVerifyCode(request: ApiClient.VerifyRequset)

    case login(refreshToken: String)
    case scanLoginQRCode(deviceID: String, data: String)
    case validateLoginQRCode(deviceID: String, data: String, passcode: String)
    case logout
    case parmaterLogin(country: String, phone: String, password: String)
    case recovery(country: String, phone: String, code: String)
    case registerDeviceToken(token: String)

    case checkAccount(phone: String, account: String)
    case getRegisterInfo
    case reigster(request: ApiClient.RegisterRequset)
    
    case getUserInfo
    case getUserGroups
    case getUserGroupPart(groupID: String)
    case getUserGroupsPart
    case getUserGroupsGeneral
    case getUserUnread
    case getUserPlatforms
    case getUserNicknames
    case getUserMemo(userID: String)
    
    // Personal Setting
    case deleteAccount
    case resetUserPassword(password: String, oneTimeToken: String)
    case uploadAvatar(data: Data)
    case modifyNickname(name: String)
    case userNotify(parameter: [String: Any])
    case updatePassword(oldPassword: String, newPassword: String)
    case updateUserNickname(userID: String, nickname: String)
    case deleteUserNickname(userID: String)
    case updateUserMemo(userID: String, memo: String)
    case getShareLink
    case setSecurityCode(oldSecurityCode: String, newSecurityCode: String)
    
    // Block
    case userBlock(userID: String)
    case removeUserBlock(userID: String)
    case blockedList
    case addGroupBlockMember(groupID: String, memberID: [String])
    case removeGroupBlockedMember(groupID: String, memberID: String)
    
    // Conversation Setting
    case userReport(userID: String, reason: Int)
    case groupReport(groupID: String, reason: Int)
    case updateGroupNotify(groupID: String, notifyType: NotifyType)
    case updateGroupDisplayName(groupID: String, displayName: String)
    case addGroupMember(groupID: String, memberID: [String])
    case deleteGroupMember(groupID: String, memberID: String)
    
    case createGroup(name: String)
    case createGroupWithImage(request: ApiClient.CreateGroupRequset)
    case createDirectGroup(contactID: String)
    
    // Conversation background Fetch
    case getGroupBy(groupID: String)
    case getGroupMember(groupID: String, memberID: String)
    case getGroupMembersBy(groupID: String)
    case getGroupFile(groupID: String, fileID: String)
    case getGroupMessages(groupID: String, direction: String, limit: Int, time: Int?)
    case getGroupMessagesWith(groupID: String, messageID: String, direction: String, limit: Int)
    case getGroupMemberIDs(groupID: String, ids: [String])
    case getGroupLastMessage(groupID: String)
    
    // Group Auth
    case getGroupAdminRole(groupID: String, memberID: String)
    case getGroupAdmins(groupID: String)
    case addGroupAdmin(groupID: String, parameter: Parameters)
    case getGroupBlocks(groupID: String)
    case setGroupMemberPermissions(groupID: String, parameter: [String: Any])
    case uploadGroupIcon(groupID: String, data: Data)
    case deleteGroupAmdin(groupID: String, memberID: String)
    case updateGroupAmdin(groupID: String, memberID: String, parameter: [String: Any])
    
    // Message
    case readMessage(groupID: String, messageID: String)
    case sendMessage(type: String, groupID: String, cid: String, message: String)
    case replyMessage(replyID: String, cid: String, message: String)
    case unsendMessage(messageID: String)
    case getMessage(groupID: String, messageID: String)
    case sendImage(groupID: String, cid: String, data: Data)
    case clearGroupMessage(groupID: String)
    case addMessageEmoji(messageID: String, emojiCode: String)
    case removeMessageEmoji(messageID: String)
    case getMessageEmojiBySelf(messageID: String)
    case getMessageEmojiList(messageID: String)
    
    // HongBao
    case getHongBao(campaignID: String)
    case getHongBaoNumbers(groupID: String)
    case getHongBaoClaimStatus(campaignID: String)
    
    // Pin Message
    case getPins(groupID: String)
    case pinMessage(groupID: String, messageID: String)
    case unpinMessages(groupID: String)
    case unpinMessage(groupID: String, messageID: String)
    
    // Contact
    case getUserContacts
    case getUserContactsPart
    case addContact(userName: String)
    case removeContact(contactID: String)
    case searchNewContacts(searchStr: String)
    
    // Hong Bao
    case getHongBaoBalance
    case getHongBaoRecord
    
    // Wallet
    case getMediumBinding
    case wellPayExchange(amount: String, securityCode: String)
    case bindWellPayWallet(code: String, address: String)

    // MARK: - Path
    private var path: String {
        switch self {
        case .country:
            return NetworkConfig.Path.country.rawValue
        case .phoneVerify:
            return NetworkConfig.Path.phoneVerify.rawValue
        case .getVerifyCode:
            return NetworkConfig.Path.getVerifyCode.rawValue
        case .examVerifyCode:
            return NetworkConfig.Path.examVerifyCode.rawValue
        case .login, .parmaterLogin:
            return NetworkConfig.Path.login.rawValue
        case .scanLoginQRCode:
            return NetworkConfig.Path.loginQRCodeScan.rawValue
        case .validateLoginQRCode:
            return NetworkConfig.Path.validateLoginQRCode.rawValue
        case .recovery:
            return NetworkConfig.Path.recovery.rawValue
        case .logout:
            return NetworkConfig.Path.logout.rawValue
        case .resetUserPassword:
            return NetworkConfig.Path.resetPassword.rawValue
        case .updatePassword:
            return NetworkConfig.Path.updatePassword.rawValue
        case .checkAccount:
            return NetworkConfig.Path.usernameCheck.rawValue
        case .reigster, .getRegisterInfo:
            return NetworkConfig.Path.register.rawValue
        case .getUserInfo, .modifyNickname, .deleteAccount:
            return NetworkConfig.Path.usersMe.rawValue
        case .getUserGroups:
            return NetworkConfig.Path.usersGroups.rawValue
        case .getUserGroupPart(let groupID):
            return String(format: NetworkConfig.Path.userGroupPart.rawValue, groupID)
        case .getUserGroupsGeneral:
            return NetworkConfig.Path.usersGroupsGeneral.rawValue
        case .getUserGroupsPart:
            return NetworkConfig.Path.userGroupsPart.rawValue
        case .getUserUnread:
            return NetworkConfig.Path.usersUnread.rawValue
        case .getUserNicknames:
            return NetworkConfig.Path.userNicknames.rawValue
        case .updateUserNickname(let userID, _), .deleteUserNickname(let userID):
            return String(format: NetworkConfig.Path.userNickname.rawValue, userID)
        case .getUserMemo(let userID), .updateUserMemo(let userID, _):
            return String(format: NetworkConfig.Path.userMemo.rawValue, userID)
        case .getUserPlatforms:
            return NetworkConfig.Path.usersPlatforms.rawValue
        case .uploadAvatar:
            return NetworkConfig.Path.usersAvatar.rawValue
        case .userBlock, .blockedList:
            return NetworkConfig.Path.usersBlock.rawValue
        case .removeUserBlock(let userID):
            return String(format: NetworkConfig.Path.usersBlockID.rawValue, userID)
        case .userReport:
            return NetworkConfig.Path.usersReport.rawValue
        case .createGroup, .createGroupWithImage:
            return NetworkConfig.Path.groups.rawValue
        case .getGroupBy(let groupID):
            return String(format: NetworkConfig.Path.groupsID.rawValue, groupID)
        case .updateGroupNotify(groupID: let groupID, _), .updateGroupDisplayName(groupID: let groupID, _):
            return String(format: NetworkConfig.Path.groupsID.rawValue, groupID)
        case .createDirectGroup:
            return NetworkConfig.Path.directGroup.rawValue
        case .getGroupMembersBy(let groupID):
            return String(format: NetworkConfig.Path.groupsIDMembers.rawValue, groupID)
        case .getGroupMember(let groupID, let memberID):
            return String(format: NetworkConfig.Path.groupsIDMemberID.rawValue, groupID, memberID)
        case .addGroupMember(let groupID, _):
            return String(format: NetworkConfig.Path.groupsIDMembers.rawValue, groupID)
        case .deleteGroupMember(let groupID, let memberID):
            return String(format: NetworkConfig.Path.groupsIDMemberID.rawValue, groupID, memberID)
        case .getGroupLastMessage(let groupID):
            return String(format: NetworkConfig.Path.groupLastMessage.rawValue, groupID)
        case .sendMessage, .sendImage:
            return NetworkConfig.Path.messages.rawValue
        case .replyMessage(let replyID, _, _):
            return String(format: NetworkConfig.Path.replyMessage.rawValue, replyID)
        case .unsendMessage(let messageID):
            return String(format: NetworkConfig.Path.unsendMessage.rawValue, messageID)
        case .getGroupMessages(let groupID, let direction, let limit, let time):
            let basePath = String(format: NetworkConfig.Path.groupsIDMessages.rawValue, groupID)
            var path: String = basePath
            if let timestamp = time {
                path = basePath.queryString(["timestamp": "\(timestamp)"])
            }
            path = path.queryString(["limit": "\(limit)", "direction": direction])
            return path
        case .getGroupAdminRole(let groupID, let memberID):
            return String(format: NetworkConfig.Path.groupAdmin.rawValue, groupID, memberID)
        case .getGroupAdmins(let groupID), .addGroupAdmin(let groupID, _):
            return String(format: NetworkConfig.Path.groupAdmins.rawValue, groupID)
        case .getGroupBlocks(let groupID), .addGroupBlockMember(let groupID, _):
            return String(format: NetworkConfig.Path.groupBlocks.rawValue, groupID)
        case .removeGroupBlockedMember(let groupID, let memberID):
            return String(format: NetworkConfig.Path.groupsIDBlockID.rawValue, groupID, memberID)
        case .setGroupMemberPermissions(let groupID, _):
            return String(format: NetworkConfig.Path.groupMemberPermission.rawValue, groupID)
        case .uploadGroupIcon(let groupID, _):
            return String(format: NetworkConfig.Path.groupIcon.rawValue, groupID)
        case .deleteGroupAmdin(let groupID, let memberID), .updateGroupAmdin(let groupID, let memberID, _):
            return String(format: NetworkConfig.Path.groupAdmin.rawValue, groupID, memberID)
        case .getGroupMessagesWith(let groupID, let messageID, let direction, let limit):
            let basePath = String(format: NetworkConfig.Path.groupsIDMessages.rawValue, groupID)
            let path = basePath.queryString(["msg_id": messageID, "limit": "\(limit)", "direction": direction])
            return path
        case .getGroupMemberIDs(let groupID, _):
            return String(format: NetworkConfig.Path.groupMembersIDs.rawValue, groupID)
        case .getMessage(groupID: let groupID, messageID: let messageID):
            return String(format: NetworkConfig.Path.groupsIDMessageID.rawValue, groupID, messageID)
        case .getPins(let groupID), .unpinMessages(let groupID), .pinMessage(let groupID, _):
            return String(format: NetworkConfig.Path.groupPins.rawValue, groupID)
        case .getHongBao(let campaignID):
            return String(format: NetworkConfig.Path.hongBao.rawValue, campaignID)
        case .getHongBaoNumbers(let groupID):
            return String(format: NetworkConfig.Path.hongBaoNumber.rawValue, groupID)
        case .getHongBaoClaimStatus(let campaignID):
            return String(format: NetworkConfig.Path.hongBaoClaimStatus.rawValue, campaignID)
        case .unpinMessage(let groupID, let messageID):
            return String(format: NetworkConfig.Path.groupUnpin.rawValue, groupID, messageID)
        case .getUserContacts:
            return NetworkConfig.Path.usersContacts.rawValue
        case .getUserContactsPart:
            return NetworkConfig.Path.usersContactsPart.rawValue
        case .addContact:
            return NetworkConfig.Path.usersContacts.rawValue
        case .removeContact(let contactID):
            return String(format: NetworkConfig.Path.removeContacts.rawValue, contactID)
        case .readMessage(let groupID, _):
            return String(format: NetworkConfig.Path.groupsIDView.rawValue, groupID)
        case .groupReport(let groupID, _):
            return String(format: NetworkConfig.Path.groupReport.rawValue, groupID)
        case .getGroupFile(groupID: let groupID, fileID: let fileID):
            return String(format: NetworkConfig.Path.groupFile.rawValue, groupID, fileID)
        case .searchNewContacts:
            return NetworkConfig.Path.searchNewContacts.rawValue
        case .userNotify(_):
            return NetworkConfig.Path.usersNotify.rawValue
        case .registerDeviceToken:
            return NetworkConfig.Path.registerDeviceToken.rawValue
        case .clearGroupMessage(groupID: let groupID):
            return String(format: NetworkConfig.Path.clearGroupMessage.rawValue, groupID)
        case .getShareLink:
            return NetworkConfig.Path.shareLink.rawValue
        case .addMessageEmoji(messageID: let messageID, emojiCode: let emojiCode):
            return String(format: NetworkConfig.Path.messageEmojis.rawValue, messageID, emojiCode)
        case .removeMessageEmoji(messageID: let messageID):
            return String(format: NetworkConfig.Path.messageEmojis.rawValue, messageID)
        case .getMessageEmojiBySelf(messageID: let messageID):
            return String(format: NetworkConfig.Path.messageEmojis.rawValue, messageID)
        case .getMessageEmojiList(messageID: let messageID):
            return String(format: NetworkConfig.Path.messageEmojiList.rawValue, messageID)
        case .getHongBaoBalance:
            return NetworkConfig.Path.hongBaoBalance.rawValue
        case .getHongBaoRecord:
            return NetworkConfig.Path.hongBaoRecord.rawValue
        case .setSecurityCode:
            return NetworkConfig.Path.setSecurityCode.rawValue
        case .getMediumBinding:
            return NetworkConfig.Path.getMediumBinding.rawValue
        case .wellPayExchange:
            return NetworkConfig.Path.getWellPayDetail.rawValue
        case .bindWellPayWallet:
            return NetworkConfig.Path.bindWellPayWallet.rawValue
        }
    }
    
    // MARK: - Need Check Access
    var needAccessToken: Bool {
        switch self {
        case .country:
            return false
        case .login, .parmaterLogin:
            return false
        case .recovery, .resetUserPassword:
            return false
        case .phoneVerify, .getVerifyCode, .examVerifyCode:
            return false
        case .checkAccount, .reigster, .getRegisterInfo:
            return false
        default:
            return true
        }
    }

    // MARK: - ContentType
    var contentType: String {
        switch self {
        case .uploadAvatar, .sendImage, .uploadGroupIcon, .createGroupWithImage:
            let boundary = AppConfig.Device.uuid
            return "multipart/form-data; boundary=\(boundary)"
        default:
            return NetworkConfig.ContentType.json.rawValue
        }
    }

    // MARK: - HttpMethod
    private var method: HTTPMethod {
        switch self {
             // Login
        case .login, .scanLoginQRCode, .validateLoginQRCode, .parmaterLogin, .recovery, .resetUserPassword, .logout, .updatePassword,
             // Register
             .checkAccount, .reigster,
             // Info Setting
             .userNotify, .clearGroupMessage, .updateUserMemo,
             // Verify
             .phoneVerify, .getVerifyCode, .examVerifyCode,
             // upload
             .uploadAvatar, .sendImage,
            // Group
             .createGroupWithImage, .createGroup, .addGroupAdmin, .getGroupMemberIDs, .uploadGroupIcon,
             // Message
             .sendMessage, .addGroupMember, .createDirectGroup, .readMessage, .replyMessage,
             // HongBao
             .getHongBao,
             // Pin
             .pinMessage,
             // Block
             .userBlock, .addGroupBlockMember,
             // Report
             .userReport, .groupReport,
             // Contact
             .searchNewContacts, .addContact,
             // 推撥註冊
             .registerDeviceToken,
             // auth permission
             .setGroupMemberPermissions,
             // emoji
             .addMessageEmoji,
             // security code
             .setSecurityCode,
             // wallet
             .wellPayExchange,
             .bindWellPayWallet:
            return .post

        case .removeUserBlock, .removeContact, .deleteGroupMember, .deleteAccount, .deleteGroupAmdin,
                .removeGroupBlockedMember, .unpinMessages, .unpinMessage, .unsendMessage, .deleteUserNickname, .removeMessageEmoji:
            return .delete

        case .updateGroupNotify, .updateGroupDisplayName, .modifyNickname, .updateGroupAmdin, .updateUserNickname:
            return .put

        default:
            return .get
        }
    }
    
    // MARK: - timeout
    private var timeoutInterval: TimeInterval {
        switch self {
        case .sendImage, .uploadAvatar, .sendMessage, .uploadGroupIcon, .createGroupWithImage:
            return Application.uploadTimeout
        default:
            return Application.timeout
        }
    }
    
    // MARK: - retry times
    var retryTimes: Int {
        switch self {
        case .uploadAvatar, .sendMessage, .uploadGroupIcon, .createGroupWithImage:
            return 4
        default:
            return 0
        }
    }
    
    // MARK: - ObjectData
    var objectData: Any? {
        switch self {
        case .addGroupMember(_, let members), .addGroupBlockMember(_, let members):
            return members
        case .getGroupMemberIDs(_, let ids):
            return ids
        default:
            return nil
        }
    }
    
    // MARK: - Parameters
    var parameters: Parameters? { // REQ Body
        switch self {
        case .phoneVerify(let request), .getVerifyCode(let request):
            let parameters = ["country": request.country, "phone": request.phone, "device_id": request.device_id]
            return parameters
        case .examVerifyCode(let request):
            let parameters = ["country": request.country, "phone": request.phone, "device_id": request.device_id, "code": request.code]
            return parameters
        case .reigster(let request):
            let parameters = ["country": request.country,
                              "phone": request.phone,
                              "password": request.password,
                              "username": request.username,
                              "nickname": request.nickname,
                              "device_id": request.device_id,
                              "social_account": request.social_account,
                              "invite_code": request.invite_code]
            return parameters
        case .checkAccount(let phone, let account):
            let parameters = ["phone": phone, "username": account]
            return parameters
        case .sendMessage(let type, let groupID, let cid, let message):
            let parameters = ["type": type, "group_id": groupID, "cid": cid, "text": message]
            return parameters
        case .replyMessage(_, let cid, let message):
            let parameters = ["type": "text", "cid": cid, "text": message]
            return parameters
        case .createGroup(let name):
            let parameters = ["name": name]
            return parameters
        case .addGroupAdmin(_, let parameter):
            return parameter
        case .login(refreshToken: let token):
            let parameters = ["refresh_token": token, "grant_type": "refresh_token", "device_id": AppConfig.Device.uuid]
            return parameters
        case .recovery(country: let country, phone: let phone, code: let code):
            let parameters = ["country": country, "phone": phone, "code": code, "device_id": AppConfig.Device.uuid]
            return parameters
        case .resetUserPassword(password: let password, oneTimeToken: _):
            let parameters = ["password": password]
            return parameters
        case .updatePassword(oldPassword: let oldPassword, newPassword: let newPassword):
            return ["old_password": oldPassword, "new_password": newPassword]
        case .parmaterLogin(country: let country, phone: let phone, password: let password):
            let parameters = ["country": country, "phone": phone, "password": password, "grant_type": "password", "device_id": AppConfig.Device.uuid]
            return parameters
        case .scanLoginQRCode(deviceID: let deviceID, data: let data):
            let parameters = ["data": data, "device_id": deviceID]
            return parameters
        case .validateLoginQRCode(deviceID: let deviceID, data: let data, passcode: let passcode):
            let parameters = ["data": data, "device_id": deviceID, "passcode": passcode]
            return parameters
        case .userBlock(let userID):
            let parameters = ["block_id": userID]
            return parameters
        case .userReport(let userID, let reason):
            let parameters = ["user_id": userID, "reason": reason] as [String: Any]
            return parameters
        case .groupReport(_, let reason):
            let parameters = ["reason": reason] as [String: Any]
            return parameters
        case .updateGroupNotify(_, let notifyType):
            return ["notify": notifyType.rawValue]
        case .updateGroupDisplayName(_, let displayName):
            return ["display_name": displayName]
        case .updateUserMemo(_, let memo):
            return ["memo": memo]
        case .updateUserNickname(_, let nickname):
            return ["nickname": nickname]
        case .createDirectGroup(contactID: let contactID):
            return ["contact_id": contactID]
        case .addContact(let name):
            let parameters = ["contact": name]
            return parameters
        case .removeContact(let contactID):
            let parameters = ["contact_id": contactID]
            return parameters
        case .readMessage(_, let messageID):
            return ["msg_id": messageID]
        case .searchNewContacts(let searchStr):
            return ["contact": searchStr]
        case .modifyNickname(name: let nickname):
            return ["nickname": nickname]
        case .userNotify(let parameter):
            return parameter
        case .setGroupMemberPermissions(_, parameter: let parameter):
            return parameter
        case .updateGroupAmdin(_, _, let parameter):
            return parameter
        case .registerDeviceToken(token: let token):
            // 1: Android 2: iOS
            return ["device_token": token, "system": 2, "bundle_id": AppConfig.Info.bundleID]
        case .pinMessage(_, let messageID):
            return ["msg_id": messageID]
        case .addMessageEmoji(_, emojiCode: let emojiCode):
            return ["emoji": emojiCode]
        case .getMessageEmojiList:
            return ["limit": 2000]
        case .setSecurityCode(oldSecurityCode: let oldSecurityCode, newSecurityCode: let newSecurityCode):
            return ["code": newSecurityCode, "confirm_code": newSecurityCode, "old_code": oldSecurityCode]
        case .wellPayExchange(amount: let amount, securityCode: let securityCode):
            return ["amount": amount, "security_code": securityCode]
        case .bindWellPayWallet(code: let code, address: let address):
            return ["code": code, "address": address]
        default:
            return nil
        }
    }
    
    struct FormDataInfo {
        let imageData: Data?
        let imageKey: String?
        var otherForm: [String: Data]?
    }
    
    var formData: FormDataInfo? {
        switch self {
        case .sendImage(groupID: let groupID, cid: let cid, data: let imageData):
            var fData = FormDataInfo.init(imageData: imageData, imageKey: "file")
            
            if let gData = groupID.data(using: .utf8) {
                fData.otherForm = ["group_id": gData]
            }
            
            if let cidData = cid.data(using: .utf8) {
                fData.otherForm?["cid"] = cidData
            }
            
            return fData
        case .uploadAvatar(data: let imageData), .uploadGroupIcon(_, data: let imageData):
            return FormDataInfo.init(imageData: imageData, imageKey: "image")
        case .createGroupWithImage(request: let request):
            var fData = FormDataInfo.init(imageData: request.img, imageKey: "image")
            if let nameData = request.displayName.data(using: .utf8),
               let usersData = request.users.data(using: .utf8) {
                fData.otherForm = ["display_name": nameData,
                                   "user_ids": usersData]
            }
            return fData
        default:
            return nil
        }
    }

    // MARK: - URLRequestConvertible
    func asURLRequest() throws -> URLRequest {
        
        let url = try (NetworkConfig.URL.APIBaseURL + path).asURL()
        let authorization = "Bearer " + self.token
        
        PRINT("authorization == \(authorization)", cate: .request)
        PRINT("path == \(url)", cate: .request)
        PRINT("method == \(method.rawValue)", cate: .request)
        
        var urlRequest = URLRequest(url: url)
        // Http method
        urlRequest.httpMethod = method.rawValue
        // Timeout
        urlRequest.timeoutInterval = self.timeoutInterval
        // Headers
        urlRequest.setValue(authorization, forHTTPHeaderField: NetworkConfig.HttpHeader.Authorization.rawValue)
        urlRequest.setValue(NetworkConfig.ContentType.json.rawValue, forHTTPHeaderField: NetworkConfig.HttpHeader.Accept.rawValue)
        urlRequest.setValue(contentType, forHTTPHeaderField: NetworkConfig.HttpHeader.contentType.rawValue)
        
        let encoding: ParameterEncoding = {
            switch method {
            case .get:
                return URLEncoding.default
            default:
                return JSONEncoding.default
            }
        }()
        
        if objectData != nil {
            return try JSONEncoding.default.encode(urlRequest, withJSONObject: objectData)
        } else {
            return try encoding.encode(urlRequest, with: parameters)
        }
    }
    
    private var token: String {
        var accessToken = UserData.shared.getData(key: .token) as? String ?? ""
        
        switch self {
        case .resetUserPassword(password: _, oneTimeToken: let onTimeToken):
            accessToken = onTimeToken
        default:
            break
        }
        
        return accessToken
    }
}
