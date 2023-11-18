//
//  FeatherStorageDriverS3Tests.swift
//  FeatherStorageDriverS3Tests
//
//  Created by Tibor Bodecs on 2023. 01. 16..
//

import NIO
import Logging
import Foundation
import XCTest
import FeatherService
import FeatherStorage
import FeatherStorageDriverS3
import XCTFeatherStorage

final class FeatherStorageDriverS3Tests: XCTestCase {

    var accessKeyId: String {
        ProcessInfo.processInfo.environment["S3_ID"]!
    }

    var secretAccessKey: String {
        ProcessInfo.processInfo.environment["S3_SECRET"]!
    }

    var region: String {
        ProcessInfo.processInfo.environment["S3_REGION"]!
    }

    var bucket: String {
        ProcessInfo.processInfo.environment["S3_BUCKET"]!
    }

    // MARK: - tests

    func testS3DriverUsingTestSuite() async throws {

        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)

        do {
            let registry = ServiceRegistry()
            try await registry.add(
                .s3Storage(
                    eventLoopGroup: eventLoopGroup,
                    credentialProvider: .static(
                        accessKeyId: accessKeyId,
                        secretAccessKey: secretAccessKey
                    ),
                    region: .init(rawValue: region),
                    bucket: .init(name: bucket)
                ),
                as: .s3Storage
            )

            try await registry.run()

            let storage = try await registry.get(.s3Storage) as! StorageService
            let suite = StorageTestSuite(storage)
            do {
                try await suite.testAll()
                try await registry.shutdown()
            }
            catch {
                try await registry.shutdown()
                throw error
            }
        }
        catch {
            XCTFail("\(error)")
        }

        try await eventLoopGroup.shutdownGracefully()
    }
}
