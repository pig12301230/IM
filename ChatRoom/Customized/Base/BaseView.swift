//
//  BaseView.swift
//  LotBase
//
//  Created by george_tseng on 2020/5/28.
//  Copyright © 2020 Paridise-Soft. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

public class BaseView: UIView {
    
    let disposeBag = DisposeBag()

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonSetting()
        setupViews()
        initBinding()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        commonSetting()
        setupViews()
        initBinding()
    }
    
    private func commonSetting() {
        
    }
    
    func setupViews() {}
    func initBinding() {}
}
