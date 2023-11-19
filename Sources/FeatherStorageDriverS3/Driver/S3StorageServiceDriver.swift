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

    func run(using config: ServiceConfig) throws -> Service {
        S3StorageService(config: config)
    }
}
