//
//  FileManager.swift
//  ChatRoom
//
//  Created by ERay_Peng on 2023/3/9.
//

import Foundation

extension FileManager {
    func getLocalImagesFolderUrl() -> URL? {
        let tmpDirectory = "iOS-photo-library"
        guard let fullPath = self.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(tmpDirectory, isDirectory: true) else {
            return nil
        }
      
        if !self.fileExists(atPath: fullPath.path) {
            _ = try? self.createDirectory(atPath: fullPath.path, withIntermediateDirectories: true, attributes: nil)
        }
        return fullPath
    }
}
