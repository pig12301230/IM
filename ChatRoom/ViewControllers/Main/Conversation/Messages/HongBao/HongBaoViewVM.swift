//
//  HongBaoViewVM.swift
//  ChatRoom
//
//  Created by Winston_Chuang on 2022/12/26.
//

import Foundation
import RxSwift
import RxRelay

class HongBaoViewVM: BaseViewModel {
    private var campaignID: String
    private var disposeBag = DisposeBag()
    let userHongBao: BehaviorSubject<UserHongBaoModel?> = .init(value: nil)
    let setupSenderView: BehaviorSubject<HongBaoContent?> = .init(value: nil)
    let showAlreadyOpened: BehaviorRelay<Bool> = .init(value: false)
    let closeHongBaoView: PublishSubject<Void> = .init()
    let showLoading = PublishRelay<Bool>()
    
    init(content: HongBaoContent) {
        self.campaignID = content.campaignID
        super.init()
        
        fetchClaimStatus(campaignID: campaignID)
            .subscribe(onNext: { [weak self] claimStatus in
                guard let self = self else { return }
                guard let claimStatus = claimStatus else {
                    self.setupSenderView.onNext(content)
                    return
                }
                if claimStatus.status == .withdrawble {
                    self.setupSenderView.onNext(content)
                } else {
                    // show ResultView
                    if claimStatus.status == .opened {
                        self.showAlreadyOpened.accept(true)
                    }
                    let hongBao = UserHongBaoModel(status: claimStatus.status, type: content.type)
                    self.userHongBao.onNext(hongBao)
                }
            }, onError: { _ in
                self.setupSenderView.onNext(content)
            }).disposed(by: disposeBag)
    }
    
    func fetchClaimStatus(campaignID: String) -> Observable<HongBaoClaimStatus?> {
        return DataAccess.shared.fetchHongBaoStatus(campaignID: campaignID)
    }
    
    func openHongBao() {
        self.showLoading.accept(true)
        DataAccess.shared.fetchUserHongBao(campaignID: self.campaignID)
            .subscribe { [weak self] userHongBao in
                guard let self = self else { return }
                self.showLoading.accept(false)
                
                if userHongBao?.status == .opened {
                    self.showAlreadyOpened.accept(true)
                }
                
                self.userHongBao.onNext(userHongBao)
            } onError: { [unowned self] _ in
                self.showLoading.accept(false)
            }.disposed(by: self.disposeBag)
    }
}
