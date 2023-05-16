//
//  LocalStorageManagerTests.swift
//  ChatRoomTests
//
//  Created by Kedia on 2023/3/27.
//

import XCTest

final class LocalStorageManagerTests: XCTestCase {
    var manager: LocalStorageManager!

    override func setUp() {
        super.setUp()
        manager = LocalStorageManager(directoryName: "TestDirectory")
    }

    override func tearDown() {
        _ = manager.removeDirectory(name: "TestDirectory")
        manager = nil
        super.tearDown()
    }

    // MARK: - Create file tests
    func testCreateFileSuccessful() async {
        let fileName = "testFile.txt"
        let data = Data("Hello, world!".utf8)
        let url = manager.createFile(name: fileName)
        await manager.appendDataToFile(name: fileName, data: data)
        XCTAssertNotNil(url, "Failed to create file")
    }

    func testCreateFileInvalidFileName() async {
        let fileName = "/\\<>?*|\""
        let url = manager.createFile(name: fileName)
        XCTAssertNil(url)
    }

    func testCreateFileEmptyData() async {
        let fileName = "emptyFile.txt"
        let data = Data()
        let url = manager.createFile(name: fileName)
        await manager.appendDataToFile(name: fileName, data: data)
        XCTAssertNotNil(url, "Failed to create an empty file")
        XCTAssertEqual(0, manager.sizeOfFile(name: fileName), "Empty file size should be 0")
    }

    func testCreateFileFileAlreadyExists() async {
        let fileName = "existingFile.txt"
        let data1 = Data("This is the first data.".utf8)
        let data2 = Data("This is the second data.".utf8)

        let url1 = manager.createFile(name: fileName)
        await manager.appendDataToFile(name: fileName, data: data1)
        XCTAssertNotNil(url1, "Failed to create the first file")

        let url2 = manager.createFile(name: fileName)
        XCTAssertNil(url2, "Should not be able to create a file with the same name")

        await manager.appendDataToFile(name: fileName, data: data2)
        let readData = await manager.readFile(name: fileName)
        XCTAssertNotNil(readData, "Failed to read the existing file")
        XCTAssertEqual(String(data: readData!, encoding: .utf8), "This is the first data.This is the second data.")
    }

    // MARK: - Append file tests
    // Test appending data to a non-existent file
    func testAppendDataToNonExistentFile() async {
        let fileName = "nonExistentFile.txt"
        let data = Data("This is some data.".utf8)

        let result = await manager.appendDataToFile(name: fileName, data: data)
        XCTAssertTrue(result, "Should successfully create and append data to the non-existent file")

        let readData = await manager.readFile(name: fileName)
        XCTAssertEqual(data, readData, "Appended data should be equal to the read data")
    }

    // Test appending data to an existing file
    func testAppendDataToExistingFile() async {
        let fileName = "existingFile.txt"
        let data1 = Data("This is the first data.".utf8)
        let data2 = Data("This is the second data.".utf8)

        let url = manager.createFile(name: fileName)
        await manager.appendDataToFile(name: fileName, data: data1)
        XCTAssertNotNil(url, "Failed to create the file")

        let result = await manager.appendDataToFile(name: fileName, data: data2)
        XCTAssertTrue(result, "Should successfully append data to the existing file")

        let readData = await manager.readFile(name: fileName)
        let expectedData = data1 + data2
        XCTAssertEqual(expectedData, readData, "Appended data should be combined with existing data")
    }

    // Test appending data with an invalid file name
    func testAppendDataWithInvalidFileName() async {
        let fileName = "/\\<>?*|\""
        let data = Data("Invalid file name test.".utf8)
        let succeed = await manager.appendDataToFile(name: fileName, data: data)
        XCTAssertFalse(succeed)
    }

    // MARK - Read file tests

    func testReadNonExistentFile() async {
        let data = await self.manager.readFile(name: "nonexistent.txt")
        XCTAssertNil(data)
    }

    func testReadEmptyFile() async {
        let fileName = "empty.txt"
        _ = manager.createFile(name: fileName)

        let fileData = await manager.readFile(name: fileName)
        XCTAssertNil(fileData)
    }

    func testReadNonEmptyFile() async {
        let fileName = "nonempty.txt"
        let fileContent = "Hello, world!"
        let fileData = fileContent.data(using: .utf8)!

        _ = manager.createFile(name: fileName)
        await manager.appendDataToFile(name: fileName, data: fileData)

        let readData = await manager.readFile(name: fileName)
        XCTAssertEqual(readData, fileData)
    }

    func testReadFileWithInvalidCharacters() async {
        let fileName = "invalid<>|*.txt"
        let data = await manager.readFile(name: fileName)
        XCTAssertNil(data)
    }

    // MARK: - File size tests

    func testSizeOfNonExistentFile() async {
        let size = manager.sizeOfFile(name: "nonexistent.txt")
        XCTAssertNil(size)
    }

    func testSizeOfEmptyFile() async {
        let fileName = "empty.txt"
        _ = manager.createFile(name: fileName)

        let fileSize = manager.sizeOfFile(name: fileName)
        XCTAssertNil(fileSize)
    }

    func testSizeOfNonEmptyFile() async {
        let fileName = "nonempty.txt"
        let fileContent = "Hello, world!"
        let fileData = fileContent.data(using: .utf8)!

        _ = manager.createFile(name: fileName)
        await manager.appendDataToFile(name: fileName, data: fileData)

        let fileSize = manager.sizeOfFile(name: fileName)
        XCTAssertEqual(fileSize, fileData.count)
    }

    func testSizeOfFileWithInvalidCharacters() async {
        let fileName = "invalid<>|*.txt"
        let size = manager.sizeOfFile(name: fileName)
        XCTAssertNil(size)
    }

    // MARK: - Remove file tests

    func testRemoveNonExistentFile() async {
        let isMoved = await manager.removeFile(name: "nonexistent.txt")
        XCTAssertTrue(isMoved)
    }

    func testRemoveEmptyFile() async {
        let fileName = "empty.txt"
        _ = manager.createFile(name: fileName)

        let isRemoved = await manager.removeFile(name: fileName)
        XCTAssertTrue(isRemoved)

        let size = manager.sizeOfFile(name: fileName)
        XCTAssertNil(size)
    }

    func testRemoveNonEmptyFile() async {
        let fileName = "nonempty.txt"
        let fileContent = "Hello, world!"
        let fileData = fileContent.data(using: .utf8)!

        _ = manager.createFile(name: fileName)
        await manager.appendDataToFile(name: fileName, data: fileData)

        let isRemoved = await manager.removeFile(name: fileName)
        XCTAssertEqual(isRemoved, true)

        let size = manager.sizeOfFile(name: fileName)
        XCTAssertNil(size)
    }

    func testRemoveFileWithInvalidCharacters() async {
        let fileName = "invalid<>|*.txt"
        let isRemoved = await manager.removeFile(name: fileName)
        XCTAssertTrue(isRemoved)
    }
    
    func testGenerateZipFileAsync_withValidFileName() async {
        manager.createFile(name: "test_file.txt")
        await manager.appendDataToFile(name: "test_file.txt", data: "test_file.txt".data(using: .utf8)!)
        let zipURL = await manager.generateZipFileAsync(fileSuffix: nil)
        XCTAssertNotNil(zipURL, "Zip URL should not be nil")
        XCTAssertTrue(zipURL!.path.hasSuffix("TestDirectory.zip"), "Zip URL should have a .zip extension")
    }
}
