//
//  ScanQRCodeLoginResponses.swift
//  ChatRoom
//
//  Created by Kedia on 2023/4/13.
//
// https://confluence.paradise-soft.com.tw/display/MT/Scan+To+Login+Flow

import Foundation

// MARK: - RScanQRCodeLoginResult
struct RScanQRCodeLoginResult: Codable {
    
    let type: ResultType?
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let int = (try? c.decode(Int.self, forKey: .type)) ?? -1
        self.type = ResultType(rawValue: int)
        assert(self.type != nil)
    }
    
    func encode(to encoder: Encoder) throws {
        
    }
    
    enum ResultType: Int {
        case newDevice = 2
        case sameDevice = 3
    }
    
    enum CodingKeys: CodingKey {
        case type
    }
}
