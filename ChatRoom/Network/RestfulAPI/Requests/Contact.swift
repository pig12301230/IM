//
//  Contact.swift
//  ChatRoom
//
//  Created by Andy Yang on 2021/5/28.
//

import Foundation
import RxSwift
import RxCocoa
import Alamofire

extension ApiClient {
    static func addContact(userName: String, takeoverError: Bool = false) -> Observable<Empty> {
        return fetch(ApiRouter.addContact(userName: userName), takeoverError: takeoverError)
    }
    
    static func removeContact(contactID: String) -> Observable<Empty> {
        return fetch(ApiRouter.removeContact(contactID: contactID))
    }
    
    static func searchNewContact(searchStr: String) -> Observable<RUserInfo> {
        return fetch(ApiRouter.searchNewContacts(searchStr: searchStr))
    }
    
    static func getContactsPart() -> Observable<[RContact]> {
        return fetch(.getUserContactsPart)
    }
}
