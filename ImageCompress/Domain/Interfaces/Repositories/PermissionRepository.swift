//
//  PermissionRepository.swift
//  ImageCompress
//
//  Created by 김미진 on 11/11/24.
//

import Foundation

/// 권한 관리 Repository 인터페이스
/// Domain Layer - 구현은 Data Layer에서
protocol PermissionRepository {
    func requestCameraPermission(completion: @escaping (Bool) -> Void)
    func requestPhotoLibraryAddOnlyPermission(completion: @escaping (Bool) -> Void)
    func requestPhotoLibraryPermission(completion: @escaping (Bool) -> Void)
}
