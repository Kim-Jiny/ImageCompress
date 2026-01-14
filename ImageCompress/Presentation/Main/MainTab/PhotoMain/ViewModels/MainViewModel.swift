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

    // ImagePicker 열기
    func openImagePicker(_ sender: UIViewController) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.imagePickerCoordinator = ImagePickerCoordinator(presenter: sender)
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
        // 새 API 우선
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

    func changeImageQuality(level: Int) {
        // 새 API 우선
        if let image = currentImage.value {
            let quality = ImageQuality.from(level: level)
            let result = imageCompressUseCase.adjustQuality(image, quality: quality)
            if case .success(let updated) = result {
                currentImage.value = updated
                // Legacy 동기화
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
        // 새 API 우선
        if let image = currentImage.value {
            let result = imageCompressUseCase.resize(image, level: level)
            if case .success(let updated) = result {
                currentImage.value = updated
                // Legacy 동기화
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

    func didCancelSelection() {
        cancelImageSelection()
    }
}
