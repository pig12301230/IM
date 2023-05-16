//
//  Completable+util.swift
//  LotBase
//
//  Created by george_tseng on 2020/5/28.
//  Copyright © 2020 Paridise-Soft. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

extension PrimitiveSequenceType where Trait == CompletableTrait, Element == Swift.Never {
    func subscribeSuccess(_ callback: (() -> Void)? = nil) -> Disposable {
        return subscribe(onCompleted: {
            callback?()
        }, onError: { _ in
//            ErrorHandler.handleError(error)
        })
    }
    
    func subscribeOn(completed completedCallback: (() -> Void)? = nil, error errorCallback: ((Swift.Error) -> Void)? = nil, finished finishCallback: (() -> Void)? = nil) -> Disposable {
        return subscribe(onCompleted: {
            finishCallback?()
            completedCallback?()
        }, onError: { error in
            finishCallback?()
            guard let customErrorCallback = errorCallback else {
//                ErrorHandler.handleError(error)
                return
            }
            customErrorCallback(error)
        })
    }
}
