//
//  CreditViewController.swift
//  ChatRoom
//
//  Created by ERay_Peng on 2022/12/27.
//

import UIKit
import RxSwift
import RxCocoa

class CreditViewController: BaseVC {
    
    var viewModel: CreditViewControllerVM!
    
    private lazy var tableView: UITableView = {
        let tView = UITableView()
        tView.backgroundColor = .clear
        tView.separatorStyle = .none
        tView.alwaysBounceVertical = false
        tView.allowsSelection = false
        if #available(iOS 15, *) {
            tView.sectionHeaderTopPadding = 0
        }
        
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 12))
        footerView.backgroundColor = .white
        
        tView.tableFooterView = footerView
        tView.delegate = self
        tView.dataSource = self
        
        tView.registerHeaderFooter(BalanceRecordHeaderView.self)
        tView.register(BalanceRecordTableViewCell.self)
        return tView
    }()
    
    private lazy var creditSummaryView: UIView = {
        let view = UIView.init()
        view.theme_backgroundColor = Theme.c_07_neutral_50.rawValue
        return view
    }()
    
    private lazy var iconImageView: UIImageView = {
        let view = UIImageView.init()
        view.image = UIImage(named: "iconPopint")
        view.layer.cornerRadius = 24
        view.clipsToBounds = true
        view.theme_backgroundColor = Theme.c_01_primary_0_500.rawValue
        view.contentMode = .center
        return view
    }()
    
    private lazy var lblAmount: UILabel = {
        let lbl = UILabel()
        lbl.theme_textColor = Theme.c_10_grand_1.rawValue
        lbl.font = .boldParagraphGiantLeft
        lbl.text = "0"
        return lbl
    }()
    
    private lazy var lblCredit: UILabel = {
        let lbl = UILabel()
        lbl.text = Localizable.point
        lbl.font = .midiumParagraphMediumLeft
        lbl.theme_textColor = Theme.c_07_neutral_400.rawValue
        return lbl
    }()
    
    private lazy var btnExchange: UIButton = {
        let btn = UIButton()
        btn.titleLabel?.font = .boldParagraphMediumCenter
        btn.setTitle(Localizable.exchange, for: .normal)
        btn.theme_setTitleColor(Theme.c_09_white_66.rawValue, forState: .disabled)
        btn.theme_setTitleColor(Theme.c_09_white.rawValue, forState: .normal)
        btn.setBackgroundColor(color: Theme.c_01_primary_0_500.rawValue.toColor(), forState: .normal)
        btn.setBackgroundColor(color: Theme.c_07_neutral_200.rawValue.toColor(), forState: .disabled)
        btn.layer.cornerRadius = 4
        return btn
    }()
    
    static func initVC(with vm: CreditViewControllerVM) -> CreditViewController {
        let vc = CreditViewController.init()
        vc.viewModel = vm
        vc.title = Localizable.point
        return vc
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.viewModel.fetchHongBaoRecord()
        Task {
            let exchangeValid = await self.viewModel.isExchangeValid()
            btnExchange.isEnabled = exchangeValid
        }
    }
    
    override func setupViews() {
        super.setupViews()
        self.view.theme_backgroundColor = Theme.c_07_neutral_100.rawValue
        
        self.view.addSubviews([creditSummaryView, tableView])
        self.creditSummaryView.addSubviews([iconImageView, lblAmount, lblCredit, btnExchange])
        
        self.creditSummaryView.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
            make.height.equalTo(136)
        }
        
        self.tableView.snp.makeConstraints { make in
            make.leading.bottom.trailing.equalToSuperview()
            make.top.equalTo(creditSummaryView.snp.bottom)
        }
        
        self.iconImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
            make.width.height.equalTo(48)
        }
        
        self.lblAmount.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(8)
            make.top.equalTo(iconImageView)
            make.bottom.equalTo(iconImageView.snp.centerY)
        }
        
        self.lblCredit.snp.makeConstraints { make in
            make.leading.equalTo(lblAmount)
            make.top.equalTo(iconImageView.snp.centerY)
            make.bottom.equalTo(iconImageView)
        }
        
        self.btnExchange.snp.makeConstraints { make in
            make.top.bottom.equalTo(iconImageView)
            make.trailing.equalToSuperview().offset(-16)
            make.width.equalTo(86)
        }
    }
    
    override func initBinding() {
        super.initBinding()
        self.viewModel.updateAmount.observe(on: MainScheduler.instance).subscribeSuccess { [weak self] balance in
            guard let self = self else { return }
            self.lblAmount.text = balance
            self.tableView.reloadData()
        }.disposed(by: self.disposeBag)
        
        self.btnExchange.rx.click.subscribeSuccess { [weak self] _ in
            guard let self = self else { return }
            self.viewModel.handleSecurityCodeHasSet()
        }.disposed(by: self.disposeBag)
        
        self.viewModel.goto.observe(on: MainScheduler.instance).subscribeSuccess { [weak self] scene in
            guard let self = self else { return }
            self.navigator.show(scene: scene, sender: self, transition: .push(animated: true))
        }.disposed(by: self.disposeBag)
        
        self.viewModel.showSetPwdAlert.observe(on: MainScheduler.instance).subscribeSuccess { [weak self] _ in
            guard let self = self else { return }
            let config = DisplayConfig(font: .regularParagraphLargeCenter, textColor: Theme.c_10_grand_1.rawValue.toColor(), text: Localizable.setSecurityPasswordToBind)
            
            let dissmissAction = UIAlertAction(title: Localizable.goToSetting, style: .default) { _ in
                self.viewModel.gotoSetSecurityPwd()
            }
            
            self.showAlert(title: nil, message: config, actions: [dissmissAction])
        }.disposed(by: self.disposeBag)
    }
}

// MARK: tableView dataSource & delegate
extension CreditViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.hongBaoRecords.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "BalanceRecordTableViewCell", for: indexPath) as? BalanceRecordTableViewCell else {
            return UITableViewCell()
        }
        let data = self.viewModel.hongBaoRecords[indexPath.row]
        cell.config(with: data)
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "BalanceRecordHeaderView")
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 12
    }
}
