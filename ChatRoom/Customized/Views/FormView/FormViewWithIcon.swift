//
//  FormViewWithIcon.swift
//  LotBase
//
//  Created by saffi_peng on 2020/12/21.
//  Copyright © 2020 Paridise-Soft. All rights reserved.
//

import RxSwift
import RxCocoa

#warning("Has to modify as Chat style")
class FormViewWithIcon: UIView {

    private var disposeBag = DisposeBag()

    let isPass: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    var textType: TextType?
    var diagramImage: UIImage? {
        get { return diagram.image ?? nil }
        set {
            diagram.image = newValue
        }
    }
    lazy var placeholder: String = {
        return txtInput.placeholder ?? ""
    }()
    var defaultContent: String = ""
    var content: String {
        get { return txtInput.text ?? "" }
        set {
            txtInput.text = newValue
            txtInput.sendActions(for: .valueChanged)
        }
    }
//    var textColor: UIColor = .brandColorTertiaryDesaturation {
//        didSet {
//            if oldValue != self.textColor {
//                txtInput.textColor = self.textColor
//            }
//        }
//    }
    var warningText: String {
        get { return lblWarning.text ?? "" }
        set {
            lblWarning.text = newValue
        }
    }
    var confirmTo: UITextField?
    var validateType: String.ValidateType?
    var keyboardType: UIKeyboardType {
        get { return txtInput.keyboardType }
        set {
            txtInput.keyboardType = newValue
        }
    }
    var isPassword: Bool = false
    var isSecureText: Bool = false {
        didSet {
            txtInput.isSecureTextEntry = self.isSecureText
            btnEye.isHidden = !self.isSecureText
            btnEye.isUserInteractionEnabled = self.isSecureText
        }
    }
    var maxLength: Int = 0

    lazy var diagram: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFit
//        image.tintColor = .brandColorTertiaryDesaturation
        return image
    }()

    lazy var txtInput: UITextField = {
        let t = UITextField()
        t.borderStyle = .none
        t.backgroundColor = .clear
//        t.font = .cRegularSize14Left
//        t.textColor = .brandColorTertiaryDesaturation
        t.delegate = self
        if #available(iOS 12, *) {
            t.textContentType = .oneTimeCode
        } else {
            t.textContentType = .init(rawValue: "")
        }
        return t
    }()

    lazy var closeButton: UIButton = {
        let b = UIButton()
//        b.setImage(UIImage(name: "icon_input_close"), for: .normal)
//        b.tintColor = .brandColorTertiaryDesaturation
        return b
    }()

    lazy var btnEye: UIButton = {
        let b = UIButton()
//        b.setImage(UIImage(name: "icon_eye_off"), for: .normal)
//        b.tintColor = .brandColorTertiaryDesaturation
        return b
    }()

    lazy var bottomLine: UIView = {
        let view = UIView()
//        view.backgroundColor = .brandColorTertiaryTertiaryOpac_2
        return view
    }()

    lazy var warningView = UIView()

//    lazy var warningImage: UIImageView = {
//        let i = UIImageView(image: UIImage(name: "icon_mistake"))
//        i.contentMode = .scaleAspectFit
//        i.sizeThatFits(CGSize(width: 10, height: 10))
//        return i
//    }()

    lazy var lblWarning: UILabel = {
        let l = UILabel()
        l.backgroundColor = .clear
//        l.font = .cRegularSize12Left
//        l.textColor = .brandColorDangerDefault
        return l
    }()

    var onClicked: () -> Void = {}

    var isFirstTimeFocused = false
    var toResetCursor: Bool = false
    var cursorPos: UITextPosition?

    private var isOnFocused: BehaviorRelay<Bool> = BehaviorRelay(value: false)

    func config(textType: TextType, diagram: UIImage? = nil, placeholder: String = "", content: String = "", warningText: String = "", confirmTo: UITextField? = nil, validateType: String.ValidateType? = nil, keyboardType: UIKeyboardType = .default, isSecureText: Bool = false, maxLength: Int = 0) {
        self.textType = textType
        self.diagramImage = diagram
        self.placeholder = placeholder
        self.content = content
        self.defaultContent = content
        self.confirmTo = confirmTo
        self.warningText = warningText
        self.validateType = validateType
        self.keyboardType = keyboardType
        self.isPassword = isSecureText
        self.isSecureText = isSecureText
        self.maxLength = maxLength
        setupViews()
        initBinding()
    }

    func setupViews() {
        self.backgroundColor = .clear
        self.clipsToBounds = true

        self.rx.click.subscribeSuccess { [unowned self] in
            self.onClicked()
            self.txtInput.becomeFirstResponder()
        }.disposed(by: disposeBag)

        self.addSubviews([diagram, txtInput, closeButton, btnEye, bottomLine, warningView])

        diagram.snp.makeConstraints { (make) in
            make.top.leading.equalToSuperview().offset(8)
            make.bottom.equalToSuperview().offset(-24)
            make.width.height.equalTo(24)
        }

        txtInput.snp.makeConstraints { (make) in
            make.centerY.equalTo(diagram)
            make.leading.equalTo(diagram.snp.trailing).offset(8)
            make.trailing.equalTo(closeButton.snp.leading).offset(-14)
            make.height.equalTo(15)
        }

        closeButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(diagram)
            make.trailing.equalToSuperview().offset(-8)
            make.width.equalTo(0)
            make.height.equalTo(24)
        }
        closeButton.rx.tap.subscribeSuccess { [unowned self] in
            self.content = ""
        }.disposed(by: disposeBag)

        btnEye.snp.makeConstraints { (make) in
            make.centerY.equalTo(diagram)
            make.trailing.equalTo(closeButton.snp.leading).offset(-8)
            make.width.height.equalTo(24)
        }
        btnEye.rx.tap.subscribeSuccess { [unowned self] in
            self.txtInput.isSecureTextEntry.toggle()
//            let image = self.txtInput.isSecureTextEntry ? UIImage(name: "icon_eye_off") : UIImage(name: "icon_eye")
//            self.btnEye.setImage(image, for: .normal)
        }.disposed(by: disposeBag)

        bottomLine.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(-16)
            make.height.equalTo(1)
        }

        warningView.backgroundColor = .clear
        warningView.snp.makeConstraints { (make) in
            make.top.equalTo(bottomLine.snp.bottom).offset(4)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(12)
        }

//        warningView.addSubviews([warningImage, lblWarning])
//
//        warningImage.snp.makeConstraints { (make) in
//            make.leading.equalToSuperview()
//            make.top.equalToSuperview()
//            make.width.height.equalTo(12)
//        }
//
//        lblWarning.snp.makeConstraints { (make) in
//            make.leading.equalTo(warningImage.snp.trailing).offset(4)
//            make.centerY.equalTo(warningImage)
//            make.height.equalTo(12)
//        }
    }

    func initBinding() {
        isOnFocused.subscribeSuccess { [unowned self] (focused) in
            self.resetView()

            if focused {
                self.setWarningText(isShow: true)
                if !isFirstTimeFocused {
                    isFirstTimeFocused = true
                }
            } else {
                if !isFirstTimeFocused, (self.content.isEmpty || self.content == self.defaultContent) {
                    // 第一次開啟不顯示warning text
                    self.setWarningText(isShow: false)
                } else {
                    self.setWarningText(isShow: !self.isPass.value)
                }
            }
        }.disposed(by: disposeBag)

        txtInput.rx.text.subscribeSuccess { [unowned self] (text) in
            guard text != nil else { return }
            self.validate()
        }.disposed(by: disposeBag)

        confirmTo?.rx.text.subscribeSuccess { [unowned self] (text) in
            guard text != nil else { return }
            self.validateConfirm()
        }.disposed(by: disposeBag)

        isPass.subscribeSuccess { [unowned self] (passed) in
//            self.warningImage.image = passed ? UIImage(name: "icon_success") : UIImage(name: "icon_mistake")
//
//            let color: UIColor = passed ? .brandColorTertiaryDesaturation : .brandColorDangerDefault
//            self.lblWarning.textColor = color
//            self.warningImage.tintColor = color

            if let tt = self.textType, tt == .amount, let vt = self.validateType, vt == .vtNone {
                // for: 點擊Amount快捷鍵輸入金額的情況(因未focus所以warningView高度會被設為0)
                if !self.isOnFocused.value, !self.content.isEmpty {
                    self.setWarningText(isShow: !passed)
                }
            }
        }.disposed(by: disposeBag)
    }

    func validate() {
        if let confirmText = confirmTo?.text {
            isPass.accept(txtInput.text == confirmText)
        } else if content.isEmpty {
            isPass.accept(false)
        } else if let vt = validateType {
            if vt == .vtNone {
                // 若 validateType = none && textType = amount/amountInt，則首位數字為 0 時判定為錯誤
                if let textType = self.textType, (textType == .amount || textType == .amountInt), let number = Double(content), number <= 0 {
                    isPass.accept(false)
                } else {
                    isPass.accept(true)
                }
            } else if vt == .vtWeChat {
                // Wechat增加特殊檢查條件：符合6-20全數字也pass
                isPass.accept(content.isValidate(type: vt))
            } else if vt == .vtAccount {
                // Account增加特殊檢查條件：符合11全數字也pass
                isPass.accept(content.isValidate(type: vt) || content.isValidate(type: .vtAccountSpecial))
            } else {
                isPass.accept(content.isValidate(type: vt))
            }
        } else {
            isPass.accept(true)
        }
    }

    func validateConfirm() {
        if let confirmText = confirmTo?.text, confirmText.count > 0 {
            isPass.accept(txtInput.text == confirmText)
        }
    }

    private func setWarningText(isShow: Bool) {
        guard !warningText.isEmpty else {
            self.warningView.isHidden = true
            return
        }
        self.warningView.isHidden = !isShow
    }

    func setToDefault() {
        self.isFirstTimeFocused = false
        self.content = self.defaultContent
        self.txtInput.isSecureTextEntry = self.isSecureText
        self.setWarningText(isShow: false)
        resetView()
    }

    private func resetView() {
        btnEye.isHidden = !isPassword
//        let image = self.txtInput.isSecureTextEntry ? UIImage(name: "icon_eye_off") : UIImage(name: "icon_eye")
        btnEye.isUserInteractionEnabled = true
//        btnEye.setImage(image, for: .normal)
    }
}

extension FormViewWithIcon: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // 數字鍵盤時不允許貼上含字母文字
        if string.count > 1, (self.keyboardType == .numberPad || self.keyboardType == .decimalPad) {
            return (string.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil)
        }

        // 自動替換文字＆return false的情況不會trigger `txtInput.rx.text`，所以替換文字後會trigger textField 的 `Event.valueChanged`
        // (若return true，反而會保留前一次輸入的字元(不符合需求))
        if self.textType == .amount {
            switch string {
            case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ".", "":
                guard let newString = (textField.text as NSString?)?.replacingCharacters(in: range, with: string) else { return false }
                if textField.text == "0" && string != "." {
                    textField.text = string
                    textField.sendActions(for: .valueChanged)
                    return false
                }
                if newString.prefix(1) == "0" && newString.count > 2 && newString.prefix(2) != "0." {
                    return false
                }
                if string == "." {
                    if textField.text?.contains(".") == true {
                        return false
                    }
                    if textField.text?.count == 0 {
                        textField.text = "0."
                        textField.sendActions(for: .valueChanged)
                        return false
                    }
                }
                if !newString.contains(".") {
                    if newString.count > 9 {
                        return false
                    }
                    return true
                }
                if let fromIndex = newString.lastIndex(of: "."),
                   let toIndex = newString.lastIndex(of: newString.last ?? Character("")),
                   newString.distance(from: fromIndex, to: toIndex) > 2 {
                    return false
                }
                return true
            default:
                return false
            }
        }

        if self.textType == .amountInt {
            switch string {
            case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "":
                if textField.text == "0" {
                    textField.text = string
                    textField.sendActions(for: .valueChanged)
                    return false
                }
                let newString = (textField.text as NSString?)?.replacingCharacters(in: range, with: string)
                if newString?.prefix(1) == "0" && newString?.count ?? 0 > 1 {
                    return false
                }
                if newString?.count ?? 0 > 9 {
                    return false
                }
                return true
            default:
                return false
            }
        }

        if self.textType == .bankCardNo {
            var isBackSpace = false
            let text = textField.text ?? ""

            if let char = string.cString(using: String.Encoding.utf8) {
                if strcmp(char, "\\b") == -92 {
                    self.toResetCursor = true
                    isBackSpace = true
                } else {
                    let post = text[range.location..<text.count]
                    self.toResetCursor = !post.isEmpty
                }
            }

            let newText = text.replacingOccurrences(of: " ", with: "")
            if newText.count >= self.maxLength && !isBackSpace {
                return false
            }

            if let selectedRange = textField.selectedTextRange {
                let index = textField.offset(from: textField.beginningOfDocument, to: selectedRange.start)
                let increase = index == 4 || index == 9 || index == 14 || index == 19 ? 2 : 1
                if self.toResetCursor {
                    self.cursorPos = textField.position(from: selectedRange.start, offset: isBackSpace ? -1 : increase)
                }
            }
            return true
        }

        var flag = true
        if string.isEmpty {
            return flag
        }
        if self.maxLength > 0 {
            let newString = (textField.text as NSString?)?.replacingCharacters(in: range, with: string)
            flag = newString?.count ?? 0 <= self.maxLength
        }

        return flag
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.isOnFocused.accept(true)

        txtInput.snp.remakeConstraints { (make) in
            make.centerY.equalTo(diagram)
            make.leading.equalTo(diagram.snp.trailing).offset(8)
            make.trailing.equalTo(btnEye.snp.leading).offset(-14)
            make.height.equalTo(15)
        }

        closeButton.snp.remakeConstraints { (make) in
            make.centerY.equalTo(diagram)
            make.trailing.equalToSuperview().offset(-16)
            make.width.height.equalTo(24)
        }
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        self.isOnFocused.accept(false)

        txtInput.snp.remakeConstraints { (make) in
            make.centerY.equalTo(diagram)
            make.leading.equalTo(diagram.snp.trailing).offset(8)
            make.trailing.equalTo(closeButton.snp.leading).offset(-14)
            make.height.equalTo(15)
        }

        closeButton.snp.remakeConstraints { (make) in
            make.centerY.equalTo(diagram)
            make.trailing.equalToSuperview().offset(-8)
            make.width.equalTo(0)
        }
    }
}
