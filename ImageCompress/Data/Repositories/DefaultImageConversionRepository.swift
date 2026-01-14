//
//  DefaultImageConversionRepository.swift
//  ImageCompress
//
//  Created by Clean Architecture
//

import UIKit
import Photos
import UniformTypeIdentifiers

/// 이미지 변환 Repository 구현체
/// Data Layer - UIKit을 사용한 실제 이미지 변환 처리
final class DefaultImageConversionRepository: ImageConversionRepository {

    // MARK: - ImageConversionRepository
    func isHEIC(data: Data) -> Bool {
        // HEIC 파일 시그니처 확인
        guard data.count >= 12 else { return false }

        // ftyp box 확인
        let ftypRange = data[4..<8]
        let ftypString = String(data: ftypRange, encoding: .ascii)

        if ftypString == "ftyp" {
            let brandRange = data[8..<12]
            let brandString = String(data: brandRange, encoding: .ascii)
            return brandString == "heic" || brandString == "heix" || brandString == "mif1"
        }

        // CGImageSource로 타입 확인
        if let source = CGImageSourceCreateWithData(data as CFData, nil),
           let type = CGImageSourceGetType(source) as String? {
            return type == "public.heic" || type == "public.heif"
        }

        return false
    }

    func convert(
        imageData: Data,
        to format: ImageFormat,
        quality: Double
    ) -> Result<Data, Error> {
        guard let image = UIImage(data: imageData) else {
            return .failure(ImageConversionError.invalidImageData)
        }

        let convertedData: Data?

        switch format {
        case .jpeg:
            convertedData = image.jpegData(compressionQuality: quality)
        case .png:
            convertedData = image.pngData()
        }

        guard let data = convertedData else {
            return .failure(ImageConversionError.conversionFailed)
        }

        return .success(data)
    }

    func saveToPhotoLibrary(
        imageData: Data,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let image = UIImage(data: imageData) else {
            completion(.failure(ImageConversionError.invalidImageData))
            return
        }

        PHPhotoLibrary.shared().performChanges {
            PHAssetCreationRequest.creationRequestForAsset(from: image)
        } completionHandler: { success, error in
            DispatchQueue.main.async {
                if success {
                    completion(.success(()))
                } else {
                    completion(.failure(error ?? ImageConversionError.saveFailed))
                }
            }
        }
    }
}
