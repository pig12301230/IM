//
//  ApiResponse.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/4/14.
//

import Foundation
import UIKit

enum GroupType: Int {
    case dm = 1
    case group
}

enum NotifyType: Int {
    case on = 1
    case off
    
    var value: Bool {
        switch self {
        case .on:
            return true
        default:
            return false
        }
    }
}

enum PermissionType: String {
    case none
    case owner
    case admin
    case member
    
    var description: String {
        switch self {
        case .owner:
            return Localizable.groupOwner
        case .admin:
            return Localizable.admin
        default :
            return ""
        }
    }
    
    var actionToolScene: ToolScene {
        switch self {
        case .admin:
            return .groupAdmin
        case .owner:
            return .groupOwner
        default:
            return .groupMember
        }
    }
}

enum HongBaoStatus: Int {
    case win = 0
    case opened
    case failToWin
    case expired
    case withdrawble
    
    var image: UIImage? {
        switch self {
        case .win, .opened:
            return UIImage(named: "chat_bubble_envelope_x_img_red_envelope_winning_2")
        case .failToWin:
            return UIImage(named: "chat_bubble_envelope_x_img_red_envelope_notwin")
        case .expired:
            return UIImage(named: "chat_bubble_envelope_x_img_red_envelope_timeout")
        default:
            return nil
        }
    }
    
    var title: String {
        switch self {
        case .win:
            return Localizable.congratulationsOnWinning
        case .failToWin:
            return Localizable.sorry
        case .expired:
            return Localizable.pity
        default:
            return ""
        }
    }
    
    var amount: String? {
        switch self {
        case .win, .opened, .withdrawble:
            return nil
        case .failToWin:
            return Localizable.didntGetRedEnvelope
        case .expired:
            return Localizable.redEnvelopeExpired
        }
    }
    
    var resultDescription: String {
        switch self {
        case .win, .opened:
            return Localizable.accumulatedToPoint
        case .failToWin:
            return Localizable.tryNextTime
        case .expired:
            return Localizable.beEarlyNextTime
        default:
            return ""
        }
    }
}

enum TradingType: Int {
    case hongBao = 3
    case wellPayBack = 13
    case pointOutput = 21
    case withdraw = 22
    case wllPayOutput = 23
    case lucky = 31
    case minesweeper = 32
    case unknown
    
    var name: String {
        switch self {
        case .hongBao:
            return Localizable.redEnvelope
        case .wellPayBack:
            return Localizable.wellPayBack
        case .pointOutput:
            return Localizable.porntsOutput
        case .wllPayOutput:
            return Localizable.wellPayOutput
        case .lucky:
            return Localizable.luckyRedEnvelope
        case .minesweeper:
            return Localizable.mineRedEnvelope
        case .withdraw:
            return Localizable.withdraw
        default:
            return "unknown"
        }
    }
}

enum HongBaoType: Int {
    case basic = 1
    case lucky
    case minesweeper
    
    var image: UIImage? {
        switch self {
        case .basic, .lucky:
            return UIImage(named: "chat_bubble_envelope_x_icon_red_envelope_normal")
        case .minesweeper:
            return UIImage(named: "chat_bubble_envelope_x_icon_red_envelope_bomb")
        }
    }
    
    var openedText: String {
        switch self {
        case .basic, .lucky:
            return Localizable.drawRedEnvelop
        case .minesweeper:
            return Localizable.openRedEnvelop
        }
    }
}

enum StateType: Int {
    case success = 1
    case wait = 2
    case failed = 9
    
    var description: String {
        switch self {
        case .success:
            return Localizable.success
        case .wait:
            return Localizable.waiting
        case .failed:
            return Localizable.fail
        }
    }
    
    var layerColor: UIColor {
        switch self {
        case .success:
            return Theme.c_04_success_100.rawValue.toColor()
        case .wait:
            return Theme.c_05_warning_100.rawValue.toColor()
        case .failed:
            return Theme.c_06_danger_100.rawValue.toColor()
        }
    }
    
    var tintColor: UIColor {
        switch self {
        case .success:
            return Theme.c_04_success_700.rawValue.toColor()
        case .wait:
            return Theme.c_05_warning_700.rawValue.toColor()
        case .failed:
            return Theme.c_06_danger_700.rawValue.toColor()
        }
    }
}

class ApiResponse<T: Codable>: Codable {
    let status: Bool
    let result: T?
}

struct ApiResponseError: Codable {
    let status: Bool
    let error: String
    let error_msg: String
}

struct MaintenanceModel: Codable {
    let status: Int
    let announcement: String
    let maintain_start: Int
    let maintain_end: Int
    let update_at: Int
}
