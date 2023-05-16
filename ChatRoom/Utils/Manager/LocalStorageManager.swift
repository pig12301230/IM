//
//  LocalStorageManager.swift
//  ChatRoom
//
//  Created by Kedia on 2023/3/27.
//

import Foundation
#if DEBUG
import ZIPFoundation
#endif

/// 用於在 Document 下操作資料夾及檔案的 class。
final class LocalStorageManager {
    
    /// 資料夾的完整 URL。
    private(set) var fullURL: URL
    /// 資料夾的名稱。
    private(set) var directoryName: String
    
    /// 建立一個新的 `LocalStorageManager` 實例，並指定資料夾名稱。
    ///
    /// - Parameter directoryName: 資料夾的名稱。
    init(directoryName: String) {
        self.directoryName = directoryName
        if let url = FileManager.default.urls(for: .documentDirectory, in:
                .userDomainMask).first?.appendingPathComponent(directoryName, isDirectory: true) {
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
                self.fullURL = url
            } catch {
                fatalError("建立資料夾失敗 in File: \(#file), Line: \(#line)")
            }
        } else {
            fatalError("directoryName 不合法，無法建立資料夾 in File: \(#file), Line: \(#line)")
        }
    }
    
    /// 刪除指定名稱的資料夾。
    ///
    /// - Parameter name: 資料夾的名稱。
    /// - Returns: 如果刪除成功，則返回 `true`，否則返回 `false`。
    @discardableResult func removeDirectory(name: String) -> Bool {
        do {
            try FileManager.default.removeItem(at: fullURL)
            return true
        } catch {
            print("刪除目錄時出現錯誤: \(error)")
            return false
        }
    }
    
    /// 檢查指定名稱的檔案是否存在。
    ///
    /// - Parameter name: 檔案的名稱。
    /// - Returns: 如果檔案存在，則返回 `true`，否則返回 `false`。
    func isFileExist(fileName name: String) -> Bool {
        if !checkIsValidName(name) {
            return false
        }
        let fileURL = fullURL.appendingPathComponent(name)
        return fileManager.fileExists(atPath: fileURL.path)
    }
    
    /// 創建一個指定名稱的檔案。
    ///
    /// - Parameter name: 檔案的名稱。
    /// - Returns: 如果創建成功，則返回檔案的 URL，否則返回 `nil`。
    @discardableResult func createFile(name: String) -> URL? {
        if !checkIsValidName(name) {
            return nil
        }
        if isFileExist(fileName: name) {
            return nil
        }
        
        let fileURL = fullURL.appendingPathComponent(name)
        
        // 檢查文件是否存在，如果不存在，創建文件
        if !fileManager.fileExists(atPath: fileURL.absoluteString) {
            fileManager.createFile(atPath: fileURL.absoluteString, contents: nil, attributes: nil)
        }
        return fileURL
    }
    
    /// 追加數據到指定名稱的檔案。
    ///
    /// - Parameters:
    ///   - name: 檔案的名稱。
    ///   - data: 要追加的數據。
    /// - Returns: 如果數據追加成功，則返回 `true`，否則返回 `false`。
    @discardableResult func appendDataToFile(name: String, data: Data) async -> Bool {
        if !checkIsValidName(name) {
            return false
        }
        let fileURL = fullURL.appendingPathComponent(name)
        do {
            return try await withCheckedThrowingContinuation { continuation in
                queue.sync {
                    do {
                        if let existingData = try? Data(contentsOf: fileURL) {
                            let combinedData = existingData + data
                            try combinedData.write(to: fileURL, options: .atomic)
                        } else {
                            try data.write(to: fileURL, options: .atomic)
                        }
                        continuation.resume(returning: true)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        } catch {
            return false
        }
        
    }
    
    /// 將 Directory 整個壓成一個 zip 檔
    @discardableResult func generateZipFileAsync(fileSuffix: String?) async -> URL? {
#if !DEBUG
        return nil
#else
        return try? await withCheckedThrowingContinuation { continuation in
            queue.sync { [weak self] in
                do {
                    guard let self else {
                        continuation.resume(returning: nil)
                        return
                    }
                    guard let zipURL = self.fileManager.urls(for: .documentDirectory, in:
                            .userDomainMask).first?.appendingPathComponent("\(self.directoryName)\(fileSuffix ?? "").zip", isDirectory: false) else {
                        continuation.resume(returning: nil)
                        return
                    }
                    // Check if the file exists and delete it if it does
                    if self.fileManager.fileExists(atPath: zipURL.path) {
                        try self.fileManager.removeItem(at: zipURL)
                    }
                    try self.fileManager.zipItem(at: self.fullURL, to: zipURL, compressionMethod: .deflate)
                    continuation.resume(returning: zipURL)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
#endif
    }
    
    /// 讀取指定名稱的檔案。
    ///
    /// - Parameter name: 檔案的名稱。
    /// - Returns: 如果檔案存在，則返回檔案的數據，否則返回 `nil`。
    func readFile(name: String) async -> Data? {
        if !checkIsValidName(name) {
            return nil
        }
        let fileURL = fullURL.appendingPathComponent(name)
        if fileManager.fileExists(atPath: fileURL.path) {
            return try? await withCheckedThrowingContinuation { continuation in
                queue.sync {
                    let data = try? Data(contentsOf: fileURL)
                    continuation.resume(returning: data)
                }
            }
        } else {
            return nil
        }
    }
    
    /// 返回指定名稱的檔案的大小。
    ///
    ///
    /// - Parameter name: 檔案的名稱。
    /// - Returns: 如果檔案存在，則返回檔案的大小（以字節為單位），否則返回 `nil`。
    func sizeOfFile(name: String) -> Int? {
        if !checkIsValidName(name) {
            return nil
        }
        let fileURL = fullURL.appendingPathComponent(name)
        do {
            let resources = try fileURL.resourceValues(forKeys: [.fileSizeKey])
            return resources.fileSize
        } catch {
            return nil
        }
    }
    
    /// 刪除指定名稱的檔案。
    ///
    /// - Parameter name: 檔案的名稱。
    /// - Returns: 如果檔案刪除成功或檔案本來就不存在，則返回 `true`，否則返回 `false`。
    @discardableResult func removeFile(name: String) async -> Bool {
        if !checkIsValidName(name) {
            return true
        }
        let fileURL = fullURL.appendingPathComponent(name)
        if fileManager.fileExists(atPath: fileURL.path) {
            do {
                return try await withCheckedThrowingContinuation { continuation in
                    queue.sync { [weak self] in
                        do {
                            try self?.fileManager.removeItem(at: fileURL)
                            continuation.resume(returning: true)
                        } catch {
                            continuation.resume(returning: false)
                        }
                    }
                }
            } catch {
                return true
            }
            
        } else {
            return true
        }
    }
    
    // MARK: Privates
    
    private lazy var fileManager: FileManager = {
        return FileManager.default
    }()
    
    /// 檢查檔案名稱是否合法。
    ///
    /// - Parameter name: 檔案的名稱。
    private func checkIsValidName(_ name: String) -> Bool {
        let invalidCharacters = CharacterSet(charactersIn: "/\\<>?*|\"")
        return name.rangeOfCharacter(from: invalidCharacters) == nil
    }
    
    private lazy var queue: DispatchQueue = {
        return DispatchQueue.global()
    }()
}
