//
//  UserInteractiveStatusInputViewModel.swift
//  ChatRoom
//
//  Created by ERay_Peng on 2023/4/14.
//

import UIKit
import RxSwift
import RxCocoa

class UserInteractiveStatusInputViewModel: TitleInputViewModel {
    var statusImageName: String
    
    let btnStatusDidTouchUpIndside = PublishSubject<Void>()
    
    init(title: String? = nil, inputEnable: Bool = true, showStatus: Bool = true, statusImageName: String = "") {
        self.statusImageName = statusImageName
        super.init(title: title, inputEnable: inputEnable, showStatus: showStatus)
    }
    
    override func setupStatusImage() {
        let img = UIImage.init(named: self.statusImageName.isEmpty ? "iconArrowsChevronRight" : self.statusImageName)
        self.statusImage.accept(img)
    }
}
