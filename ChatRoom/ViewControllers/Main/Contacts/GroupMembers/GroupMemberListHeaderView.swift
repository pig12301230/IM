//
//  GroupMemberListHeaderView.swift
//  ChatRoom
//
//  Created by Andy Yang on 2021/6/8.
//

import UIKit

class GroupMemberListHeaderView: UITableViewHeaderFooterView {
    
    static let headerID = String(describing: GroupMemberListHeaderView.self)
    
    lazy var label: UILabel = {
        let label = UILabel()
        label.font = .midiumParagraphMediumLeft
        label.theme_textColor = Theme.c_10_grand_2.rawValue
        return label
    }()
    
    private lazy var separator: UIView = {
        let view = UIView.init()
        view.theme_backgroundColor = Theme.c_07_neutral_900_10.rawValue
        return view
    }()
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        contentView.theme_backgroundColor = Theme.c_07_neutral_50.rawValue
        
        contentView.addSubview(label)
        contentView.addSubview(separator)
        
        label.snp.makeConstraints {
            $0.leading.equalTo(16)
            $0.centerY.equalToSuperview()
        }
        
        separator.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(1)
        }
    }
}
