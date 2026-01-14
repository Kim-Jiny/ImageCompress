//
//  DefaultImageSaveUseCase.swift
//  ImageCompress
//
//  Created by Clean Architecture Refactoring
//

import Foundation

/// 이미지 저장 UseCase 기본 구현
/// Domain Layer - UIKit 무의존, Repository를 통해 처리
final class DefaultImageSaveUseCase: ImageSaveUseCase {

    // MARK: - Dependencies
    private let imageRepository: ImageRepository
    private let imageProcessingRepository: ImageProcessingRepository

    // MARK: - Init
    init(
        imageRepository: ImageRepository,
        imageProcessingRepository: ImageProcessingRepository
    ) {
        self.imageRepository = imageRepository
        self.imageProcessingRepository = imageProcessingRepository
    }

    // MARK: - ImageSaveUseCase
    func save(_ image: CompressedImage, completion: @escaping (Result<Void, ImageRepositoryError>) -> Void) {
        // 메타데이터 제거 후 저장
        guard let cleanedData = imageProcessingRepository.removeMetadata(from: image.compressedData) else {
            completion(.failure(.invalidData))
            return
        }

        var imageToSave = image
        imageToSave.compressedData = cleanedData

        imageRepository.saveToPhotoLibrary(imageToSave, completion: completion)
    }
}
