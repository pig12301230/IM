//
//  RecommandMessageCellVM.swift
//  ChatRoom
//
//  Created by Saffi Peng on 2021/7/20.
//

import Foundation
import RxSwift
import RxCocoa

protocol RecommandMessageCellVMDelegate: AnyObject {
//    func goto(scene: Navigator.Scene)
}

class RecommandMessageCellVM: MessageBaseCellVM {

    weak var delegate: RecommandMessageCellVMDelegate?

    let template: BehaviorRelay<TemplateModel?> = BehaviorRelay(value: nil)
    private(set) var cellHeight: CGFloat = 202

    override init(model: MessageBaseModel, withRead: Bool) {
        super.init(model: model, withRead: withRead)
        self.cellIdentifier = (model.config.sender == .me ? "RecommandMessageRCell" : "RecommandMessageLCell")
        
        if let mTemplate = model.message.template {
            let height = mTemplate.description.height(width: (MessageContentSize.maxWidth - 32), font: UIFont.regularParagraphSmallLeft)
            cellHeight += height
        }
        
        self.config.accept(model.config)
        self.updateView(model: model)
        self.template.accept(model.message.template)
    }

    func gotoRecommand() {
        guard let urlString = self.template.value?.action?.url, let url = URL(string: urlString) else {
            return
        }
        let config = WebViewControllerVM.WebViewConfig(url: url, shouldHandleCookie: true)
//        delegate?.goto(scene: .customWeb(vm: WebViewControllerVM(config: config)))
    }

    func isOutlineContainerNeedToChangeLine() -> Bool {
        return AppConfig.Screen.isSmallScreen || self.baseModel.message.template?.betType.contains("定位") == true
    }
}
