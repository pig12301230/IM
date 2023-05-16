//
//  ScanToLoginQRCodeModel.swift
//  ChatRoom
//
//  Created by Kedia on 2023/4/14.
//

import Foundation

/// 掃碼登入時，QR code 裡的內容
struct ScanToLoginQRCodeModel: Codable {
    let user_id, device_id: String?
    let type: Int?
    let data, passcode: String?
}
/*
 {
 "user_id": "",
 "device_id": "8e5604af-99db-47a5-b5e9-465040486690-7106542",
 "type": 1,
 "data": "abb3b104170745bf05529cb959003b61f69a0546071f2b8df1f79d9678fa8483",
 "passcode": ""
}*/
