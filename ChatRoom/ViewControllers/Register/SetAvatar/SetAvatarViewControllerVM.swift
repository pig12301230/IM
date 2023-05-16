//
//  SetAvatarViewControllerVM.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/4/27.
//

import Foundation
import RxSwift
import RxCocoa

class SetAvatarViewControllerVM: RegisterBaseVM {
    var disposeBag = DisposeBag()

    let doneEnable: BehaviorRelay<Bool> = BehaviorRelay(value: true)
    let uploadResult = PublishRelay<Bool>()

    var image: UIImage?

    override init() {
        super.init()
        
        self.initBinding()
    }

    func initBinding() {
        self.uploadResult.bind(to: self.nextEnable).disposed(by: self.disposeBag)
    }

    func uploadAvatar(image: UIImage) {
        let size = image.getSizeIn(.megabyte, opt: .jpeg)
        guard size > 0.0 else {
            return
        }
        let limit = Application.shared.limitImageMB
        let compression = size < limit ? 1 : (limit / size) - 0.05
        guard let data = image.jpegData(compressionQuality: CGFloat(compression)) else {
            return
        }
        
        self.showLoading.accept(true)
        ApiClient.uploadAvatar(imageData: data)
            .subscribe { [unowned self] _ in
                self.image = image
                self.uploadResult.accept(true)
            } onError: { [unowned self] _ in
                self.uploadResult.accept(false)
                self.showLoading.accept(false)
            } onCompleted: { [unowned self] in
                self.showLoading.accept(false)
            }.disposed(by: self.disposeBag)
    }
}
