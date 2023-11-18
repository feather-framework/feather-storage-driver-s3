// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "feather-storage-driver-s3",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .library(name: "FeatherStorageDriverS3", targets: ["FeatherStorageDriverS3"]),
    ],
    dependencies: [
        .package(url: "https://github.com/soto-project/soto", from: "6.8.0"),
        .package(url: "https://github.com/feather-framework/feather-storage.git", .upToNextMinor(from: "0.1.0")),
    ],
    targets: [
        .target(
            name: "FeatherStorageDriverS3",
            dependencies: [
                .product(name: "SotoS3", package: "soto"),
                .product(name: "FeatherStorage", package: "feather-storage"),
            ]
        ),
        .testTarget(
            name: "FeatherStorageDriverS3Tests",
            dependencies: [
                .product(name: "FeatherStorage", package: "feather-storage"),
                .product(name: "XCTFeatherStorage", package: "feather-storage"),
                .target(name: "FeatherStorageDriverS3"),
            ]
        ),
    ]
)
