//
//  TitleInputView.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/4/22.
//

import UIKit
import SwiftTheme

class TitleInputView<T: TitleInputViewModel>: BaseViewModelView<T>, UITextFieldDelegate {
    private(set) lazy var lblTitle: UILabel = {
        let lbl = UILabel.init()
        lbl.textAlignment = .left
        lbl.font = .midiumParagraphLargeLeft
        lbl.theme_textColor = Theme.c_10_grand_1.rawValue
        return lbl
    }()
    
    private(set) lazy var inputTextField: DesignableUITextField = {
        let textField = DesignableUITextField.init()
        textField.delegate = self
        textField.font = .regularParagraphLargeLeft
        textField.smartInsertDeleteType = .no
        textField.theme_textColor = Theme.c_10_grand_1.rawValue
        textField.theme_placeholderAttributes = ThemeStringAttributesPicker([.foregroundColor: Theme.c_07_neutral_400.rawValue.toColor(),
                                                                             .font: UIFont.regularParagraphLargeLeft])
        textField.textContentType = .oneTimeCode
        return textField
    }()
    
    private(set) lazy var separatorView: UIView = {
        let view = UIView.init()
        view.theme_backgroundColor = Theme.c_07_neutral_100.rawValue
        return view
    }()
    
    private(set) lazy var btnStatus: UIButton = {
        let btn = UIButton.init(type: .custom)
        btn.titleLabel?.adjustsFontSizeToFitWidth = true
        btn.titleLabel?.numberOfLines = 2
        btn.theme_tintColor = Theme.c_07_neutral_800.rawValue
        return btn
    }()
    
    internal let tapGesture = UITapGestureRecognizer()
    
    override func setupViews() {
        super.setupViews()
        self.addSubview(self.lblTitle)
        self.addSubview(self.inputTextField)
        self.addSubview(self.btnStatus)
        self.addSubview(self.separatorView)        
        
        self.lblTitle.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(0)
            make.top.equalToSuperview().offset(12)
            make.height.equalTo(24)
            make.width.equalTo(0)
        }
        
        self.inputTextField.snp.makeConstraints { (make) in
            make.leading.equalTo(self.lblTitle.snp.trailing).offset(16)
            make.centerY.equalTo(self.lblTitle)
        }
        
        self.btnStatus.snp.makeConstraints { (make) in
            make.leading.equalTo(self.inputTextField.snp.trailing).offset(8)
            make.height.width.equalTo(24)
            make.centerY.equalTo(self.inputTextField)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        self.setupSeparatorView()
        
        self.addGestureRecognizer(self.tapGesture)
    }
    
    override func bindViewModel() {
        super.bindViewModel()
        
        self.tapGesture.rx.event.subscribeSuccess { [unowned self] _ in
            self.viewModel.touchInputAction.onNext(())
        }.disposed(by: self.disposeBag)
        
        self.viewModel.typeTitle.bind(to: self.lblTitle.rx.text).disposed(by: self.disposeBag)
        self.viewModel.statusImage.bind(to: self.btnStatus.rx.backgroundImage()).disposed(by: self.disposeBag)
        self.viewModel.inputBorderColor.bind(to: self.inputTextField.layer.rx.borderColor).disposed(by: self.disposeBag)
        self.viewModel.inputViewBGColor.bind(to: self.inputTextField.rx.backgroundColor).disposed(by: self.disposeBag)
        self.viewModel.input.inputEnable.bind(to: self.inputTextField.rx.isEnabled).disposed(by: self.disposeBag)
        self.viewModel.outputText.bind(to: self.inputTextField.rx.text).disposed(by: self.disposeBag)
        self.inputTextField.rx.text.bind(to: self.viewModel.inputText).disposed(by: self.disposeBag)
        self.inputTextField.rx.text.subscribeSuccess { [weak self] newString in
            guard let self = self, let newString = newString else { return }
            if self.viewModel.config.needKerning {
                let kern = self.inputTextField.frame.width / 7
                let string = NSMutableAttributedString(string: newString)
                let kernLength = string.length > 0 ? string.length - 1 : 0
                string.addAttribute(NSAttributedString.Key.kern, value: kern, range: NSRange(location: 0, length: kernLength))
                self.inputTextField.attributedText = string
            }
        }.disposed(by: self.disposeBag)
        self.viewModel.interactionEnabled.bind(to: self.rx.isUserInteractionEnabled).disposed(by: self.disposeBag)
    }
    
    override func updateViews() {
        super.updateViews()
        self.viewModel.inputText.accept(self.viewModel.config.defaultString)
        self.inputTextField.text = self.viewModel.config.defaultString
        self.inputTextField.keyboardType = self.viewModel.config.keyboardType
        self.inputTextField.placeholder = self.viewModel.config.placeholder
        self.inputTextField.clearButtonMode = self.viewModel.config.clearButtonMode
        self.inputTextField.font = viewModel.inputTextFont
        
        guard self.viewModel.showTitle else {
            return
        }
        
        self.lblTitle.snp.remakeConstraints { (make) in
            make.leading.equalToSuperview().offset(8)
            make.top.equalToSuperview().offset(12)
            make.height.equalTo(24)
            make.width.equalTo(96)
        }
    }
    
    func setupSeparatorView() {
        self.separatorView.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(1)
            make.top.equalTo(self.lblTitle.snp.bottom).offset(12)
            make.bottom.equalToSuperview()
        }
    }
    
    func setupStatusImageView() {
        self.btnStatus.snp.remakeConstraints { (make) in
            make.leading.equalTo(self.inputTextField.snp.trailing).offset(8)
            make.height.equalTo(24)
            make.width.equalTo(0)
            make.centerY.equalTo(self.inputTextField)
            make.trailing.equalToSuperview().offset(-8)
        }
    }
    
    // Delegate
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let max = viewModel.maxInputLength, let count = textField.text?.count  else {
            return true
        }

        guard count < max else {
            // 如果輸入的是刪除鍵, 就不能用原本的判定
            if string == "" {
                return true
            }
            return false
        }
        
        return true
    }
}
