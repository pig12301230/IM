//
//  ObservableType+util.swift
//  LotBase
//
//  Created by george_tseng on 2020/5/28.
//  Copyright © 2020 Paridise-Soft. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

extension ObservableType {
    func subscribeSuccess(_ callback: ((Element) -> Void)?) -> Disposable {
        return subscribe(onNext: { data in
            callback?(data)
        }, onError: { _ in
//            ErrorHandler.handleError(error)
        })
    }
    
    func subscribeOn(next nextCallback: ((Element) -> Void)? = nil, error errorCallback: ((Swift.Error) -> Void)? = nil, finished finishCallback: (() -> Void)? = nil) -> Disposable {
        return subscribe(onNext: { data in
            finishCallback?()
            nextCallback?(data)
        }, onError: { error in
            finishCallback?()
            guard let customErrorCallback = errorCallback else {
//                ErrorHandler.handleError(error)
                return
            }
            customErrorCallback(error)
        })
    }
    
    func subscribeSuccess<Observer>(_ observer: Observer) -> Disposable where Observer: ObserverType, Self.Element == Observer.Element {
        return subscribeSuccess(observer.onNext)
    }
    
    func subscribeSuccess<Element>(_ observer: BehaviorRelay<Element>) -> Disposable where Self.Element == Element {
        return subscribeSuccess(observer.accept)
    }
    
    func withPrevious(startWith first: Element) -> Observable<(Element, Element)> {
        return scan((first, first)) { ($0.1, $1) }.skip(1)
    }
}
