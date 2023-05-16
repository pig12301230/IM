//
//  StringUtilTests.swift
//  ChatRoomTests
//
//  Created by Kedia on 2023/3/28.
//

import XCTest

final class StringUtilTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    // MARK: - linesToRemove tests
    func testEmptyString() async {
        let input = ""
        let result = await input.linesToRemove(fileSizeToRemove: 10)
        XCTAssertEqual(result, "")
    }

    func testFileSizeToRemoveZero() async {
        let input = "Hello\nWorld"
        let result = await input.linesToRemove(fileSizeToRemove: 0)
        XCTAssertEqual(result, "Hello\nWorld")
    }

    func testFileSizeToRemoveLargerThanString() async {
        let input = "Hello\nWorld"
        let result = await input.linesToRemove(fileSizeToRemove: 100)
        XCTAssertEqual(result, "")
    }

    func testRemoveExactFileSize() async {
        let input = "Hello\nWorld\nSwift"
        let result = await input.linesToRemove(fileSizeToRemove: 11)
        XCTAssertEqual(result, "World\nSwift")
    }

    func testDoNotCountLastLine() async {
        let input = "Hello\nWorld\nSwift"
        let result = await input.linesToRemove(fileSizeToRemove: 12)
        XCTAssertEqual(result, "Swift")
    }

    // MARK: - lastPathComponent tests
    func testLastPathComponent() {
        XCTAssertEqual("/Users/kedia/Documents/chatroom-ios/ChatRoom/AppDelegate.swift".lastPathComponent, "AppDelegate.swift")
        XCTAssertEqual("file.txt".lastPathComponent, "file.txt")
        XCTAssertEqual("/path/to/your/folder/".lastPathComponent, "folder")
        XCTAssertEqual("".lastPathComponent, "")
        XCTAssertEqual("/".lastPathComponent, "")
    }

    // MARK: - String.truncate(toBytes:) tests
    func testEmptyString() {
        let input = ""
        let expectedOutput = ""
        XCTAssertEqual(input.truncate(toBytes: 5), expectedOutput)
    }

    func testSingleLineWithinLimit() {
        let input = "Hello, World!"
        let expectedOutput = "Hello, World!"
        XCTAssertEqual(input.truncate(toBytes: 20), expectedOutput)
    }

    func testSingleLineExceedingLimit() {
        let input = "Hello, World!"
        let expectedOutput = ""
        XCTAssertEqual(input.truncate(toBytes: 5), expectedOutput)
    }

    func testMultilineWithinLimit() {
        let input = "Hello, World!\nThis is a test."
        let expectedOutput = "This is a test."
        XCTAssertEqual(input.truncate(toBytes: 20), expectedOutput)
    }

    func testMultilineExceedingLimit() {
        let input = "Hello, World!\nThis is a test."
        let expectedOutput = ""
        XCTAssertEqual(input.truncate(toBytes: 5), expectedOutput)
    }

    func testExactByteLimit() {
        let input = "Hello, World!\nThis is a test.\n"
        let expectedOutput = "This is a test."
        XCTAssertEqual(input.truncate(toBytes: 15), expectedOutput)
    }
}
