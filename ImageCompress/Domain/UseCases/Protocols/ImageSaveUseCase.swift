//
//  ImageSaveUseCase.swift
//  ImageCompress
//
//  Created by Clean Architecture Refactoring
//

import Foundation

/// 이미지 저장 UseCase 인터페이스
/// Domain Layer - 비즈니스 로직 정의
protocol ImageSaveUseCase {
    /// 이미지를 사진 라이브러리에 저장
    func save(_ image: CompressedImage, completion: @escaping (Result<Void, ImageRepositoryError>) -> Void)
}
