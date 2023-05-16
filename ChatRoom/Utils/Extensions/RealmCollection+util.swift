//
//  RealmCollection+util.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/5/11.
//

import RealmSwift

extension RealmCollection {
    func toArray<T>() -> [T] {
        return self.compactMap { $0 as? T }
    }
}
