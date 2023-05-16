//
//  Double+util.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/6/1.
//

import Foundation

extension Double {
    func rounded(to digits: Int) -> Double {
        let multiplier = pow(10.0, Double(digits))
        return (self * multiplier).rounded() / multiplier
    }

    func ceil(to digits: Int) -> Double {
        let multiplier = abs(pow(10.0, Double(digits)))
        if self.sign == .minus {
            return Double(Int(self * multiplier)) / multiplier
        } else {
            return Double(ceil(to: Int(self * multiplier))) / multiplier
        }
    }
}
