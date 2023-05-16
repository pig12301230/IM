//
//  FileLogManagerTests.swift
//  ChatRoomTests
//
//  Created by Kedia on 2023/3/27.
//

import XCTest



final class FileLogManagerTests: XCTestCase {

    var fileLogger: FileLogAdapter!

    override func setUp() {
        super.setUp()
        fileLogger = FileLogAdapter.shared
    }

    override func tearDown() {
        super.tearDown()
        Task {
            await fileLogger.deleteLogFile()
        }
    }

    // Test case: 正常寫入日誌
    func testWriteLogNormal() async {
        let testLog = "This is a test log entry"
        await fileLogger.writeLog(testLog)
        let logContents = await fileLogger.readLogFileContents()
        XCTAssert(logContents?.contains(testLog) == true)
    }

    // Test case: 確保時間戳和換行符添加正確
    func testWriteLogTimestampAndNewline() async {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 8 * 3600)

        let testLog = "This is a test log entry"
        await fileLogger.writeLog(testLog)
        let logContents = await fileLogger.readLogFileContents()

        let timestamp = dateFormatter.string(from: Date())

        XCTAssert(logContents?.contains(timestamp) == true)
        XCTAssert(logContents?.hasSuffix("\n") == true)
    }

    // Test case: 寫入日誌後檢查文件大小
    func testWriteLogFileSize() async {
        let testLog = "This is a test log entry"
        await fileLogger.writeLog(testLog)
        let fileSize = fileLogger.logFileSize()
        XCTAssertNotNil(fileSize)
        XCTAssertTrue(fileSize! == 54)
    }

    // Test case: 文件大小超過限制後的自動刪除
    func testWriteLogFileSizeExceeded() async {
        let testLog = "A\n"
        let fileSizeExceededString = String(repeating: testLog, count: fileLogger.maxFileSize/testLog.count + 1)

        await fileLogger.writeLog(fileSizeExceededString)
        await fileLogger.writeLog(testLog)
        let fileSizeAfterExceeded = fileLogger.logFileSize()!

        XCTAssert(fileSizeAfterExceeded < fileLogger.maxFileSize, "fileSizeAfterExceeded: \(fileSizeAfterExceeded)")
        XCTAssertTrue(fileSizeAfterExceeded > fileLogger.maxFileSize / 10 * 8
        )
        
    }

}
