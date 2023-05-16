//
//  ContactorMemoViewController.swift
//  ChatRoom
//
//  Created by Winston_Chuang on 2022/3/22.
//

import Foundation
import UIKit

class ContactorMemoViewController: BaseVC {
    var viewModel: ContactorMemoViewControllerVM!
    
    private lazy var saveButtonItem: UIBarButtonItem = {
        let buttonItem = UIBarButtonItem(title: Localizable.done, style: .plain, target: self, action: #selector(saveMemo))
        buttonItem.theme_tintColor = Theme.c_10_grand_1.rawValue
        buttonItem.setTitleTextAttributes([.font: UIFont.midiumParagraphLargeRight,
                                           .foregroundColor: Theme.c_10_grand_1.rawValue.toColor()],
                                          for: .normal)
        buttonItem.setTitleTextAttributes([.font: UIFont.midiumParagraphLargeRight,
                                           .foregroundColor: Theme.c_10_grand_1.rawValue.toColor()],
                                          for: .selected)
        buttonItem.setTitleTextAttributes([.font: UIFont.midiumParagraphLargeRight,
                                           .foregroundColor: Theme.c_07_neutral_400.rawValue.toColor()],
                                          for: .disabled)
        return buttonItem
    }()
    
    private lazy var nickTitleView: MemoTitleView = {
        let view = MemoTitleView(title: Localizable.nickname, limit: Localizable.nicknameTips)
        return view
    }()
    
    private lazy var nickTextView: MultipleRulesInputView = {
        let textView = MultipleRulesInputView(with: self.viewModel.nickNameInputViewModel)
        textView.theme_backgroundColor = Theme.c_07_neutral_50.rawValue
        return textView
    }()
    
    private lazy var describeTitleView: MemoTitleView = {
        let view = MemoTitleView(title: Localizable.describe, limit: Localizable.describeTips)
        return view
    }()
    
    private lazy var lineView: UIView = {
        let view = UIView()
        view.theme_backgroundColor = Theme.c_07_neutral_900_10.rawValue
        return view
    }()
    
    private lazy var describeTextView: UITextView = {
        let textView = UITextView()
        textView.theme_backgroundColor = Theme.c_07_neutral_50.rawValue
        textView.smartInsertDeleteType = .no
        textView.font = .regularParagraphLargeLeft
        textView.theme_textColor = Theme.c_10_grand_1.rawValue
        textView.textAlignment = .left
        textView.isScrollEnabled = false
        textView.isEditable = true
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        textView.textContainer.lineFragmentPadding = 0
        textView.toolbarPlaceholder = Localizable.describeTips
        textView.delegate = self
        
        return textView
    }()
    
    private lazy var describeTextViewPlaceholder: UILabel = {
        let label = UILabel()
        label.text = Localizable.describeTips
        label.font = .regularParagraphLargeLeft
        label.textAlignment = .left
        label.theme_textColor = Theme.c_07_neutral_400.rawValue
        return label
    }()
    
    static func initVC(with vm: ContactorMemoViewControllerVM) -> ContactorMemoViewController {
        let vc = ContactorMemoViewController()
        vc.viewModel = vm
        return vc
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func setupViews() {
        self.title = Localizable.settingMemo
        self.navigationItem.rightBarButtonItem = saveButtonItem
        self.view.theme_backgroundColor = Theme.c_07_neutral_0.rawValue
        self.view.addSubviews([nickTitleView, nickTextView, describeTitleView, describeTextView, lineView])
        describeTextView.addSubview(describeTextViewPlaceholder)
        
        nickTitleView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(44)
        }
        
        nickTextView.snp.makeConstraints { make in
            make.top.equalTo(nickTitleView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(56)
        }
        
        describeTitleView.snp.makeConstraints { make in
            make.top.equalTo(nickTextView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(44)
        }
        
        describeTextView.snp.makeConstraints { make in
            make.top.equalTo(describeTitleView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.greaterThanOrEqualTo(104)
            make.height.lessThanOrEqualTo(464)
            make.bottom.lessThanOrEqualTo(-16).priority(.high)
        }
        
        describeTextViewPlaceholder.snp.makeConstraints { make in
            make.top.leading.equalTo(16)
            make.trailing.bottom.equalTo(-16)
        }
        
        lineView.snp.makeConstraints { make in
            make.top.equalTo(describeTextView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(1)
        }
    }
    
    override func initBinding() {
        super.initBinding()
        self.viewModel.describeInputText.bind(to: self.describeTextView.rx.text).disposed(by: disposeBag)
        self.describeTextView.rx.text.subscribeSuccess { [unowned self] text in
            self.describeTextViewPlaceholder.isHidden = !(text ?? "").isEmpty
            self.viewModel.describeInputText.accept(text)
        }.disposed(by: disposeBag)

        self.viewModel.contentChanged.bind(to: self.saveButtonItem.rx.isEnabled).disposed(by: disposeBag)
        
        self.viewModel.showLoading
            .bind { show in
                show ? LoadingView.shared.show() : LoadingView.shared.hide()
            }.disposed(by: disposeBag)
        
        self.viewModel.dismissVC.subscribeSuccess { _ in
            self.popViewController()
        }.disposed(by: disposeBag)
    }
    
    @objc func saveMemo() {
        self.viewModel.updatePersonalSetting()
    }
}

extension ContactorMemoViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let maxLength = 300
        let currentString = textView.text as NSString
        var newString = currentString.replacingCharacters(in: range, with: text)
        if newString.count >= maxLength {
            newString = String(newString.prefix(maxLength))
            textView.text = newString
        }
        return newString.count < maxLength
    }
    
    func textViewDidChange(_ textView: UITextView) {
        let textViewMaxHeight = AppConfig.Screen.mainFrameHeight - 160 - (self.navigationController?.navigationBar.frame.height ?? 44) - AppConfig.Screen.statusBarHeight
        let maxHeight = min(464, textViewMaxHeight)
        textView.isScrollEnabled = textView.contentSize.height >= maxHeight
        textView.setNeedsUpdateConstraints()
    }
}
