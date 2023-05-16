//
//  PushManager.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/5/19.
//

import UIKit
import AVFoundation

extension Data {
    func deviceTokenString() -> String {
        return self.map { String(format: "%.2hhx", $0) }.joined()
    }
}

class PushManager: NSObject {

    static let shared = PushManager()

    private(set) var deviceToken: Data?
    private var audio: AVPlayer!

    func registerPushNotification() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [unowned self] permission, _ in
            guard permission else {
                return
            }
            self.registerRemoteNotification()
        }
    }

    private func registerRemoteNotification() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                guard settings.authorizationStatus == .authorized else {
                    return
                }
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
}

// MARK: - result of Register Remote Notification
extension PushManager {
    func registerSuccess(deviceToken: Data) {
        self.deviceToken = deviceToken
        self.setupAVPlayer()
        
        DataAccess.shared.registerDeviceToken(token: deviceToken.deviceTokenString())
    }

    func registerFailed(error: Error) {
        PRINT(error.localizedDescription, cate: .error)
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension PushManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // showing Notification when App is running in the foreground
        
        // 前景時不秀出 notify alert
        guard UIApplication.shared.applicationState != .active else {
            guard let info = UserData.shared.userInfo else { return }
            if info.sound == .on {
                self.playSound()
            }
            
            if info.vibration == .on {
                AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            }
            return
        }
        
        // notification 會設置背景時的聲音為 'choose_background'
        completionHandler([.alert, .badge, .sound])
    }
}

// MARK: - AVPlayer
private extension PushManager {
    func setupAVPlayer() {
        guard let url = Bundle.main.url(forResource: "bamboo_pop", withExtension: "wav") else {
            return
        }
        audio = AVPlayer(url: url)
    }

    func playSound() {
        guard let audio = self.audio else {
            return
        }
        audio.seek(to: .zero)
        audio.play()
    }
}
