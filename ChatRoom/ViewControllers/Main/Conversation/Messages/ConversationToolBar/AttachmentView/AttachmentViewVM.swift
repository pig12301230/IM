//
//  AttachmentViewVM.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/6/3.
//

import RxSwift
import RxCocoa

class AttachmentViewVM: BaseViewModel {
    
    var disposeBag = DisposeBag()
    
    struct Input {
        let photo = PublishSubject<Void>()
        let camera = PublishSubject<Void>()
        let finish = PublishSubject<Void>()
    }
    
    struct Output {
        let photo = PublishSubject<Void>()
        let camera = PublishSubject<Void>()
    }
    
    let input: Input = Input.init()
    let output: Output = Output.init()
    private var isProcessing: Bool = false
    
    override init() {
        super.init()
        self.initBinding()
    }
}

private extension AttachmentViewVM {
    func initBinding() {
        self.input.photo.subscribeSuccess { [unowned self] in
            self.doPhotoAction()
        }.disposed(by: self.disposeBag)
        
        self.input.camera.subscribeSuccess { [unowned self] in
            self.doCameraAction()
        }.disposed(by: self.disposeBag)
        
        self.input.finish.subscribeSuccess { [unowned self] in
            self.isProcessing = false
        }.disposed(by: self.disposeBag)
    }
    
    func doPhotoAction() {
        guard !self.isProcessing else {
            return
        }
        
        self.isProcessing = true
        self.output.photo.onNext(())
    }
    
    func doCameraAction() {
        guard !self.isProcessing else {
            return
        }
        
        self.isProcessing = true
        self.output.camera.onNext(())
    }
}
