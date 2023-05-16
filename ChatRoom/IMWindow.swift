//
//  IMWindow.swift
//  ChatRoom
//
//  Created by Kedia on 2023/4/7.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

class IMWindow: UIWindow {
    let shakeSubject = PublishSubject<Void>()
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            shakeSubject.onNext(())
        }
    }
}
