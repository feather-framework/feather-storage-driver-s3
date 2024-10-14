//
//  S3StorageComponent.swift
//  FeatherStorageDriverS3
//
//  Created by Tibor Bodecs on 2020. 04. 28..
//

import FeatherComponent
import FeatherStorage
import SotoS3

@dynamicMemberLookup
struct S3StorageComponent {

    public let config: ComponentConfig

    subscript<T>(
        dynamicMember keyPath: KeyPath<S3StorageComponentContext, T>
    ) -> T {
        let context = config.context as! S3StorageComponentContext
        return context[keyPath: keyPath]
    }
}

extension S3StorageComponent {

    fileprivate var bucketName: String { self.bucket.name! }

    fileprivate var s3: S3 {
        let awsUrl = "https://s3.\(self.region.rawValue).amazonaws.com"
        let endpoint = self.endpoint ?? awsUrl

        return .init(
            client: self.client,
            region: self.region,
            endpoint: endpoint,
            timeout: self.timeout
        )
    }
}

extension S3StorageComponent: StorageComponent {

    public var availableSpace: UInt64 {
        .max
    }

    public func uploadStream(
        key: String,
        sequence: StorageAnyAsyncSequence<ByteBuffer>
    ) async throws {
        do {
            _ = try await s3.putObject(
                .init(
                    body: .init(
                        asyncSequence: sequence,
                        length: sequence.length.map { Int($0) }
                    ),
                    bucket: bucketName,
                    key: key
                ),
                logger: logger
            )
        }
        catch {
            throw StorageComponentError.unknown(error)
        }
    }

    public func downloadStream(
        key: String,
        range: ClosedRange<Int>?
    ) async throws -> StorageAnyAsyncSequence<ByteBuffer> {
        let exists = await exists(key: key)
        guard exists else {
            throw StorageComponentError.invalidKey
        }
        do {
            let byteRange = range.map {
                "bytes=\($0.lowerBound)-\($0.upperBound)"
            }
            let response = try await s3.getObject(
                .init(
                    bucket: bucketName,
                    key: key,
                    range: byteRange
                ),
                logger: logger
            )
            return .init(
                asyncSequence: response.body,
                length: response.body.length.map { UInt64($0) }
            )
        }
        catch let error as StorageComponentError {
            throw error
        }
        catch {
            throw StorageComponentError.unknown(error)
        }
    }

    public func exists(key: String) async -> Bool {
        do {
            /// check if key exists
            _ = try await s3.getObject(
                .init(
                    bucket: bucketName,
                    key: key
                ),
                logger: logger
            )
            return true
        }
        catch {
            if !key.hasSuffix("/") {
                return await exists(key: key + "/")
            }
            return false
        }
    }

    public func size(key: String) async -> UInt64 {
        let exists = await exists(key: key)
        guard exists else {
            return 0
        }
        do {
            let res = try await s3.headObject(
                .init(
                    bucket: bucketName,
                    key: key
                ),
                logger: logger
            )
            return UInt64(res.contentLength ?? 0)
        }
        catch {
            return 0
        }
    }

    public func copy(key source: String, to destination: String) async throws {
        let exists = await exists(key: source)
        guard exists else {
            throw StorageComponentError.invalidKey
        }
        do {
            _ = try await s3.copyObject(
                .init(
                    bucket: bucketName,
                    copySource: bucketName + "/" + source,
                    key: destination
                ),
                logger: logger
            )
        }
        catch {
            throw StorageComponentError.unknown(error)
        }
    }

    public func list(key: String?) async throws -> [String] {
        do {
            let list = try await s3.listObjects(
                .init(
                    bucket: bucketName,
                    prefix: key
                ),
                logger: logger
            )
            let keys = (list.contents ?? []).map(\.key).compactMap { $0 }
            var dropCount = 0
            if let prefix = key {
                dropCount = prefix.split(separator: "/").count
            }
            return keys.compactMap {
                $0.split(separator: "/")
                    .dropFirst(dropCount)
                    .map(String.init)
                    .first
            }
        }
        catch {
            throw StorageComponentError.unknown(error)
        }
    }

    public func delete(key: String) async throws {
        do {
            _ = try await s3.deleteObject(
                .init(
                    bucket: bucketName,
                    key: key
                ),
                logger: logger
            )
        }
        catch {
            throw StorageComponentError.unknown(error)
        }
    }

    public func create(key: String) async throws {
        do {
            let safeKey = key.split(separator: "/").joined(separator: "/") + "/"
            _ = try await s3.putObject(
                .init(
                    bucket: bucketName,
                    contentLength: 0,
                    key: safeKey
                ),
                logger: logger
            )
        }
        catch {
            throw StorageComponentError.unknown(error)
        }
    }

    public func createMultipartId(
        key: String
    ) async throws -> String {
        do {
            let res = try await s3.createMultipartUpload(
                .init(
                    bucket: bucketName,
                    key: key
                ),
                logger: logger
            )
            guard let uploadId = res.uploadId else {
                throw StorageComponentError.invalidMultipartId
            }
            return uploadId
        }
        catch let error as StorageComponentError {
            throw error
        }
        catch {
            throw StorageComponentError.unknown(error)
        }
    }

    public func uploadStream(
        multipartId: String,
        key: String,
        number: Int,
        sequence: StorageAnyAsyncSequence<ByteBuffer>
    ) async throws -> StorageChunk {
        do {
            let res = try await s3.uploadPart(
                .init(
                    body: .init(
                        asyncSequence: sequence,
                        length: sequence.length.map { Int($0) }
                    ),
                    bucket: bucketName,
                    key: key,
                    partNumber: number,
                    uploadId: multipartId
                ),
                logger: logger
            )
            guard let etag = res.eTag else {
                throw StorageComponentError.invalidMultipartChunk
            }
            return .init(chunkId: etag, number: number)
        }
        catch {
            throw StorageComponentError.unknown(error)
        }
    }

    public func abort(
        multipartId: String,
        key: String
    ) async throws {
        do {
            _ = try await s3.abortMultipartUpload(
                .init(
                    bucket: bucketName,
                    key: key,
                    uploadId: multipartId
                ),
                logger: logger
            )
        }
        catch {
            throw StorageComponentError.unknown(error)
        }
    }

    public func finish(
        multipartId: String,
        key: String,
        chunks: [StorageChunk]
    ) async throws {
        do {
            let parts = chunks.map { chunk -> S3.CompletedPart in
                .init(
                    eTag: chunk.chunkId,
                    partNumber: chunk.number
                )
            }
            _ = try await s3.completeMultipartUpload(
                .init(
                    bucket: bucketName,
                    key: key,
                    multipartUpload: .init(parts: parts),
                    uploadId: multipartId
                ),
                logger: logger
            )
        }
        catch {
            throw StorageComponentError.unknown(error)
        }
    }
}
