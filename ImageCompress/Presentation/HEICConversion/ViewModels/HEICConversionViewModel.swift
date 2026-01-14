//
//  HEICConversionViewModel.swift
//  ImageCompress
//
//  Created by Clean Architecture
//

import Foundation
import UIKit

// MARK: - Input Protocol
protocol HEICConversionViewModelInput {
    func viewDidLoad()
    func selectImages(_ sender: UIViewController)
    func removeImage(at index: Int)
    func removeAllImages()
    func setOutputFormat(_ format: ImageFormat)
    func setQuality(_ quality: ImageQuality)
    func convertAll()
    func saveAll()
}

// MARK: - Output Protocol
protocol HEICConversionViewModelOutput {
    var selectedImages: Observable<[SelectedImage]> { get }
    var conversionResults: Observable<[ConversionResult]> { get }
    var conversionProgress: Observable<ConversionProgress?> { get }
    var isConverting: Observable<Bool> { get }
    var isSaving: Observable<Bool> { get }
    var error: Observable<String?> { get }
    var savedCount: Observable<Int?> { get }
    var outputFormat: Observable<ImageFormat> { get }
    var quality: Observable<ImageQuality> { get }
    var totalOriginalSize: Int { get }
    var totalConvertedSize: Int { get }
}

/// HEICConversionViewModel 타입
typealias HEICConversionViewModel = HEICConversionViewModelInput & HEICConversionViewModelOutput

// MARK: - Implementation

final class DefaultHEICConversionViewModel: HEICConversionViewModel {

    // MARK: - Dependencies
    private let heicConversionUseCase: HEICConversionUseCase
    private let permissionUseCase: PermissionUseCase
    private var imagePickerCoordinator: MultiImagePickerCoordinator?

    // MARK: - Output
    let selectedImages: Observable<[SelectedImage]> = Observable([])
    let conversionResults: Observable<[ConversionResult]> = Observable([])
    let conversionProgress: Observable<ConversionProgress?> = Observable(nil)
    let isConverting: Observable<Bool> = Observable(false)
    let isSaving: Observable<Bool> = Observable(false)
    let error: Observable<String?> = Observable(nil)
    let savedCount: Observable<Int?> = Observable(nil)
    let outputFormat: Observable<ImageFormat> = Observable(.jpeg)
    let quality: Observable<ImageQuality> = Observable(.high)

    var totalOriginalSize: Int {
        selectedImages.value.reduce(0) { $0 + $1.originalSize }
    }

    var totalConvertedSize: Int {
        conversionResults.value.reduce(0) { $0 + $1.convertedSize }
    }

    // MARK: - Init
    init(
        heicConversionUseCase: HEICConversionUseCase,
        permissionUseCase: PermissionUseCase
    ) {
        self.heicConversionUseCase = heicConversionUseCase
        self.permissionUseCase = permissionUseCase
    }

    // MARK: - Input
    func viewDidLoad() {
        // 초기화
    }

    func selectImages(_ sender: UIViewController) {
        imagePickerCoordinator = MultiImagePickerCoordinator(
            presenter: sender,
            maxSelection: 50,
            filterHEICOnly: false
        )
        imagePickerCoordinator?.delegate = self
        imagePickerCoordinator?.presentPicker()
    }

    func removeImage(at index: Int) {
        guard index >= 0 && index < selectedImages.value.count else { return }
        var images = selectedImages.value
        images.remove(at: index)
        selectedImages.value = images

        // 변환 결과도 함께 제거
        if index < conversionResults.value.count {
            var results = conversionResults.value
            results.remove(at: index)
            conversionResults.value = results
        }
    }

    func removeAllImages() {
        selectedImages.value = []
        conversionResults.value = []
    }

    func setOutputFormat(_ format: ImageFormat) {
        outputFormat.value = format
        // 포맷 변경 시 기존 변환 결과 초기화
        conversionResults.value = []
    }

    func setQuality(_ quality: ImageQuality) {
        self.quality.value = quality
        // 품질 변경 시 기존 변환 결과 초기화
        conversionResults.value = []
    }

    func convertAll() {
        guard !selectedImages.value.isEmpty else { return }

        isConverting.value = true
        conversionResults.value = []

        let images = selectedImages.value.map { ($0.data, $0.name) }

        heicConversionUseCase.convertBatch(
            images: images,
            to: outputFormat.value,
            quality: quality.value,
            progress: { [weak self] progress in
                self?.conversionProgress.value = progress
            },
            completion: { [weak self] result in
                self?.isConverting.value = false
                self?.conversionProgress.value = nil

                switch result {
                case .success(let results):
                    self?.conversionResults.value = results
                case .failure(let error):
                    self?.error.value = error.localizedDescription
                }
            }
        )
    }

    func saveAll() {
        guard !conversionResults.value.isEmpty else { return }

        permissionUseCase.checkPhotoLibraryAddOnlyPermission { [weak self] hasPermission in
            guard hasPermission else {
                self?.error.value = "사진 저장 권한이 필요합니다."
                return
            }

            self?.performSave()
        }
    }

    private func performSave() {
        isSaving.value = true

        heicConversionUseCase.saveConvertedImages(results: conversionResults.value) { [weak self] result in
            self?.isSaving.value = false

            switch result {
            case .success(let count):
                self?.savedCount.value = count
            case .failure(let error):
                self?.error.value = error.localizedDescription
            }
        }
    }
}

// MARK: - MultiImagePickerDelegate
extension DefaultHEICConversionViewModel: MultiImagePickerDelegate {

    func didSelectImages(_ images: [SelectedImage]) {
        selectedImages.value = images
        conversionResults.value = []
    }

    func didCancelMultiSelection() {
        // 취소 시 아무 동작 없음
    }

    func didUpdateLoadingProgress(current: Int, total: Int) {
        // 이미지 로딩 진행 상태 (필요시 UI 업데이트)
    }
}
