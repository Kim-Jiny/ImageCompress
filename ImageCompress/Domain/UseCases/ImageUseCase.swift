//
//  ImageUseCase.swift
//  ImageCompress
//
//  Created by 김미진 on 12/26/24.
//  DEPRECATED: Use ImageCompressUseCase and ImageSaveUseCase instead
//

import Foundation
import UIKit
import UniformTypeIdentifiers

/// Legacy UseCase - ImageCompressUseCase와 ImageSaveUseCase로 대체됨
/// - Note: 새 코드에서는 ImageCompressUseCase와 ImageSaveUseCase를 사용하세요
@available(*, deprecated, message: "Use ImageCompressUseCase and ImageSaveUseCase instead")
protocol ImageUseCase {
    func adjustImageQuality(_ imageWithMetadata: ImageWithMetadata, quality: CGFloat) -> ImageWithMetadata?
    func resizeImage(_ imageWithMetadata: ImageWithMetadata, targetSize: CGSize) -> ImageWithMetadata?
    func saveImage(_ imageWithMetadata: ImageWithMetadata, completion: @escaping (Result<Bool, Error>) -> Void)
}

/// Legacy UseCase 구현체 - DefaultImageCompressUseCase와 DefaultImageSaveUseCase로 대체됨
@available(*, deprecated, message: "Use DefaultImageCompressUseCase and DefaultImageSaveUseCase instead")
class ImageUseCaseImpl: ImageUseCase {
    
    func adjustImageQuality(_ imageWithMetadata: ImageWithMetadata, quality: CGFloat) -> ImageWithMetadata? {
        guard quality >= 0 && quality <= 1 else { return nil }
        
        var data = imageWithMetadata
        data.imgQuality = quality
        return resizeImage(data, targetSize: data.imgSize)
    }
    
    
    func resizeImage(_ imageWithMetadata: ImageWithMetadata, targetSize: CGSize) -> ImageWithMetadata? {
        guard let originalImage = UIImage(data: imageWithMetadata.originImgData) else { return nil }
        if targetSize == UIImage(data:imageWithMetadata.originImgData)?.size && imageWithMetadata.imgQuality == 1 {
            var data = imageWithMetadata
            data.imgData = data.originImgData
            return data
        }
        // 현재 이미지 크기
//        let originalSize = originalImage.size
//        
//        // 가로 및 세로 비율 계산
        let widthRatio = targetSize.width / originalImage.size.width
        let heightRatio = targetSize.height / originalImage.size.height
//
//        // 최소 비율로 이미지 비율 유지
        let scaleFactor = min(widthRatio, heightRatio)
//
//        // 새로운 크기 계산
//        let newSize = CGSize(width: originalSize.width * scaleFactor,
//                             height: originalSize.height * scaleFactor)
//        
        // 이미지 크기 조정
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1)
        originalImage.draw(in: CGRect(origin: .zero, size: targetSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        print("img quality \(imageWithMetadata.imgQuality)")
        if let type: String = UserDefaultsManager.shared.getData(forKey: "imageExtensionType"), type == "png" {
            guard let jpegImageData = resizedImage?.jpegData(compressionQuality: imageWithMetadata.imgQuality == 1 ? 0.8 : imageWithMetadata.imgQuality) else { return nil }
            
            guard let jpegImage = UIImage(data: jpegImageData),let resizedImageData = jpegImage.pngData() else { return nil }
            return ImageWithMetadata(imgName: imageWithMetadata.imgName, originImgData: imageWithMetadata.originImgData, imgData: resizedImageData, metaData: imageWithMetadata.metaData, asset: imageWithMetadata.asset, imgSize: targetSize, imgQuality: imageWithMetadata.imgQuality)
        }else {
            guard let resizedImageData = resizedImage?.jpegData(compressionQuality: imageWithMetadata.imgQuality == 1 ? 0.8 : imageWithMetadata.imgQuality) else { return nil }
            
            return ImageWithMetadata(imgName: imageWithMetadata.imgName, originImgData: imageWithMetadata.originImgData, imgData: resizedImageData, metaData: imageWithMetadata.metaData, asset: imageWithMetadata.asset, imgSize: targetSize, imgQuality: imageWithMetadata.imgQuality)
        }
    }
    
    
    
    func saveImage(_ imageWithMetadata: ImageWithMetadata, completion: @escaping (Result<Bool, Error>) -> Void) {
        print("이미지 저장 시도")

        // 수정된 메타데이터를 포함하여 이미지를 저장
        guard let removeMetaImg = removeMetadata(from: imageWithMetadata.imgData), let imageData = UIImage(data: removeMetaImg) else {
            completion(.failure(NSError(domain: "ImageSaveError", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image data"])))
            return
        }

        // 완료 콜백 호출
        UIImageWriteToSavedPhotosAlbum(imageData, nil, nil, nil)
        completion(.success(true))
    }
    
    func removeMetadata(from imageData: Data) -> Data? {
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let type = CGImageSourceGetType(source) else { return nil }
        
        let outputData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(outputData as CFMutableData, type, 1, nil) else { return nil }
        
        CGImageDestinationAddImageFromSource(destination, source, 0, nil)
        guard CGImageDestinationFinalize(destination) else { return nil }
        
        return outputData as Data
    }
    
    @objc private func imageSaveCompleted(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            print("이미지 저장 실패: \(error.localizedDescription)")
        } else {
            print("이미지가 성공적으로 저장되었습니다.")
        }
    }
    
    func applyMetadataToImage(imageData: Data, metadata: [String: Any]) -> UIImage? {
        // CGImageSource 생성
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil) else {
            print("Failed to create CGImageSource")
            return nil
        }

        // 메타데이터 수정
        guard let mutableMetadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
            print("Failed to copy image properties")
            return nil
        }

        var updatedMetadata = mutableMetadata
        for (key, value) in metadata {
            updatedMetadata[key] = value
        }

        // CGImageDestination 생성
        let outputData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(outputData as CFMutableData, UTType.jpeg.identifier as CFString, 1, nil) else {
            print("Failed to create CGImageDestination")
            return nil
        }

        // 수정된 메타데이터를 사용하여 이미지 생성
        CGImageDestinationAddImageFromSource(destination, source, 0, updatedMetadata as CFDictionary)

        // 이미지 저장
        guard CGImageDestinationFinalize(destination) else {
            print("Failed to finalize image destination")
            return nil
        }
        print("updatedMetadata")
        print(updatedMetadata)
        // UIImage로 변환
        return UIImage(data: outputData as Data)
    }
}
