//
//  Data+util.swift
//  ChatRoom
//
//  Created by Kedia on 2023/3/16.
//

import Foundation
import UIKit


extension Data {
    
    var fileSizeInKB: Double {
        let bytesCount = Double(self.count)
        return bytesCount / 1_000
    }
    
    var fileSizeInMB: Double {
        let bytesCount = Double(self.count)
        return bytesCount / 1_000_000
    }

    func getImageCompressionQuality(limit: Double) -> CGFloat {
        let oriSizeD = self.fileSizeInMB
        if limit >= oriSizeD {
            return 1.0
        }

        let min: Double = 0.05
        let compression = Swift.max((limit / oriSizeD) - min, min)
        return compression
    }

}
