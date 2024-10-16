//
//  FeatherStorageDriverS3Tests.swift
//  FeatherStorageDriverS3Tests
//
//  Created by Tibor Bodecs on 2023. 01. 16..
//

import FeatherComponent
import FeatherStorage
import FeatherStorageDriverS3
import Foundation
import Logging
import NIO
import NIOFoundationCompat
import SotoCore
import XCTFeatherStorage
import XCTest

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
        let eventLoopGroup = MultiThreadedEventLoopGroup(
            numberOfThreads: 1  //System.coreCount
        )
        do {
            let registry = ComponentRegistry()

            let client = AWSClient(
                credentialProvider: .static(
                    accessKeyId: id,
                    secretAccessKey: secret
                )
            )

            try await registry.addStorage(
                S3StorageComponentContext(
                    eventLoopGroup: eventLoopGroup,
                    client: client,
                    region: .init(rawValue: self.region),
                    bucket: .init(name: self.bucket),
                    timeout: .seconds(60)
                )
            )

            let storage = try await registry.storage()

            do {
                let suite = StorageTestSuite(storage)
                try await suite.testAll()
                try await client.shutdown()
            }
            catch {
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
