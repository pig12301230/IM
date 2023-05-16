//
//  FormInputView.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/4/15.
//

import UIKit

class FormInputView<T: FormInputViewModel>: BaseViewModelView<T> {
    lazy var inputTextField: DesignableUITextField = {
        let textField = DesignableUITextField.init()
        return textField
    }()
    
    private lazy var hintView: UIView = {
        let view = UIView.init()
        return view
    }()
    
    private lazy var lblHint: UILabel = {
        let lbl = UILabel.init()
        lbl.font = .regular(12)
        return lbl
    }()
    
    private lazy var hintImageView: UIImageView = {
        let imageView = UIImageView.init()
        return imageView
    }()
    
    // MARK: - override function
    override func updateViews() {
        super.updateViews()
        
        self.snp.makeConstraints { (make) in
            make.height.equalTo(self.viewModel.totalViewHeight())
        }
        
        self.addSubview(self.inputTextField)
        self.addSubview(self.hintView)
        
        self.inputTextField.snp.makeConstraints { (make) in
            make.leading.top.equalToSuperview().offset(self.viewModel.edge)
            make.trailing.equalToSuperview().offset(-self.viewModel.edge)
            make.height.equalTo(self.viewModel.textFieldHeight)
        }
        
        self.hintView.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(self.viewModel.edge)
            make.trailing.equalToSuperview().offset(-self.viewModel.edge)
            make.top.equalTo(self.inputTextField.snp.bottom)
            make.bottom.equalToSuperview().offset(-self.viewModel.edge)
            make.height.equalTo(self.viewModel.hintViewHeight)
        }
        
        self.setupHintView()
        
        self.inputTextField.placeholder = self.viewModel.config.placeholder
        self.inputTextField.clearButtonMode = self.viewModel.config.clearButtonMode
    }
    
    override func bindViewModel() {
        super.bindViewModel()
        
        self.viewModel.updateHintViewSetting.subscribeSuccess { [unowned self] (_) in
            self.updateHintSetting(self.viewModel.hintConfig)
        }.disposed(by: self.disposeBag)
        
        self.inputTextField.rx.text.bind(to: self.viewModel.inputText).disposed(by: self.disposeBag)
        self.viewModel.inputBorderColor.bind(to: self.inputTextField.layer.rx.borderColor).disposed(by: self.disposeBag)
        self.viewModel.inputViewBGColor.bind(to: self.inputTextField.rx.backgroundColor).disposed(by: self.disposeBag)
        self.viewModel.hintViewText.bind(to: self.lblHint.rx.text).disposed(by: self.disposeBag)
    }
}

private extension FormInputView {
    func setupHintView() {
        self.hintView.addSubview(self.hintImageView)
        self.hintView.addSubview(self.lblHint)
        
        guard self.viewModel.keepLeft else {
            self.setupHintViewKeepRight()
            return
        }
        
        self.setupHintViewKeepLeft()
    }
    
    func setupHintViewKeepRight() {
        self.lblHint.textAlignment = .natural
        
        self.lblHint.snp.remakeConstraints { (make) in
            make.top.equalToSuperview().offset(8)
            make.bottom.trailing.equalToSuperview()
        }
        
        self.hintImageView.snp.remakeConstraints { (make) in
            make.height.width.equalTo(12)
            make.centerY.equalTo(self.lblHint)
            make.trailing.equalTo(self.lblHint.snp.leading).offset(-8)
            make.bottom.leading.equalToSuperview()
        }
    }
    
    func setupHintViewKeepLeft() {        
        self.lblHint.textAlignment = .left
        
        self.hintImageView.snp.remakeConstraints { (make) in
            make.height.width.equalTo(12)
            make.centerY.equalTo(self.lblHint)
            make.leading.equalToSuperview()
        }
        
        self.lblHint.snp.remakeConstraints { (make) in
            make.top.equalToSuperview()
            make.leading.equalTo(self.hintImageView.snp.trailing)
            make.bottom.trailing.equalToSuperview()
        }
    }
    
    func updateHintSetting(_ config: FormInputViewModel.HintViewConfig) {
        self.setupHintViewHidden(config.hidden)
        self.hintImageView.image = config.image
        self.lblHint.textColor = config.textColor
    }
    
    func setupHintViewHidden(_ isHidden: Bool) {
        self.hintView.isHidden = isHidden
        
        self.snp.updateConstraints { (make) in
            make.height.equalTo(self.viewModel.totalViewHeight())
        }
        
        self.hintView.snp.updateConstraints { (make) in
            make.height.equalTo(self.viewModel.hintViewHeight)
        }
    }
}
