//
//  SearchResultView.swift
//  ChatRoom
//
//  Created by Andy Yang on 2021/6/28.
//

import UIKit

class SearchResultView: UIView {
    private lazy var centerLabel: UILabel = {
        let label = UILabel()
        label.font = .midiumParagraphMediumLeft
        label.theme_textColor = Theme.c_10_grand_1.rawValue
        label.textAlignment = .center
        return label
    }()
    private lazy var searchIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "buttonIconSearch")
        return imageView
    }()
    private lazy var searchLabel: UILabel = {
        let label = UILabel()
        label.font = .midiumParagraphMediumLeft
        label.theme_textColor = Theme.c_10_grand_1.rawValue
        label.textAlignment = .left
        return label
    }()
    private lazy var separator: UIView = {
        let view = UIView()
        view.theme_backgroundColor = Theme.c_07_neutral_900_10.rawValue
        return view
    }()
    
    struct SearchStatus {
        var isSearching: Bool
        var searchStr: String
    }
    
    var status: SearchStatus? {
        didSet {
            if status?.isSearching == true {
                centerLabel.isHidden = true
                searchIcon.isHidden = false
                searchLabel.isHidden = false
                separator.isHidden = false
                searchLabel.text = status?.searchStr
            } else {
                centerLabel.isHidden = false
                searchIcon.isHidden = true
                searchLabel.isHidden = true
                separator.isHidden = true
                centerLabel.text = status?.searchStr
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        addSubview(centerLabel)
        addSubview(searchIcon)
        addSubview(searchLabel)
        addSubview(separator)
        
        centerLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        
        searchIcon.snp.makeConstraints {
            $0.leading.equalTo(16)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(36)
        }
        
        searchLabel.snp.makeConstraints {
            $0.leading.equalTo(searchIcon.snp.trailing).offset(12)
            $0.centerY.equalToSuperview()
        }
        
        separator.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(1)
        }
    }
}
