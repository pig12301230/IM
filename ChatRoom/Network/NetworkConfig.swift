//
//  NetworkConfig.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/4/12.
//

import UIKit
import RxSwift
import RxCocoa

enum NetworkConfig {

    struct URL {
        static var APIBaseURL = AppConfig.bundle.getChatPropertyFromPlist(key: "APIBaseURL")
        static var WSBaseURL = AppConfig.bundle.getChatPropertyFromPlist(key: "WSBaseURL")       
    }

    // Api Headers
    enum HttpHeader: String {
        case Authorization, Accept
        case contentType = "Content-Type"
        case acceptEncoding = "Accept-Encoding"
    }

    // Api Content Type
    enum ContentType: String {
        case text = "text/plain"
        case html = "text/html"
        case json = "application/json"
        case javaScript = "application/javascript"
        case xml = "application/xml"
    }

    // 極豋Api keys
    enum RegInfoApiKey: String {
        case appKey = "2KR2TKIN-02"
        case secretKey = "321baeb5-e5ea-4a21-be2e-c3dba4a707b8"
    }

    enum Path: String {
        case country = "/v1/country"
        // Verify
        case phoneVerify = "/v1/phone/check"
        case getVerifyCode = "/v1/verification"
        case examVerifyCode = "/v1/verification/check"
        // Oauth
        case oauthLogin = "/v1/oauth/login"
        // Login
        case login = "/v1/login"
        case loginQRCodeScan = "/v1/login/qrcode/scan"
        case validateLoginQRCode = "/v1/login/qrcode/validate"
        case recovery = "/v1/recovery"
        case logout = "/v1/logout"
        // Register
        case usernameCheck = "/v1/username/check"
        case register = "/v1/register"
        // Platforms
        case platformsID = "/v1/platforms/%@"
        case platforms = "/v1/platforms"
        // Groups
        case groups = "/v1/groups"
        case groupsID = "/v1/groups/%@"
        case groupsIDMembers = "/v1/groups/%@/members"
        case groupMembersIDs = "/v1/groups/%@/members/ids"
        case groupsIDMemberID = "/v1/groups/%@/members/%@"
        case groupsIDMessageID = "/v1/groups/%@/messages/%@"
        case groupsIDMessages = "/v1/groups/%@/messages"
        case groupLastMessage = "/v1/groups/%@/last_message"
        case directGroup = "/v1/groups/direct"
        case groupsIDView = "/v1/groups/%@/view"
        case groupReport = "/v1/groups/%@/report"
        case clearGroupMessage = "/v1/groups/%@/clear"
        // Messages
        case messages = "/v1/messages"
        case replyMessage = "/v1/messages/%@/thread"
        case unsendMessage = "/v1/messages/%@"
        case messageEmojis = "/v1/messages/%@/emoji"
        case messageEmojiList = "/v1/messages/%@/emojis"
        // HongBao
        case hongBao = "/v1/campaigns/%@/red-envelopes"
        case hongBaoNumber = "/v1/users/groups/%@/red-envelopes/number"
        case hongBaoClaimStatus = "/v1/campaigns/%@/red-envelopes/claim-status"
        // Pin
        case groupPins = "/v1/groups/%@/pins"
        case groupUnpin = "/v1/groups/%@/pins/%@"
        // Users
        case usersMe = "/v1/users/me"
        case usersPlatforms = "/v1/users/platforms"
        case usersGroups = "/v1/users/groups"
        case userGroupPart = "/v1/users/group/%@"
        case userGroupsPart = "/v1/users/groups/part"
        case usersGroupsGeneral = "/v1/users/groups/general"
        case usersUnread = "/v1/users/unread"
        case resetPassword = "/v1/users/password/reset"
        case updatePassword = "/v1/users/password"
        case usersAvatar = "/v1/users/avatar"
        case usersBlock = "/v1/users/blocks"
        case usersBlockID = "/v1/users/blocks/%@"
        case usersReport = "/v1/users/report"
        case usersNotify = "/v1/users/notify"
        case userMemo = "/v1/users/memo/%@"
        case userNicknames = "/v1/users/nicknames"
        case userNickname = "/v1/users/nicknames/%@"
        case groupFile = "/v1/groups/%@/files/%@"
        case shareLink = "/v1/share"
        case setSecurityCode = "/v1/users/security-code"
        // Contact
        case usersContacts = "/v1/users/contacts"
        case usersContactsPart = "/v1/users/contacts/part"
        case removeContacts = "/v1/users/contacts/%@"
        case searchNewContacts = "/v1/contacts/search"
        
        case registerDeviceToken = "/v1/notification/device"
        
        // admin
        case groupAdmins = "/v1/groups/%@/admins"
        case groupAdmin = "/v1/groups/%@/admins/%@"
        case groupBlocks = "/v1/groups/%@/blocks"
        case groupsIDBlockID = "/v1/groups/%@/blocks/%@"
        case groupMemberPermission = "/v1/groups/%@/permissions"
        case groupIcon = "/v1/groups/%@/icon"
        
        // hongBao
        case hongBaoBalance = "/v1/wallet/balance"
        case hongBaoRecord = "/v1/wallet/trading-logs"
        
        // wallet
        case getMediumBinding = "/v1/payment/provider"
        case getWellPayDetail = "/v1/payment/withdrawal/wellpay"
        case bindWellPayWallet = "/v1/users/binding/wellpay"
    }
}
