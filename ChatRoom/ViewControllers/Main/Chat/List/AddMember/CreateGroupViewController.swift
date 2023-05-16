//
//  CreateGroupViewController.swift
//  ChatRoom
//
//  Created by Winston_Chuang on 2022/1/21.
//

import Foundation
import UIKit

class CreateGroupViewController: BaseVC {
    var viewModel: CreateGroupViewControllerVM!
    
    private lazy var createBarButtonItem: UIBarButtonItem = {
        let buttonItem = UIBarButtonItem.init(title: Localizable.build,
                                              style: .plain,
                                              target: self,
                                              action: #selector(create))
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
    
    private lazy var groupView: UIView = {
        let view = UIView()
        return view
    }()
    
    private lazy var imgGroup: UIImageView = {
        let imgView = UIImageView()
        imgView.contentMode = .scaleAspectFill
        imgView.image = UIImage(named: "avatarsGroup")
        return imgView
    }()
    
    private lazy var imgCamera: UIImageView = {
        let imgView = UIImageView()
        imgView.image = UIImage(named: "iconIconDevicesCamera")
        return imgView
    }()
    
    private lazy var lblGroupNameLimit: UILabel = {
        let label = UILabel()
        label.textAlignment = .right
        label.font = .regularParagraphMediumRight
        label.theme_textColor = Theme.c_07_neutral_400.rawValue
        return label
    }()
    
    private lazy var groupNameInputView: MultipleRulesInputView = {
        let inputView = MultipleRulesInputView(with: self.viewModel.groupNameViewModel)
        
        return inputView
    }()
    
    private lazy var lblGroupLimit: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.font = .midiumParagraphMediumLeft
        label.theme_textColor = Theme.c_10_grand_2.rawValue
        return label
    }()
    
    private lazy var demarcationView: UIView = {
        let view = UIView()
        view.theme_backgroundColor = Theme.c_07_neutral_900_10.rawValue
        return view
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.theme_backgroundColor = Theme.c_07_neutral_50.rawValue

        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.register(AddMemberCollectionViewCell.self, forCellWithReuseIdentifier: "memberCell")
        return collectionView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    static func initVC(with viewModel: CreateGroupViewControllerVM) -> CreateGroupViewController {
        let vc = CreateGroupViewController()
        vc.viewModel = viewModel
        return vc
    }
    
    @objc func create() {
        self.viewModel.createGroup(with: imgGroup.image)
    }
    
    override func initBinding() {
        self.viewModel.reloadData
            .bind { [unowned self] in
                collectionView.reloadData()
                let count = self.viewModel.selectedMembers.count
                let format = String(format: Localizable.groupMembersCountIOS, String(count))
                self.lblGroupLimit.text = format
            }
            .disposed(by: disposeBag)
        
        viewModel.canCreate
            .bind { [unowned self] canCreate in
                navigationItem.rightBarButtonItem?.isEnabled = canCreate
            }
            .disposed(by: disposeBag)
        
        viewModel.createSuccess
            .bind { [unowned self] in
                navigator.pop(sender: self, toRoot: true, animated: true)
            }
            .disposed(by: disposeBag)
        
        groupView.rx.click
            .bind { [unowned self] in
                PhotoLibraryManager.open(sender: self, type: .select, allowEdit: true) { [weak self] image in
                    guard let self = self,
                          let image = image else {
                        return
                    }
                    
                    self.viewModel.groupImg.accept(image)
                    self.imgGroup.image = image
                }
            }
            .disposed(by: disposeBag)
        
        viewModel.groupNameViewModel.inputText
            .bind { [unowned self] str in
                let count = str?.count ?? 0
                self.lblGroupNameLimit.text = "\(String(count))/20"
            }
            .disposed(by: disposeBag)
        
        viewModel.showLoading.subscribeSuccess { show in
            show ? LoadingView.shared.show() : LoadingView.shared.hide()
        }.disposed(by: self.disposeBag)
        
        viewModel.showError
            .bind { [unowned self] errorMsg in
                showAlert(title: Localizable.serverParamInvalid,
                          message: errorMsg,
                          comfirmBtnTitle: Localizable.sure,
                          onConfirm: nil)
            }.disposed(by: disposeBag)
    }
    
    override func setupViews() {
        super.setupViews()
        view.backgroundColor = .white
        title = Localizable.addGroup
        navigationItem.rightBarButtonItem = createBarButtonItem
        
        self.lblGroupLimit.text = String(format: Localizable.groupMembersCountIOS, String(viewModel.selectedMembers.count))
        
        view.addSubviews([groupView, lblGroupNameLimit, groupNameInputView, lblGroupLimit, demarcationView, collectionView])
        groupView.addSubviews([imgGroup, imgCamera])
        
        groupView.snp.makeConstraints { make in
            make.width.height.equalTo(84)
            make.top.leading.equalTo(16)
        }
        
        imgGroup.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        imgGroup.roundSelf()
        
        imgCamera.snp.makeConstraints { make in
            make.width.height.equalTo(24)
            make.trailing.equalTo(imgGroup.snp.trailing)
            make.bottom.equalTo(imgGroup.snp.bottom)
        }
        imgCamera.roundSelf()
        
        groupNameInputView.snp.makeConstraints { make in
            make.top.equalTo(lblGroupNameLimit.snp.bottom)
            make.leading.equalTo(imgGroup.snp.trailing).offset(12)
            make.trailing.equalTo(-16)
            make.height.equalTo(48)
        }
        
        lblGroupNameLimit.snp.makeConstraints { make in
            make.top.equalTo(16)
            make.trailing.equalTo(-16)
            make.leading.equalTo(imgGroup.snp.trailing).offset(12)
            make.height.equalTo(20)
        }
        
        lblGroupLimit.snp.makeConstraints { make in
            make.top.equalTo(imgGroup.snp.bottom).offset(32)
            make.leading.equalTo(16)
            make.trailing.equalTo(-16)
            make.height.equalTo(20)
        }
        
        demarcationView.snp.makeConstraints { make in
            make.height.equalTo(1)
            make.top.equalTo(lblGroupLimit.snp.bottom).offset(7)
            make.leading.trailing.equalToSuperview()
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(demarcationView.snp.bottom).offset(16)
            make.leading.equalTo(16)
            make.trailing.equalTo(-16)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }
}

extension CreateGroupViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.viewModel.selectedMembers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "memberCell", for: indexPath) as? AddMemberCollectionViewCell else {
            return UICollectionViewCell()
        }
        let member = self.viewModel.selectedMembers[indexPath.row]
        if indexPath.row == 0 {
            cell.hideDeleteBtn()
        }
        cell.setupMember(member: member)

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let member = self.viewModel.selectedMembers[indexPath.row]
        self.viewModel.removeMember.onNext(member)
    }
    
}

extension CreateGroupViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 60, height: 84)
    }
}
