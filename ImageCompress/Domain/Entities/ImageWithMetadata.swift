//
//  ImageWithMetadata.swift
//  ImageCompress
//
//  Created by 김미진 on 12/26/24.
//  DEPRECATED: Use CompressedImage instead
//

import Foundation
import Photos

/// Legacy Entity - CompressedImage로 대체됨
/// - Note: 새 코드에서는 CompressedImage를 사용하세요
/// - Warning: 이 구조체는 Domain Layer에서 UIKit 타입(CGSize, CGFloat)을 사용하므로 클린 아키텍처 원칙에 위배됩니다.
@available(*, deprecated, message: "Use CompressedImage instead")
struct ImageWithMetadata {
    var imgName: String
    var originImgData: Data
    var imgData: Data
    var metaData: [String: Any]
    var asset: PHAsset?
    var imgSize: CGSize
    var imgQuality: CGFloat
}

// MARK: - Conversion Helpers

extension ImageWithMetadata {
    /// CompressedImage로 변환
    func toCompressedImage() -> CompressedImage {
        CompressedImage(
            name: imgName,
            originalData: originImgData,
            compressedData: imgData,
            metadata: ImageMetadata(creationDate: asset?.creationDate, properties: metaData),
            size: ImageSize(width: Double(imgSize.width), height: Double(imgSize.height)),
            quality: ImageQuality.from(cgFloat: imgQuality),
            format: .jpeg
        )
    }
}

extension CompressedImage {
    /// ImageWithMetadata로 변환 (Legacy 호환용)
    func toLegacyImageWithMetadata() -> ImageWithMetadata {
        ImageWithMetadata(
            imgName: name,
            originImgData: originalData,
            imgData: compressedData,
            metaData: metadata.properties,
            asset: nil,
            imgSize: CGSize(width: size.width, height: size.height),
            imgQuality: CGFloat(quality.rawValue)
        )
    }
}
