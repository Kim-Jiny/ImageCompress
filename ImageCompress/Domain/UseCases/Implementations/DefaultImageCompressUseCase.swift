//
//  DefaultImageCompressUseCase.swift
//  ImageCompress
//
//  Created by Clean Architecture Refactoring
//

import Foundation

/// 이미지 압축 UseCase 기본 구현
/// Domain Layer - UIKit 무의존, Repository를 통해 처리
final class DefaultImageCompressUseCase: ImageCompressUseCase {

    // MARK: - Dependencies
    private let imageProcessingRepository: ImageProcessingRepository
    private let settingsRepository: SettingsRepository

    // MARK: - Init
    init(
        imageProcessingRepository: ImageProcessingRepository,
        settingsRepository: SettingsRepository
    ) {
        self.imageProcessingRepository = imageProcessingRepository
        self.settingsRepository = settingsRepository
    }

    // MARK: - ImageCompressUseCase
    func adjustQuality(_ image: CompressedImage, quality: ImageQuality) -> Result<CompressedImage, ImageProcessingError> {
        let format = settingsRepository.imageFormat

        let result = imageProcessingRepository.compress(
            image.originalData,
            quality: quality,
            size: image.size,
            format: format
        )

        switch result {
        case .success(let data):
            var updated = image
            updated.compressedData = data
            updated.quality = quality
            updated.format = format
            return .success(updated)
        case .failure(let error):
            return .failure(error)
        }
    }

    func resize(_ image: CompressedImage, targetSize: ImageSize) -> Result<CompressedImage, ImageProcessingError> {
        let format = settingsRepository.imageFormat

        let result = imageProcessingRepository.compress(
            image.originalData,
            quality: image.quality,
            size: targetSize,
            format: format
        )

        switch result {
        case .success(let data):
            var updated = image
            updated.compressedData = data
            updated.size = targetSize
            updated.format = format
            return .success(updated)
        case .failure(let error):
            return .failure(error)
        }
    }

    func resize(_ image: CompressedImage, level: Int) -> Result<CompressedImage, ImageProcessingError> {
        // 원본 이미지에서 크기 추출
        guard let originalSize = imageProcessingRepository.getImageSize(from: image.originalData) else {
            return .failure(.invalidImageData)
        }

        let scaleFactor = ImageSize.scaleFactor(for: level)
        let targetSize = originalSize.scaled(by: scaleFactor)

        return resize(image, targetSize: targetSize)
    }
}
