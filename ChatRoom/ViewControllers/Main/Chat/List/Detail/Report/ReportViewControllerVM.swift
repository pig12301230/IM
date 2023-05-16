//
//  ReportViewControllerVM.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/5/14.
//

import Foundation
import RxSwift
import RxCocoa

class ReportViewControllerVM: BaseViewModel {

    enum ReportType: Int, CaseIterable {
        case spam = 0, sexual, harassment, other

        var title: String {
            switch self {
            case .spam:
                return Localizable.spamAdvertising
            case .sexual:
                return Localizable.sexualHarassment
            case .harassment:
                return Localizable.otherHarassment
            case .other:
                return Localizable.other
            }
        }
    }

    private var disposeBag = DisposeBag()

    let showLoading = PublishRelay<Bool>()
    let errorMessage = PublishRelay<String>()
    let reportCompleted = PublishRelay<Void>()

    private let reportUser: (groupID: String?, userID: String)

    private var reportVMs: [ReportItemCellVM] = []
    private var selectedType: ReportType = .spam

    init(groupID: String? = nil, userID: String) {
        self.reportUser = (groupID, userID)

        super.init()
        self.createCellVMs()
    }

    func createCellVMs() {
        for type in ReportType.allCases {
            let item = ReportItemCellVM.ItemModel(selected: (type == self.selectedType), title: type.title, hideSeparatorLine: (type == .other))
            let vm = ReportItemCellVM(with: item)
            self.reportVMs.append(vm)
        }
    }

    func didSelected(at indexPath: IndexPath) {
        guard let type = ReportType(rawValue: indexPath.row) else {
            return
        }
        if type != self.selectedType {
            self.updateSelection(to: type)
        }
    }

    func sendReport() {
        self.showLoading.accept(true)
        if let groupID = self.reportUser.groupID {
            ApiClient.groupReport(groupID: groupID, reason: selectedType.rawValue + 1)
                .subscribe(onNext: nil) { [weak self] _ in
                    guard let self = self else { return }
                    self.showLoading.accept(false)
                } onCompleted: {
                    self.showLoading.accept(false)
                    self.reportCompleted.accept(())
                }.disposed(by: disposeBag)
            return
        }
        
        ApiClient.report(userID: self.reportUser.userID, reason: self.selectedType.rawValue + 1)
            .subscribe(onNext: nil) { [weak self] (_) in
                guard let self = self else { return }
                self.showLoading.accept(false)
            } onCompleted: {
                self.showLoading.accept(false)
                self.reportCompleted.accept(())
            }.disposed(by: self.disposeBag)
    }
}

// MARK: - Private
private extension ReportViewControllerVM {
    func updateSelection(to newType: ReportType) {
        self.reportVMs[self.selectedType.rawValue].selected.accept(false)
        self.reportVMs[newType.rawValue].selected.accept(true)

        self.selectedType = newType
    }
}

// MARK: - Setup TableView
extension ReportViewControllerVM {
    func numberOfRow() -> Int {
        return ReportType.allCases.count
    }

    func cellIdentifier() -> String {
        return "ReportItemCell"
    }

    func cellViewModel(in indexPath: IndexPath) -> BaseTableViewCellVM? {
        guard self.reportVMs.count > indexPath.row else {
            return nil
        }
        return self.reportVMs[indexPath.row]
    }
}
