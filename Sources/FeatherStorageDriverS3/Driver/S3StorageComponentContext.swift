//
//  S3StorageComponentContext.swift
//  FeatherStorageDriverS3
//
//  Created by Tibor Bodecs on 2020. 04. 28..
//

import FeatherComponent
import NIOCore
import SotoS3

public struct S3StorageComponentContext: ComponentContext {
    let eventLoopGroup: EventLoopGroup
    let client: AWSClient
    let region: Region
    let bucket: S3.Bucket
    let endpoint: String?
    let timeout: TimeAmount?

    public init(
        eventLoopGroup: EventLoopGroup,
        client: AWSClient,
        region: Region,
        bucket: S3.Bucket,
        endpoint: String? = nil,
        timeout: TimeAmount? = nil
    ) {
        self.eventLoopGroup = eventLoopGroup
        self.client = client
        self.region = region
        self.bucket = bucket
        self.endpoint = endpoint
        self.timeout = timeout
    }

    public func make() throws -> ComponentFactory {
        S3StorageComponentFactory()
    }
}
