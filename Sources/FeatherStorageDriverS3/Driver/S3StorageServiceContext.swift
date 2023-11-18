//
//  S3StorageServiceContext.swift
//  FeatherStorageDriverS3
//
//  Created by Tibor Bodecs on 2020. 04. 28..
//

@preconcurrency import SotoS3
import FeatherService

struct S3StorageServiceContext: ServiceContext {

    let eventLoopGroup: EventLoopGroup

    /// credential provider
    let credentialProvider: CredentialProviderFactory

    /// region
    let region: Region

    /// bucket
    let bucket: S3.Bucket

    let timeout: TimeAmount? = nil

    /// custom endpoint
    let endpoint: String?

    /// custom log level for the AWS client
    let logLevel: Logger.Level

    /// custom logger
    let logger: Logger

    func createDriver() throws -> ServiceDriver {
        S3StorageServiceDriver(context: self)
    }
}
