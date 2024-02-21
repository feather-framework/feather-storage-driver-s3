//
//  S3StorageComponentBuilder.swift
//  FeatherStorageDriverS3
//
//  Created by Tibor Bodecs on 2020. 04. 28..
//

import SotoS3
import SotoCore
import FeatherComponent

struct S3StorageComponentBuilder: ComponentBuilder {

    func build(using config: ComponentConfig) throws -> Component {
        S3StorageComponent(config: config)
    }
}
