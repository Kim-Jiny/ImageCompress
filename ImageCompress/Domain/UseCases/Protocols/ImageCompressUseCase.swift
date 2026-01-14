//
//  ImageCompressUseCase.swift
//  ImageCompress
//
//  Created by Clean Architecture Refactoring
//

import Foundation

/// 이미지 압축 UseCase 인터페이스
/// Domain Layer - 비즈니스 로직 정의
protocol ImageCompressUseCase {
    /// 이미지 품질 조절
    func adjustQuality(_ image: CompressedImage, quality: ImageQuality) -> Result<CompressedImage, ImageProcessingError>

    /// 이미지 크기 조절
    func resize(_ image: CompressedImage, targetSize: ImageSize) -> Result<CompressedImage, ImageProcessingError>

    /// 이미지 크기를 레벨로 조절 (0: 원본, 1: 75%, 2: 50%, 3: 25%)
    func resize(_ image: CompressedImage, level: Int) -> Result<CompressedImage, ImageProcessingError>
}
