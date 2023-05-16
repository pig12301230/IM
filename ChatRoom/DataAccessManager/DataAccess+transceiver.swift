//
//  DataAccess+transceiver.swift
//  ChatRoom
//
//  Created by Winston_Chuang on 2023/3/23.
//

import Foundation

extension DataAccess {
    
    func getGroupTransceiver(by groupID: String, memberID: String) -> TransceiverModel? {
        let id = TransceiverModel.uniqueID(groupID, memberID)
        return self.realmDAO.immediatelyModel(type: TransceiverModel.self, id: id)
    }
    
    func updateGroupTransceiver(transceiverID: String, isMember: Bool, atGroup groupID: String) {
        updateTransceiverStatus(transceiverKey: transceiverID, isMember: isMember) { [weak self] in
            guard let self = self else { return }
            self.realmDAO.getModels(type: TransceiverModel.self, predicateFormat: "groupID = '\(groupID)'") { transceiverModels in
                self.replaceGroupTransceivers(groupID: groupID, transceivers: transceiverModels ?? [])
            }
        }
    }
    
    func updateTransceiverStatus(transceiverKey: String, isMember: Bool, complete: @escaping () -> Void) {
        realmDAO.getModel(type: TransceiverModel.self, id: transceiverKey) { model in
            guard var model = model else {
                complete()
                return
            }
            model.isMember = isMember
            let rlm = model.convertToDBObject()
            self.realmDAO.update([rlm], policy: .modified, completion: complete)
        }
    }
    
    /**
     更新 group's transceivers, 如有重複的 transceiver.id 已傳入的作為新的資料
     - Parameters:
       - groupID:
       - transceivers:
     */
    func updateGroupTransceivers(groupID: String, transceivers: [TransceiverModel]) {
        let observer = getGroupObserver(by: groupID)
        let trans: [TransceiverModel] = Array(observer.transceiverDict.value.values)

        // 統一使用同一個入口改寫 signal's info
        replaceGroupTransceivers(groupID: groupID, transceivers: trans + transceivers)
    }

    /**
     替換掉 group's transceivers
     - Parameters:
       - groupID:
       - transceivers:
     */
    func replaceGroupTransceivers(groupID: String, transceivers: [TransceiverModel]) {
        let dict = transceivers.toDictionary { $0.userID }
        getGroupObserver(by: groupID).transceiverDict.accept(dict)
    }
}
