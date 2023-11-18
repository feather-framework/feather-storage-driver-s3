//
//  ServiceContextFactory+S3StorageService.swift
//  FeatherStorageDriverS3
//
//  Created by Tibor Bodecs on 2020. 04. 28..
//

import SotoS3
import FeatherService

public extension ServiceContextFactory {

    static func s3Storage(
        eventLoopGroup: EventLoopGroup,
        credentialProvider: CredentialProviderFactory = .default,
        region: Region,
        bucket: S3.Bucket,
        endpoint: String? = nil,
        logLevel: Logger.Level = .notice,
        logger: Logger = AWSClient.loggingDisabled
    ) -> Self {
        .init {
            S3StorageServiceContext(
                eventLoopGroup: eventLoopGroup,
                credentialProvider: credentialProvider,
                region: region,
                bucket: bucket,
                endpoint: endpoint,
                logLevel: logLevel,
                logger: logger
            )
        }
    }
}
