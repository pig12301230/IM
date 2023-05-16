//
//  DataExtensionTests.swift
//  ChatRoomTests
//
//  Created by Kedia on 2023/3/16.
//

import XCTest

class DataUtilTests: XCTestCase {

}

// MARK: - fileSizeInMB Tests

extension DataUtilTests {

    func testEmptyData() {
        let emptyData = Data()
        XCTAssertEqual(emptyData.fileSizeInMB, 0)
    }

    func testOneByteData() {
        let oneByteData = Data([0x01])
        XCTAssertEqual(oneByteData.fileSizeInMB, 0.000001)
    }

    func testOneKilobyteData() {
        let oneKilobyteData = Data(repeating: 0, count: 1_000)
        XCTAssertEqual(oneKilobyteData.fileSizeInMB, 0.001)
    }

    func testOneMegabyteData() {
        let oneMegabyteData = Data(repeating: 0, count: 1_000_000)
        XCTAssertEqual(oneMegabyteData.fileSizeInMB, 1)
    }

    func testLargeData() {
        let largeData = Data(repeating: 0, count: 2_500_000)
        XCTAssertEqual(largeData.fileSizeInMB, 2.5)
    }
}

// MARK: - getImageCompressionQuality Tests

extension DataUtilTests {

    func testImageCompressionQualityWithSmallData() {
            let data = "Hello, world!".data(using: .utf8) ?? Data()
            let limit = 10.0
            let result = data.getImageCompressionQuality(limit: limit)
            XCTAssertEqual(result, 1.0, accuracy: 0.001)
        }

        func testImageCompressionQualityWithLargeData() {
            let data = Data(count: 1024 * 1024 * 2)
            let limit = 1.0
            let result = data.getImageCompressionQuality(limit: limit)
            XCTAssertGreaterThan(result, 0.05, "Compression quality should be greater than 0.05")
            XCTAssertLessThan(result, 1.0, "Compression quality should be less than 1.0")
        }

        func testImageCompressionQualityWithLimit() {
            let data = Data(count: 1024 * 1024 * 2)
            let limit = Double(data.count)
            let result = data.getImageCompressionQuality(limit: limit)
            XCTAssertEqual(result, 1.0, accuracy: 0.001)
        }
}
