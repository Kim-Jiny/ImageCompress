//
//  ImagePickerCoordinator.swift
//  ImageCompress
//
//  Created by Clean Architecture Refactoring
//

import UIKit
import PhotosUI

/// 선택된 이미지 정보
struct SelectedImageInfo {
    let data: Data
    let name: String
    let metadata: [String: Any]
    let creationDate: Date?
    let originalSize: Int

    var isHEIC: Bool {
        guard data.count >= 12 else { return false }
        let ftypRange = data[4..<8]
        let ftypString = String(data: ftypRange, encoding: .ascii)
        if ftypString == "ftyp" {
            let brandRange = data[8..<12]
            let brandString = String(data: brandRange, encoding: .ascii)
            return brandString == "heic" || brandString == "heix" || brandString == "mif1"
        }
        return false
    }
}

/// 이미지 선택 델리게이트 프로토콜
protocol ImagePickerDelegate: AnyObject {
    /// 단일 이미지가 선택되었을 때 호출 (기존 호환)
    func didSelectImage(
        _ imageData: Data,
        name: String,
        metadata: [String: Any],
        creationDate: Date?
    )

    /// 여러 이미지가 선택되었을 때 호출
    func didSelectImages(_ images: [SelectedImageInfo])

    /// 선택이 취소되었을 때 호출
    func didCancelSelection()
}

// 기본 구현 (선택적 메서드)
extension ImagePickerDelegate {
    func didSelectImages(_ images: [SelectedImageInfo]) {
        // 기본: 첫 번째 이미지만 전달 (하위 호환)
        if let first = images.first {
            didSelectImage(first.data, name: first.name, metadata: first.metadata, creationDate: first.creationDate)
        }
    }
}

/// 이미지 선택 코디네이터
/// PHPickerViewController 처리를 ViewModel에서 분리
final class ImagePickerCoordinator: NSObject {

    // MARK: - Properties
    private weak var presenter: UIViewController?
    weak var delegate: ImagePickerDelegate?
    private let maxSelection: Int

    // MARK: - Init
    init(presenter: UIViewController, maxSelection: Int = 1) {
        self.presenter = presenter
        self.maxSelection = maxSelection
        super.init()
    }

    // MARK: - Public Methods
    func presentPicker() {
        var config = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
        config.selectionLimit = maxSelection
        config.filter = .images

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        presenter?.present(picker, animated: true)
    }
}

// MARK: - PHPickerViewControllerDelegate
extension ImagePickerCoordinator: PHPickerViewControllerDelegate {

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard !results.isEmpty else {
            delegate?.didCancelSelection()
            return
        }

        // 다중 이미지 처리
        let group = DispatchGroup()
        var selectedImages: [SelectedImageInfo] = []
        let lock = NSLock()

        for (index, result) in results.enumerated() {
            group.enter()

            result.itemProvider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { [weak self] data, error in
                defer { group.leave() }

                guard let data = data, error == nil else { return }

                var name = result.itemProvider.suggestedName ?? "image_\(index + 1)"
                var creationDate: Date?
                var metadata: [String: Any] = [:]

                // PHAsset에서 메타데이터 추출
                if let assetIdentifier = result.assetIdentifier,
                   let asset = PHAsset.fetchAssets(withLocalIdentifiers: [assetIdentifier], options: nil).firstObject {
                    creationDate = asset.creationDate

                    // 파일 확장자 추출
                    if let resource = PHAssetResource.assetResources(for: asset).first {
                        let originalName = resource.originalFilename
                        if !originalName.isEmpty {
                            name = originalName
                        }
                    }
                }

                // EXIF 메타데이터 추출
                if let ciImage = CIImage(data: data) {
                    metadata = ciImage.properties
                }

                let imageInfo = SelectedImageInfo(
                    data: data,
                    name: name,
                    metadata: metadata,
                    creationDate: creationDate,
                    originalSize: data.count
                )

                lock.lock()
                selectedImages.append(imageInfo)
                lock.unlock()
            }
        }

        group.notify(queue: .main) { [weak self] in
            if selectedImages.isEmpty {
                self?.delegate?.didCancelSelection()
            } else if selectedImages.count == 1 {
                // 단일 이미지: 기존 메서드 호출
                let img = selectedImages[0]
                self?.delegate?.didSelectImage(img.data, name: img.name, metadata: img.metadata, creationDate: img.creationDate)
            } else {
                // 다중 이미지: 새 메서드 호출
                self?.delegate?.didSelectImages(selectedImages)
            }
        }
    }
}
