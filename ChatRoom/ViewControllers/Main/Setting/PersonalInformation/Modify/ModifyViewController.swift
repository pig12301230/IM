//
//  ModifyViewController.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/7/1.
//

import UIKit
import RxSwift

class ModifyViewController: BaseVC {
    
    var viewModel: ModifyViewControllerVM!
    
    private lazy var lblCount: UILabel = {
        let lbl = UILabel()
        lbl.font = .regularParagraphMediumLeft
        lbl.theme_textColor = Theme.c_07_neutral_400.rawValue
        lbl.textAlignment = .right
        return lbl
    }()
    
    private lazy var inputRuleView: MultipleRulesInputView = {
        let iView = MultipleRulesInputView.init(with: self.viewModel.inputVM)
        return iView
    }()
    
    private lazy var btnSubmin: UIButton = {
        let btn = UIButton.init()
        btn.layer.cornerRadius = 4
        btn.theme_backgroundColor = Theme.c_07_neutral_200.rawValue
        btn.theme_setTitleColor(Theme.c_09_white.rawValue, forState: .normal)
        btn.setTitle(Localizable.done, for: .normal)
        btn.titleLabel?.font = .boldParagraphMediumLeft
        return btn
    }()
    
    static func initVC(with vm: ModifyViewControllerVM) -> ModifyViewController {
        let vc = ModifyViewController.init()
        vc.barType = .default
        vc.viewModel = vm
        vc.title = vm.modifyType.title
        return vc
    }
    
    override func setupViews() {
        super.setupViews()
        
        self.view.theme_backgroundColor = Theme.c_07_neutral_50.rawValue
        self.view.addSubview(self.lblCount)
        self.view.addSubview(self.inputRuleView)
        self.view.addSubview(self.btnSubmin)
        
        self.lblCount.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.top.equalToSuperview().offset(16)
        }
        
        self.inputRuleView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self.lblCount)
            make.top.equalTo(self.lblCount.snp.bottom)
        }
        
        self.btnSubmin.snp.makeConstraints { (make) in
            make.top.equalTo(self.inputRuleView.snp.bottom).offset(32)
            make.leading.trailing.equalTo(self.inputRuleView)
            make.height.equalTo(48)
        }
    }
    
    override func initBinding() {
        super.initBinding()
        
        self.btnSubmin.rx.controlEvent(.touchUpInside).bind(to: self.viewModel.submitModify).disposed(by: self.disposeBag)
        
        self.viewModel.inputCount.bind(to: self.lblCount.rx.text).disposed(by: self.disposeBag)
        self.viewModel.submitEnable.distinctUntilChanged().subscribeSuccess { [unowned self] enable in
            self.btnSubmin.isEnabled = enable
            self.btnSubmin.theme_backgroundColor = enable ? Theme.c_01_primary_400.rawValue : Theme.c_07_neutral_200.rawValue
        }.disposed(by: self.disposeBag)
        
        self.viewModel.goBack.observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] _ in
            self.popViewController()
        }.disposed(by: self.disposeBag)
        
        self.viewModel.showLoading.observe(on: MainScheduler.instance).subscribeSuccess { isShow in
            isShow ? LoadingView.shared.show() : LoadingView.shared.hide()
        }.disposed(by: self.disposeBag)
    }
}
