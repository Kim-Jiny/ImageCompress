//
//  PhotoLibraryPermissionDataSource.swift
//  ImageCompress
//
//  Created by 김미진 on 11/11/24.
//  Refactored for Clean Architecture
//

import Foundation
import Photos

/// 사진 라이브러리 권한 DataSource 프로토콜
protocol PhotoLibraryPermissionDataSourceProtocol {
    func requestAddOnlyPermission(completion: @escaping (Bool) -> Void)
    func requestFullPermission(completion: @escaping (Bool) -> Void)
}

/// 사진 라이브러리 권한 DataSource 구현체
/// Data Layer - Photos Framework를 사용한 실제 권한 처리
final class PhotoLibraryPermissionDataSource: PhotoLibraryPermissionDataSourceProtocol {

    // MARK: - PhotoLibraryPermissionDataSourceProtocol

    /// 사진 라이브러리에 저장만 가능한 권한 요청
    func requestAddOnlyPermission(completion: @escaping (Bool) -> Void) {
        let authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .addOnly)

        switch authorizationStatus {
        case .authorized, .limited:
            completion(true)

        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
                completion(newStatus == .authorized || newStatus == .limited)
            }

        case .denied, .restricted:
            completion(false)

        @unknown default:
            completion(false)
        }
    }

    /// 사진 라이브러리 전체 접근 권한 요청
    func requestFullPermission(completion: @escaping (Bool) -> Void) {
        let authorizationStatus = PHPhotoLibrary.authorizationStatus()

        switch authorizationStatus {
        case .authorized:
            completion(true)

        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { newStatus in
                completion(newStatus == .authorized)
            }

        case .denied, .restricted, .limited:
            completion(false)

        @unknown default:
            completion(false)
        }
    }
}
