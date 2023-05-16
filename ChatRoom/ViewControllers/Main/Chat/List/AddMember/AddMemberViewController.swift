//
//  AddMemberViewController.swift
//  ChatRoom
//
//  Created by Winston_Chuang on 2022/1/19.
//

import Foundation
import UIKit
import SwiftTheme

class AddMemberViewController: BaseVC {
    var vm: AddMemberViewControllerVM!
    
    private lazy var titleView: UIStackView = {
        let stackView = UIStackView()
        stackView.distribution = .equalCentering
        stackView.alignment = .center
        stackView.axis = .vertical
        return stackView
    }()
    
    private lazy var lblTitle: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.theme_textColor = Theme.c_10_grand_1.rawValue
        label.font = .boldParagraphLargeCenter
        return label
    }()
    
    private lazy var lblMemberLimit: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .regularParagraphTinyCenter
        label.theme_textColor = Theme.c_10_grand_1.rawValue
        label.text = String(format: Localizable.candidateMemberCountIOS, "0")
        return label
    }()
    
    private lazy var searchView: SearchView = {
        let searchView = SearchView.init(with: vm.searchVM)
        return searchView
    }()
    
    private lazy var lineView: UIView = {
        let view = UIView()
        view.theme_backgroundColor = Theme.c_07_neutral_900_10.rawValue
        
        return view
    }()
    
    private lazy var selectedView: UIView = {
        let view = UIView()
        view.theme_backgroundColor = Theme.c_07_neutral_50.rawValue
        return view
    }()
    
    private lazy var lblInfo: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.theme_textColor = Theme.c_07_neutral_400.rawValue
        label.font = .regularParagraphMediumLeft
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.theme_backgroundColor = Theme.c_07_neutral_50.rawValue

        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.showsHorizontalScrollIndicator = false
        
        collectionView.register(AddMemberCollectionViewCell.self, forCellWithReuseIdentifier: "addMemberCollectionViewCell")
        return collectionView
    }()
    
    private lazy var groupView: UIView = {
        let view = UIView()
        view.theme_backgroundColor = Theme.c_07_neutral_50.rawValue

        let demarcationView = UIView()
        demarcationView.theme_backgroundColor = Theme.c_07_neutral_900_10.rawValue
        
        view.addSubview(demarcationView)
        
        demarcationView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(1)
        }
        
        return view
    }()
    
    private lazy var groupLabel: UILabel = {
        let label = UILabel()
        label.font = .midiumParagraphMediumLeft
        label.theme_textColor = Theme.c_10_grand_2.rawValue
        label.textAlignment = .left
        return label
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.theme_backgroundColor = Theme.c_07_neutral_0.rawValue
        
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        
        tableView.register(SectionHeaderView.self, forHeaderFooterViewReuseIdentifier: "titleHeader")
        tableView.register(AddMemberCell.self, forCellReuseIdentifier: "addMemberCell")
        
        tableView.allowsMultipleSelection = true
        return tableView
    }()
    
    private lazy var nextBarButtonItem: UIBarButtonItem = {
        let buttonItem = UIBarButtonItem.init(title: Localizable.next,
                                              style: .plain,
                                              target: self,
                                              action: #selector(nextAction))
        buttonItem.theme_tintColor = Theme.c_10_grand_1.rawValue
        buttonItem.setTitleTextAttributes([.font: UIFont.boldParagraphLargeRight,
                                           .foregroundColor: Theme.c_10_grand_1.rawValue.toColor()],
                                          for: .normal)
        buttonItem.setTitleTextAttributes([.font: UIFont.boldParagraphLargeRight,
                                           .foregroundColor: Theme.c_10_grand_1.rawValue.toColor()],
                                          for: .selected)
        buttonItem.setTitleTextAttributes([.font: UIFont.boldParagraphLargeRight,
                                           .foregroundColor: Theme.c_07_neutral_400.rawValue.toColor()],
                                          for: .disabled)
        return buttonItem
    }()
    
    static func initVC(type: AddMemberType, members: [FriendModel], groupID: String?) -> AddMemberViewController {
        let vc = AddMemberViewController()
        vc.barType = .pure
        vc.vm = AddMemberViewControllerVM(type: type, members: members, groupID: groupID)
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    @objc func nextAction() {
        self.vm.nextAction()
    }
    
    override func initBinding() {
        vm.reloadData.bind { [weak self] _ in
            self?.tableView.reloadData()
        }.disposed(by: disposeBag)
        
        vm.selectedMemberList.bind { [weak self] members in
            guard let self = self else { return }
            if !members.isEmpty {
                self.collectionView.reloadData()
                self.tableView.reloadData()
            }
            
            let candidateCount = members.count + self.vm.currentMemeberList.count + (self.vm.type == .createGroup ? 1:0)
            let format = String(format: Localizable.candidateMemberCountIOS, String(candidateCount))
            self.lblMemberLimit.text = format
            self.navigationItem.rightBarButtonItem?.isEnabled = !members.isEmpty
            self.collectionView.isHidden = members.isEmpty
            self.lblInfo.isHidden = !members.isEmpty
            
            self.selectedView.snp.updateConstraints { make in
                make.height.equalTo(self.vm.selectedViewHeight)
            }
        }.disposed(by: disposeBag)
        
        vm.alertMessage
            .bind { [unowned self] message in
                let action = UIAlertAction(title: Localizable.add, style: .destructive) { _ in
                    vm.confirmAction()
                }
                showSheet(title: "", message: message, actions: action, cancelBtnTitle: Localizable.cancel)
            }.disposed(by: disposeBag)
        
        vm.showLoading
            .bind { show in
                show ? LoadingView.shared.show() : LoadingView.shared.hide()
            }.disposed(by: disposeBag)
        
        vm.showError
            .bind { [unowned self] errorMsg in
                showAlert(title: Localizable.serverParamInvalid,
                          message: errorMsg,
                          comfirmBtnTitle: Localizable.sure,
                          onConfirm: nil)
            }.disposed(by: disposeBag)

        vm.dissmissVC
            .bind { [unowned self] in
                navigator.pop(sender: self)
            }.disposed(by: disposeBag)
        
        vm.navigateToCreateGroup
            .bind { [unowned self] _ in
                guard let selfData = vm.mySelfData else { return }
                let viewModel = CreateGroupViewControllerVM(selectedMembers: vm.selectedMemberList.value,
                                                            mySelfData: selfData)
                viewModel.removeMember.bind(to: self.vm.removeSelectedMember).disposed(by: disposeBag)
                navigator.show(scene: .createGroup(vm: viewModel), sender: self)
            }
            .disposed(by: disposeBag)
    }
    
    override func setupViews() {
        groupLabel.text = self.vm.type.groupName
        lblTitle.text = self.vm.type.title
        lblInfo.text = self.vm.type.selectedEmptyInfo
        
        titleView.addArrangedSubviews([lblTitle, lblMemberLimit])
        
        lblMemberLimit.isHidden = vm.type == .addBlacklist || vm.type == .addAdmin
            
        self.navigationItem.titleView = titleView
        
        if vm.type != .addAdmin {
            self.navigationItem.rightBarButtonItem = nextBarButtonItem
        }
        
        view.addSubviews([searchView, selectedView, groupView, tableView])
        selectedView.addSubviews([collectionView, lblInfo])
        
        groupView.addSubview(groupLabel)
        
        selectedView.addSubview(lineView)
        
        searchView.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
            make.height.equalTo(52)
        }
        
        selectedView.snp.makeConstraints { make in
            make.top.equalTo(searchView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(self.vm.selectedViewHeight)
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.leading.trailing.bottom.equalToSuperview()
        }
        
        lblInfo.snp.makeConstraints { make in
            make.top.leading.equalTo(12)
            make.trailing.equalTo(-12)
        }
        
        lineView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(1)
        }
        
        groupView.snp.makeConstraints { make in
            make.top.equalTo(selectedView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(44)
        }
        
        groupLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-8)
        }
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(groupView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
}

extension AddMemberViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.vm.memberList.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.vm.memberList[section].members.count
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let member = self.vm.memberList[indexPath.section].members[indexPath.row]
        
        if self.vm.selectedMemberList.value.contains(where: { $0.id == member.id }) {
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "addMemberCell", for: indexPath) as? AddMemberCell else {
            return UITableViewCell()
        }
        
        guard let member = self.vm.getFriendModel(section: indexPath.section, row: indexPath.row) else {
            return cell
        }
        
        let isExist = self.vm.isAlreadyInList(member: member)
        cell.setup(member: member, isExist: isExist, needCheckBox: self.vm.needCheckBox())
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard self.vm.type != .addAdmin else {
            return indexPath
        }
        
        // 檢查是否已在群組內
        if let cell = tableView.cellForRow(at: indexPath) as? AddMemberCell,
           cell.isExist {
            return nil
        } else if self.vm.selectedMemberList.value.count >= self.vm.type.maxLimit {
            // 檢查是否新增超出數量
            showAlert(title: "", message: vm.type.exceedAlert, comfirmBtnTitle: Localizable.sure, onConfirm: nil)
            return nil
        } else {
            return indexPath
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let member = self.vm.getFriendModel(section: indexPath.section, row: indexPath.row) else {
            return
        }
            
        guard let scene = self.vm.getNextScene(at: indexPath) else {
            guard let cell = tableView.cellForRow(at: indexPath) as? AddMemberCell else { return }
            cell.setCheckedImage()
            self.vm.addSelectedMember.onNext(member)
            return
        }
        
        self.navigator.show(scene: scene, sender: self)
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? AddMemberCell else { return }
        let member = self.vm.memberList[indexPath.section].members[indexPath.row]
        cell.setCheckedImage()
        self.vm.removeSelectedMember.onNext(member)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "titleHeader") as? SectionHeaderView
        header?.setSectionTitle(self.vm.memberList[section].title)
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if self.vm.isSearching {
            return 0
        } else {
            return 36
        }
    }
}

extension AddMemberViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.vm.selectedMemberList.value.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "addMemberCollectionViewCell", for: indexPath) as? AddMemberCollectionViewCell else {
            return UICollectionViewCell()
        }
        let member = self.vm.selectedMemberList.value[indexPath.row]
        cell.setupMember(member: member)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let member = self.vm.selectedMemberList.value[indexPath.row]
        self.vm.removeSelectedMember.onNext(member)
        if let indexPath = vm.getFriendIndexPath(member: member),
           let cell = tableView.cellForRow(at: indexPath) as? AddMemberCell {
            cell.setSelected(false, animated: true)
        }
    }
}

extension AddMemberViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 60, height: 84)
    }
}
