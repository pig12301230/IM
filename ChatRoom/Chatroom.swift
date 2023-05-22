//
//  Chatroom.swift
//  Chatroom
//
//  Created by Winston_Chuang on 2023/5/10.
//

import UIKit
import RxSwift

@objc public class Chatroom: NSObject {
    
    private static var disposeBag = DisposeBag()
    public static func setup() {
        AppConfig.bundle = Bundle(for: Chatroom.self).self
        Application.shared.setups()
    }
    
    public static func login() {
        ApiClient.parmaterLogin(country: "TW", phone: "886999888001", password: "Qaz12345").subscribe(onNext: { (info) in
            DataAccess.shared.checkUserAccountAndDatabase(country: "TW", phone: "886999888001") {
                DataAccess.shared.saveUserInformation(info)
                UserData.shared.setData(key: .remember, data: true)
            }
        }).disposed(by: self.disposeBag)
    }
    
    public static func getMessage(group: String, message: String, completion: @escaping (MessageModel?) -> Void) {
        print("init type: ", group, message)
        DataAccess.shared.fetchMessage(groupID: group, messageID: message, completion: completion)
    }
    
    public static func getCountry() -> Observable<[RCountryCode]> {
        return ApiClient.getCountryCode()
    }
    
    public static func setDomain(apiUrl: String, socketUrl: String) {
        NetworkConfig.URL.APIBaseURL = apiUrl
        NetworkConfig.URL.WSBaseURL = socketUrl
    }
    
    public static func getChatListVC() -> ChatListViewController {
        let vm = ChatListViewControllerVM()
        return ChatListViewController.initVC(with: vm)
    }
}
