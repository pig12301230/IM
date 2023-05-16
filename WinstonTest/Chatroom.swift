//
//  Chatroom.swift
//  Chatroom
//
//  Created by Winston_Chuang on 2023/5/10.
//

import UIKit
import RxSwift

@objc public class Chatroom: NSObject {
    
    public static func getMessage(group: String, message: String, completion: @escaping (MessageModel?) -> Void) {
        print("init type: ", group, message)
        DataAccess.shared.fetchMessage(groupID: group, messageID: message, completion: completion)
        
//        let vm = ChatListViewControllerVM()
//        return ChatListViewController.initVC(with: vm)
    }
    
    public static func getCountry() -> Observable<[RCountryCode]> {
        return ApiClient.getCountryCode()
    }
    
    public static func setDomain(apiUrl: String, socketUrl: String) {
        NetworkConfig.URL.APIBaseURL = apiUrl
        NetworkConfig.URL.WSBaseURL = socketUrl
    }
}
