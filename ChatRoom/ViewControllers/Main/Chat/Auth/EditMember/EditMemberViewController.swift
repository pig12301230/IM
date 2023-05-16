//
//  EditMemberViewController.swift
//  ChatRoom
//
//  Created by ZoeLin on 2022/1/22.
//

import Foundation
import UIKit
import RxSwift

class EditMemberViewController: BaseIntrinsicTableViewVC {
    
    private(set) lazy var searchView: SearchView = {
        return SearchView.init(with: self.viewModel.searchVM)
    }()
    
    private lazy var countView: UIView = {
        let view = UIView()
        view.theme_backgroundColor = Theme.c_07_neutral_50.rawValue
        view.addSubviews([lblCount, countSeparatorView])
        return view
    }()
    
    private lazy var countSeparatorView: UIView = {
        let view = UIView()
        view.theme_backgroundColor = Theme.c_07_neutral_900_10.rawValue
        return view
    }()
    
    private lazy var lblCount: UILabel = {
        let lbl = UILabel()
        lbl.theme_textColor = Theme.c_10_grand_2.rawValue
        lbl.font = .midiumParagraphMediumLeft
        return lbl
    }()
    
    private lazy var hintView: UIView = {
        let view = UIView()
        view.addSubviews([lblHint, hintSeparatorView])
        view.theme_backgroundColor = Theme.c_07_neutral_50.rawValue
        return view
    }()
    
    private lazy var hintSeparatorView: UIView = {
        let view = UIView()
        view.theme_backgroundColor = Theme.c_07_neutral_900_10.rawValue
        return view
    }()
    
    private lazy var lblHint: UILabel = {
        let lbl = UILabel()
        lbl.text = viewModel.editType.hintMessage
        lbl.theme_textColor = Theme.c_10_grand_2.rawValue
        lbl.font = .midiumParagraphMediumLeft
        lbl.numberOfLines = 0
        return lbl
    }()
    
    private lazy var lblEdit: UILabel = {
        let lbl = UILabel()
        lbl.text = Localizable.edit
        lbl.font = .boldParagraphLargeRight
        lbl.theme_textColor = Theme.c_10_grand_1.rawValue
        return lbl
    }()
    
    private lazy var emptyView: EmptyView = {
        let view = EmptyView()
        view.updateEmptyType(.noSearchResults)
        return view
    }()
    
    var viewModel: EditMemberViewControllerVM!
    
    static func initVC(with vm: EditMemberViewControllerVM) -> EditMemberViewController {
        let vc = EditMemberViewController()
        vc.viewModel = vm
        vc.title = vm.editType.title
        return vc
    }
    
    override func setupViews() {
        super.setupViews()
        
        if viewModel.canRemove {
            let barItem = UIBarButtonItem.init(customView: lblEdit)
            self.navigationItem.rightBarButtonItem = barItem
        }
        
        view.addSubview(searchView)
        view.addSubview(countView)
        view.addSubview(hintView)
        view.addSubview(emptyView)
        view.theme_backgroundColor = Theme.c_07_neutral_0.rawValue
        
        searchView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(viewModel.canSearch ? 52 : 0)
        }
        
        countView.snp.makeConstraints { make in
            make.top.equalTo(searchView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(viewModel.countViewHight)
        }
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(hintView.snp.bottom)
            make.bottom.leading.trailing.equalToSuperview()
        }
        
        emptyView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        if viewModel.showHintView {
            hintView.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview()
                make.top.equalTo(countView.snp.bottom)
            }
            
            lblHint.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(16)
                make.trailing.equalToSuperview().offset(-16)
                make.top.equalToSuperview().offset(16)
                make.bottom.equalToSuperview().offset(-8)
            }
            
            hintSeparatorView.snp.makeConstraints { make in
                make.leading.trailing.bottom.equalToSuperview()
                make.height.equalTo(1)
            }
        } else {
            hintView.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview()
                make.top.equalTo(countView.snp.bottom)
                make.height.equalTo(0)
            }
        }
        
        lblHint.isHidden = !viewModel.showHintView
        hintSeparatorView.isHidden = !viewModel.showHintView
        
        let showCountView = viewModel.countViewHight > 0
        lblCount.isHidden = !showCountView
        countSeparatorView.isHidden = !showCountView
        guard showCountView else {
            return
        }
        
        lblCount.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().offset(-8)
        }
        
        countSeparatorView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(1)
        }
    }
    
    override func initBinding() {
        super.initBinding()
        
        lblEdit.rx.click.throttle(.milliseconds(500), scheduler: MainScheduler.instance).subscribeSuccess { [unowned self] _ in
            if self.tableView.isEditing {
                self.tableView.setEditing(false, animated: false)
            }
            
            self.viewModel.changeEditStatus()
            self.tableView.setEditing(self.viewModel.isEditing, animated: true)
        }.disposed(by: disposeBag)
        
        viewModel.showAlert.subscribeSuccess { [unowned self] message in
            self.showAlert(message: message, comfirmBtnTitle: Localizable.confirm)
        }.disposed(by: disposeBag)
        
        viewModel.isLoading.subscribeSuccess { isLoading in
            isLoading ? LoadingView.shared.show() : LoadingView.shared.hide()
        }.disposed(by: disposeBag)
        
        viewModel.reloadView.observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] in
            self.tableView.reloadData()
        }.disposed(by: disposeBag)
        
        viewModel.countText.bind(to: self.lblCount.rx.text).disposed(by: disposeBag)

        viewModel.isEmptyResult.observe(on: MainScheduler.instance).subscribeSuccess { [unowned self] emptyResult in
            self.emptyView.isHidden = !emptyResult
            self.view.theme_backgroundColor = emptyResult ? Theme.c_07_neutral_50.rawValue : Theme.c_07_neutral_0.rawValue
        }.disposed(by: disposeBag)
    }
    
    override func setupNavigationBar() {
        super.setupNavigationBar()
        self.btnBack.setImage(UIImage(named: viewModel.editType.backButtonIcon), for: .normal)
        self.btnBack.theme_tintColor = Theme.c_10_grand_1.rawValue
        let barItem = UIBarButtonItem.init(customView: btnBack)
        self.navigationItem.leftBarButtonItem = barItem
    }
    
    // MARK: - IntrinsicTableViewVCProtocol
    override func implementTableViewDelegateAndDataSource() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsSelectionDuringEditing = true
    }
    
    override func registerCells() {
        for type in viewModel.cellTypes {
            tableView.register(type.cellClass, forCellReuseIdentifier: type.cellIdentifier)
        }
    }
    
    private func showConfirm(indexPath: IndexPath, completion: ((Bool) -> Void)? = nil) {
        let alert = UIAlertController(title: "", message: viewModel.deleteMessage(at: indexPath.row), preferredStyle: .alert)
        
        let cancel = UIAlertAction(title: Localizable.cancel, style: .default) { _ in
            completion?(false)
        }
        let deleteTitle = viewModel.editType == .admin ? Localizable.remove : Localizable.delete
        let delete = UIAlertAction(title: deleteTitle, style: .destructive) { _ in
            self.viewModel.delete(at: indexPath.row)
            completion?(true)
        }
        alert.addAction(cancel)
        alert.addAction(delete)

        self.present(alert, animated: true)
    }
}

extension EditMemberViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.numberOfRows()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.viewModel.cellIdentifier(at: indexPath.row), for: indexPath)
        
        if let cell = cell as? MemberTableViewCell {
            let config = self.viewModel.cellConfig(at: indexPath.row)
            cell.setupConfig(config)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.viewModel.cellHeight(at: indexPath.row)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let scene = self.viewModel.getScene(at: indexPath.row) else {
            return
        }
        
        self.navigator.show(scene: scene, sender: self)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return self.viewModel.cellCanEdit(at: indexPath.row)
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else {
            return
        }
        
        self.showConfirm(indexPath: indexPath)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard !self.viewModel.isEditing else {
            self.showConfirm(indexPath: indexPath)
            return UISwipeActionsConfiguration(actions: [])
        }
        
        let actionDelete = UIContextualAction(style: .destructive, title: Localizable.delete) { (action, _, completion) in
            action.backgroundColor = Theme.c_06_danger_0_500.rawValue.toColor()
            self.showConfirm(indexPath: indexPath, completion: completion)
        }
        return UISwipeActionsConfiguration(actions: [actionDelete])
    }
}
