//
//  HEICConversionUseCase.swift
//  ImageCompress
//
//  Created by Clean Architecture
//

import Foundation

/// HEIC 변환 결과
struct ConversionResult {
    let originalName: String
    let convertedData: Data
    let originalSize: Int
    let convertedSize: Int

    var compressionRatio: Double {
        guard originalSize > 0 else { return 0 }
        return Double(convertedSize) / Double(originalSize)
    }

    var savedPercentage: Double {
        return (1 - compressionRatio) * 100
    }
}

/// HEIC 일괄 변환 진행 상태
struct ConversionProgress {
    let current: Int
    let total: Int
    let currentFileName: String

    var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(current) / Double(total) * 100
    }
}

/// HEIC 변환 UseCase 프로토콜
/// Domain Layer - HEIC를 JPEG/PNG로 변환하는 비즈니스 로직
protocol HEICConversionUseCase {
    /// 단일 HEIC 이미지를 변환
    func convert(
        imageData: Data,
        fileName: String,
        to format: ImageFormat,
        quality: ImageQuality
    ) -> Result<ConversionResult, Error>

    /// 여러 HEIC 이미지를 일괄 변환
    func convertBatch(
        images: [(data: Data, name: String)],
        to format: ImageFormat,
        quality: ImageQuality,
        progress: @escaping (ConversionProgress) -> Void,
        completion: @escaping (Result<[ConversionResult], Error>) -> Void
    )

    /// 변환된 이미지들을 저장
    func saveConvertedImages(
        results: [ConversionResult],
        completion: @escaping (Result<Int, Error>) -> Void
    )
}
