//
//  S3StorageServiceContext.swift
//  FeatherStorageDriverS3
//
//  Created by Tibor Bodecs on 2020. 04. 28..
//

import SotoS3
import FeatherService

public struct S3StorageServiceContext: ServiceContext {
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

    public func make() throws -> ServiceBuilder {
        S3StorageServiceBuilder()
    }
}
