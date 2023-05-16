//
//  Thread+util.swift
//  ChatRoom
//
//  Created by Kedia on 2023/4/21.
//

import Foundation

extension Thread {
    
    class var currentThreadDescription: String {
        return "⚡️: \(Thread.current)\n" + "🏭: \(OperationQueue.current?.underlyingQueue?.label ?? "None")"
    }
}
