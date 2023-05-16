//
//  ExchangeViewController.swift
//  GuChat
//
//  Created by ERay_Peng on 2023/2/14.
//

import UIKit
import RxSwift

class ExchangeViewController: BaseIntrinsicTableViewVC {
    
    var viewModel: ExchangeViewControllerVM!
    
    private lazy var arrowRightImageView: UIImageView = {
        let view = UIImageView.init(image: UIImage.init(named: "iconArrowsChevronRight"))
        view.contentMode = .scaleAspectFit
        view.theme_tintColor = Theme.c_07_neutral_500.rawValue
        return view
    }()
    
    static func initVC(with vm: ExchangeViewControllerVM) -> ExchangeViewController {
        let vc = ExchangeViewController.init()
        vc.viewModel = vm
        vc.title = Localizable.exchange
        return vc
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.viewModel.fetchMediumBinding()
    }
    
    override func setupViews() {
        super.setupViews()
        self.view.theme_backgroundColor = Theme.c_07_neutral_100.rawValue
        
        self.tableView.snp.makeConstraints { make in
            make.height.equalTo(self.viewModel.numberOfRows() * 56)
            make.bottom.lessThanOrEqualToSuperview().offset(0)
            make.leading.top.trailing.equalToSuperview()
        }
    }
    
    override func initBinding() {
        super.initBinding()
        
        self.viewModel.reloadRowAt
            .observe(on: MainScheduler.instance)
            .bind(onNext: { [weak self] row in
                guard let self = self else { return }
                let indexPath = IndexPath(row: row, section: 0)
                self.tableView.reloadRows(at: [indexPath], with: .none)
            }).disposed(by: disposeBag)
        
        self.viewModel.showExchangeDisableAlert
            .observe(on: MainScheduler.instance)
            .subscribeSuccess { [weak self] _ in
                guard let self = self else { return }
                self.showAlert(message: Localizable.exchangeDisableHint, cancelBtnTitle: Localizable.sure, comfirmBtnTitle: nil)
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

extension ExchangeViewController: UITableViewDelegate, UITableViewDataSource {
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
        
        self.navigator.show(scene: scene, sender: self, transition: .push(animated: false))
    }
}
