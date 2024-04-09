//
//  S3StorageComponentFactory.swift
//  FeatherStorageDriverS3
//
//  Created by Tibor Bodecs on 2020. 04. 28..
//

import FeatherComponent
import SotoCore
import SotoS3

struct S3StorageComponentFactory: ComponentFactory {

    func build(using config: ComponentConfig) throws -> Component {
        S3StorageComponent(config: config)
    }
}
