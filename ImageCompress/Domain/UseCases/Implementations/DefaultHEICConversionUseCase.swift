//
//  DefaultHEICConversionUseCase.swift
//  ImageCompress
//
//  Created by Clean Architecture
//

import Foundation

/// HEIC 변환 UseCase 구현체
/// Domain Layer - HEIC → JPEG/PNG 변환 로직
final class DefaultHEICConversionUseCase: HEICConversionUseCase {

    // MARK: - Dependencies
    private let conversionRepository: ImageConversionRepository
    private let imageRepository: ImageRepository

    // MARK: - Init
    init(
        conversionRepository: ImageConversionRepository,
        imageRepository: ImageRepository
    ) {
        self.conversionRepository = conversionRepository
        self.imageRepository = imageRepository
    }

    // MARK: - HEICConversionUseCase
    func convert(
        imageData: Data,
        fileName: String,
        to format: ImageFormat,
        quality: ImageQuality
    ) -> Result<ConversionResult, Error> {
        let result = conversionRepository.convert(
            imageData: imageData,
            to: format,
            quality: quality.compressionQuality
        )

        switch result {
        case .success(let convertedData):
            let conversionResult = ConversionResult(
                originalName: fileName,
                convertedData: convertedData,
                originalSize: imageData.count,
                convertedSize: convertedData.count
            )
            return .success(conversionResult)

        case .failure(let error):
            return .failure(error)
        }
    }

    func convertBatch(
        images: [(data: Data, name: String)],
        to format: ImageFormat,
        quality: ImageQuality,
        progress: @escaping (ConversionProgress) -> Void,
        completion: @escaping (Result<[ConversionResult], Error>) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            var results: [ConversionResult] = []
            let total = images.count

            for (index, image) in images.enumerated() {
                // 진행 상태 업데이트
                let progressInfo = ConversionProgress(
                    current: index + 1,
                    total: total,
                    currentFileName: image.name
                )
                DispatchQueue.main.async {
                    progress(progressInfo)
                }

                // 변환 수행
                let result = self.convert(
                    imageData: image.data,
                    fileName: image.name,
                    to: format,
                    quality: quality
                )

                switch result {
                case .success(let conversionResult):
                    results.append(conversionResult)
                case .failure(let error):
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                    return
                }
            }

            DispatchQueue.main.async {
                completion(.success(results))
            }
        }
    }

    func saveConvertedImages(
        results: [ConversionResult],
        completion: @escaping (Result<Int, Error>) -> Void
    ) {
        var savedCount = 0
        let group = DispatchGroup()

        for result in results {
            group.enter()
            conversionRepository.saveToPhotoLibrary(imageData: result.convertedData) { saveResult in
                switch saveResult {
                case .success:
                    savedCount += 1
                case .failure:
                    break
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            if savedCount > 0 {
                completion(.success(savedCount))
            } else {
                completion(.failure(ImageConversionError.saveFailed))
            }
        }
    }
}
