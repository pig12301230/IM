//
//  ImageViewerModel.swift
//  ChatRoom
//
//  Created by Winston_Chuang on 2023/5/15.
//

import Foundation

enum ViewerActionType {
    case none
    case viewAndUploadAvatar
    case viewAndDownload
    
    var enableEdit: Bool {
        switch self {
        case .viewAndUploadAvatar:
            return true
        default:
            return false
        }
    }
    
    var enableDownload: Bool {
        switch self {
        case .viewAndDownload:
            return true
        default:
            return false
        }
    }
    
    var showActionMessage: Bool {
        switch self {
        case .viewAndUploadAvatar:
            return true
        default:
            return false
        }
    }
    
    var messagePresentTyoe: MessagePresentType {
        switch self {
        case .viewAndUploadAvatar:
            return .alert
        case .viewAndDownload:
            return .toast
        default:
            return .default
        }
    }
    
    var successMessage: String {
        switch self {
        case .viewAndUploadAvatar:
            return Localizable.setAvatarSuccessed
        case .viewAndDownload:
            return Localizable.savedToPhotos
        default:
            return ""
        }
    }
    
    var failedMessage: String {
        switch self {
        case .viewAndUploadAvatar:
            return Localizable.imageUploadFailed
        case .viewAndDownload:
            return Localizable.failToSave
        default:
            return ""
        }
    }
}

struct ImageViewerConfig: Hashable {
    let title: String
    let date: Date?
    let imageURL: String
    let actionType: ViewerActionType
    let fileID: String?
    let messageId: String?
    
    static func == (lhs: ImageViewerConfig, rhs: ImageViewerConfig) -> Bool {
        return lhs.messageId == rhs.messageId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(messageId)
    }
}
