//
//  S3StorageServiceDriver.swift
//  FeatherStorageDriverS3
//
//  Created by Tibor Bodecs on 2020. 04. 28..
//

import SotoS3
import SotoCore
import FeatherService

struct S3StorageServiceDriver: ServiceDriver {

    let context: S3StorageServiceContext
    let client: AWSClient

    init(context: S3StorageServiceContext) {
        self.context = context
        self.client = AWSClient(
            credentialProvider: context.credentialProvider,
            options: .init(
                requestLogLevel: context.logLevel,
                errorLogLevel: context.logLevel
            ),
            httpClientProvider: .createNewWithEventLoopGroup(
                context.eventLoopGroup
            ),
            logger: context.logger
        )
    }

    func run(using config: ServiceConfig) throws -> Service {

        let awsUrl = "https://s3.\(context.region.rawValue).amazonaws.com"
        let endpoint = context.endpoint ?? awsUrl

        let s3 = S3(
            client: client,
            region: context.region,
            endpoint: endpoint
        )
        return S3StorageService(
            s3: s3,
            config: config
        )
    }

    func shutdown() throws {
        try client.syncShutdown()
    }
}
