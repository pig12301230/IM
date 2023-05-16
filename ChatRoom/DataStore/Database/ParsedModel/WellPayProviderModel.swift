//
//  WellPayProviderModel.swift
//  ChatRoom
//
//  Created by ERay_Peng on 2023/4/20.
//

import Foundation

struct WalletProviderModel {
    var walletName: String
    var name: String
    var enable: Bool
    var isBind: Bool
    var bindAddress: String
    
    init(with object: RProvider) {
        self.walletName = object.walletName
        self.name = object.name
        self.enable = object.enable
        self.isBind = object.isBind
        self.bindAddress = object.bindAddress
    }
}
