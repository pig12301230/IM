//
//  FileLogAdapter.swift
//  ChatRoom
//
//  Created by Kedia on 2023/3/27.
//

import Foundation
import UIKit

extension FileLogAdapter: LogAdapterProtocol {
    
    func log(_ message: String) {
        Task {
            await writeLog(message)
        }
    }
}

/// `FileLogAdapter` 是一個用於管理日誌文件的 class，可以在日誌文件中寫入日誌。
/// 它具有一個共享實例，用於將字符串寫入名為 log.csv 的文件。
/// 該文件位於名為 Logs 的資料夾中，log.csv 文件大小最大為 10 MB，
/// 超過時，以一行為一個單位刪除約 1 MB 的文件。
/// 在寫入字符串時，會在字符串前面添加當前時間，後面加上換行符。
final class FileLogAdapter {
    
    /// `FileLogAdapter` 的共享實例。
    static let shared = FileLogAdapter()
    /// 最大的日誌文件大小。預設為 10 MB。
    let maxFileSize: Int = 10 * 1024 * 1024
    
    /// 將日誌字符串寫入日誌文件。
    ///
    /// - Parameter log: 要寫入日誌文件的字符串。
    func writeLog(_ log: String? = nil) async {
#if DEBUG
        if !storageManager.isFileExist(fileName: logFileName) {
            _ = storageManager.createFile(name: logFileName)
        }
        
        let timestamp = dateFormatter.string(from: Date())
        let logEntry = "\(timestamp)\t\(log ?? "")\n"
        
        buffer.append(logEntry)
        if buffer.count >= bufferSize {
            await flushBuffer()
        }
        
        if let fileSize = logFileSize(), fileSize >= Int(maxFileSize) {
            await removeOldLogFileContents()
        }
        
        if let data = logEntry.data(using: .utf8) {
            await storageManager.appendDataToFile(name: logFileName, data: data)
        }
#endif
    }
    
    /// 讀取日誌文件的內容。
    ///
    /// - Returns: 返回日誌文件的內容字符串，如果文件不存在，則返回 `nil`。
    func readLogFileContents() async -> String? {
        await flushBuffer()
        if let data = await storageManager.readFile(name: logFileName) {
            return String(data: data, encoding: .utf8)
        } else {
            return nil
        }
    }
    
    /// 將 Logs 資料夾整個壓縮成一個 zip 檔, 主檔名後面會加上單位到千分之1秒的時間
    func generateDirectoryZip() async -> URL? {
        await writeEvnFile()
        return await storageManager.generateZipFileAsync(fileSuffix: dateFormatter.string(from: Date()))
    }
    
    /// 返回當前日誌文件的大小（以 byte 為單位）。
    ///
    /// - Returns: 返回日誌文件的大小，如果文件不存在，則返回 `nil`。
    func logFileSize() -> Int? {
        return storageManager.sizeOfFile(name: logFileName)
    }
    
    /// 刪除整個日誌文件夾。
    ///
    /// 該函數將刪除名為 `Logs` 的文件夾，並移除其中的所有日誌文件。
    func deleteLogFolder() async {
        storageManager.removeDirectory(name: Self.logDirectoryName)
    }
    
    /// 刪除日誌文件。
    ///
    /// 該函數將刪除名為 `log.csv` 的文件。
    func deleteLogFile() async {
        _ = await storageManager.removeFile(name: logFileName)
    }
    
    // MARK: - Privates
    
    private let logFileName = "log.csv"
    private let envFileName = "env.txt"
    static private let logDirectoryName = "Logs"
    private var buffer: [String] = []
    private let bufferSize = 20
    /// 當 log.csv 檔超過 maxFileSize 時，要刪掉的約略 byte 數，目前是 1 MB
    private lazy var fileSizeToRemove: Int = {
        return maxFileSize / 10
    }()
    
    private lazy var dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSZ"
        df.timeZone = TimeZone(secondsFromGMT: 8 * 3600)
        return df
    }()
    
    init() {
        registerNotifications()
    }
    
    private let storageManager: LocalStorageManager = LocalStorageManager(directoryName: FileLogAdapter.logDirectoryName)
    
    private func writeEvnFile() async {
        await storageManager.removeFile(name: envFileName)
        storageManager.createFile(name: envFileName)
        var envString = "Info.brand: \(AppConfig.Info.brand)"
        envString.append("\n")
        envString.append("Info.bundleID: \(AppConfig.Info.bundleID)")
        envString.append("\n")
        envString.append("Info.appVersion: \(AppConfig.Info.appVersion ?? "")")
        envString.append("\n")
        envString.append("Info.buildVersion: \(AppConfig.Info.buildVersion ?? "")")
        envString.append("\n")
        envString.append("Info.bundleName: \(AppConfig.Info.bundleName ?? "")")
        envString.append("\n")
        envString.append("Info.appName: \(AppConfig.Info.appName)")
        envString.append("\n")
        envString.append("Info.isMaintaining: \(AppConfig.Info.isMaintaining)")
        envString.append("\n")
        envString.append("Info.themeFileName: \(AppConfig.Info.themeFileName)")
        envString.append("\n")
        envString.append("Database.schemaVersion: \(AppConfig.Database.schemaVersion)")
        envString.append("\n")
        envString.append("Device.iOSVersion: \(AppConfig.Device.iOSVersion)")
        envString.append("\n")
        envString.append("Device.uuid: \(AppConfig.Device.uuid)")
        envString.append("\n")
        envString.append("Device.modelIdentifier: \(AppConfig.Device.modelIdentifier)")
        envString.append("\n")
        envString.append("Device.language: \(AppConfig.Device.language)")
        envString.append("\n")
        if let data = envString.data(using: .utf8) {
            await storageManager.appendDataToFile(name: envFileName, data: data)
        }
    }
    
    private func removeOldLogFileContents() async {
        guard let data = await storageManager.readFile(name: logFileName),
              let contents = String(data: data, encoding: .utf8) else {
            return
        }
        
        let newContents = await contents.linesToRemove(fileSizeToRemove: fileSizeToRemove)
        
        guard let newData = newContents.data(using: .utf8) else {
            return
        }
        
        await storageManager.removeFile(name: logFileName)
        _ = storageManager.createFile(name: logFileName)
        await storageManager.appendDataToFile(name: logFileName, data: newData)
    }
    
    private func flushBuffer() async {
        if !storageManager.isFileExist(fileName: logFileName) {
            _ = storageManager.createFile(name: logFileName)
        }
        
        let logEntries = buffer.joined()
        
        if let fileSize = logFileSize(), fileSize >= Int(maxFileSize) {
            await removeOldLogFileContents()
        }
        
        if let data = logEntries.data(using: .utf8) {
            await storageManager.appendDataToFile(name: logFileName, data: data)
            buffer.removeAll()
        }
    }
    
    private func registerNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppLifecycleNotification(_:)), name: UIApplication.willTerminateNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppLifecycleNotification(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppLifecycleNotification(_:)), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
    }
    
    @objc private func handleAppLifecycleNotification(_ notification: Notification) async {
        await flushBuffer()
    }
}
