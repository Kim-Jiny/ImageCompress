//
//  ImageProcessingRepository.swift
//  ImageCompress
//
//  Created by Clean Architecture Refactoring
//

import Foundation

/// 이미지 처리 에러
enum ImageProcessingError: Error {
    case invalidImageData
    case compressionFailed
    case resizeFailed
    case metadataRemovalFailed

    var localizedDescription: String {
        switch self {
        case .invalidImageData:
            return "Invalid image data"
        case .compressionFailed:
            return "Image compression failed"
        case .resizeFailed:
            return "Image resize failed"
        case .metadataRemovalFailed:
            return "Metadata removal failed"
        }
    }
}

/// 이미지 처리 인터페이스
/// Domain Layer - UIKit 처리는 Data Layer 구현체에서
protocol ImageProcessingRepository {
    /// 이미지 압축 (품질 조절)
    func compress(
        _ imageData: Data,
        quality: ImageQuality,
        size: ImageSize,
        format: ImageFormat
    ) -> Result<Data, ImageProcessingError>

    /// 이미지 데이터에서 크기 추출
    func getImageSize(from data: Data) -> ImageSize?

    /// 메타데이터 제거
    func removeMetadata(from data: Data) -> Data?
}
