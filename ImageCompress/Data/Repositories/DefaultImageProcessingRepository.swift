//
//  DefaultImageProcessingRepository.swift
//  ImageCompress
//
//  Created by Clean Architecture Refactoring
//

import UIKit
import CoreGraphics

/// 이미지 처리 Repository 구현체
/// Data Layer - UIKit을 사용한 실제 이미지 처리
final class DefaultImageProcessingRepository: ImageProcessingRepository {

    // MARK: - ImageProcessingRepository
    func compress(
        _ imageData: Data,
        quality: ImageQuality,
        size: ImageSize,
        format: ImageFormat
    ) -> Result<Data, ImageProcessingError> {

        guard let originalImage = UIImage(data: imageData) else {
            return .failure(.invalidImageData)
        }

        // 원본 크기와 동일하고 품질이 1.0이면 원본 반환
        let originalSize = originalImage.size
        if size.width == Double(originalSize.width) &&
           size.height == Double(originalSize.height) &&
           quality == .original {
            return .success(imageData)
        }

        let targetSize = CGSize(width: size.width, height: size.height)

        // 이미지 리사이즈
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1)
        originalImage.draw(in: CGRect(origin: .zero, size: targetSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard let image = resizedImage else {
            return .failure(.resizeFailed)
        }

        // 포맷에 따라 압축
        let compressionQuality = quality == .original ? 0.8 : CGFloat(quality.compressionQuality)

        let resultData: Data?
        switch format {
        case .jpeg:
            resultData = image.jpegData(compressionQuality: compressionQuality)
        case .png:
            // PNG의 경우 먼저 JPEG로 압축 후 PNG로 변환
            if let jpegData = image.jpegData(compressionQuality: compressionQuality),
               let jpegImage = UIImage(data: jpegData) {
                resultData = jpegImage.pngData()
            } else {
                resultData = nil
            }
        }

        guard let data = resultData else {
            return .failure(.compressionFailed)
        }

        return .success(data)
    }

    func getImageSize(from data: Data) -> ImageSize? {
        guard let image = UIImage(data: data) else { return nil }
        return ImageSize(width: Double(image.size.width), height: Double(image.size.height))
    }

    func removeMetadata(from data: Data) -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let type = CGImageSourceGetType(source) else { return nil }

        let outputData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(outputData as CFMutableData, type, 1, nil) else { return nil }

        CGImageDestinationAddImageFromSource(destination, source, 0, nil)
        guard CGImageDestinationFinalize(destination) else { return nil }

        return outputData as Data
    }
}
