//
//  ServiceContextFactory+S3StorageService.swift
//  FeatherStorageDriverS3
//
//  Created by Tibor Bodecs on 2020. 04. 28..
//

import SotoS3
import SotoCore
import FeatherService

public extension ServiceContextFactory {

    static func s3Storage(
        eventLoopGroup: EventLoopGroup,
        client: AWSClient,
        region: Region,
        bucket: S3.Bucket,
        endpoint: String? = nil,
        timeout: TimeAmount? = nil
    ) -> Self {
        .init {
            S3StorageServiceContext(
                eventLoopGroup: eventLoopGroup,
                client: client,
                region: region,
                bucket: bucket,
                endpoint: endpoint,
                timeout: timeout
            )
        }
    }
}
