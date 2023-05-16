//
//  UICollectionViewCell+util.swift
//  LotBase
//
//  Created by george_tseng on 2020/6/17.
//  Copyright © 2020 Paridise-Soft. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

extension Reactive where Base: UICollectionViewCell {
    // 提供一个重用垃圾回收袋
    var reuseBag: DisposeBag {
        MainScheduler.ensureExecutingOnScheduler()
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
