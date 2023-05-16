//
//  MemberInfoCellVM.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/5/7.
//

import Foundation
import RxSwift
import RxCocoa

class MemberInfoCellVM: BaseTableViewCellVM {

    struct InfoModel {
        let avatarURL: String
        var nickname: String
        var members: [FriendModel]?
        var isDeleted: Bool = false
    }
    let avatarImage: BehaviorRelay<String> = BehaviorRelay(value: "")
    let nickname: BehaviorRelay<String> = BehaviorRelay(value: "")
    let showIsDeletedUser: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    let avatarTapped = PublishSubject<Void>()
    let reloadData = PublishRelay<Void>()
    let tapMemberList = PublishRelay<[FriendModel]>()

    private(set) var infoModel: InfoModel?
    private var vmList: [[BaseCollectionViewCellVMProtocol]] = []
    private let displayCount: Int = 4
    
    override init() {
        super.init()
        self.cellIdentifier = "MemberInfoCell"
    }

    convenience init(with info: InfoModel? = nil) {
        self.init()
        infoModel = info
        setupViews()
        parseMemberVM()
    }

    func setupViews() {
        guard let info = self.infoModel else { return }
        avatarImage.accept(info.avatarURL)
        nickname.accept(info.nickname)
        showIsDeletedUser.accept(info.isDeleted)
    }
    
    func updateMemebers(members: [FriendModel]) {
        infoModel?.members = members
        vmList.removeAll()
        parseMemberVM()
    }
    
    func updateNickname(nickname: String) {
        infoModel?.nickname = nickname
        self.nickname.accept(nickname)
    }
    
    func parseMemberVM() {
        guard let groupMembers = infoModel?.members else { return }

        let sorted = groupMembers.sorted { $0.joinAt?.timeIntervalSince1970 ?? 0 < $1.joinAt?.timeIntervalSince1970 ?? 0 }
        var displaySection: [BaseCollectionViewCellVMProtocol] = []
        for (idx, member) in sorted.enumerated() where idx < displayCount {
            let vm = GroupAvatarCellVM(with: member)
            displaySection.append(vm)
        }
        vmList.append(displaySection)
        let restVM = GroupMoreCellVM(with: sorted) // show all group member count
        vmList.append([restVM])
        reloadData.accept(())
    }
    
    func numberOfRow(in section: Int) -> Int {
        return vmList[section].count
    }
    
    func numerOfSection() -> Int {
        return vmList.count
    }
    
    func cellViewModel(in indexPath: IndexPath) -> BaseCollectionViewCellVMProtocol? {
        return vmList[indexPath.section][indexPath.item]
    }
    
    func didSelect(at indexPath: IndexPath) {
        guard indexPath.section == 1,
              let vm = vmList[indexPath.section][indexPath.item] as? GroupMoreCellVM,
              let members = vm.data else { return }
        tapMemberList.accept(members)
    }
}
