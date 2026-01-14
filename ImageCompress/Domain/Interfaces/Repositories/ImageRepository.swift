//
//  ImageRepository.swift
//  ImageCompress
//
//  Created by Clean Architecture Refactoring
//

import Foundation

/// 이미지 저장소 에러
enum ImageRepositoryError: Error {
    case saveFailed
    case permissionDenied
    case invalidData
}

/// 이미지 저장소 인터페이스
/// Domain Layer - 구현은 Data Layer에서
protocol ImageRepository {
    /// 이미지를 사진 라이브러리에 저장
    func saveToPhotoLibrary(_ image: CompressedImage, completion: @escaping (Result<Void, ImageRepositoryError>) -> Void)
}
