//
//  SplashViewController.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/4/28.
//

import UIKit
import RxSwift

class SplashViewController: BaseVC {
    var viewModel: SplashViewControllerVM!
    
    private lazy var bgImageView: UIImageView = {
        let iView = UIImageView.init(image: UIImage.init(named: "conceptImageIcon"))
        iView.contentMode = .scaleAspectFill
        return iView
    }()

    private lazy var lblLanguage: EdgeInsetsLabel = {
        let lbl = EdgeInsetsLabel()
        lbl.contentInsets = UIEdgeInsets(top: 7, left: 16, bottom: 7, right: 16)
        lbl.theme_backgroundColor = Theme.c_01_primary_600.rawValue
        lbl.theme_textColor = Theme.c_09_white.rawValue
        lbl.font = .boldParagraphSmallCenter
        lbl.text = Localizable.languageName
        lbl.layer.cornerRadius = 4
        lbl.clipsToBounds = true
        return lbl
    }()
    
    private lazy var btnLogin: UIButton = {
        let btn = UIButton.init(type: .custom)
        btn.layer.borderWidth = 1
        btn.layer.cornerRadius = 4
        btn.layer.borderColor = Theme.c_01_primary_0_500.rawValue.toCGColor()
        btn.theme_backgroundColor = Theme.c_09_white.rawValue
        btn.setTitle(Localizable.login, for: .normal)
        btn.theme_setTitleColor(Theme.c_01_primary_0_500.rawValue, forState: .normal)
        btn.titleLabel?.font = .boldParagraphMediumLeft
        return btn
    }()
    
    private lazy var btnRegister: UIButton = {
        let btn = UIButton.init(type: .custom)
        btn.layer.cornerRadius = 4
        btn.theme_backgroundColor = Theme.c_01_primary_600.rawValue
        btn.setTitle(Localizable.register, for: .normal)
        btn.titleLabel?.font = .boldParagraphMediumLeft
        return btn
    }()
    
    static func initVC(with vm: SplashViewControllerVM) -> SplashViewController {
        let vc = SplashViewController.init()
        vc.viewModel = vm
        return vc
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
        self.viewModel.viewAppear = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.navigationBar.isHidden = false
    }
    
    override func setupViews() {
        super.setupViews()
        self.view.addSubview(self.bgImageView)
        self.view.addSubview(self.btnLogin)
        self.view.addSubview(self.btnRegister)
        self.view.addSubview(self.lblLanguage)
        
        self.bgImageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        self.btnLogin.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().offset(-66)
            make.height.equalTo(48)
        }
        
        self.btnRegister.snp.makeConstraints { (make) in
            make.leading.equalTo(self.btnLogin.snp.trailing).offset(16)
            make.bottom.width.top.equalTo(self.btnLogin)
            make.trailing.equalToSuperview().offset(-16)
        }

        self.lblLanguage.snp.makeConstraints { make in
            make.top.equalTo(44)
            make.trailing.equalTo(-16)
            make.height.equalTo(32)
        }
        
    }
    
    override func initBinding() {
        super.initBinding()
        
        self.viewModel.gotoView.subscribeSuccess { [unowned self] (scene, toRoot) in
            guard toRoot else {
                self.navigator.show(scene: scene, sender: self, transition: .push(animated: true))
                return
            }
            guard let window = appDelegate?.window else { return }
            self.navigator.show(scene: scene, sender: self, transition: .root(in: window, duration: 0))
        }.disposed(by: self.disposeBag)
        
        self.viewModel.accessFailed.observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] _ in
            let msg = String(format: Localizable.errorHandlingUnauthorizedIOS, AppConfig.Info.appName)
            self.showAlert(message: msg, comfirmBtnTitle: Localizable.sure, onConfirm: { [weak self] in
                self?.viewModel.goto(scene: .login)
            })
        }.disposed(by: self.disposeBag)
        
        self.viewModel.showActionButton.map { !$0 }.bind(to: self.btnLogin.rx.isHidden).disposed(by: self.disposeBag)
        self.viewModel.showActionButton.map { !$0 }.bind(to: self.btnRegister.rx.isHidden).disposed(by: self.disposeBag)
        
        self.btnLogin.rx.controlEvent(.touchUpInside).throttle(.seconds(2), scheduler: MainScheduler.instance).subscribeSuccess { [unowned self] _ in
            self.viewModel.goto(scene: .login)
        }.disposed(by: self.disposeBag)
        
        self.btnRegister.rx.controlEvent(.touchUpInside).throttle(.seconds(2), scheduler: MainScheduler.instance).subscribeSuccess { [unowned self] _ in
            let vm = PhoneVerifyViewControllerVM()
            self.viewModel.goto(scene: .phoneVerify(vm: vm))
        }.disposed(by: self.disposeBag)
    }
}
