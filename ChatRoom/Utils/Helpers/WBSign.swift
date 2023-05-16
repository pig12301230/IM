//
//  FPCore.swift
//  LotBase
//
//  Created by george_tseng on 2020/5/27.
//  Copyright © 2020 Paridise-Soft. All rights reserved.
//

import Foundation
import UIKit
import CommonCrypto

public class WBSign {
    static func wBSignSha1(dict: [String: Any]) -> String {
        var keys = dict.sorted { $0.0 < $1.0 }
        keys.append(("gea_secret", NetworkConfig.RegInfoApiKey.secretKey))
        var sign: String! = ""
        for (key, value) in keys {
            if value is [Any] {
                if let ary = value as? [String] {
                    for index in ary {
                        sign += key + "[]=" + index + "&"
                    }
                }
            } else if value is String {
                sign += key + "=" + (value as? String ?? "") + "&"
            } else {
                if let num = value as? Int {
                    sign += key + "=" + String(num) + "&"
                }
            }
        }

        let indexStart = sign.index(sign.startIndex, offsetBy: 0)
        let indexEnd   = sign.index(sign.endIndex, offsetBy: -1)
        sign = String(sign[indexStart..<indexEnd])

        // print("签名参数:\(sign)")
        // print("sign: \(sign.sha1())")
        return sign?.lowercased().sha1() ?? ""
    }
}

extension String {
    // sha1算法
    func sha1() -> String {
        guard let data: Data = self.data(using: .utf8, allowLossyConversion: true) else { return "" }
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        let dataBytes = data.withUnsafeBytes { $0.baseAddress }
        let dataLength = CC_LONG(data.count)
        
        CC_SHA1(dataBytes, dataLength, &digest)
        
        let output = NSMutableString(capacity: Int(CC_SHA1_DIGEST_LENGTH))
        for byte in digest {
            output.appendFormat("%02x", byte)
        }
        return output as String
    }
    
    /// 随机字符串, len 长度
    static let random_str_characters = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    static func randomStr(len: Int) -> String {
        var ranStr = ""
        for _ in 0..<len {
            let index = Int(arc4random_uniform(UInt32(random_str_characters.count)))
            ranStr.append(random_str_characters[random_str_characters.index(random_str_characters.startIndex, offsetBy: index)])
        }
        return ranStr
    }
}
