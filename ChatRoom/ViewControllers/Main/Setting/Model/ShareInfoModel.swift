//
//  ShreLinkModel.swift
//  ChatRoom
//
//  Created by ERay_Peng on 2022/4/14.
//

struct ShareInfoModel {
    let title: String
    let content: String
    let link: String
    
    init(title: String, content: String, link: String) {
        self.title = title
        self.content = content
        self.link = link
    }

    init(with shareModel: RUserShareLink) {
        title = shareModel.title
        content = shareModel.content
        link = shareModel.link
    }
}
