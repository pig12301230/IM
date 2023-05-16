//
//  DebuggingUploadLogCell.swift
//  ChatRoom
//
//  Created by Kedia on 2023/4/6.
//

import Foundation
import UIKit
import RxSwift
import SnapKit

final class DebuggingUploadLogCell: UITableViewCell {
    
    static let identifier = "DebuggingUploadLogCell"
    let buttonTapSubject = PublishSubject<Void>()
    var disposeBag = DisposeBag()
    
    private(set) lazy var nameTextField: UITextField = {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.autocapitalizationType = .none
        tf.borderStyle = .roundedRect
        tf.placeholder = "User Name"
        return tf
    }()
    
    private(set) lazy var passwordTextField: UITextField = {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.borderStyle = .roundedRect
        tf.isSecureTextEntry = true
        tf.placeholder = "Password"
        return tf
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(lblTitle)
        contentView.addSubview(lblHint)
        contentView.addSubview(nameTextField)
        contentView.addSubview(passwordTextField)
        contentView.addSubview(button)
        
        button.snp.makeConstraints { make in
            make.width.equalTo(60)
            make.height.equalTo(30)
            make.centerY.equalTo(contentView.snp.centerY)
            make.trailing.equalTo(contentView.snp.trailing).offset(-8)
        }

        lblTitle.snp.makeConstraints { make in
            make.top.equalTo(contentView.snp.top).offset(8)
            make.height.equalTo(21)
            make.leading.equalTo(contentView.snp.leading).offset(8)
            make.trailing.equalTo(button.snp.leading).offset(-8)
        }

        lblHint.snp.makeConstraints { make in
            make.top.equalTo(lblTitle.snp.bottom).offset(8)
            make.height.equalTo(21)
            make.leading.equalTo(contentView.snp.leading).offset(8)
            make.trailing.equalTo(button.snp.leading).offset(-8)
            make.bottom.equalTo(nameTextField.snp.top).offset(-8)
        }

        nameTextField.snp.makeConstraints { make in
            make.top.equalTo(lblHint.snp.bottom).offset(8)
            make.bottom.equalTo(contentView.snp.bottom).offset(-8)
            make.leading.equalTo(contentView.snp.leading).offset(8)
            make.trailing.equalTo(passwordTextField.snp.leading).offset(-8)
        }

        passwordTextField.snp.makeConstraints { make in
            make.height.equalTo(nameTextField.snp.height)
            make.centerY.equalTo(nameTextField.snp.centerY)
            make.trailing.equalTo(button.snp.leading).offset(-8)
            make.width.equalTo(nameTextField.snp.width)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        nameTextField.text = nil
        passwordTextField.text = nil
        disposeBag = DisposeBag()
    }
    
    // MARK: - Privates
    
    private lazy var lblTitle: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.minimumScaleFactor = 0.3
        l.adjustsFontSizeToFitWidth = true
        l.text = "將 log 檔上傳到 Jira 單上"
        l.font = .systemFont(ofSize: 14)
        return l
    }()
    
    private lazy var lblHint: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.minimumScaleFactor = 0.3
        l.adjustsFontSizeToFitWidth = true
        l.text = "請先在下方輸入您在 Jira 上的帳密, 按下送出後，帳密會被存在手機端"
        l.font = .systemFont(ofSize: 12)
        l.textColor = .darkGray
        return l
    }()
    
    private lazy var button: UIButton = {
        let b = UIButton()
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setTitle("上傳", for: .normal)
        b.setTitleColor(.red, for: .normal)
        b.layer.borderColor = UIColor.red.cgColor
        b.layer.borderWidth = 1
        b.layer.cornerRadius = 4
        b.layer.masksToBounds = true
        b.rx.tap.bind(to: buttonTapSubject).disposed(by: disposeBag)
        return b
    }()
    
}
