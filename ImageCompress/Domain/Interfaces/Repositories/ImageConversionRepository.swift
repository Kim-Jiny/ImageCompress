//
//  ImageConversionRepository.swift
//  ImageCompress
//
//  Created by Clean Architecture
//

import Foundation

/// 이미지 변환 Repository 인터페이스
/// Domain Layer - 이미지 포맷 변환 추상화
protocol ImageConversionRepository {
    /// HEIC 데이터인지 확인
    func isHEIC(data: Data) -> Bool

    /// 이미지 데이터를 지정된 포맷으로 변환
    func convert(
        imageData: Data,
        to format: ImageFormat,
        quality: Double
    ) -> Result<Data, Error>

    /// 이미지를 사진 라이브러리에 저장
    func saveToPhotoLibrary(
        imageData: Data,
        completion: @escaping (Result<Void, Error>) -> Void
    )
}

/// 이미지 변환 에러
enum ImageConversionError: LocalizedError {
    case invalidImageData
    case conversionFailed
    case unsupportedFormat
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "유효하지 않은 이미지 데이터입니다."
        case .conversionFailed:
            return "이미지 변환에 실패했습니다."
        case .unsupportedFormat:
            return "지원하지 않는 이미지 포맷입니다."
        case .saveFailed:
            return "이미지 저장에 실패했습니다."
        }
    }
}
