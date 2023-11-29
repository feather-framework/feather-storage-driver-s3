# Feather Storage Driver S3

S3 compatible storage driver for the Feather CMS storage service.

## Getting started

⚠️ This repository is a work in progress, things can break until it reaches v1.0.0. 

Use at your own risk.

### Adding the dependency

To add a dependency on the package, declare it in your `Package.swift`:

```swift
.package(url: "https://github.com/feather-framework/feather-storage-driver-s3", .upToNextMinor(from: "0.3.0")),
```

and to your application target, add `FeatherStorageDriverS3` to your dependencies:

```swift
.product(name: "FeatherStorageDriverS3", package: "feather-storage-driver-s3")
```

Example `Package.swift` file with `FeatherStorageDriverS3` as a dependency:

```swift
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "my-application",
    dependencies: [
        .package(url: "https://github.com/feather-framework/feather-storage-driver-s3", .upToNextMinor(from: "0.3.0")),
    ],
    targets: [
        .target(name: "MyApplication", dependencies: [
            .product(name: "FeatherStorageDriverS3", package: "feather-storage-driver-s3")
        ]),
        .testTarget(name: "MyApplicationTests", dependencies: [
            .target(name: "MyApplication"),
        ]),
    ]
)
```

