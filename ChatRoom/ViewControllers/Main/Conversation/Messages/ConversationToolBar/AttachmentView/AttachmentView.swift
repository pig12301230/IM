//
//  AttachmentView.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/6/3.
//

import UIKit
import RxSwift

class AttachmentView: BaseViewModelView<AttachmentViewVM> {
    private lazy var btnPhoto: UIButton = {
        let btn = UIButton.init()
        btn.layer.cornerRadius = 8
        btn.clipsToBounds = true
        btn.setImage(UIImage.init(named: "iconIconPictureFill"), for: .normal)
        btn.setBackgroundColor(color: Theme.c_07_neutral_100.rawValue.toColor(), forState: .normal)
        btn.setBackgroundColor(color: Theme.c_07_neutral_200.rawValue.toColor(), forState: .highlighted)
        btn.setBackgroundColor(color: Theme.c_07_neutral_200.rawValue.toColor(), forState: .selected)
        return btn
    }()
    
    private lazy var btnCamera: UIButton = {
        let btn = UIButton.init()
        btn.layer.cornerRadius = 8
        btn.clipsToBounds = true
        btn.setImage(UIImage.init(named: "iconIconPhotFill"), for: .normal)
        btn.setBackgroundColor(color: Theme.c_07_neutral_100.rawValue.toColor(), forState: .normal)
        btn.setBackgroundColor(color: Theme.c_07_neutral_200.rawValue.toColor(), forState: .highlighted)
        btn.setBackgroundColor(color: Theme.c_07_neutral_200.rawValue.toColor(), forState: .selected)
        return btn
    }()
    
    private lazy var lblPhoto: UILabel = {
        let lbl = UILabel.init()
        lbl.theme_textColor = Theme.c_10_grand_2.rawValue
        lbl.text = Localizable.photos
        lbl.font = .midiumParagraphSmallLeft
        return lbl
    }()
    
    private lazy var lblCamera: UILabel = {
        let lbl = UILabel.init()
        lbl.theme_textColor = Theme.c_10_grand_2.rawValue
        lbl.text = Localizable.shoot
        lbl.font = .midiumParagraphSmallLeft
        return lbl
    }()
    
    override func setupViews() {
        super.setupViews()
        
        self.addSubview(self.btnPhoto)
        self.addSubview(self.btnCamera)
        self.addSubview(self.lblPhoto)
        self.addSubview(self.lblCamera)
        
        self.btnPhoto.snp.makeConstraints { make in
            make.trailing.equalTo(self.snp.centerX).offset(-39)
            make.height.width.equalTo(64)
            make.top.equalToSuperview().offset(8)
        }
        
        self.btnCamera.snp.makeConstraints { make in
            make.leading.equalTo(self.snp.centerX).offset(39)
            make.height.width.centerY.equalTo(self.btnPhoto)
        }
        
        self.lblPhoto.snp.makeConstraints { make in
            make.top.equalTo(self.btnPhoto.snp.bottom).offset(4)
            make.centerX.equalTo(self.btnPhoto)
        }
        
        self.lblCamera.snp.makeConstraints { make in
            make.top.equalTo(self.btnCamera.snp.bottom).offset(4)
            make.centerX.equalTo(self.btnCamera)
        }
    }
    
    override func bindViewModel() {
        super.bindViewModel()
        self.btnPhoto.rx.controlEvent(.touchUpInside).throttle(.microseconds(500), scheduler: MainScheduler.instance).bind(to: self.viewModel.input.photo).disposed(by: self.disposeBag)
        self.btnCamera.rx.controlEvent(.touchUpInside).throttle(.microseconds(500), scheduler: MainScheduler.instance).bind(to: self.viewModel.input.camera).disposed(by: self.disposeBag)
    }
}
