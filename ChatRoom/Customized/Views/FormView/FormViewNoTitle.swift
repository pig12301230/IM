//
//  FormViewNoTitle.swift
//  LotBase
//
//  Created by saffi_peng on 2020/12/14.
//  Copyright © 2020 Paridise-Soft. All rights reserved.
//

import RxCocoa
import RxSwift

#warning("Has to modify as Chat style")
class FormViewNoTitle: UIView {

    struct FormViewNoTitleDefault {
//        var borderColor = UIColor.brandColorNormalDisable.cgColor
        var borderWidth: CGFloat = 0
        var cornerRadius: CGFloat = 9
    }

    private var disposeBag = DisposeBag()
    var isEabled: Bool = true {
        didSet {
            if oldValue == isEabled { return }
            setEnabled(isEabled)
        }
    }
    let isPass: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    var layoutDefault: FormViewNoTitleDefault = FormViewNoTitleDefault() {
        didSet {
            self.bgView.layer.cornerRadius = layoutDefault.cornerRadius
//            self.bgView.layer.borderColor = layoutDefault.borderColor
            self.bgView.layer.borderWidth = layoutDefault.borderWidth
        }
    }

    var textType: TextType?
    lazy var placeholder: String = {
        txtInput.placeholder ?? ""
    }()
    var defaultContent: String = ""
    var content: String {
        get { return txtInput.text ?? "" }
        set {
            txtInput.text = newValue
            txtInput.sendActions(for: .valueChanged)
        }
    }
    var warningText: String {
        get { return lblWarning.text ?? "" }
        set {
            lblWarning.text = newValue
        }
    }
    var confirmTo: UITextField?
    var isDropDownMenu: Bool = false {
        didSet {
            txtInput.isUserInteractionEnabled = !isDropDownMenu
            if isDropDownMenu {
//                button.setImage(UIImage(name: "icon_picker_down"), for: .normal)
//                button.tintColor = .brandColorTertiarySaturation
            }
            button.isUserInteractionEnabled = !isDropDownMenu
        }
    }
    var validateType: String.ValidateType?
    var keyboardType: UIKeyboardType {
        get { return txtInput.keyboardType }
        set {
            txtInput.keyboardType = newValue
        }
    }
    var isPassword: Bool = false
    var isSecureText: Bool {
        get { return txtInput.isSecureTextEntry }
        set {
            txtInput.isSecureTextEntry = newValue
            btnEye.isHidden = !newValue
            btnEye.isUserInteractionEnabled = newValue
        }
    }
    var maxLength: Int = 0

    lazy var bgView = UIView()
    lazy var warningView = UIView()

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

    lazy var lblWarning: UILabel = {
        let l = UILabel()
        l.backgroundColor = .clear
//        l.font = .cRegularSize12Left
//        l.textColor = .brandColorDangerDefault
        return l
    }()

    lazy var button: UIButton = {
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

//    lazy var imageView: UIImageView = {
//        let i = UIImageView(image: UIImage(name: "icon_mistake"))
//        i.contentMode = .scaleAspectFit
//        i.sizeThatFits(CGSize(width: 10, height: 10))
//        return i
//    }()

    var onClicked: () -> Void = {}

    var isFirstTimeFocused = false
    var toResetCursor: Bool = false
    var cursorPos: UITextPosition?

    private var isOnFocused: BehaviorRelay<Bool> = BehaviorRelay(value: false)

    func config(textType: TextType, placeholder: String = "", content: String = "", warningText: String = "", confirmTo: UITextField? = nil, isDropDownMenu: Bool = false, validateType: String.ValidateType? = nil, keyboardType: UIKeyboardType = .default, isSecureText: Bool = false, isEabled: Bool = true, maxLength: Int = 0) {
        self.textType = textType
        self.placeholder = placeholder
        self.content = content
        self.defaultContent = content
        self.confirmTo = confirmTo
        self.warningText = warningText
        self.isDropDownMenu = isDropDownMenu
        self.validateType = validateType
        self.keyboardType = keyboardType
        self.isPassword = isSecureText
        self.isSecureText = isSecureText
        self.maxLength = maxLength
        setupViews()
        self.isEabled = isEabled
        initBinding()
    }

    func setupViews() {
        self.backgroundColor = .clear
        self.clipsToBounds = true

        self.rx.click.subscribeSuccess { [unowned self] in
            self.onClicked()
            self.txtInput.becomeFirstResponder()
        }.disposed(by: disposeBag)

        self.addSubviews([bgView, warningView])

//        bgView.backgroundColor = .brandColorNormalWhite
        bgView.layer.cornerRadius = layoutDefault.cornerRadius
//        bgView.layer.borderColor = layoutDefault.borderColor
        bgView.layer.borderWidth = layoutDefault.borderWidth

        bgView.snp.makeConstraints { (maker) in
            maker.top.leading.trailing.equalToSuperview()
        }

        warningView.backgroundColor = .clear
        warningView.snp.makeConstraints { (maker) in
            maker.top.equalTo(bgView.snp.bottom)
            maker.leading.trailing.bottom.equalToSuperview()
            maker.height.equalTo(0)
        }

//        warningView.addSubviews([imageView, lblWarning])
//        imageView.snp.makeConstraints { (maker) in
//            maker.leading.equalToSuperview()
//            maker.top.equalToSuperview().offset(8)
//            maker.width.height.equalTo(12)
//        }
//
//        lblWarning.snp.makeConstraints { (maker) in
//            maker.top.equalTo(imageView)
//            maker.leading.equalTo(imageView.snp.trailing).offset(4)
//            maker.height.equalTo(12)
//        }

        bgView.addSubviews([txtInput, button, btnEye])

        txtInput.snp.makeConstraints { (maker) in
            maker.top.equalToSuperview().offset(15)
            maker.bottom.equalToSuperview().offset(-15)
            maker.leading.equalToSuperview().offset(16)
            maker.trailing.equalTo(button.snp.leading).offset(-14)
            maker.height.equalTo(16)
        }

        button.snp.makeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            maker.trailing.equalToSuperview().offset(-8)
            maker.width.equalTo(isDropDownMenu ? 24 : 0)
            maker.height.equalTo(24)
        }

        btnEye.snp.makeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            maker.trailing.equalTo(button.snp.leading).offset(-8)
            maker.width.height.equalTo(24)
        }

        button.rx.tap.subscribeSuccess {[unowned self] in
            self.content = ""
        }.disposed(by: disposeBag)

        btnEye.rx.tap.subscribeSuccess {[unowned self] in
            self.txtInput.isSecureTextEntry.toggle()
//            let image = self.txtInput.isSecureTextEntry ? UIImage(name: "icon_eye_off") : UIImage(name: "icon_eye")
//            self.btnEye.setImage(image, for: .normal)
        }.disposed(by: disposeBag)
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
//            self.imageView.image = passed ? UIImage(name: "icon_success") : UIImage(name: "icon_mistake")

//            let color: UIColor = passed ? .brandColorTertiaryDesaturation : .brandColorDangerDefault
//            self.lblWarning.textColor = color
//            self.imageView.tintColor = color

            if let tt = self.textType, tt == .amount, let vt = self.validateType, vt == .vtNone {
                // for: 點擊Amount快捷鍵輸入金額的情況(因未focus所以warningView高度會被設為0)
                if !self.isOnFocused.value, !self.content.isEmpty {
                    self.setWarningText(isShow: !passed)
                }
            }
        }.disposed(by: disposeBag)
    }

    func validate() {
        if content.isEmpty {
            isPass.accept(false)
        } else if let confirmText = confirmTo?.text, confirmText.count > 0 {
            isPass.accept(txtInput.text == confirmText)
            isOnFocused.accept(true)
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
            isOnFocused.accept(true)
        }
    }

    func setWarningText(isShow: Bool) {
        self.warningView.snp.remakeConstraints { (maker) in
            maker.top.equalTo(self.bgView.snp.bottom)
            maker.leading.trailing.bottom.equalToSuperview()
            maker.height.equalTo(isShow ? 20 : 0)
        }
    }

    private func setEnabled(_ isEnabled: Bool) {
        if isEnabled {
            txtInput.isUserInteractionEnabled = true
            btnEye.isHidden = !isPassword
//            bgView.backgroundColor = .brandColorNormalWhite
        } else {
            resetView()
            content = defaultContent
            txtInput.isUserInteractionEnabled = false
            btnEye.isHidden = true
//            bgView.backgroundColor = .brandColorNormalDisable
        }
    }

    func setToDefault() {
        self.isEabled = true
        self.isFirstTimeFocused = false
        self.content = self.defaultContent
        self.txtInput.isSecureTextEntry = self.isSecureText
        self.setWarningText(isShow: false)
        resetView()
    }

    private func resetView() {
//        button.setImage(UIImage(name: isDropDownMenu ? "icon_picker_down" : "icon_input_close"), for: .normal)
        btnEye.isHidden = !isPassword
//        let image = self.txtInput.isSecureTextEntry ? UIImage(name: "icon_eye_off") : UIImage(name: "icon_eye")
        btnEye.isUserInteractionEnabled = true
//        btnEye.setImage(image, for: .normal)
    }
}

extension FormViewNoTitle: UITextFieldDelegate {

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
                   let toIndex = newString.lastIndex(of: Character("")),
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

            if let char = string.cString(using: .utf8) {
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

        txtInput.snp.remakeConstraints { (maker) in
            maker.top.equalToSuperview().offset(15)
            maker.bottom.equalToSuperview().offset(-15)
            maker.leading.equalToSuperview().offset(16)
            maker.trailing.equalTo(btnEye.snp.leading).offset(-14)
            maker.height.equalTo(16)
        }

        button.snp.remakeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            maker.trailing.equalToSuperview().offset(-16)
            maker.width.height.equalTo(24)
        }
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        self.isOnFocused.accept(false)

        txtInput.snp.remakeConstraints { (maker) in
            maker.top.equalToSuperview().offset(15)
            maker.bottom.equalToSuperview().offset(-15)
            maker.leading.equalToSuperview().offset(16)
            maker.trailing.equalTo(button.snp.leading).offset(-14)
            maker.height.equalTo(16)
        }

        button.snp.remakeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            maker.trailing.equalToSuperview().offset(-8)
            maker.width.equalTo(0)
            maker.height.equalTo(24)
        }
    }
}
