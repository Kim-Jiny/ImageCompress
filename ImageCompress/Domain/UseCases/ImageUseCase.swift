//
//  ImageUseCase.swift
//  ImageCompress
//
//  Created by 김미진 on 12/26/24.
//

import Foundation
import UIKit

protocol ImageUseCase {
    func renameImage(_ imageWithMetadata: ImageWithMetadata, newName: String) -> ImageWithMetadata?
    func updateImageDateTime(_ imageWithMetadata: ImageWithMetadata, newDateTime: Date) -> ImageWithMetadata?
    func adjustImageQuality(_ imageWithMetadata: ImageWithMetadata, quality: CGFloat) -> ImageWithMetadata?
    func resizeImage(_ imageWithMetadata: ImageWithMetadata, targetSize: CGSize) -> ImageWithMetadata?
    func updateImageLocation(_ imageWithMetadata: ImageWithMetadata, latitude: Double, longitude: Double) -> ImageWithMetadata?
    
    func saveImage(_ imageWithMetadata: ImageWithMetadata, completion: @escaping (Result<Bool, Error>) -> Void)
}

class ImageUseCaseImpl: ImageUseCase {
    func renameImage(_ imageWithMetadata: ImageWithMetadata, newName: String) -> ImageWithMetadata? {
        var updatedMetadata = imageWithMetadata.metaData
        updatedMetadata["FileName"] = newName

        guard let updatedImageData = UIImage(data: imageWithMetadata.imgData)?.jpegData(compressionQuality: 1) else { return nil }
        
        return ImageWithMetadata(imgName: newName, imgData: updatedImageData, metaData: updatedMetadata)
    }
    
    
    func updateImageDateTime(_ imageWithMetadata: ImageWithMetadata, newDateTime: Date) -> ImageWithMetadata? {
        var updatedMetadata = imageWithMetadata.metaData
        updatedMetadata[kCGImagePropertyExifDateTimeOriginal as String] = newDateTime

        guard let updatedImageData = UIImage(data: imageWithMetadata.imgData)?.jpegData(compressionQuality: 1) else { return nil }
        
        return ImageWithMetadata(imgName: imageWithMetadata.imgName, imgData: updatedImageData, metaData: updatedMetadata)
    }
    
    func adjustImageQuality(_ imageWithMetadata: ImageWithMetadata, quality: CGFloat) -> ImageWithMetadata? {
        guard quality >= 0 && quality <= 1 else { return nil }
        
        guard let updatedImageData = UIImage(data: imageWithMetadata.imgData)?.jpegData(compressionQuality: quality) else { return nil }
        
        return ImageWithMetadata(imgName: imageWithMetadata.imgName, imgData: updatedImageData, metaData: imageWithMetadata.metaData)
    }
    
    
    func resizeImage(_ imageWithMetadata: ImageWithMetadata, targetSize: CGSize) -> ImageWithMetadata? {
        guard let originalImage = UIImage(data: imageWithMetadata.imgData) else { return nil }
        
        let newImage = UIGraphicsImageRenderer(size: targetSize).image { _ in
            originalImage.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        
        guard let resizedImageData = newImage.jpegData(compressionQuality: 1) else { return nil }
        
        return ImageWithMetadata(imgName: imageWithMetadata.imgName, imgData: resizedImageData, metaData: imageWithMetadata.metaData)
    }
    
    
    func updateImageLocation(_ imageWithMetadata: ImageWithMetadata, latitude: Double, longitude: Double) -> ImageWithMetadata? {
        var updatedMetadata = imageWithMetadata.metaData
        let locationData: [String: Any] = ["Latitude": latitude, "Longitude": longitude]
        updatedMetadata[kCGImagePropertyGPSDictionary as String] = locationData

        guard let updatedImageData = UIImage(data: imageWithMetadata.imgData)?.jpegData(compressionQuality: 1) else { return nil }
        
        return ImageWithMetadata(imgName: imageWithMetadata.imgName, imgData: updatedImageData, metaData: updatedMetadata)
    }
    
    func saveImage(_ imageWithMetadata: ImageWithMetadata, completion: @escaping (Result<Bool, Error>) -> Void) {
        print("이미지 저장 시도")

        // 수정된 메타데이터를 포함하여 이미지를 저장
        guard let imageData = UIImage(data: imageWithMetadata.imgData)?.jpegData(compressionQuality: 1) else {
            completion(.failure(NSError(domain: "ImageSaveError", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image data"])))
            return
        }

        // 이미지와 수정된 메타데이터를 포함하여 저장
        guard let updatedImage = UIImage(data: imageData)?.applyingExifMetadata(imageWithMetadata.metaData) else {
            completion(.failure(NSError(domain: "ImageSaveError", code: 1002, userInfo: [NSLocalizedDescriptionKey: "Failed to apply metadata"])))
            return
        }

        // 이미지를 저장하려면 UIImageWriteToSavedPhotosAlbum에 메서드가 필요함
        UIImageWriteToSavedPhotosAlbum(updatedImage, self, #selector(imageSaveCompleted(_:didFinishSavingWithError:contextInfo:)), nil)

        // 완료 콜백 호출
        completion(.success(true))
    }
    
    @objc private func imageSaveCompleted(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            print("이미지 저장 실패: \(error.localizedDescription)")
        } else {
            print("이미지가 성공적으로 저장되었습니다.")
        }
    }
    
}
