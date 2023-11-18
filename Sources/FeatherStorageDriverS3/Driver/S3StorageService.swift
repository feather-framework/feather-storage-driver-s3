//
//  S3StorageService.swift
//  FeatherStorageDriverS3
//
//  Created by Tibor Bodecs on 2020. 04. 28..
//

import SotoS3
import FeatherService
import FeatherStorage

/// S3 storage service implementation
@dynamicMemberLookup
struct S3StorageService {

    let s3: S3

    public let config: ServiceConfig

    subscript<T>(
        dynamicMember keyPath: KeyPath<S3StorageServiceContext, T>
    ) -> T {
        let context = config.context as! S3StorageServiceContext
        return context[keyPath: keyPath]
    }

    init(
        s3: S3,
        config: ServiceConfig
    ) {
        self.s3 = s3
        self.config = config
    }
}

private extension S3StorageService {

    var bucketName: String { self.bucket.name! }
}

extension S3StorageService: StorageService {

    public var availableSpace: UInt64 {
        .max
    }

    public func upload(
        key: String,
        buffer: ByteBuffer
    ) async throws {
        do {
            let customS3 = s3.with(timeout: self.timeout)
            _ = try await customS3.putObject(
                .init(
                    body: .byteBuffer(buffer),
                    bucket: bucketName,
                    key: key
                ),
                logger: logger,
                on: self.eventLoopGroup.any()
            )
        }
        catch {
            throw StorageServiceError.unknown(error)
        }
    }

    public func download(
        key: String,
        range: ClosedRange<UInt>?
    ) async throws -> ByteBuffer {
        let exists = await exists(key: key)
        guard exists else {
            throw StorageServiceError.invalidKey
        }
        do {
            let customS3 = s3.with(timeout: self.timeout)
            let byteRange = range.map {
                "bytes=\($0.lowerBound)-\($0.upperBound)"
            }
            let response = try await customS3.getObject(
                .init(
                    bucket: bucketName,
                    key: key,
                    range: byteRange
                ),
                logger: logger,
                on: self.eventLoopGroup.any()
            )
            guard let buffer = response.body?.asByteBuffer() else {
                throw StorageServiceError.invalidBuffer
            }
            return buffer
        }
        catch let error as StorageServiceError {
            throw error
        }
        catch {
            throw StorageServiceError.unknown(error)
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
                logger: logger,
                on: self.eventLoopGroup.any()
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
                logger: logger,
                on: self.eventLoopGroup.any()
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
            throw StorageServiceError.invalidKey
        }
        do {
            _ = try await s3.copyObject(
                .init(
                    bucket: bucketName,
                    copySource: bucketName + "/" + source,
                    key: destination
                ),
                logger: logger,
                on: self.eventLoopGroup.any()
            )
        }
        catch {
            throw StorageServiceError.unknown(error)
        }
    }

    public func list(key: String?) async throws -> [String] {
        do {
            let list = try await s3.listObjects(
                .init(
                    bucket: bucketName,
                    prefix: key
                ),
                logger: logger,
                on: self.eventLoopGroup.any()
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
            throw StorageServiceError.unknown(error)
        }
    }

    public func delete(key: String) async throws {
        do {
            _ = try await s3.deleteObject(
                .init(
                    bucket: bucketName,
                    key: key
                ),
                logger: logger,
                on: self.eventLoopGroup.any()
            )
        }
        catch {
            throw StorageServiceError.unknown(error)
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
                logger: logger,
                on: self.eventLoopGroup.any()
            )
        }
        catch {
            throw StorageServiceError.unknown(error)
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
                logger: logger,
                on: self.eventLoopGroup.any()
            )
            guard let uploadId = res.uploadId else {
                throw StorageServiceError.invalidMultipartId
            }
            return uploadId
        }
        catch let error as StorageServiceError {
            throw error
        }
        catch {
            throw StorageServiceError.unknown(error)
        }
    }

    public func upload(
        multipartId: String,
        key: String,
        number: Int,
        buffer: ByteBuffer
    ) async throws -> Multipart.Chunk {
        do {
            let customS3 = s3.with(timeout: self.timeout)
            let res = try await customS3.uploadPart(
                .init(
                    body: .byteBuffer(buffer),
                    bucket: bucketName,
                    key: key,
                    partNumber: number,
                    uploadId: multipartId
                ),
                logger: logger,
                on: self.eventLoopGroup.any()
            )
            guard let etag = res.eTag else {
                throw StorageServiceError.invalidMultipartChunk
            }
            return .init(chunkId: etag, number: number)
        }
        catch {
            throw StorageServiceError.unknown(error)
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
                logger: logger,
                on: self.eventLoopGroup.any()
            )
        }
        catch {
            throw StorageServiceError.unknown(error)
        }
    }

    public func finish(
        multipartId: String,
        key: String,
        chunks: [Multipart.Chunk]
    ) async throws {
        do {
            let parts = chunks.map { chunk -> S3.CompletedPart in
                .init(
                    eTag: chunk.chunkId,
                    partNumber: chunk.number
                )
            }
            let customS3 = s3.with(timeout: self.timeout)
            _ = try await customS3.completeMultipartUpload(
                .init(
                    bucket: bucketName,
                    key: key,
                    multipartUpload: .init(parts: parts),
                    uploadId: multipartId
                ),
                logger: logger,
                on: self.eventLoopGroup.any()
            )
        }
        catch {
            throw StorageServiceError.unknown(error)
        }
    }
}
