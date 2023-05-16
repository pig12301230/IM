//
//  InputPasscodeViewController.swift
//  ChatRoom
//
//  Created by Kedia on 2023/4/17.
//

import Foundation
import UIKit
import SnapKit
import RxSwift

/// 輸入四碼的 passcode 頁面, https://zpl.io/B16KpkA
class InputPasscodeViewController: BaseVC {
    
    private var viewModel: InputPasscodeViewControllerVM
    
    private lazy var inputBoxesView: InputBoxesView = {
        let v = InputBoxesView(hint: Localizable.inputPasscodeHint)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private lazy var navigationBar: UINavigationBar = {
        let bar = UINavigationBar()
        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.items = [customNAVItem]
        return bar
    }()
    
    private lazy var customNAVItem: UINavigationItem = {
        let navigationItem = UINavigationItem(title: Localizable.pleaseInputVerificationCode)
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "iconIconCrossBlack")?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.snp.makeConstraints { make in
            make.width.equalTo(44)
            make.height.equalTo(44)
        }
        button.addTarget(self, action: #selector(navigationLeftButtonMethod), for: .touchUpInside)
        let leftButton =
        UIBarButtonItem(customView: button)
        navigationItem.leftBarButtonItem = leftButton
        return navigationItem
    }()
    
    init(viewModel: InputPasscodeViewControllerVM) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .fullScreen
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.theme_backgroundColor = Theme.c_09_white.rawValue
        view.addSubview(inputBoxesView)
        view.addSubview(navigationBar)
        
        installConstraints()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        inputBoxesView.startInput()
    }
    
    override func initBinding() {
        super.initBinding()
        
        viewModel.passcodeDidExpiredSubject.subscribe(onNext: { [weak self] in
            self?.navigator.dismiss(sender: self)
        }).disposed(by: disposeBag)
        
        inputBoxesView.passcodeDidFilledSubject.subscribe { [weak self] passcode in
            guard let self else {
                return
            }
            Task {
                let isSucceed = await self.viewModel.validate(passcode: passcode)
                if !isSucceed {
                    self.inputBoxesView.cleanText()
                    self.inputBoxesView.startInput()
                    return
                }
                self.toastManager.showToast(iconName: "iconIconActionsCheckmarkCircle", hint: Localizable.passcodeVerifySuccess) {
                    self.navigator.dismiss(sender: self)
                }
            }
            
        }.disposed(by: disposeBag)
        
        viewModel.showInvalidAccessAlert.subscribe { [weak self] _ in
            guard let self else { return }
            DataAccess.shared.logout()
            let msg = String(format: Localizable.errorHandlingUnauthorizedIOS, AppConfig.Info.appName)
            self.showAlert(message: msg, comfirmBtnTitle: Localizable.sure, onConfirm: {
                self.gotoViewController(locate: .login)
            })
        }.disposed(by: disposeBag)
    }
    
    private func installConstraints() {
        
        inputBoxesView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        navigationBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.equalTo(view.snp.leading)
            make.trailing.equalTo(view.snp.trailing)
            make.height.equalTo(44)
        }
    }
    
    @objc private func navigationLeftButtonMethod() {
        self.navigator.dismiss(sender: self)
    }
}
