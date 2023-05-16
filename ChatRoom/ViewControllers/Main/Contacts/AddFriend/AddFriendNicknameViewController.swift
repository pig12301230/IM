//
//  AddFriendNicknameViewController.swift
//  ChatRoom
//
//  Created by Winston_Chuang on 2022/9/5.
//

import Foundation
import UIKit
import RxSwift

class AddFriendNicknameViewController: BaseVC {
    
    private var viewModel: AddFriendNicknameViewControllerVM!
    private var toast = ToastManager()
    
    private lazy var addButtonItem: UIBarButtonItem = {
        let buttonItem = UIBarButtonItem(title: Localizable.add, style: .plain, target: self, action: #selector(addToContact))
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
    
    private lazy var memoTitleView: MemoTitleView = {
        let view = MemoTitleView(title: Localizable.nickname, limit: Localizable.nicknameTips)
        return view
    }()
    
    private lazy var memoTextView: MultipleRulesInputView = {
        let textView = MultipleRulesInputView(with: self.viewModel.memoInputViewModel)
        textView.theme_backgroundColor = Theme.c_07_neutral_50.rawValue
        return textView
    }()
    
    static func initVC(with vm: AddFriendNicknameViewControllerVM) -> AddFriendNicknameViewController {
        let vc = AddFriendNicknameViewController()
        vc.viewModel = vm
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func setupViews() {
        self.title = Localizable.addFriend
        self.navigationItem.rightBarButtonItem = addButtonItem
        self.view.theme_backgroundColor = Theme.c_07_neutral_0.rawValue
        self.view.addSubviews([memoTitleView, memoTextView])
        
        memoTitleView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(44)
        }
        
        memoTextView.snp.makeConstraints { make in
            make.top.equalTo(memoTitleView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(56)
        }
    }
    
    override func initBinding() {
        super.initBinding()
        
        self.viewModel.showLoading
            .bind { show in
                show ? LoadingView.shared.show() : LoadingView.shared.hide()
            }.disposed(by: disposeBag)
        
        self.viewModel.showToastResult
            .observe(on: MainScheduler.instance)
            .subscribeSuccess { [unowned self] result in
                let icon = result ? UIImage(named: "iconIconActionsCheckmarkCircle") : UIImage(named: "iconIconAlertError")
                let hint = result ? Localizable.addSuccessfully : Localizable.failedToAdd
                toastManager.showToast(icon: icon ?? UIImage(), hint: hint) {
                    if result {
                        self.popViewController()
                    }
                }
            }.disposed(by: disposeBag)
    }
    
    @objc func addToContact() {
        if let nickname = self.viewModel.memoInputViewModel.inputText.value, !nickname.isEmptyWhitespace {
            self.viewModel.addUserContactWithNickname(nickname: nickname)
        } else {
            self.viewModel.addUserContact()
        }
    }
}
