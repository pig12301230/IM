//
//  ReportViewController.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/5/14.
//

import UIKit
import RxSwift

class ReportViewController: BaseVC {

    var viewModel: ReportViewControllerVM!

    private lazy var tableView: IntrinsicTableView = {
        let header = ReportHeaderView(frame: CGRect(origin: .zero, size: CGSize(width: self.view.bounds.width, height: 44)),
                                      title: Localizable.pleaseSelectReportReason)

        let table = IntrinsicTableView()
        table.backgroundColor = .clear
        table.separatorStyle = .none
        table.delegate = self
        table.dataSource = self
        table.tableHeaderView = header
        table.register(ReportItemCell.self)
        return table
    }()

    private lazy var hint: UILabel = {
        let label = UILabel()
        label.font = .regularParagraphMediumLeft
        label.theme_textColor = Theme.c_10_grand_2.rawValue
        label.numberOfLines = 0
        label.lineBreakMode = .byCharWrapping
        label.text = Localizable.reportHint
        return label
    }()

    private lazy var sendButton: UIButton = {
        let button = UIButton()
        button.theme_backgroundColor = Theme.c_01_primary_400.rawValue
        button.theme_setTitleColor(Theme.c_09_white.rawValue, forState: .normal)
        button.titleLabel?.font = .boldParagraphMediumLeft
        button.setTitle(Localizable.agreeAndSend, for: .normal)
        button.layer.cornerRadius = 4
        button.clipsToBounds = true
        return button
    }()

    static func initVC(with vm: ReportViewControllerVM) -> ReportViewController {
        let vc = ReportViewController()
        vc.title = Localizable.report
        vc.viewModel = vm
        return vc
    }

    override func setupViews() {
        super.setupViews()

        self.view.theme_backgroundColor = Theme.c_07_neutral_50.rawValue

        self.view.addSubview(tableView)
        self.view.addSubview(hint)
        self.view.addSubview(sendButton)

        self.tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        self.sendButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-16)
            make.height.equalTo(48)
        }

        self.hint.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self.sendButton)
            make.bottom.equalTo(self.sendButton.snp.top).offset(-16)
            make.height.greaterThanOrEqualTo(70)
        }
    }

    override func initBinding() {
        super.initBinding()

        self.sendButton.rx.controlEvent(.touchUpInside).subscribeSuccess { [unowned self] in
            self.viewModel.sendReport()
        }.disposed(by: self.disposeBag)

        self.viewModel.showLoading.observe(on: MainScheduler.instance).subscribeSuccess { show in
            show ? LoadingView.shared.show() : LoadingView.shared.hide()
        }.disposed(by: self.disposeBag)

        self.viewModel.errorMessage.observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] message in
            // TODO: error mapping table
            self.showAlert(message: message, comfirmBtnTitle: Localizable.sure)
        }.disposed(by: self.disposeBag)

        self.viewModel.reportCompleted.observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] in
            self.toastManager = ToastManager()
            self.toastManager.showToast(icon: UIImage(named: "iconIconActionsCheckmarkCircle") ?? UIImage(),
                                         hint: Localizable.reportFinish)
            self.popViewController()
        }.disposed(by: self.disposeBag)
    }
}

extension ReportViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.viewModel.numberOfRow()
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        56
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.viewModel.cellIdentifier(), for: indexPath)
        if let cell = cell as? ImplementViewModelProtocol, let vm = self.viewModel.cellViewModel(in: indexPath) {
            cell.setupViewModel(viewModel: vm)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.viewModel.didSelected(at: indexPath)
    }
}
