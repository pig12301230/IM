//
//  CharacterSet+util.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/5/7.
//

import Foundation

extension CharacterSet {
    static let urlQueryParameterNotAllowed = CharacterSet.urlQueryAllowed.subtracting(CharacterSet(charactersIn: "!#$%&'()*+,/:;=?@[]"))
}
