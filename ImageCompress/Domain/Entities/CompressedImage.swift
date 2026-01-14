//
//  CompressedImage.swift
//  ImageCompress
//
//  Created by Clean Architecture Refactoring
//

import Foundation

/// 이미지 메타데이터
/// Domain Layer - Pure Swift, UIKit 무의존
struct ImageMetadata {
    let creationDate: Date?
    let properties: [String: Any]

    init(creationDate: Date? = nil, properties: [String: Any] = [:]) {
        self.creationDate = creationDate
        self.properties = properties
    }
}

/// 압축된 이미지를 나타내는 Entity
/// Domain Layer - Pure Swift, UIKit 무의존 (PHAsset 제거)
struct CompressedImage {
    let id: UUID
    let name: String
    let originalData: Data
    var compressedData: Data
    var metadata: ImageMetadata
    var size: ImageSize
    var quality: ImageQuality
    var format: ImageFormat

    init(
        id: UUID = UUID(),
        name: String,
        originalData: Data,
        compressedData: Data,
        metadata: ImageMetadata = ImageMetadata(),
        size: ImageSize = .zero,
        quality: ImageQuality = .original,
        format: ImageFormat = .jpeg
    ) {
        self.id = id
        self.name = name
        self.originalData = originalData
        self.compressedData = compressedData
        self.metadata = metadata
        self.size = size
        self.quality = quality
        self.format = format
    }

    /// 원본 데이터 크기 (바이트)
    var originalDataSize: Int {
        originalData.count
    }

    /// 압축된 데이터 크기 (바이트)
    var compressedDataSize: Int {
        compressedData.count
    }

    /// 압축률 (0.0 ~ 1.0, 낮을수록 많이 압축됨)
    var compressionRatio: Double {
        guard originalDataSize > 0 else { return 1.0 }
        return Double(compressedDataSize) / Double(originalDataSize)
    }

    /// 사람이 읽기 쉬운 파일 크기 문자열
    var formattedOriginalSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(originalDataSize), countStyle: .file)
    }

    /// 사람이 읽기 쉬운 압축된 파일 크기 문자열
    var formattedCompressedSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(compressedDataSize), countStyle: .file)
    }
}
