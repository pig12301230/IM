//
//  SettingViewController.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/6/30.
//

import UIKit
import RxSwift

class SettingViewController: BaseIntrinsicTableViewVC {
    
    var viewModel: SettingViewControllerVM!
    
    private lazy var bgView: UIView = {
        let view = UIView.init()
        view.theme_backgroundColor = Theme.c_07_neutral_100.rawValue
        return view
    }()
    
    private lazy var infoView: UIView = {
        let view = UIView.init()
        view.theme_backgroundColor = Theme.c_07_neutral_50.rawValue
        return view
    }()
    
    private lazy var iconImageView: UIImageView = {
        let view = UIImageView.init(image: UIImage.init(named: "avatarsPhoto"))
        view.layer.cornerRadius = 36
        view.clipsToBounds = true
        view.contentMode = .scaleAspectFill
        return view
    }()
    
    private lazy var lblName: UILabel = {
        let lbl = UILabel.init()
        lbl.font = .boldParagraphLargeLeft
        lbl.theme_textColor = Theme.c_10_grand_1.rawValue
        return lbl
    }()
    
    private lazy var lblUserID: UILabel = {
        let lbl = UILabel.init()
        lbl.font = .midiumParagraphMediumLeft
        lbl.theme_textColor = Theme.c_07_neutral_400.rawValue
        return lbl
    }()
    
    private lazy var arrowRightImageView: UIImageView = {
        let view = UIImageView.init(image: UIImage.init(named: "iconArrowsChevronRight"))
        view.contentMode = .scaleAspectFit
        view.theme_tintColor = Theme.c_07_neutral_500.rawValue
        return view
    }()
    
    static func initVC(with vm: SettingViewControllerVM) -> SettingViewController {
        let vc = SettingViewController.init()
        vc.barType = .hide
        vc.viewModel = vm
        return vc
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.viewModel.setHongBaoBalance()
    }
    
    override func setupViews() {
        super.setupViews()
        
        self.view.theme_backgroundColor = Theme.c_07_neutral_50.rawValue
        self.view.insertSubview(self.bgView, at: 0)
        self.view.addSubview(self.infoView)
        self.infoView.addSubview(self.iconImageView)
        self.infoView.addSubview(self.arrowRightImageView)
        self.infoView.addSubview(self.lblName)
        self.infoView.addSubview(self.lblUserID)
        
        let topInset: CGFloat = UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 0
        self.infoView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(topInset)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(137)
        }
        
        self.bgView.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(infoView)
            make.bottom.equalToSuperview()
        }
        
        self.iconImageView.snp.makeConstraints { make in
            make.height.width.equalTo(72)
            make.leading.equalTo(16)
            make.centerY.equalToSuperview()
        }
        
        self.arrowRightImageView.snp.makeConstraints { make in
            make.width.height.equalTo(24)
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalTo(self.iconImageView)
        }
        
        self.lblName.snp.makeConstraints { make in
            make.leading.equalTo(self.iconImageView.snp.trailing).offset(8)
            make.bottom.equalTo(self.iconImageView.snp.centerY).offset(-2)
            make.trailing.equalTo(self.arrowRightImageView.snp.leading).offset(-8)
            make.height.equalTo(24)
        }
        
        self.lblUserID.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self.lblName)
            make.top.equalTo(self.lblName.snp.bottom).offset(4)
            make.height.equalTo(20)
        }
        
        self.tableView.snp.makeConstraints { make in
            make.height.equalTo(self.viewModel.numberOfRows() * 56)
            make.bottom.lessThanOrEqualToSuperview().offset(0)
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(self.infoView.snp.bottom).offset(8)
        }
        
        self.setupUserInfoViews()
    }
    
    override func initBinding() {
        super.initBinding()
        
        self.infoView.rx.click.subscribeSuccess { [unowned self] _ in
            let vm = self.viewModel.getPersonalInformationVM()
            self.navigator.show(scene: .personalInformation(vm: vm), sender: self)
        }.disposed(by: self.disposeBag)
        
        self.viewModel.avatarImage.bind(to: self.iconImageView.rx.image).disposed(by: self.disposeBag)
        self.viewModel.nickname.bind(to: self.lblName.rx.text).disposed(by: self.disposeBag)
        
        self.viewModel.showShareContent.observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] contentModel in
            guard let url = URL(string: contentModel.link) else { return }
            let activityItem = LinkActivityItemSource(title: contentModel.title, subtitle: contentModel.content, url: url)
            let activityVC = UIActivityViewController(activityItems: [activityItem], applicationActivities: nil)
            present(activityVC, animated: true, completion: nil)
        }.disposed(by: self.disposeBag)

        viewModel.showLoading.distinctUntilChanged().subscribeSuccess { isLoading in
            isLoading ? LoadingView.shared.show() : LoadingView.shared.hide()
        }.disposed(by: disposeBag)
        
        viewModel.reloadData.subscribeSuccess { [weak self] _ in
            guard let self = self else { return }
            self.tableView.reloadData()
        }.disposed(by: disposeBag)
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

private extension SettingViewController {
    
    func setupUserInfoViews() {        
        self.lblUserID.text = String(format: Localizable.idFormat, self.viewModel.userName)
    }
}

extension SettingViewController: UITableViewDelegate, UITableViewDataSource {
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
