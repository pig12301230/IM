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
    
    class func sendMessage(type: String, groupID: String, cid: String, message: String, takeOver: Bool) -> Observable<RMessage> {
        return fetch(ApiRouter.sendMessage(type: type, groupID: groupID, cid: cid, message: message), takeoverError: takeOver)
    }
    
    class func unsendMessage(messageID: String) -> Observable<Empty> {
        return fetch(.unsendMessage(messageID: messageID), takeoverError: true)
    }
    
    class func sendReplyMessage(message: String, cid: String, replyID: String) -> Observable<RMessage> {
        return fetch(ApiRouter.replyMessage(replyID: replyID, cid: cid, message: message), takeoverError: true)
    }
    
    class func getGroupMessages(groupID: String, time: Int, direction: MessageDirection, limit: Int) -> Observable<[RMessage]> {
        return fetch(ApiRouter.getGroupMessages(groupID: groupID, direction: direction.rawValue, limit: limit, time: time), takeoverError: true)
    }
    
    class func getGroupMessages(groupID: String, messageID: String, direction: MessageDirection, limit: Int) -> Observable<[RMessage]> {
        return fetch(ApiRouter.getGroupMessagesWith(groupID: groupID, messageID: messageID, direction: direction.rawValue, limit: limit), takeoverError: true)
    }
    
    class func getGroupMessage(groupID: String, messageID: String) -> Observable<RMessage> {
        return fetch(ApiRouter.getMessage(groupID: groupID, messageID: messageID), takeoverError: true)
    }
    
    class func sendImage(groupID: String, cid: String, data: Data, uploadRequest: ((UploadRequest) -> Void)?) -> Observable<RMessage> {
        return upload(ApiRouter.sendImage(groupID: groupID, cid: cid, data: data), uploadRequest: uploadRequest)
    }
    
    class func getFile(groupID: String, fileID: String) -> Observable<RFile> {
        return fetch(ApiRouter.getGroupFile(groupID: groupID, fileID: fileID), takeoverError: true)
    }
    
    class func addMessageEmoji(messageID: String, emojiCode: String) -> Observable<Empty> {
        return fetch(ApiRouter.addMessageEmoji(messageID: messageID, emojiCode: emojiCode), takeoverError: true)
    }
    
    class func removeMessageEmoji(messageID: String) -> Observable<Empty> {
        return fetch(ApiRouter.removeMessageEmoji(messageID: messageID), takeoverError: true)
    }
    
    class func getMessageEmojiBySelf(messageId: String) -> Observable<REmoji> {
        return fetch(ApiRouter.getMessageEmojiBySelf(messageID: messageId), takeoverError: true)
    }
    
    class func getMessageEmojiList(messageID: String) -> Observable<REmojiList> {
        return fetch(.getMessageEmojiList(messageID: messageID), takeoverError: true)
    }
}
