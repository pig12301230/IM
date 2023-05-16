//
//  AuthSettingViewController.swift
//  ChatRoom
//
//  Created by ZoeLin on 2022/1/20.
//

import UIKit
import RxSwift

class AuthSettingViewController: BaseIntrinsicTableViewVC {
    
    var viewModel: AuthSettingViewControllerVM!
    
    private lazy var infoView: UIView = {
        let view = UIView.init()
        view.theme_backgroundColor = Theme.c_07_neutral_50.rawValue
        view.addSubview(self.iconImageView)
        return view
    }()
    
    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage.init(named: viewModel.authSettingType.defautIcon))
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    private lazy var cameraImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage.init(named: "iconIconDevicesCamera"))
        imageView.isUserInteractionEnabled = false
        return imageView
    }()
    
    private lazy var editNameView: UIView = {
        let view = UIView.init()
        view.addSubviews([lblNameTitle, lblName, arrowImageView, separatorView1])
        return view
    }()
    
    private lazy var lblNameTitle: UILabel = {
        let lbl = UILabel()
        lbl.text = Localizable.groupName
        lbl.font = .midiumParagraphLargeLeft
        lbl.theme_textColor = Theme.c_10_grand_1.rawValue
        return lbl
    }()
    
    private lazy var lblName: UILabel = {
        let lbl = UILabel()
        return lbl
    }()
    
    private lazy var arrowImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage.init(named: "iconArrowsChevronRight"))
        imageView.setImageColor(color: Theme.c_07_neutral_500.rawValue.toColor())
        return imageView
    }()
    
    private lazy var separatorView1: UIView = {
        let view = UIView.init()
        view.theme_backgroundColor = Theme.c_07_neutral_900_10.rawValue
        return view
    }()
    
    private lazy var hintView: UIView = {
        let view = UIView.init()
        view.theme_backgroundColor = Theme.c_07_neutral_50.rawValue
        view.addSubviews([lblHint, separatorView2])
        return view
    }()
    
    private lazy var lblHint: UILabel = {
        let lbl = UILabel()
        lbl.font = .midiumParagraphMediumLeft
        lbl.theme_textColor = Theme.c_10_grand_2.rawValue
        lbl.text = viewModel.authSettingType.authHint
        return lbl
    }()
    
    private lazy var separatorView2: UIView = {
        let view = UIView.init()
        view.theme_backgroundColor = Theme.c_07_neutral_900_10.rawValue
        return view
    }()
    
    private lazy var lblDone: UILabel = {
        let lbl = UILabel()
        lbl.font = .midiumParagraphLargeRight
        lbl.theme_textColor = Theme.c_10_grand_1.rawValue
        lbl.text = Localizable.done
        return lbl
    }()
    
    static func initVC(with vm: AuthSettingViewControllerVM) -> AuthSettingViewController {
        let vc = AuthSettingViewController.init()
        vc.viewModel = vm
        vc.title = vm.authSettingType.title
        vc.barType = .default
        return vc
    }
    
    override func setupNavigationBar() {
        super.setupNavigationBar()
        self.btnBack.setImage(UIImage(named: viewModel.authSettingType.backButtonIcon), for: .normal)
        self.btnBack.theme_tintColor = Theme.c_10_grand_1.rawValue
        let barItem = UIBarButtonItem.init(customView: btnBack)
        self.navigationItem.leftBarButtonItem = barItem
    }
    
    override func setupViews() {
        super.setupViews()
        self.view.theme_backgroundColor = viewModel.authSettingType.backgroundTheme.rawValue
        
        self.view.addSubview(self.infoView)
        self.view.addSubview(self.hintView)
        self.infoView.addSubview(self.iconImageView)
        
        self.infoView.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
        }
        
        self.iconImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.centerX.equalToSuperview()
            make.height.width.equalTo(96)
        }
        
        self.hintView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(self.infoView.snp.bottom).offset(8)
        }
        
        self.lblHint.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.top.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().offset(-8)
        }
        
        self.separatorView2.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(1)
        }
        
        self.tableView.snp.makeConstraints { make in
            make.top.equalTo(self.hintView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.lessThanOrEqualToSuperview().offset(0)
            make.height.equalTo(self.viewModel.numberOfRows() * 56)
        }
        
        self.iconImageView.roundSelf()
        
        if viewModel.allowSetting, !viewModel.authSettingType.editImmediately {
            let item = UIBarButtonItem(customView: lblDone)
            self.navigationItem.rightBarButtonItem = item
        }
        
        guard viewModel.authSettingType.canEdit else {
            self.infoView.addSubview(self.lblName)
            
            self.lblName.snp.makeConstraints { make in
                make.top.equalTo(self.iconImageView.snp.bottom).offset(4)
                make.centerX.equalTo(self.infoView)
                make.bottom.equalToSuperview().offset(-16)
            }
            
            self.lblName.font = .midiumParagraphSmallCenter
            self.lblName.theme_textColor = Theme.c_10_grand_1.rawValue
            return
        }
        
        self.infoView.addSubview(self.cameraImageView)
        self.infoView.addSubview(self.editNameView)
        
        self.cameraImageView.snp.makeConstraints { make in
            make.trailing.bottom.equalTo(self.iconImageView)
            make.width.height.equalTo(24)
        }
        
        self.editNameView.snp.makeConstraints { make in
            make.top.equalTo(self.iconImageView.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(56)
            make.bottom.equalToSuperview()
        }
        
        self.lblNameTitle.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.height.equalTo(24)
            make.leading.equalToSuperview().offset(16)
        }
        
        self.arrowImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalTo(self.lblNameTitle)
            make.height.width.equalTo(24)
        }
        
        self.separatorView1.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.height.equalTo(1)
            make.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        self.lblName.snp.makeConstraints { make in
            make.trailing.equalTo(self.arrowImageView.snp.leading).offset(-16)
            make.centerY.equalTo(self.lblNameTitle)
        }
        
        self.lblName.font = .midiumParagraphMediumRight
        self.lblName.theme_textColor = Theme.c_07_neutral_400.rawValue
    }
    
    override func initBinding() {
        super.initBinding()
        
        viewModel.popView.observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] _ in
            guard let target = self.viewModel.authSettingType.popTarget else {
                self.navigator.pop(sender: self)
                return
            }
            
            _ = self.navigator.pop(sender: self, to: target)
        }.disposed(by: disposeBag)
        
        viewModel.reload.observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] _ in
            self.tableView.reloadData()
            self.tableView.snp.updateConstraints { (make) in
                make.height.equalTo(self.viewModel.numberOfRows() * 56)
            }
        }.disposed(by: disposeBag)
        
        viewModel.showLoading.observe(on: MainScheduler.instance).subscribeSuccess { (isShow) in
            isShow ? LoadingView.shared.show() : LoadingView.shared.hide()
        }.disposed(by: disposeBag)
        
        viewModel.targetName.bind(to: self.lblName.rx.text).disposed(by: disposeBag)
        
        viewModel.targetThumbnail.distinctUntilChanged().observe(on: MainScheduler.instance).subscribeSuccess { urlString in
            guard !urlString.isEmpty else { return }
            guard let url = URL(string: urlString) else {
                self.iconImageView.image = UIImage(named: self.viewModel.authSettingType.defautIcon)
                return
            }
            self.iconImageView.kf.setImage(with: url, placeholder: UIImage(named: self.viewModel.authSettingType.defautIcon))
        }.disposed(by: disposeBag)
        
        if !viewModel.authSettingType.editImmediately {
            self.lblDone.rx.click.throttle(.milliseconds(500), scheduler: MainScheduler.instance).subscribeSuccess { [unowned self] _ in
                self.viewModel.executeAuthSetting()
            }.disposed(by: disposeBag)
        }
                        
        guard viewModel.authSettingType.canEdit else {
            return
        }
        
        iconImageView.rx.click.subscribeSuccess { _ in
            PhotoLibraryManager.open(sender: self, type: .select) { [weak self] image in
                guard let self = self, let image = image else { return }
                self.viewModel.uploadIcon(image)
            }
        }.disposed(by: disposeBag)
        
        editNameView.rx.click.subscribeSuccess { [unowned self] _ in
            guard self.viewModel.authSettingType.canEdit, let model = self.viewModel.targetModel else {
                return
            }
            
            switch self.viewModel.authSettingType {
            case .group:
                let vm = ModifyViewControllerVM.init(type: .groupName(groupID: model.targetID), default: self.viewModel.targetModel?.display ?? "")
                self.navigator.show(scene: .modify(vm: vm), sender: self)
            default:
                break
            }
        }.disposed(by: disposeBag)
        
    }
    
    // MARK: - IntrinsicTableViewVCProtocol
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

extension AuthSettingViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.numberOfRows()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.viewModel.cellIdentifier(at: indexPath.row), for: indexPath)
        
        if let cell = cell as? ImplementViewModelProtocol, let vm = self.viewModel.cellViewModel(at: indexPath.row) {
            cell.setupViewModel(viewModel: vm)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Do nothing
    }
}
