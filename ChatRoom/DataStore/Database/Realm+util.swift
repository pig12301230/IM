//
//  Realm+util.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/4/13.
//

import Foundation
import RealmSwift

extension Realm {
    /**
     確認＆更新Realm的Schema
     */
    public static func migration() {
        Realm.Configuration.defaultConfiguration = Realm.Configuration(
            schemaVersion: AppConfig.Database.schemaVersion, // 修改schema後，要記得把版號+1，舊的DB才會自動更新
            migrationBlock: { _, oldSchemaVersion in
                if oldSchemaVersion < 1 {
                    print("[Realm] v1: init version")
                }
            }
        )
    }
}
