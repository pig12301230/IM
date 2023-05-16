//
//  FriendListMainHeaderVM.swift
//  ChatRoom
//
//  Created by Andy Yang on 2021/6/1.
//

import Foundation
import RxSwift
import RxCocoa

class FriendListMainHeaderVM: BaseSectionVM {
    
    var collapsable: Bool = true
    var section: ListSection = .group
    
    override var reuseIdentifier: String {
        return "FriendListMainHeaderView"
    }
    
    convenience init(section: ListSection, title: String, collapsable: Bool) {
        self.init()
        self.section = section
        self.title = title
        self.collapsable = collapsable
    }
    
    func didTapCollapsed() {
        let groupIsCollapse = UserDefaults.standard.bool(forKey: ListSection.group.collapseKey)
        let friendIsCollapse = UserDefaults.standard.bool(forKey: ListSection.friend.collapseKey)
        
        switch self.section {
        case .group:
            UserDefaults.standard.set(!groupIsCollapse, forKey: ListSection.group.collapseKey)
        case .friend:
            UserDefaults.standard.set(!friendIsCollapse, forKey: ListSection.friend.collapseKey)
        }
    }
}
