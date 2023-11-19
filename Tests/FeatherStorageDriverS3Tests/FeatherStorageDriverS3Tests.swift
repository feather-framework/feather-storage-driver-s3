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
import SotoCore

final class FeatherStorageDriverS3Tests: XCTestCase {

    var id: String {
        ProcessInfo.processInfo.environment["S3_ID"]!
    }

    var secret: String {
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
            
            let client = AWSClient(
                credentialProvider: .static(
                    accessKeyId: id,
                    secretAccessKey: secret
                ),
                httpClientProvider: .createNewWithEventLoopGroup(eventLoopGroup)
            )
            
            try await registry.add(
                .s3Storage(
                    eventLoopGroup: eventLoopGroup,
                    client: client,
                    region: .init(rawValue: region),
                    bucket: .init(name: bucket)
                ),
                as: .s3Storage
            )

            try await registry.run()
            let storage = try await registry.get(.s3Storage) as! StorageService

            do {
                let suite = StorageTestSuite(storage)
                try await suite.testAll()

                try await registry.shutdown()
                try await client.shutdown()
            }
            catch {
                try await registry.shutdown()
                try await client.shutdown()
                throw error
            }
        }
        catch {
            XCTFail("\(error)")
        }

        try await eventLoopGroup.shutdownGracefully()
    }
}
