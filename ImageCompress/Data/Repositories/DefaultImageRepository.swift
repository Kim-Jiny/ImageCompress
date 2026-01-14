//
//  DefaultImageRepository.swift
//  ImageCompress
//
//  Created by Clean Architecture Refactoring
//

import UIKit
import Photos

/// 이미지 저장소 Repository 구현체
/// Data Layer - Photos Framework를 사용한 실제 이미지 저장
final class DefaultImageRepository: ImageRepository {

    // MARK: - ImageRepository
    func saveToPhotoLibrary(_ image: CompressedImage, completion: @escaping (Result<Void, ImageRepositoryError>) -> Void) {
        guard let uiImage = UIImage(data: image.compressedData) else {
            completion(.failure(.invalidData))
            return
        }

        UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
        completion(.success(()))
    }
}
