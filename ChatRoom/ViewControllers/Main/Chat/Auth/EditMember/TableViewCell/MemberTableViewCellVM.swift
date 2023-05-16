//
//  MemberTableViewCellVM.swift
//  ChatRoom
//
//  Created by ZoeLin on 2022/1/24.
//

import Foundation
import UIKit
import RxCocoa

class MemberTableViewCellVM: BaseViewModel, CellConfigProtocol, SearchContentProtocol {
    var leading: CGFloat = 64.0
    var title: String = ""
    private(set) var description: String = ""
    private(set) var iconPlaceholder: String = ""
    private(set) var icon: String = ""
    private(set) var transceiver: TransceiverModel?
    private(set) var allowEdit: Bool = false
    private(set) var isOwner: Bool = false
    private(set) var editType: EditMemberType?
    
    // FOR - SearchContentProtocol
    var compareString: String = ""
    var keyString: String = ""
    let attributedName: BehaviorRelay<NSAttributedString?> = BehaviorRelay(value: nil)
    private(set) var nameMutableAttributedString: NSMutableAttributedString = NSMutableAttributedString.init(string: "")
    
    init(addType: EditMemberType) {
        iconPlaceholder = "buttonIconPlus"
        
        switch addType {
        case .member:
            title = Localizable.joinMembers
        case .admin:
            title = Localizable.groupAddAdmin
        case .block:
            title = Localizable.groupJoinBlacklist
        }
        
        super.init()
        self.setupNameMutableAttributedString(with: title)
    }
    
    init(model: TransceiverModel, role: PermissionType? = nil, type: EditMemberType) {
        transceiver = model
        title = model.display
        icon = model.avatarThumbnail
        iconPlaceholder = "avatarsPhoto"
        self.editType = type
        
        super.init()
        self.setupCompareString(model.display)
        
        guard let role = role else {
            self.allowEdit = model.userID != UserData.shared.userInfo?.id
            return
        }
        
        self.isOwner = role == .owner
        self.allowEdit = role != .owner && model.userID != UserData.shared.userInfo?.id
        self.description = role.description
    }
}

extension MemberTableViewCellVM {
    
    func isFitSearchContent(key: String) -> Bool {
        self.keyString = key
        self.setupSearchContentColor(key: key)
        
        guard !key.isEmpty else {
            return true
        }
        
        return self.compareString.localizedCaseInsensitiveContains(key)
    }
    
    func setupSearchContentColor(key: String) {
        self.nameMutableAttributedString.recoverColor(to: Theme.c_10_grand_1.rawValue.toColor())
        if key.count > 0 {
            self.nameMutableAttributedString.setColorToAllRange(color: Theme.c_01_primary_0_500.rawValue.toColor(), forText: key)
        }
        
        self.attributedName.accept(self.nameMutableAttributedString)
    }
    
    func setupCompareString(_ compare: String) {
        self.compareString = compare
        self.setupNameMutableAttributedString(with: self.compareString)
    }
    
    func setupNameMutableAttributedString(with message: String?) {
        guard let message = message else {
            return
        }
        
        self.nameMutableAttributedString = NSMutableAttributedString.init(string: message)
        self.nameMutableAttributedString.recoverColor(to: Theme.c_10_grand_1.rawValue.toColor())
        self.attributedName.accept(self.nameMutableAttributedString)
    }
}
