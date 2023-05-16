//
//  InputBoxesView.swift
//  ChatRoom
//
//  Created by Kedia on 2023/4/17.
//  zeplin: https://zpl.io/O0jdnRL

import Foundation
import UIKit
import SnapKit
import RxSwift

final class InputBoxesView: UIView, UITextFieldDelegate {
    
    let passcodeDidFilledSubject = PublishSubject<String>()
    private let hiddenTextField = UITextField()
    private let stackView = UIStackView()
    private let labels: [UILabel] = (0..<4).map { _ in UILabel() }
    private lazy var lblHint: UILabel = {
        let l = UILabel()
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .midiumParagraphMediumLeft
        l.theme_textColor = Theme.c_10_grand_1.rawValue
        return l
    }()
    
    init(hint: String) {
        super.init(frame: .zero)
        lblHint.text = hint
        setupView()
    }
    
    /// 讓遊標停在第一格
    func startInput() {
        hiddenTextField.becomeFirstResponder()
    }
    
    /// 清空所有已輸入的內容
    func cleanText() {
        hiddenTextField.text = nil
        for l in labels {
            l.text = ""
        }
    }
    
    private init() {
        super.init(frame: .zero)
        setupView()
    }
    
    private override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        addSubview(hiddenTextField)
        addSubview(stackView)
        addSubview(lblHint)
        setupTextField()
        setupLabels()
        setupStackView()
        installConstraints()
    }
    
    private func installConstraints() {
        
        lblHint.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(280.0/414.0)
            make.top.equalTo(snp.bottom).multipliedBy(152.0/896.0)
        }
        
        stackView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.height.equalTo(56)
            make.top.equalTo(lblHint.snp.bottom).offset(16)
        }
        
        for label in labels {
            label.snp.makeConstraints { make in
                make.width.equalTo(64)
                make.height.equalTo(stackView.snp.height)
            }
        }
    }
    
    private func setupTextField() {
        hiddenTextField.keyboardType = .numberPad
        hiddenTextField.delegate = self
        hiddenTextField.isHidden = true
    }
    
    private func setupLabels() {
        for label in labels {
            label.layer.cornerRadius = 8
            label.layer.borderWidth = 1
            label.layer.borderColor = Theme.c_07_neutral_200.rawValue.toCGColor()
            label.textAlignment = .center
            label.clipsToBounds = true
            label.theme_textColor = Theme.c_01_primary_0_500.rawValue
            label.font = UIFont.semibold(20)
        }
    }
    
    private func setupStackView() {
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 8
        
        for label in labels {
            stackView.addArrangedSubview(label)
        }
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        hiddenTextField.becomeFirstResponder()
    }
    
    // MARK: - UITextFieldDelegate
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text as? NSString else {
            return true
        }
        let newText = text.replacingCharacters(in: range, with: string)
        if newText.count <= 4 {
            for (index, label) in labels.enumerated() {
                if index < newText.count {
                    label.text = newText[index]
                } else {
                    label.text = ""
                }
            }
            if newText.count == 4 {
                passcodeDidFilledSubject.onNext(newText)
            }
            return true
        } else {
            return false
        }
    }
}
