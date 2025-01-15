//
//  MainViewModel.swift
//  ImageCompress
//
//  Created by 김미진 on 10/8/24.
//

import Foundation
import AVFoundation
import UIKit
import Photos
import PhotosUI

// MARK: - Actions (ViewModel에서 호출될 액션 정의)
struct MainViewModelActions {
}

// MARK: - MainViewModel의 Input, Output 정의

// Input 프로토콜: 뷰에서 호출되는 메서드들
protocol MainViewModelInput {
    func viewDidLoad()
//    func downloadImage(image: ImageWithMetadata, completion: @escaping (Bool) -> Void)
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
}

// Output 프로토콜: 뷰모델에서 뷰로 전달될 데이터들
protocol MainViewModelOutput {
    var error: Observable<String> { get }
    var photoLibraryPermission: Observable<Bool?> { get }
    var photoLibraryOnlyAddPermission: Observable<Bool?> { get }
    var selectedImg: Observable<ImageWithMetadata?> { get }
    var needReset: Observable<Void?> { get }
    var isDownloadSuccess: Bool { get set }
}

// MainViewModel 타입: Input과 Output을 모두 결합한 타입
typealias MainViewModel = MainViewModelInput & MainViewModelOutput

// MARK: - MainViewModel 구현 (ViewModel)

final class DefaultMainViewModel: NSObject, MainViewModel {
    
    // MARK: - Dependencies (필수 의존성들)
    private let imageUseCase: ImageUseCase
    private let permissionUseCase: PermissionUseCase
    private let fetchAppVersionUseCase: FetchAppVersionUseCase
    private let actions: MainViewModelActions?
    private let mainQueue: DispatchQueueType
    
    private var ListLoadTask: Cancellable? { willSet { ListLoadTask?.cancel() } } // QR 항목 로딩을 위한 Cancellable 객체
    
    // MARK: - Output (출력 프로퍼티)
    let error: Observable<String> = Observable("") // 오류 메시지
    let photoLibraryPermission: Observable<Bool?> = Observable(nil) // 사진 라이브러리 권한 상태
    let photoLibraryOnlyAddPermission: Observable<Bool?> = Observable(nil) // 사진 라이브러리 추가 권한 상태
    var selectedImg: Observable<ImageWithMetadata?> = Observable(nil) // 선택된 이미지
    var needReset: Observable<Void?> = Observable(nil)
    var isDownloadSuccess: Bool = false
    
    // MARK: - Init (초기화)
    init(
        imageUseCase: ImageUseCase,
        permissionUseCase: PermissionUseCase,
        fetchAppVersionUseCase: FetchAppVersionUseCase,
        actions: MainViewModelActions? = nil,
        mainQueue: DispatchQueueType = DispatchQueue.main
    ) {
        self.imageUseCase = imageUseCase
        self.permissionUseCase = permissionUseCase
        self.fetchAppVersionUseCase = fetchAppVersionUseCase
        self.actions = actions
        self.mainQueue = mainQueue
    }

    // MARK: - Private Methods (비공개 메서드)
    private func load() {
        
    }
    
    // 오류 처리
    private func handle(error: Error) {
        
    }
    
    // MARK: - Permissions Check (권한 확인)

    // 설정 화면으로 이동하는 메서드
    func openAppSettings() {
        permissionUseCase.openAppSettings()
    }
    
    // 사진 라이브러리 권한 확인
    func checkPhotoLibraryPermission() {
        permissionUseCase.checkPhotoLibraryPermission { [weak self] isPermission in
            self?.photoLibraryPermission.value = isPermission
        }
    }

    // 사진 라이브러리 추가 권한 확인
    func checkPhotoLibraryOnlyAddPermission() {
        permissionUseCase.checkPhotoLibraryAddOnlyPermission { [weak self] isPermission in
            self?.photoLibraryOnlyAddPermission.value = isPermission
        }
    }
    

    // MARK: - Image Download (이미지 다운로드)
    
    // 이미지 다운로드 실행
    private func downloadImage(image: ImageWithMetadata, completion: @escaping (Bool) -> Void) {
        imageUseCase.saveImage(image) { result in
            switch result {
            case .success(let success):
                completion(success) // 성공 시 완료 핸들러 호출
            case .failure(let failure):
                print(failure.localizedDescription)
                completion(false)
            }
        }
    }
   
    
    // MARK: App Setting
    
    func loadLatestVersion(completion: @escaping (String?) -> Void) {
        fetchAppVersionUseCase.execute { [weak self] latestVersion in
            completion(latestVersion)
        }
    }
    
}

// MARK: - Input (뷰 이벤트 처리)

extension DefaultMainViewModel {
    
    // 뷰 로드 시 호출
    func viewDidLoad() {
        load()
    }
    
     // ImagePicker 열기
     func openImagePicker(_ sender: UIViewController) {
         // Create UIImagePickerController instance
         DispatchQueue.main.async {
             var config = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
             config.selectionLimit = 1
             config.filter = .any(of: [.livePhotos, .images])

             let picker = PHPickerViewController(configuration: config)
             picker.delegate = self
             sender.present(picker, animated: true, completion: nil)
         }
     }
    
    // Image 공유하기
    func shareImage(_ sender: UIViewController) {
        guard let shareImg = self.selectedImg.value, let image = UIImage(data: shareImg.imgData) else {
            print("공유할 이미지가 없습니다.")
            return
        }
        
        let activityViewController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        
        // iPad에서의 팝오버 설정 (iPad에서는 이 설정이 없으면 앱이 충돌할 수 있음)
        if let popoverController = activityViewController.popoverPresentationController {
            popoverController.sourceView = sender.view // 공유 버튼이 있는 뷰를 기준으로 팝오버 표시
        }
        
        sender.present(activityViewController, animated: true, completion: nil)
    }
    
    func formatImageDate(_ date: Date) -> String? {
        let outputDateFormatter = DateFormatter()
        outputDateFormatter.dateStyle = .medium
        outputDateFormatter.timeStyle = .short
        return outputDateFormatter.string(from: date)
    }
    
    func imageSave(completion: @escaping (Bool) -> Void) {
        if let img = selectedImg.value {
            self.downloadImage(image: img) { isSuccess in
                completion(isSuccess)
            }
        }
    }
    
    func changeImageQuality(level: Int) {
        guard let data = self.selectedImg.value else { return }
        switch level {
        case 0:
            self.selectedImg.value = imageUseCase.adjustImageQuality(data, quality: 1)
        case 1:
            self.selectedImg.value = imageUseCase.adjustImageQuality(data, quality: 0.5)
        case 2:
            self.selectedImg.value = imageUseCase.adjustImageQuality(data, quality: 0.3)
        case 3:
            self.selectedImg.value = imageUseCase.adjustImageQuality(data, quality: 0)
        default:
            return
        }
    }
    
    
    func changeImageSize(level: Int) {
        guard let data = self.selectedImg.value, let img = UIImage(data: data.originImgData) else { return }
        switch level {
        case 0:
            self.selectedImg.value = imageUseCase.resizeImage(data, targetSize: CGSizeMake(CGFloat(img.size.width), CGFloat(img.size.height)))
        case 1:
            self.selectedImg.value = imageUseCase.resizeImage(data, targetSize: CGSizeMake(CGFloat(img.size.width / 4 * 3), CGFloat(img.size.height / 4 * 3)))
        case 2:
            self.selectedImg.value = imageUseCase.resizeImage(data, targetSize: CGSizeMake(CGFloat(img.size.width / 4 * 2), CGFloat(img.size.height / 4 * 2)))
        case 3:
            self.selectedImg.value = imageUseCase.resizeImage(data, targetSize: CGSizeMake(CGFloat(img.size.width / 4), CGFloat(img.size.height / 4)))
        case 4:
            //TODO: 커스텀 가로 세로를 보여줘야함.
            return
        default:
            return
        }
    }
}

extension DefaultMainViewModel: PHPickerViewControllerDelegate {
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: nil)
        self.needReset.value = .none
        for result in results {
            result.itemProvider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, error in
                guard let data = data, error == nil else { 
                    self.selectedImg.value = nil
                    return
                }
                
                var returnData = ImageWithMetadata(imgName: result.itemProvider.suggestedName ?? "unknown", originImgData: data, imgData: data, metaData: [:], asset: nil, imgSize: UIImage(data: data)?.size ?? .zero, imgQuality: 1)
                // PHPickerResult에서 PHAsset 추출
                if let assetIdentifier = result.assetIdentifier,
                   let asset = PHAsset.fetchAssets(withLocalIdentifiers: [assetIdentifier], options: nil).firstObject {
                    returnData.asset = asset
                    // 촬영 시간 (Creation Date)
                    print("Creation Date: \(asset.creationDate ?? Date())")
                    
                    if let resource = PHAssetResource.assetResources(for: asset).first {
                        let ext = resource.uniformTypeIdentifier
                        // 확장자만 추출하기
                        if let lastPathComponent = ext.components(separatedBy: ".").last {
                            print("확장자: \(lastPathComponent)")
                            returnData.imgName += ".\(lastPathComponent)"
                        }else {
                            if ext != "" {
                                returnData.imgName += ".\(ext)"
                            }
                        }
                    }
                    // 위치 (Location)
//                    if let location = asset.location {
//                        print("Location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
//                    }
                    
                    // EXIF 메타데이터
                    if let ciImage = CIImage(data: data) {
                        let properties = ciImage.properties
                        returnData.metaData = properties
                    }
                }
                
                self.selectedImg.value = returnData
            }
        }
    }
    
}
