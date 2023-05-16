//
//  Reactive+util.swift
//  LotBase
//
//  Created by george_tseng on 2020/5/28.
//  Copyright © 2020 Paridise-Soft. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

extension Reactive where Base: UIView {
    var click: RxSwift.Observable<Void> {
        
        if let tap = base.gestureRecognizers?.filter({ $0 is UITapGestureRecognizer }).first {
            return tap.rx.event.map { _ -> Void  in
                return
            }
        } else {
            let tap = UITapGestureRecognizer()
            base.addGestureRecognizer(tap)
            base.isUserInteractionEnabled = true
            return tap.rx.event.map { _ -> Void  in
                return
            }
        }
    }
    
    var longPress: RxSwift.Observable<UILongPressGestureRecognizer> {
        guard let longPress = base.gestureRecognizers?.filter({ $0 is UILongPressGestureRecognizer }).first as? UILongPressGestureRecognizer else {
            let longPress = UILongPressGestureRecognizer()
            base.addGestureRecognizer(longPress)
            base.isUserInteractionEnabled = true
            return longPress.rx.event.asObservable()
        }
        
        return longPress.rx.event.asObservable()
    }
    
    var doubleTap: RxSwift.Observable<UITapGestureRecognizer> {
        guard let doubleTap = base.gestureRecognizers?.filter({ $0 is UITapGestureRecognizer }).first as? UITapGestureRecognizer else {
            let doubleTap = UITapGestureRecognizer()
            doubleTap.numberOfTapsRequired = 2
            base.addGestureRecognizer(doubleTap)
            base.isUserInteractionEnabled = true
            return doubleTap.rx.event.asObservable()
        }
        doubleTap.numberOfTapsRequired = 2
        return doubleTap.rx.event.asObservable()
    }
}

extension Reactive where Base: UIView {
    var hidden: Observable<Bool> {
        return self.methodInvoked(#selector(setter: self.base.isHidden))
            .map { event -> Bool in
                guard let isHidden = event.first as? Bool else {
                    fatalError()
                }
                return isHidden
            }
            .startWith(self.base.isHidden)
    }
}

// extension Reactive where Base: UIControl {
//    var selected: ControlProperty<Bool> {
//        let source: Observable<Bool> = methodInvoked(#selector(setter: base.isSelected))
//            .map { event -> Bool in
//                guard let isSelected = event.first as? Bool else {
//                    fatalError()
//                }
//                return isSelected
//            }
//            .startWith(base.isSelected)
//        return ControlProperty(values: source, valueSink: isSelected)
//    }
// }
