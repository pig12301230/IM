//
//  PersonalInformationViewController.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/6/30.
//

import UIKit
import RxSwift

class PersonalInformationViewController: BaseIntrinsicTableViewVC {
    
    var viewModel: PersonalInformationViewControllerVM!
    
    private lazy var avatarImageView: UIImageView = {
        let view = UIImageView.init(image: UIImage.init(named: "avatarsPhoto"))
        view.layer.cornerRadius = 48
        view.clipsToBounds = true
        view.contentMode = .scaleAspectFill
        return view
    }()
    
    private lazy var scanButton: UIBarButtonItem = {
        let buttonImage = UIImage(named: "iconIconScan")?.withRenderingMode(.alwaysOriginal)
        return UIBarButtonItem(image: buttonImage, style: .plain, target: self, action: #selector(scanButtonMethod))
    }()
    
    static func initVC(with vm: PersonalInformationViewControllerVM) -> PersonalInformationViewController {
        let vc = PersonalInformationViewController.init()
        vc.barType = .default
        vc.viewModel = vm
        vc.title = Localizable.profile
        return vc
    }
    
    override func setupViews() {
        super.setupViews()
        
        self.view.theme_backgroundColor = Theme.c_07_neutral_50.rawValue
        self.view.addSubview(self.avatarImageView)
        
        self.avatarImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(16)
            make.height.width.equalTo(96)
        }
        
        self.tableView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(self.avatarImageView.snp.bottom).offset(24)
            make.height.equalTo(self.viewModel.numberOfRows() * 56)
            make.bottom.lessThanOrEqualToSuperview().offset(0)
        }
        
        navigationItem.rightBarButtonItem = scanButton
        
    }
    
    override func initBinding() {
        super.initBinding()
        self.avatarImageView.rx.click.bind(to: self.viewModel.didTapAvatar).disposed(by: self.disposeBag)
        self.viewModel.avatarImage.bind(to: self.avatarImageView.rx.image).disposed(by: self.disposeBag)
        
        self.viewModel.showImageViewer.subscribeSuccess { [unowned self] viewerVM in
            self.navigator.show(scene: .functionalImageViewer(vm: viewerVM), sender: self, transition: .present(animated: true, style: .fullScreen))
        }.disposed(by: self.disposeBag)
        
        self.viewModel.openCamera.subscribeSuccess { [unowned self] _ in
            self.openCamera()
        }.disposed(by: self.disposeBag)
        
        self.viewModel.showAlert.subscribeSuccess { [unowned self] messgae in
            self.showAlert(message: messgae, comfirmBtnTitle: Localizable.sure)
        }.disposed(by: self.disposeBag)
        
        self.viewModel.refresh.observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] _ in
            self.tableView.reloadData()
            self.tableView.snp.updateConstraints { (make) in
                make.height.equalTo(self.viewModel.numberOfRows() * 56)
            }
        }.disposed(by: self.disposeBag)
        
        self.viewModel.showLoading.distinctUntilChanged().subscribeSuccess { show in
            show ? LoadingView.shared.show() : LoadingView.shared.hide()
        }.disposed(by: self.disposeBag)
    }
    
    override func implementTableViewDelegateAndDataSource() {
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func registerCells() {
        for type in viewModel.cellTypes {
            tableView.register(type.cellClass, forCellReuseIdentifier: type.cellIdentifier)
        }
    }
}

private extension PersonalInformationViewController {
    func openCamera() {
        PhotoLibraryManager.open(sender: self, type: .select) { [weak self] image in
            guard let self = self, let image = image else { return }
            self.viewModel.uploadAvatar(image)
        }
    }
    
    @objc func scanButtonMethod() {
        let vm = ScanToLoginQRCodeViewControllerVM()
        self.navigator.show(scene: .scanLoginQRCode(vm: vm), sender: self, completion: nil)
    }
}

extension PersonalInformationViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.numberOfRows()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.viewModel.cellIdentifier(at: indexPath.row), for: indexPath)
        
        if let cell = cell as? TitleTableViewCell {
            let config = self.viewModel.cellConfig(at: indexPath.row)
            cell.setupConfig(config)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let scene = self.viewModel.getScene(at: indexPath.row) else {
            return
        }
        
        self.navigator.show(scene: scene, sender: self)
    }
}
