//
//  MultipleRulesInputView.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/4/20.
//

import UIKit

class MultipleRulesInputView<T: MultipleRulesInputViewModel>: TitleInputView<T> {
    
    private lazy var hintsView: UIView = {
        let tView = UIView.init()
        tView.isHidden = true
        return tView
    }()
    
    private lazy var btnSecurity: UIButton = {
        let btn = UIButton.init()
        return btn
    }()
    
    override func setupViews() {
        super.setupViews()
        self.addSubview(self.hintsView)
        
        self.hintsView.snp.makeConstraints { (make) in
            make.leading.trailing.equalTo(self.separatorView)
            make.top.equalTo(self.separatorView)
            make.height.equalTo(0)
            make.bottom.equalToSuperview()
        }
    }
    
    override func setupSeparatorView() {
        self.separatorView.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(1)
            make.top.equalTo(self.lblTitle.snp.bottom).offset(12)
        }
    }
    
    override func updateViews() {
        super.updateViews()
        
        if self.viewModel.needSecurity {
            self.setupViewWithSecurity()
        } else {
            self.setupStatusImageView()
        }
        
        self.setupHintsView()
    }
    
    override func bindViewModel() {
        super.bindViewModel()
        
        self.btnSecurity.rx.controlEvent(.touchUpInside).bind(to: self.viewModel.changeSecurity).disposed(by: self.disposeBag)
        self.viewModel.securityImage.bind(to: self.btnSecurity.rx.backgroundImage()).disposed(by: self.disposeBag)
        self.viewModel.isSecurity.bind(to: self.inputTextField.rx.isSecureTextEntry).disposed(by: self.disposeBag)
        
        self.inputTextField.rx.controlEvent(.editingDidBegin).subscribeSuccess { [unowned self] (_) in
            self.updateHintsView(isEditing: true)
        }.disposed(by: self.disposeBag)
        
        self.inputTextField.rx.controlEvent(.editingDidEnd).subscribeSuccess { [unowned self] (_) in
            self.updateHintsView(isEditing: false)
        }.disposed(by: self.disposeBag)
        
        self.viewModel.output.correct.distinctUntilChanged().subscribeSuccess { [unowned self] (_) in
            guard !self.inputTextField.isEditing else {
                return
            }
            self.updateHintsView(isEditing: false)
        }.disposed(by: self.disposeBag)
    }
}

private extension MultipleRulesInputView {
    func setupViewWithSecurity() {
        self.addSubview(self.btnSecurity)
        self.btnSecurity.snp.remakeConstraints { (make) in
            make.height.width.equalTo(24)
            make.leading.equalTo(self.inputTextField.snp.trailing).offset(8)
            make.centerY.equalTo(self.inputTextField)
            if !self.viewModel.canCheckSecurity {
                make.leading.equalTo(self.inputTextField.snp.trailing)
                make.width.equalTo(0)
            }
        }
        
        self.btnStatus.snp.remakeConstraints { (make) in
            make.leading.equalTo(self.btnSecurity.snp.trailing).offset(8)
            make.height.equalTo(24)
            make.width.equalTo(0)
            make.centerY.equalTo(self.btnSecurity)
            make.trailing.equalToSuperview().offset(-8)
        }
    }
    
    func setupHintsView() {
        var preView: UIView?
        
        for (index, vm) in self.viewModel.hintVMs.enumerated() {
            let view = HintView.init(with: vm)
            self.hintsView.addSubview(view)
            if index == 0 {
                view.snp.makeConstraints { (make) in
                    make.top.equalToSuperview().offset(8)
                }
            } else if let pView = preView {
                view.snp.makeConstraints { (make) in
                    make.top.equalTo(pView.snp.bottom)
                }
            }
            
            view.snp.makeConstraints { (make) in
                make.leading.equalToSuperview().offset(16)
                make.trailing.equalToSuperview().offset(-16)
            }
            
            if index == self.viewModel.hintVMs.count - 1 {
                view.snp.makeConstraints { (make) in
                    make.bottom.equalToSuperview().offset(-8)
                }
            }
            preView = view
        }
    }    
    
    func updateHintsView(isEditing: Bool) {
        
        if self.viewModel.needCheck && !isEditing {
            self.btnStatus.snp.updateConstraints { (make) in
                make.width.equalTo(24)
                make.trailing.equalToSuperview().offset(-16)
            }
        } else {
            self.btnStatus.snp.updateConstraints { (make) in
                make.width.equalTo(0)
                make.trailing.equalToSuperview().offset(-8)
            }
        }
        
        guard self.viewModel.showHint else {
            return
        }
        
        self.hintsView.isHidden = !isEditing
        let height = isEditing ? self.viewModel.hintViewHeight : 0
        self.hintsView.snp.updateConstraints { (make) in
            make.height.equalTo(height)
        }
    }
}
