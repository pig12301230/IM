//
//  SocketClient.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/4/12.
//

import Foundation
import Starscream

protocol SocketClientDelegate: AnyObject {
    func groupRead(with info: RSocketReadInfo)
    func groupAdd(with info: RSocketInfo)
    func groupLeft(with info: RSocketInfo)
    func groupDisplay(with info: RSocketGroupDisplay)
    func groupIcon(with info: RSocketGroupIcon)
    func memberAdd(with info: RSocketInfo)
    func memberLeft(with info: RSocketInfo)
    func message(with message: RMessage)
    func messageDelete(with info: RSocketGroupMessage)
    func groupPermission(with group: RSocketGroup)
    func groupPins(with info: RSocketGroupMessage)
    func receiveHongBao(with info: RSocketHongBaoClaim)
}

class SocketClient {
    enum SocketResponseCommand: String {
        case hello
        case message
        case groupRead = "group_read"
        case groupAdd = "group_add"
        case groupLeft = "group_left"
        case groupDisplay = "group_displayname"
        case groupIcon = "group_icon"
        case memberAdd = "member_join"
        case memberLeft = "member_left"
        case groupPermission = "group_permission"   // member auth change, ex. send_message, send_images
        case messageDelete = "message_delete"
        case messagePin = "message_pin"
        case messageUnpin = "message_unpin"
        case groupCreatePermission = "group_create_permission"
        case hongBaoClaim = "red_envelope_claim"
    }
    
    weak var delegate: SocketClientDelegate?
    
    private(set) var socket: WebSocket!
    private(set) var isConnected = false
    private(set) var initiativeDisconnect = false
    private var pingTimer: Timer?
    private var timeoutTimer: Timer?
    private var timeoutCount: Int = 0
    
    private lazy var pingData: Data? = {
        let dic = ["event": "ping"]
        guard JSONSerialization.isValidJSONObject(dic) else {
            return nil
        }
        
        return try? JSONSerialization.data(withJSONObject: dic, options: [])
    }()
    
    private func initWebSocket() {
        guard let token = UserData.shared.getData(key: .token) as? String, token.count > 0 else {
            return
        }
        
        let socketBasePath = NetworkConfig.URL.WSBaseURL + "/v1/websocket"
        let fullPath = socketBasePath.queryString(["token": token])
        PRINT("connect to \(fullPath)", cate: .socket)
        guard let url = URL(string: fullPath) else {
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = Application.timeout
        self.socket = WebSocket(request: request)
        self.socket.delegate = self
        self.socket.connect()
    }
    
    func connect() {
        NetworkManager.websocketStatus.accept(.connecting)
        guard let socket = self.socket, self.initiativeDisconnect == false else {
            self.initWebSocket()
            return
        }
        
        socket.connect()
    }
    
    func disconnect() {
        NetworkManager.websocketStatus.accept(.disconnected)
        
        self.initiativeDisconnect = true
        self.isConnected = false
        self.resetPingTimer()
        self.stopTimeoutTimer()
        
        guard let socket = self.socket else {
            return
        }

        socket.disconnect()
    }
}

extension SocketClient: WebSocketDelegate {
    
    func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected:
            self.isConnected = true
            self.initiativeDisconnect = false
            self.initPingTimer()
            self.initTimeoutTimer()
            NetworkManager.websocketStatus.accept(.connected)
            PRINT("connected", cate: .socket)
        case .disconnected:
            self.connectRetry()
            PRINT("disconnected", cate: .socket)
        case .cancelled:
            self.disconnect()
            PRINT("cancelled", cate: .socket)
        case .error(let error):
            if let err = error {
                self.handleError(err)
            }
            self.connectRetry()
            PRINT("error", cate: .socket)
        case .viabilityChanged(let result):
            if !result {
                self.connectRetry()
            }
        case .reconnectSuggested(let result):
            if result {
                self.connectRetry()
            }
        case .text(let message):
            self.resetTimeoutTimer()
            guard let jsonObject = message.jsonStringToDictionary() else {
                return
            }
            
            guard let event = jsonObject["event"] as? String,
                  let command = SocketResponseCommand(rawValue: event) else {
                PRINT("message event string error", cate: .socket)
                return
            }
            
            PRINT(command.rawValue, cate: .socket)
            guard let jsonData = message.data(using: .utf8) else { return }
            
            switch command {
            case SocketResponseCommand.hello:
                break
            case SocketResponseCommand.message:
                if let object = try? JSONDecoder().decode(SocketResponse<RMessage>.self, from: jsonData) {
                    self.delegate?.message(with: object.data)
                }
            case SocketResponseCommand.groupAdd:
                if let object = try? JSONDecoder().decode(SocketResponse<RSocketInfo>.self, from: jsonData) {
                    self.delegate?.groupAdd(with: object.data)
                }
            case SocketResponseCommand.groupLeft:
                if let object = try? JSONDecoder().decode(SocketResponse<RSocketInfo>.self, from: jsonData) {
                    self.delegate?.groupLeft(with: object.data)
                }
            case SocketResponseCommand.memberAdd:
                if let object = try? JSONDecoder().decode(SocketResponse<RSocketInfo>.self, from: jsonData) {
                    self.delegate?.memberAdd(with: object.data)
                }
            case SocketResponseCommand.memberLeft:
                if let object = try? JSONDecoder().decode(SocketResponse<RSocketInfo>.self, from: jsonData) {
                    self.delegate?.memberLeft(with: object.data)
                }
            case .groupRead:
                if let object = try? JSONDecoder().decode(SocketResponse<RSocketReadInfo>.self, from: jsonData) {
                    self.delegate?.groupRead(with: object.data)
                }
            case .groupDisplay:
                if let object = try? JSONDecoder().decode(SocketResponse<RSocketGroupDisplay>.self, from: jsonData) {
                    self.delegate?.groupDisplay(with: object.data)
                }
            case .groupIcon:
                if let object = try? JSONDecoder().decode(SocketResponse<RSocketGroupIcon>.self, from: jsonData) {
                    self.delegate?.groupIcon(with: object.data)
                }
            case .groupPermission:
                if let object = try? JSONDecoder().decode(SocketResponse<RSocketGroup>.self, from: jsonData) {
                    self.delegate?.groupPermission(with: object.data)
                }
            case .messagePin, .messageUnpin:
                if let object = try? JSONDecoder().decode(SocketResponse<RSocketGroupMessage>.self, from: jsonData) {
                    self.delegate?.groupPins(with: object.data)
                }
            case .messageDelete:
                if let object = try? JSONDecoder().decode(SocketResponse<RSocketGroupMessage>.self, from: jsonData) {
                    self.delegate?.messageDelete(with: object.data)
                }
            case .hongBaoClaim:
                if let object = try? JSONDecoder().decode(SocketResponse<RSocketHongBaoClaim>.self, from: jsonData) {
                    self.delegate?.receiveHongBao(with: object.data)
                }
            default:
                PRINT("[ ERROR! ] receive event \(event), but not handle event yet", cate: .socket)
            }
        case .pong(let data):
            self.resetTimeoutTimer()
            PRINT("pong == \(data ?? Data())", cate: .socket)
        case .ping(let data):
            self.resetTimeoutTimer()
            PRINT("ping == \(data ?? Data())", cate: .socket)
        default:
            PRINT("did Receive DEFAULT \(event)", cate: .socket)
        }
    }
    
    func handleError(_ error: Error) {
        guard let wsError = error as? WSError else {
            PRINT(error.localizedDescription)
            return
        }
        PRINT(wsError.localizedString)
    }
}

private extension SocketClient {
    
    func connectRetry() {
        self.disconnect()
        // Delay重連, 是為了讓UI以及斷線重連邏輯看起來正常
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            guard let self = self else { return }
            self.connect()
        }
    }
    
    func resetPingTimer() {
        self.pingTimer?.invalidate()
    }
    
    func initPingTimer() {
        self.resetPingTimer()
        
        self.pingTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true, block: { [weak self] _ in

            guard let strongSelf = self, strongSelf.isConnected == true, let socket = strongSelf.socket else {
                self?.resetPingTimer()
                return
            }
            
            guard let data = strongSelf.pingData else {
                return
            }
            
            socket.write(ping: data) {
                PRINT("send ping", cate: .socket)
            }
        })
    }
    
    func initTimeoutTimer() {
        self.stopTimeoutTimer()
        self.resetTimeoutTimer()
        self.timeoutTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] _ in
            guard let self = self else { return }
            self.timeoutCount += 1
            if self.timeoutCount > 20 {
                self.connectRetry()
            }
        })
    }
    
    func resetTimeoutTimer() {
        self.timeoutCount = 0
    }
    
    func stopTimeoutTimer() {
        self.timeoutTimer?.invalidate()
    }
}
