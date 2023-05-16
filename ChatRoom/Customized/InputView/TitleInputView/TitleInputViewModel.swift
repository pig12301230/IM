//
//  TitleInputViewModel.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/4/22.
//

import RxCocoa
import RxSwift

class TitleInputViewModel: InputViewModel {
    private(set) var showTitle: Bool = false
    
    // Output for view
    let typeTitle: BehaviorRelay<String?> = BehaviorRelay(value: nil)
    let statusImage: BehaviorRelay<UIImage?> = BehaviorRelay(value: nil)
    let touchInputAction = PublishSubject<Void>()
    let interactionEnabled: BehaviorRelay<Bool> = BehaviorRelay(value: true)
    var maxInputLength: Int?
    var inputTextFont: UIFont = .regularParagraphLargeLeft
    
    init(title: String? = nil, inputEnable: Bool = true, showStatus: Bool = true) {
        showTitle = title != nil
        super.init()
        self.input.inputEnable.accept(inputEnable)
        self.typeTitle.accept(title)
        
        guard showStatus else {
            return
        }
        self.setupStatusImage()
    }
    
    func setupStatusImage() {
        self.statusImage.accept(UIImage.init(named: "iconArrowsChevronRight"))
    }
    
    override func examineInput(input: String) {
        if let maxInputLength = self.maxInputLength, input.count > maxInputLength {
            let newInput = String(input.prefix(maxInputLength))
            self.outputText.accept(newInput)
        } else {
            self.outputText.accept(input)
        }
    }
}
