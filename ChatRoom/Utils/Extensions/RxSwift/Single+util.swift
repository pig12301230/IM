//
//  Single+util.swift
//  LotBase
//
//  Created by george_tseng on 2020/5/28.
//  Copyright © 2020 Paridise-Soft. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

extension PrimitiveSequenceType where Trait == SingleTrait {

    func subscribeSuccess(_ callback: ((Element) -> Void)? = nil) -> Disposable {
        return subscribe(onSuccess: { data in
            callback?(data)
        }, onError: { _ in
//            ErrorHandler.handleError(error)
        })
    }

    func subscribeOn(success successCallback: ((Element) -> Void)? = nil, error errorCallback: ((Swift.Error) -> Void)? = nil, finished finishCallback: (() -> Void)? = nil) -> Disposable {
        return subscribe(onSuccess: { data in
            finishCallback?()
            successCallback?(data)
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
}
