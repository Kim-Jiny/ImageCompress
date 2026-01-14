//
//  DefaultPermissionRepository.swift
//  ImageCompress
//
//  Created by 김미진 on 11/11/24.
//  Refactored for Clean Architecture
//

import Foundation

/// 권한 관리 Repository 구현체
/// Data Layer - DataSource를 통한 실제 권한 처리
final class DefaultPermissionRepository: PermissionRepository {

    // MARK: - Dependencies
    private let cameraPermissionDataSource: CameraPermissionDataSourceProtocol
    private let photoLibraryPermissionDataSource: PhotoLibraryPermissionDataSourceProtocol

    // MARK: - Init
    init(
        cameraPermissionDataSource: CameraPermissionDataSourceProtocol,
        photoLibraryPermissionDataSource: PhotoLibraryPermissionDataSourceProtocol
    ) {
        self.cameraPermissionDataSource = cameraPermissionDataSource
        self.photoLibraryPermissionDataSource = photoLibraryPermissionDataSource
    }

    // MARK: - PermissionRepository
    func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        cameraPermissionDataSource.requestPermissionCamera(completion: completion)
    }

    func requestPhotoLibraryAddOnlyPermission(completion: @escaping (Bool) -> Void) {
        photoLibraryPermissionDataSource.requestPermissionAndSaveImage(completion: completion)
    }

    func requestPhotoLibraryPermission(completion: @escaping (Bool) -> Void) {
        photoLibraryPermissionDataSource.requestPermissionPhotoLibrary(completion: completion)
    }
}

// MARK: - Legacy Support (Deprecated)
/// 기존 코드 호환을 위한 타입 별칭 - 추후 제거 예정
@available(*, deprecated, renamed: "DefaultPermissionRepository")
typealias PermissionRepositoryImpl = DefaultPermissionRepository
