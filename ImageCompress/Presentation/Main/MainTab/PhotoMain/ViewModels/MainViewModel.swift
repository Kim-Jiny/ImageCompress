//
//  MainViewModel.swift
//  ImageCompress
//
//  Created by 김미진 on 10/8/24.
//  Refactored for Clean Architecture
//

import Foundation
import UIKit

// MARK: - Actions (Coordinator에서 처리할 액션 정의)
struct MainViewModelActions {
    var onRequestImagePicker: (() -> Void)?
    var onShareImage: ((Data) -> Void)?
}

// MARK: - MainViewModel의 Input, Output 정의

/// Input 프로토콜: 뷰에서 호출되는 메서드들
protocol MainViewModelInput {
    func viewDidLoad()
    func openAppSettings()
    func checkPhotoLibraryOnlyAddPermission()
    func checkPhotoLibraryPermission()
    func loadLatestVersion(completion: @escaping (String?) -> Void)
    func openImagePicker(_ sender: UIViewController)
    func shareImage(_ sender: UIViewController)
    func formatImageDate(_ date: Date) -> String?
    func imageSave(completion: @escaping (Bool) -> Void)
    func changeImageQuality(level: Int)
    func changeImageSize(level: Int)

    // 새 API - ImagePickerDelegate에서 호출
    func selectImage(data: Data, name: String, metadata: [String: Any], creationDate: Date?)
    func cancelImageSelection()

    // 다중 이미지 API
    func selectCurrentImageAt(index: Int)
    func removeImageAt(index: Int)
}

/// Output 프로토콜: 뷰모델에서 뷰로 전달될 데이터들
protocol MainViewModelOutput {
    var error: Observable<String> { get }
    var photoLibraryPermission: Observable<Bool?> { get }
    var photoLibraryOnlyAddPermission: Observable<Bool?> { get }
    var selectedImg: Observable<ImageWithMetadata?> { get }
    var currentImage: Observable<CompressedImage?> { get }
    var needReset: Observable<Void?> { get }
    var isDownloadSuccess: Bool { get set }

    // 다중 이미지 지원
    var selectedImages: Observable<[CompressedImage]> { get }
    var currentImageIndex: Observable<Int> { get }
    var totalImageCount: Observable<Int> { get }
}

/// MainViewModel 타입: Input과 Output을 모두 결합한 타입
typealias MainViewModel = MainViewModelInput & MainViewModelOutput

// MARK: - MainViewModel 구현 (ViewModel)

final class DefaultMainViewModel: NSObject, MainViewModel {

    // MARK: - Dependencies (필수 의존성들)
    private let imageCompressUseCase: ImageCompressUseCase
    private let imageSaveUseCase: ImageSaveUseCase
    private let permissionUseCase: PermissionUseCase
    private let fetchAppVersionUseCase: FetchAppVersionUseCase
    private let imageProcessingRepository: ImageProcessingRepository
    private var actions: MainViewModelActions?
    private let mainQueue: DispatchQueueType

    // Legacy UseCase (기존 호환용)
    private var legacyImageUseCase: ImageUseCase?

    // ImagePicker 코디네이터
    private var imagePickerCoordinator: ImagePickerCoordinator?

    // MARK: - Output (출력 프로퍼티)
    let error: Observable<String> = Observable("")
    let photoLibraryPermission: Observable<Bool?> = Observable(nil)
    let photoLibraryOnlyAddPermission: Observable<Bool?> = Observable(nil)
    var selectedImg: Observable<ImageWithMetadata?> = Observable(nil)
    var currentImage: Observable<CompressedImage?> = Observable(nil)
    var needReset: Observable<Void?> = Observable(nil)
    var isDownloadSuccess: Bool = false

    // 다중 이미지 지원
    var selectedImages: Observable<[CompressedImage]> = Observable([])
    var currentImageIndex: Observable<Int> = Observable(0)
    var totalImageCount: Observable<Int> = Observable(0)

    // 다중 이미지 설정 (이미지 선택 개수 제한)
    private let maxImageSelection: Int = 20

    // MARK: - Init (새 클린 아키텍처용)
    init(
        imageCompressUseCase: ImageCompressUseCase,
        imageSaveUseCase: ImageSaveUseCase,
        permissionUseCase: PermissionUseCase,
        fetchAppVersionUseCase: FetchAppVersionUseCase,
        imageProcessingRepository: ImageProcessingRepository,
        actions: MainViewModelActions? = nil,
        mainQueue: DispatchQueueType = DispatchQueue.main
    ) {
        self.imageCompressUseCase = imageCompressUseCase
        self.imageSaveUseCase = imageSaveUseCase
        self.permissionUseCase = permissionUseCase
        self.fetchAppVersionUseCase = fetchAppVersionUseCase
        self.imageProcessingRepository = imageProcessingRepository
        self.actions = actions
        self.mainQueue = mainQueue
        super.init()
    }

    // MARK: - Legacy Init (기존 호환용)
    convenience init(
        imageUseCase: ImageUseCase,
        permissionUseCase: PermissionUseCase,
        fetchAppVersionUseCase: FetchAppVersionUseCase,
        actions: MainViewModelActions? = nil,
        mainQueue: DispatchQueueType = DispatchQueue.main
    ) {
        // 기본 Repository 생성
        let imageProcessingRepository = DefaultImageProcessingRepository()
        let settingsRepository = DefaultSettingsRepository()
        let imageRepository = DefaultImageRepository()

        self.init(
            imageCompressUseCase: DefaultImageCompressUseCase(
                imageProcessingRepository: imageProcessingRepository,
                settingsRepository: settingsRepository
            ),
            imageSaveUseCase: DefaultImageSaveUseCase(
                imageRepository: imageRepository,
                imageProcessingRepository: imageProcessingRepository
            ),
            permissionUseCase: permissionUseCase,
            fetchAppVersionUseCase: fetchAppVersionUseCase,
            imageProcessingRepository: imageProcessingRepository,
            actions: actions,
            mainQueue: mainQueue
        )
        self.legacyImageUseCase = imageUseCase
    }

    // MARK: - Private Methods
    private func load() {
        // 초기화 로직
    }

    private func handle(error: Error) {
        self.error.value = error.localizedDescription
    }

    // MARK: - Permissions Check

    func openAppSettings() {
        permissionUseCase.openAppSettings()
    }

    func checkPhotoLibraryPermission() {
        permissionUseCase.checkPhotoLibraryPermission { [weak self] isPermission in
            self?.photoLibraryPermission.value = isPermission
        }
    }

    func checkPhotoLibraryOnlyAddPermission() {
        permissionUseCase.checkPhotoLibraryAddOnlyPermission { [weak self] isPermission in
            self?.photoLibraryOnlyAddPermission.value = isPermission
        }
    }

    // MARK: - App Setting

    func loadLatestVersion(completion: @escaping (String?) -> Void) {
        fetchAppVersionUseCase.execute { latestVersion in
            completion(latestVersion)
        }
    }
}

// MARK: - Input (뷰 이벤트 처리)

extension DefaultMainViewModel {

    func viewDidLoad() {
        load()
    }

    // ImagePicker 열기 (다중 이미지 지원)
    func openImagePicker(_ sender: UIViewController) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.imagePickerCoordinator = ImagePickerCoordinator(
                presenter: sender,
                maxSelection: self.maxImageSelection
            )
            self.imagePickerCoordinator?.delegate = self
            self.imagePickerCoordinator?.presentPicker()
        }
    }

    // Image 공유하기
    func shareImage(_ sender: UIViewController) {
        // 새 API 우선
        if let image = currentImage.value {
            guard let uiImage = UIImage(data: image.compressedData) else {
                print("공유할 이미지가 없습니다.")
                return
            }

            let activityViewController = UIActivityViewController(activityItems: [uiImage], applicationActivities: nil)

            if let popoverController = activityViewController.popoverPresentationController {
                popoverController.sourceView = sender.view
            }

            sender.present(activityViewController, animated: true)
            return
        }

        // Legacy 지원
        guard let shareImg = selectedImg.value, let image = UIImage(data: shareImg.imgData) else {
            print("공유할 이미지가 없습니다.")
            return
        }

        let activityViewController = UIActivityViewController(activityItems: [image], applicationActivities: nil)

        if let popoverController = activityViewController.popoverPresentationController {
            popoverController.sourceView = sender.view
        }

        sender.present(activityViewController, animated: true)
    }

    func formatImageDate(_ date: Date) -> String? {
        let outputDateFormatter = DateFormatter()
        outputDateFormatter.dateStyle = .medium
        outputDateFormatter.timeStyle = .short
        return outputDateFormatter.string(from: date)
    }

    func imageSave(completion: @escaping (Bool) -> Void) {
        let images = selectedImages.value

        // 다중 이미지 저장
        if !images.isEmpty {
            saveMultipleImages(images, completion: completion)
            return
        }

        // 단일 이미지 저장 (하위 호환)
        if let image = currentImage.value {
            imageSaveUseCase.save(image) { result in
                switch result {
                case .success:
                    completion(true)
                case .failure(let error):
                    print(error)
                    completion(false)
                }
            }
            return
        }

        // Legacy 지원
        if let img = selectedImg.value {
            legacyImageUseCase?.saveImage(img) { result in
                switch result {
                case .success(let success):
                    completion(success)
                case .failure(let failure):
                    print(failure.localizedDescription)
                    completion(false)
                }
            }
        }
    }

    private func saveMultipleImages(_ images: [CompressedImage], completion: @escaping (Bool) -> Void) {
        let group = DispatchGroup()
        var allSuccess = true

        for image in images {
            group.enter()
            imageSaveUseCase.save(image) { result in
                defer { group.leave() }
                if case .failure(let error) = result {
                    print("이미지 저장 실패: \(error)")
                    allSuccess = false
                }
            }
        }

        group.notify(queue: .main) {
            completion(allSuccess)
        }
    }

    func changeImageQuality(level: Int) {
        let quality = ImageQuality.from(level: level)

        // 다중 이미지 처리
        if !selectedImages.value.isEmpty {
            var updatedImages: [CompressedImage] = []
            for image in selectedImages.value {
                if case .success(let updated) = imageCompressUseCase.adjustQuality(image, quality: quality) {
                    updatedImages.append(updated)
                } else {
                    updatedImages.append(image)
                }
            }
            selectedImages.value = updatedImages
            totalImageCount.value = updatedImages.count

            // 현재 선택된 이미지 업데이트
            let index = currentImageIndex.value
            if index < updatedImages.count {
                currentImage.value = updatedImages[index]
                syncToLegacy(from: updatedImages[index])
            }
            return
        }

        // 단일 이미지 (하위 호환)
        if let image = currentImage.value {
            let result = imageCompressUseCase.adjustQuality(image, quality: quality)
            if case .success(let updated) = result {
                currentImage.value = updated
                syncToLegacy(from: updated)
            }
            return
        }

        // Legacy 지원
        guard let data = selectedImg.value else { return }
        let qualities: [CGFloat] = [1, 0.5, 0.3, 0]
        guard level < qualities.count else { return }
        selectedImg.value = legacyImageUseCase?.adjustImageQuality(data, quality: qualities[level])
    }

    func changeImageSize(level: Int) {
        // 다중 이미지 처리
        if !selectedImages.value.isEmpty {
            var updatedImages: [CompressedImage] = []
            for image in selectedImages.value {
                if case .success(let updated) = imageCompressUseCase.resize(image, level: level) {
                    updatedImages.append(updated)
                } else {
                    updatedImages.append(image)
                }
            }
            selectedImages.value = updatedImages
            totalImageCount.value = updatedImages.count

            // 현재 선택된 이미지 업데이트
            let index = currentImageIndex.value
            if index < updatedImages.count {
                currentImage.value = updatedImages[index]
                syncToLegacy(from: updatedImages[index])
            }
            return
        }

        // 단일 이미지 (하위 호환)
        if let image = currentImage.value {
            let result = imageCompressUseCase.resize(image, level: level)
            if case .success(let updated) = result {
                currentImage.value = updated
                syncToLegacy(from: updated)
            }
            return
        }

        // Legacy 지원
        guard let data = selectedImg.value, let img = UIImage(data: data.originImgData) else { return }
        let factors: [CGFloat] = [1, 0.75, 0.5, 0.25]
        guard level < factors.count else { return }
        let targetSize = CGSize(
            width: img.size.width * factors[level],
            height: img.size.height * factors[level]
        )
        selectedImg.value = legacyImageUseCase?.resizeImage(data, targetSize: targetSize)
    }

    // MARK: - 다중 이미지 API

    func selectCurrentImageAt(index: Int) {
        guard index >= 0 && index < selectedImages.value.count else { return }
        currentImageIndex.value = index
        let image = selectedImages.value[index]
        currentImage.value = image
        syncToLegacy(from: image)
    }

    func removeImageAt(index: Int) {
        guard index >= 0 && index < selectedImages.value.count else { return }

        var images = selectedImages.value
        images.remove(at: index)
        selectedImages.value = images
        totalImageCount.value = images.count

        if images.isEmpty {
            // 모든 이미지 제거됨
            currentImage.value = nil
            selectedImg.value = nil
            currentImageIndex.value = 0
        } else {
            // 현재 인덱스 조정
            let newIndex = min(currentImageIndex.value, images.count - 1)
            currentImageIndex.value = newIndex
            let image = images[newIndex]
            currentImage.value = image
            syncToLegacy(from: image)
        }
    }

    // MARK: - New API (ImagePickerDelegate에서 호출)

    func selectImage(data: Data, name: String, metadata: [String: Any], creationDate: Date?) {
        needReset.value = ()

        guard let size = imageProcessingRepository.getImageSize(from: data) else {
            selectedImg.value = nil
            currentImage.value = nil
            return
        }

        // 새 Entity 생성
        let compressedImage = CompressedImage(
            name: name,
            originalData: data,
            compressedData: data,
            metadata: ImageMetadata(creationDate: creationDate, properties: metadata),
            size: size,
            quality: .original,
            format: .jpeg
        )
        currentImage.value = compressedImage

        // Legacy Entity 동기화
        let legacyImage = ImageWithMetadata(
            imgName: name,
            originImgData: data,
            imgData: data,
            metaData: metadata,
            asset: nil,
            imgSize: CGSize(width: size.width, height: size.height),
            imgQuality: 1
        )
        selectedImg.value = legacyImage
    }

    func cancelImageSelection() {
        selectedImg.value = nil
        currentImage.value = nil
    }

    // MARK: - Private Helpers

    private func syncToLegacy(from image: CompressedImage) {
        let legacyImage = ImageWithMetadata(
            imgName: image.name,
            originImgData: image.originalData,
            imgData: image.compressedData,
            metaData: image.metadata.properties,
            asset: nil,
            imgSize: CGSize(width: image.size.width, height: image.size.height),
            imgQuality: CGFloat(image.quality.rawValue)
        )
        selectedImg.value = legacyImage
    }
}

// MARK: - ImagePickerDelegate

extension DefaultMainViewModel: ImagePickerDelegate {

    func didSelectImage(_ imageData: Data, name: String, metadata: [String : Any], creationDate: Date?) {
        selectImage(data: imageData, name: name, metadata: metadata, creationDate: creationDate)
    }

    func didSelectImages(_ images: [SelectedImageInfo]) {
        needReset.value = ()

        var compressedImages: [CompressedImage] = []

        for imageInfo in images {
            guard let size = imageProcessingRepository.getImageSize(from: imageInfo.data) else {
                continue
            }

            let compressedImage = CompressedImage(
                name: imageInfo.name,
                originalData: imageInfo.data,
                compressedData: imageInfo.data,
                metadata: ImageMetadata(
                    creationDate: imageInfo.creationDate,
                    properties: imageInfo.metadata
                ),
                size: size,
                quality: .original,
                format: .jpeg
            )
            compressedImages.append(compressedImage)
        }

        if compressedImages.isEmpty {
            cancelImageSelection()
            return
        }

        // 다중 이미지 저장
        selectedImages.value = compressedImages
        totalImageCount.value = compressedImages.count
        currentImageIndex.value = 0

        // 첫 번째 이미지를 현재 이미지로 설정
        let firstImage = compressedImages[0]
        currentImage.value = firstImage
        syncToLegacy(from: firstImage)
    }

    func didCancelSelection() {
        cancelImageSelection()
    }
}
