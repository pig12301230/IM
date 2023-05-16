//
//  ActionToolVM.swift
//  ChatRoom
//
//  Created by ZoeLin on 2022/2/25.
//

import Foundation
import RxSwift
import RxCocoa

class ActionToolVM: BaseViewModel {
    struct Setting {
        var scene: ToolScene = .directMessage
        var sender: Sender = .oneself
        var messageTyep: MessageType = .text
        var anchor: AnchorPosition = .top
        var messageModel: MessageModel?
    }
    
    struct Output {
        // change action list and visble
        let actions = BehaviorRelay<[ActionType]>(value: [])
        // only change visble
        let visible = BehaviorRelay<Bool>(value: false)
        let active = PublishSubject<(ActionType, MessageModel)>()
    }
    
    private(set) var setting: Setting = Setting()
    private(set) var output: Output = Output()
        
    func setup(scene: ToolScene) {
        guard scene != setting.scene else {
            return
        }
        
        setting.scene = scene
    }
    
    func setup(sender: Sender, message: MessageModel, anchor: AnchorPosition) {
        setting.sender = sender
        setting.messageModel = message
        setting.messageTyep = message.messageType
        setting.anchor = anchor
        
        let mActions = getMessageActions(message.messageType, sender: sender)
        guard !mActions.isEmpty else {
            self.updateActions(to: [])
            return
        }
        
        let sActions = getSceneActions(setting.scene)
        let allActions = (mActions + sActions).removeDuplicateElement().sorted(by: <)
        self.updateActions(to: allActions)
    }
    
    func activeAction(_ action: ActionType) {
        guard let model = setting.messageModel else {
            return
        }
        
        self.output.active.onNext((action, model))
    }
    
    private func updateActions(to ations: [ActionType]) {
        guard output.actions.value != ations else {
            output.visible.accept(true)
            output.actions.accept(ations)
            return
        }
        
        PRINT("get actions == \(ations)")
        output.actions.accept(ations)
    }
}

private extension ActionToolVM {
    func getMessageActions(_ messageTyep: MessageType, sender: Sender) -> [ActionType] {
        var actions = [ActionType]()
        switch messageTyep {
        case .text:
            actions = [.delete, .copy, .reply]
        case .image:
            actions = [.delete, .reply]
        case .recommend:
            actions = [.announcement, .reply]
        // TODO: implement new message type
        // case video??
        // return [.delete, .unsend, .reply]
        
        // case emoji??
        // return [.unsend, .reply]
        default:
            return []
        }
        
        guard !actions.isEmpty, sender == .oneself else {
            return actions
        }
        // 只能撤回自己所發送的 message (文字讯息＼图片＼影片\emoji)
        if canBeUnsend() {
            actions.append(.unsend)
        }
        return actions
    }
    
    func getSceneActions(_ scene: ToolScene) -> [ActionType] {
        switch scene {
        case .directMessage:
            return [.announcement, .delete]
        case .groupMember:
            return [.delete]
        case .groupAdmin, .groupOwner:
            return [.announcement, .delete, .unsend]
       }
    }
    
    func canBeUnsend() -> Bool {
        guard let message = setting.messageModel else { return false }
        // 12小時內才可撤回訊息
        if Date().timeIntervalSince1970 - Double(message.timestamp) / 1000 < 3600 * 12 {
            return true
        } else {
            return false
        }
    }
}
