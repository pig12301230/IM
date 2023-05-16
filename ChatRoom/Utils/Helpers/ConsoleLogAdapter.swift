//
//  ConsoleLogAdapter.swift
//  LotBase
//
//  Created by george_tseng on 2020/5/27.
//  Copyright © 2020 Paridise-Soft. All rights reserved.
//

import UIKit
import Foundation

final class ConsoleLogAdapter: LogAdapterProtocol {
    
    func log(_ category: LogCategory, message: String) {
        
        if category.showTimestamp {
            log(Date().debugDescription)
        }
        
        if category == .thread {
            log(Thread.currentThreadDescription)
            return
        }
        log("\(category.prefix), \(message)")
    }
    
    func log(_ message: String) {
        print(message)
    }
}
