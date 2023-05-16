//
//  AnnouncementViewModel.swift
//  ChatRoom
//
//  Created by Winston_Chuang on 2022/2/24.
//

import Foundation
import RxSwift
import RxRelay

class AnnouncementViewModel: BaseViewModel {
    
    private(set) var hasPermission: Bool = false
    private(set) var transceivers: [TransceiverModel] = []
    let isExpand: BehaviorRelay<Bool> = .init(value: false)
    
    let scrollToMessage: PublishSubject<String> = .init()
    let unpinMessage: PublishSubject<String> = .init()
    let announcements: BehaviorRelay<[AnnouncementModel]> = .init(value: [])
    
    init(with transceivers: [TransceiverModel]) {
        self.transceivers = transceivers
    }
    
    func setPermission(_ hasPermission: Bool) {
        self.hasPermission = hasPermission
    }
    
    func updateTransceivers(transceivers: [TransceiverModel]) {
        self.transceivers = transceivers
    }
}
