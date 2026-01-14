//
//  PermissionUseCase.swift
//  ImageCompress
//
//  Created by 김미진 on 11/11/24.
//

import Foundation

/// 권한 상태
enum PermissionStatus {
    case authorized
    case denied
    case notDetermined
}

/// 권한 관리 UseCase 인터페이스
/// Domain Layer - UIKit 무의존
protocol PermissionUseCase {
    func openAppSettings()
    func checkCameraPermission(completion: @escaping (Bool) -> Void)
    func checkPhotoLibraryAddOnlyPermission(completion: @escaping (Bool) -> Void)
    func checkPhotoLibraryPermission(completion: @escaping (Bool) -> Void)
}

/// 권한 관리 UseCase 기본 구현
/// Domain Layer - UIApplication 의존성 제거, ApplicationRepository 사용
final class DefaultPermissionUseCase: PermissionUseCase {

    // MARK: - Dependencies
    private let permissionRepository: PermissionRepository
    private let applicationRepository: ApplicationRepository

    // MARK: - Init
    init(
        permissionRepository: PermissionRepository,
        applicationRepository: ApplicationRepository
    ) {
        self.permissionRepository = permissionRepository
        self.applicationRepository = applicationRepository
    }

    // MARK: - PermissionUseCase
    func openAppSettings() {
        applicationRepository.openSettings()
    }

    func checkCameraPermission(completion: @escaping (Bool) -> Void) {
        permissionRepository.requestCameraPermission(completion: completion)
    }

    func checkPhotoLibraryAddOnlyPermission(completion: @escaping (Bool) -> Void) {
        permissionRepository.requestPhotoLibraryAddOnlyPermission(completion: completion)
    }

    func checkPhotoLibraryPermission(completion: @escaping (Bool) -> Void) {
        permissionRepository.requestPhotoLibraryPermission(completion: completion)
    }
}

// MARK: - Legacy Support (Deprecated)
/// 기존 코드 호환을 위한 타입 별칭 - 추후 제거 예정
@available(*, deprecated, renamed: "DefaultPermissionUseCase")
typealias PermissionUseCaseImpl = DefaultPermissionUseCase
