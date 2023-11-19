//
//  S3StorageServiceContext.swift
//  FeatherStorageDriverS3
//
//  Created by Tibor Bodecs on 2020. 04. 28..
//

import SotoS3
import FeatherService

struct S3StorageServiceContext: ServiceContext {

    let eventLoopGroup: EventLoopGroup
    let client: AWSClient
    let region: Region
    let bucket: S3.Bucket
    let endpoint: String?
    let timeout: TimeAmount?

    func createDriver() throws -> ServiceDriver {
        S3StorageServiceDriver()
    }
}
