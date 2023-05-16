//
//  ActionView.swift
//  ChatRoom
//
//  Created by ZoeLin on 2022/3/2.
//

import UIKit

class ActionView: UIView {
    typealias ActiveAction = (ActionType) -> Void
    
    struct Config {
        var action: ActionType = .delete
        var needLeftSeparate: Bool = false
    }
    
    lazy var icon: UIImageView = {
        let img = UIImageView()
        img.contentMode = .scaleAspectFit
        return img
    }()
    
    lazy var lblName: UILabel = {
        let lbl = UILabel()
        lbl.font = .midiumParagraphTinyCenter
        lbl.theme_textColor = Theme.c_09_white.rawValue
        lbl.textAlignment = .center
        return lbl
    }()
    
    lazy var separateView: UIView = {
        let view = UIView()
        view.theme_backgroundColor = Theme.c_09_white_25.rawValue
        return view
    }()
    
    var doAction: ActiveAction?
    private var config: Config = Config()
    
    convenience init(with config: Config) {
        self.init()
        self.setupViews(with: config)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews(with config: Config = Config()) {
        self.config = config
        self.addSubview(icon)
        self.addSubview(lblName)
        self.addSubview(separateView)
        self.snp.makeConstraints { make in
            make.width.equalTo(56)
        }
        
        icon.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(self.snp.centerY).offset(2)
            make.width.height.equalTo(24)
        }
        
        lblName.snp.makeConstraints { make in
            make.centerX.equalTo(icon)
            make.top.equalTo(icon.snp.bottom).offset(2)
            make.leading.equalTo(separateView.snp.trailing)
        }
        
        separateView.snp.makeConstraints { make in
            make.height.equalTo(40)
            make.leading.centerY.equalToSuperview()
            make.width.equalTo(0.5)
        }
        
        separateView.isHidden = !config.needLeftSeparate
        icon.image = UIImage(named: config.action.icon)
        lblName.text = config.action.name
        
        let tap = UITapGestureRecognizer()
        tap.addTarget(self, action: #selector(clickView))
        self.addGestureRecognizer(tap)
    }
    
    @objc func clickView() {
        self.doAction?(config.action)
    }
}
