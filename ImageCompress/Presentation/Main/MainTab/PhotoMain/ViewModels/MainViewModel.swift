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
    let showDetail: (QRItem) -> Void // QR 항목 세부 사항을 보여주는 액션
}

// MARK: - MainViewModel의 Input, Output 정의

// Input 프로토콜: 뷰에서 호출되는 메서드들
protocol MainViewModelInput {
    func viewDidLoad()
    func didSelectItem(at index: Int)
//    func downloadImage(image: ImageWithMetadata, completion: @escaping (Bool) -> Void)
    func openAppSettings()
    func checkCameraPermission()
    func checkPhotoLibraryOnlyAddPermission()
    func checkPhotoLibraryPermission()
    func removeMyQR(_ item: QRItem)
    func saveMyQRList()
    func updateQRItem(_ item: QRItem)
    func fetchMyQRList()
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
    var typeItems: Observable<[QRTypeItemViewModel]> { get }
    var myQRItems: Observable<[QRItem]> { get }
    var error: Observable<String> { get }
    var scannedResult: Observable<String> { get }
    var cameraPermission: Observable<Bool?> { get }
    var photoLibraryPermission: Observable<Bool?> { get }
    var photoLibraryOnlyAddPermission: Observable<Bool?> { get }
    var selectedImg: Observable<ImageWithMetadata?> { get }
}

// MainViewModel 타입: Input과 Output을 모두 결합한 타입
typealias MainViewModel = MainViewModelInput & MainViewModelOutput

// MARK: - MainViewModel 구현 (ViewModel)

final class DefaultMainViewModel: NSObject, MainViewModel {
    
    // MARK: - Dependencies (필수 의존성들)
    private let imageUseCase: ImageUseCase
    private let permissionUseCase: PermissionUseCase
    private let getQRListUseCase: GetQRListUseCase
    private let qrScannerUseCase: QRScannerUseCase
    private let qrItemUseCase: QRItemUseCase
    private let fetchAppVersionUseCase: FetchAppVersionUseCase
    private let actions: MainViewModelActions?
    private let mainQueue: DispatchQueueType
    
    private var ListLoadTask: Cancellable? { willSet { ListLoadTask?.cancel() } } // QR 항목 로딩을 위한 Cancellable 객체
    
    // MARK: - Output (출력 프로퍼티)
    let typeItems: Observable<[QRTypeItemViewModel]> = Observable([]) // QR 항목 뷰모델 리스트
    let myQRItems: Observable<[QRItem]> = Observable([]) // QR 항목 데이터
    let error: Observable<String> = Observable("") // 오류 메시지
    let scannedResult: Observable<String> = Observable("") // 스캔된 결과
    let cameraPermission: Observable<Bool?> = Observable(nil) // 카메라 권한 상태
    let photoLibraryPermission: Observable<Bool?> = Observable(nil) // 사진 라이브러리 권한 상태
    let photoLibraryOnlyAddPermission: Observable<Bool?> = Observable(nil) // 사진 라이브러리 추가 권한 상태
    var selectedImg: Observable<ImageWithMetadata?> = Observable(nil) // 선택된 이미지
    
    // MARK: - Init (초기화)
    init(
        imageUseCase: ImageUseCase,
        permissionUseCase: PermissionUseCase,
        getQRListUseCase: GetQRListUseCase,
        qrScannerUseCase: QRScannerUseCase,
        qrItemUseCase: QRItemUseCase,
        fetchAppVersionUseCase: FetchAppVersionUseCase,
        actions: MainViewModelActions? = nil,
        mainQueue: DispatchQueueType = DispatchQueue.main
    ) {
        self.imageUseCase = imageUseCase
        self.permissionUseCase = permissionUseCase
        self.getQRListUseCase = getQRListUseCase
        self.qrScannerUseCase = qrScannerUseCase
        self.qrItemUseCase = qrItemUseCase
        self.fetchAppVersionUseCase = fetchAppVersionUseCase
        self.actions = actions
        self.mainQueue = mainQueue
    }

    // MARK: - Private Methods (비공개 메서드)

    // QR 항목 로딩
    private func load() {
        ListLoadTask = getQRListUseCase.execute(
            completion: { [weak self] result in
                self?.mainQueue.async {
                    switch result {
                    case .success(let qrTypes):
                        self?.fetchList(qrTypes) // 항목을 성공적으로 가져온 경우
                    case .failure(let error):
                        self?.handle(error: error) // 실패 시 오류 처리
                    }
                }
            }
        )
    }
    
    // QR 항목 뷰모델로 변환하여 typeItems에 설정
    private func fetchList(_ qrTypes: [QRTypeItem]) {
        typeItems.value = qrTypes.map(QRTypeItemViewModel.init)
    }
    
    func removeMyQR(_ item: QRItem) {
        qrItemUseCase.removeQRItem(item)
        fetchMyQRList()
    }
    
    func saveMyQRList() {
        qrItemUseCase.saveQRList(myQRItems.value)
    }
    
    // 저장된 내 QRList Fetch
    func fetchMyQRList() {
        myQRItems.value = qrItemUseCase.getQRItems() ?? []
    }
    
    func updateQRItem(_ item: QRItem) {
        if let index = myQRItems.value.firstIndex(where: { $0.id == item.id }) {
            myQRItems.value[index] = item // 기존 항목을 새로운 항목으로 업데이트
            qrItemUseCase.updateQRItem(item) // 저장소에서도 업데이트
        }
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
    
    // 카메라 권한 확인
    func checkCameraPermission() {
        permissionUseCase.checkCameraPermission { [weak self] isPermission in
            self?.cameraPermission.value = isPermission
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
    
    // 항목 선택 시 호출
    func didSelectItem(at index: Int) {
        actions?.showDetail(myQRItems.value[index]) // 선택된 항목에 대한 세부 정보 표시
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
        guard let shareImg = self.selectedImg.value else {
            print("공유할 이미지가 없습니다.")
            return
        }
        
        let activityViewController = UIActivityViewController(activityItems: [shareImg], applicationActivities: nil)
        
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
            self.selectedImg.value = imageUseCase.adjustImageQuality(data, quality: 0.8)
        case 2:
            self.selectedImg.value = imageUseCase.adjustImageQuality(data, quality: 0.5)
        case 3:
            self.selectedImg.value = imageUseCase.adjustImageQuality(data, quality: 0)
        default:
            return
        }
    }
    
    
    func changeImageSize(level: Int) {
        guard let data = self.selectedImg.value, let cgData = UIImage(data: data.originImgData)?.cgImage else { return }
        print(cgData.width)
        print(cgData.height)
        switch level {
        case 0:
            self.selectedImg.value?.imgData = data.originImgData
        case 1:
            self.selectedImg.value = imageUseCase.resizeImage(data, targetSize: CGSizeMake(CGFloat(cgData.width / 4 * 3), CGFloat(cgData.height / 4 * 3)))
            print("\(cgData.width / 4 * 3) \(cgData.height / 4 * 3)")
        case 2:
            self.selectedImg.value = imageUseCase.resizeImage(data, targetSize: CGSizeMake(CGFloat(cgData.width / 4 * 2), CGFloat(cgData.height / 4 * 2)))
            print("\(cgData.width / 4 * 2) \(cgData.height / 4 * 2)")
        case 3:
            self.selectedImg.value = imageUseCase.resizeImage(data, targetSize: CGSizeMake(CGFloat(cgData.width / 4), CGFloat(cgData.height / 4)))
            print("\(cgData.width / 4) \(cgData.height / 4)")
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
        for result in results {
            result.itemProvider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, error in
                guard let data = data, error == nil else { 
                    self.selectedImg.value = nil
                    return
                }
                
                let asset = result.assetIdentifier
                var returnData = ImageWithMetadata(imgName: result.itemProvider.suggestedName ?? "unknown", originImgData: data, imgData: data, metaData: [:], asset: nil)
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
