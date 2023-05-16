//
//  String+UtilTestable.swift
//  ChatRoom
//
//  Created by Kedia on 2023/3/29.
//

import Foundation


extension String {

    /// 最後一個路徑組件
    ///
    /// 這個屬性會解析字串並返回最後一個非空路徑組件。路徑組件之間使用斜線（`/`）分隔。
    ///
    /// ```
    /// let path = "/Users/kedia/Documents/chatroom-ios/ChatRoom/AppDelegate.swift"
    /// let lastComponent = path.lastPathComponent
    /// print(lastComponent) // 輸出 "AppDelegate.swift"
    /// ```
    ///
    /// 如果字串以斜線結尾或者字串本身為空，則返回最後一個非空組件或空字串。
    ///
    /// ```
    /// let emptyPath = "/path/to/your/folder/"
    /// print(emptyPath.lastPathComponent) // 輸出 "folder"
    /// ```
    var lastPathComponent: String {
        let components = self.split(separator: "/")
        guard let lastNonEmptyComponent = components.last(where: { !$0.isEmpty }) else {
            return ""
        }
        return String(lastNonEmptyComponent)
    }

    /// 根據指定的 `fileSizeToRemove`，從輸入的字符串開始移除行，直到移除的行的總字節大小超過 `fileSizeToRemove` 為止，並以異步方式返回新的字符串。
    ///
    /// 此函數將根據指定的 `fileSizeToRemove` 從輸入的字符串開始移除行。當累計字節大小超過 `fileSizeToRemove` 時，返回剩餘的行。否則，返回空字符串。
    ///
    /// - Parameter fileSizeToRemove: 要移除的最小字節大小。每次移除時以一行為一個單位，從上面的行開始刪。
    ///
    /// - Returns: 一個新的字符串，表示移除指定字節大小後的剩餘行。此函數將以異步方式返回結果。
    ///
    /// # Example
    /// ```
    /// let input = "Hello\nWorld\nSwift"
    /// let result = await input.linesToRemove(fileSizeToRemove: 12)
    /// print(result) // 輸出 "Swift"
    /// ```
    func linesToRemove(fileSizeToRemove: Int) async -> String {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                let lines = self.split(separator: "\n", omittingEmptySubsequences: false)
                var totalBytes = 0

                for (index, line) in lines.enumerated() {
                    totalBytes += line.utf8.count + 1 // 加 1 是因為換行符的字節
                    if totalBytes > fileSizeToRemove {
                        continuation.resume(returning: lines[index...].joined(separator: "\n"))
                        return
                    }
                }
                continuation.resume(returning: "")
            }
        }
    }

    func truncate(toBytes byteLimit: Int) -> String {
        let lines = self.split(separator: "\n", omittingEmptySubsequences: false)
        var totalBytes = 0
        var result = ""

        for line in lines.reversed() {
            let lineBytes = line.utf8.count
            if totalBytes + lineBytes <= byteLimit {
                totalBytes += lineBytes
                result = "\(line)\n\(result)"
            } else {
                break
            }
        }

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

}
