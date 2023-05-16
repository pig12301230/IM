//
//  UITableViewCell+util.swift
//  ChatRoom
//
//  Created by ZoeLin on 2021/7/22.
//

import Foundation
import RxSwift
import RxCocoa

extension Reactive where Base: UITableViewCell {
    // 提供一个重用垃圾回收袋
    var reuseBag: DisposeBag {
//        MainScheduler.ensureExecutingOnScheduler()
        var prepareForReuseBag: Int8 = 0
        if let bag = objc_getAssociatedObject(base, &prepareForReuseBag) as? DisposeBag {
            return bag
        }
        
        let bag = DisposeBag()
        objc_setAssociatedObject(base, &prepareForReuseBag, bag, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        
        _ = sentMessage(#selector(Base.prepareForReuse))
            .subscribe(onNext: { [weak base] _ in
                let newBag = DisposeBag()
                guard let base = base else { return }
                objc_setAssociatedObject(base, &prepareForReuseBag, newBag, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
            })
        return bag
    }
}
