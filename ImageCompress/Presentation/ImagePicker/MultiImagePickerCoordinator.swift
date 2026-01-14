//
//  MultiImagePickerCoordinator.swift
//  ImageCompress
//
//  Created by Clean Architecture
//

import UIKit
import PhotosUI

/// 다중 이미지 선택 결과
struct SelectedImage {
    let data: Data
    let name: String
    let isHEIC: Bool
    let originalSize: Int
}

/// 다중 이미지 선택 델리게이트 프로토콜
protocol MultiImagePickerDelegate: AnyObject {
    /// 이미지들이 선택되었을 때 호출
    func didSelectImages(_ images: [SelectedImage])

    /// 선택이 취소되었을 때 호출
    func didCancelMultiSelection()

    /// 이미지 로딩 진행 상태
    func didUpdateLoadingProgress(current: Int, total: Int)
}

/// 다중 이미지 선택 코디네이터
/// PHPickerViewController를 통한 여러 이미지 선택 처리
final class MultiImagePickerCoordinator: NSObject {

    // MARK: - Properties
    private weak var presenter: UIViewController?
    weak var delegate: MultiImagePickerDelegate?
    private let maxSelection: Int
    private let filterHEICOnly: Bool

    // MARK: - Init
    init(
        presenter: UIViewController,
        maxSelection: Int = 20,
        filterHEICOnly: Bool = false
    ) {
        self.presenter = presenter
        self.maxSelection = maxSelection
        self.filterHEICOnly = filterHEICOnly
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
extension MultiImagePickerCoordinator: PHPickerViewControllerDelegate {

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard !results.isEmpty else {
            delegate?.didCancelMultiSelection()
            return
        }

        let total = results.count
        var selectedImages: [SelectedImage] = []
        let group = DispatchGroup()

        for (index, result) in results.enumerated() {
            group.enter()

            // 진행 상태 업데이트
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.didUpdateLoadingProgress(current: index + 1, total: total)
            }

            result.itemProvider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { [weak self] data, error in
                defer { group.leave() }

                guard let data = data, error == nil else { return }

                var name = result.itemProvider.suggestedName ?? "image_\(index + 1)"

                // 파일 확장자 추출
                if let assetIdentifier = result.assetIdentifier,
                   let asset = PHAsset.fetchAssets(withLocalIdentifiers: [assetIdentifier], options: nil).firstObject,
                   let resource = PHAssetResource.assetResources(for: asset).first {
                    let originalName = resource.originalFilename
                    if !originalName.isEmpty {
                        name = originalName
                    }
                }

                // HEIC 여부 확인
                let isHEIC = self?.checkIsHEIC(data: data) ?? false

                // HEIC 필터링이 활성화된 경우
                if self?.filterHEICOnly == true && !isHEIC {
                    return
                }

                let selectedImage = SelectedImage(
                    data: data,
                    name: name,
                    isHEIC: isHEIC,
                    originalSize: data.count
                )

                DispatchQueue.main.async {
                    selectedImages.append(selectedImage)
                }
            }
        }

        group.notify(queue: .main) { [weak self] in
            if selectedImages.isEmpty {
                self?.delegate?.didCancelMultiSelection()
            } else {
                self?.delegate?.didSelectImages(selectedImages)
            }
        }
    }

    // MARK: - Private Methods
    private func checkIsHEIC(data: Data) -> Bool {
        guard data.count >= 12 else { return false }

        let ftypRange = data[4..<8]
        let ftypString = String(data: ftypRange, encoding: .ascii)

        if ftypString == "ftyp" {
            let brandRange = data[8..<12]
            let brandString = String(data: brandRange, encoding: .ascii)
            return brandString == "heic" || brandString == "heix" || brandString == "mif1"
        }

        if let source = CGImageSourceCreateWithData(data as CFData, nil),
           let type = CGImageSourceGetType(source) as String? {
            return type == "public.heic" || type == "public.heif"
        }

        return false
    }
}
