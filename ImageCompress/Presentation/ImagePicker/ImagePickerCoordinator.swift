//
//  ImagePickerCoordinator.swift
//  ImageCompress
//
//  Created by Clean Architecture Refactoring
//

import UIKit
import PhotosUI

/// 이미지 선택 델리게이트 프로토콜
protocol ImagePickerDelegate: AnyObject {
    /// 이미지가 선택되었을 때 호출
    func didSelectImage(
        _ imageData: Data,
        name: String,
        metadata: [String: Any],
        creationDate: Date?
    )

    /// 선택이 취소되었을 때 호출
    func didCancelSelection()
}

/// 이미지 선택 코디네이터
/// PHPickerViewController 처리를 ViewModel에서 분리
final class ImagePickerCoordinator: NSObject {

    // MARK: - Properties
    private weak var presenter: UIViewController?
    weak var delegate: ImagePickerDelegate?

    // MARK: - Init
    init(presenter: UIViewController) {
        self.presenter = presenter
        super.init()
    }

    // MARK: - Public Methods
    func presentPicker() {
        var config = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
        config.selectionLimit = 1
        config.filter = .any(of: [.livePhotos, .images])

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        presenter?.present(picker, animated: true)
    }
}

// MARK: - PHPickerViewControllerDelegate
extension ImagePickerCoordinator: PHPickerViewControllerDelegate {

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let result = results.first else {
            delegate?.didCancelSelection()
            return
        }

        result.itemProvider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { [weak self] data, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    self?.delegate?.didCancelSelection()
                }
                return
            }

            var name = result.itemProvider.suggestedName ?? "unknown"
            var creationDate: Date?
            var metadata: [String: Any] = [:]

            // PHAsset에서 메타데이터 추출
            if let assetIdentifier = result.assetIdentifier,
               let asset = PHAsset.fetchAssets(withLocalIdentifiers: [assetIdentifier], options: nil).firstObject {
                creationDate = asset.creationDate

                // 파일 확장자 추출
                if let resource = PHAssetResource.assetResources(for: asset).first {
                    let ext = resource.uniformTypeIdentifier
                    if let lastComponent = ext.components(separatedBy: ".").last {
                        name += ".\(lastComponent)"
                    } else if !ext.isEmpty {
                        name += ".\(ext)"
                    }
                }
            }

            // EXIF 메타데이터 추출
            if let ciImage = CIImage(data: data) {
                metadata = ciImage.properties
            }

            DispatchQueue.main.async {
                self?.delegate?.didSelectImage(data, name: name, metadata: metadata, creationDate: creationDate)
            }
        }
    }
}
